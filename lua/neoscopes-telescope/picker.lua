local pickers = require "telescope.pickers"
local finders = require "telescope.finders"
local previewers = require "telescope.previewers"
local conf = require("telescope.config").values
local actions = require "telescope.actions"
local action_state = require "telescope.actions.state"
local entry_display = require "telescope.pickers.entry_display"
local strings = require "plenary.strings"

local entries = require "neoscopes-telescope.entries"
local scopes = require "neoscopes"

local hlnamespace_selection = vim.api.nvim_create_namespace("neoscopes-telescope")
local hlgroup_selected = "TelescopeMultiSelection"

local make_neoscopes_finder = function(opts)
	local icon = opts.icons.scope

	local function make_neoscope_entry(entry)
		return {
			value = entries.Entry:new("scope", entry.name),
			ordinal = entry.name,
			path = entry.name,
			display = icon .. " " .. entry.name,
		}
	end

	local scope_list = {}
	for _, scope in pairs(scopes.get_all_scopes()) do
		table.insert(scope_list, scope)
	end

	return finders.new_table({
		results = scope_list,
		entry_maker = make_neoscope_entry,
	})
end

local make_dir_finder = function(opts)
	local icon = opts.icons.dir
	local displayer = entry_display.create({
		separator = " ",
		items = {
			{ width = strings.strdisplaywidth(icon) },
			{ remaining = true },
		},
	})

	local function make_dir_entry(entry)
		return {
			value = entries.Entry:new("dir", entry),
			ordinal = entry,
			path = entry,
			display = displayer({
				{ icon },
				{ entry },
			})
		}
	end

	return finders.new_async_job({
		command_generator = function(prompt) --return the command broken down in an array + optionally a cwd field and an env field
			return { "find", "-type", "d", "-iname", "*" .. prompt .. "*", "-not", "-path", "*/.git*", "-mindepth", "1", "-printf", "%P\\n" }
		end,
		entry_maker = make_dir_entry,
		cwd = nil, -- fallback if cwd field is not returned by command_generator
		env = nil, -- fallback if env field is not returned by command_generator
		writer = nil, -- not supported for async job finders
	})
end

local make_compound_finder = function(opts)
	local finder_list = {
		make_dir_finder(opts),
		make_neoscopes_finder(opts),
	}
	local results = {}

	local function add_to_results(finder_results)
		for _, finder_result in ipairs(finder_results) do
			table.insert(results, finder_result)
		end
	end

	return setmetatable({
		results = results,

		close = function(self)
			for _, finder in ipairs(finder_list) do
				finder:close()
			end
		end,
	}, {
		__call = function(self, prompt, process_result, process_complete)
			for _, finder in ipairs(finder_list) do
				finder(prompt, process_result, process_complete)
				add_to_results(finder.reuslts or {})
			end
		end,
	})
end

local make_selection_previewer = function(opts)
	---@type EntrySet
	local cached_selection = entries.EntrySet:new() -- TODO move this in previewer setup config to put it in self.state once 159b8b79666e17c8de0378d5c9dc1bc8c7afabcf is released (probably starting from 0.1.8)

	---@param bufnr number
	---@param selection EntrySet
	local function set_content(bufnr, selection)
		local content_lines = selection:get_directories()
		vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, content_lines)
	end

	local previewer = previewers.new_buffer_previewer {
		define_preview = function(self, _, _) set_content(self.state.bufnr, cached_selection) end,
		title = opts.previewer_title
	}

	---@param selection EntrySet
	function previewer:update(selection)
		cached_selection = selection
		set_content(self.state.bufnr, selection)
	end

	return previewer
end

local make_dir_picker = function(opts, on_confirm)
	opts = opts or {}
	on_confirm = on_confirm or function() end

	local selection = entries.EntrySet:new()

	local picker
	local previewer = make_selection_previewer(opts)

	picker = pickers.new(opts, {
		finder = make_compound_finder(opts),
		previewer = previewer,
		sorter = conf.file_sorter(opts),
		prompt_title = "Search Scope",
		results_title = false,
		layout_strategy = opts.layout_strategy,
		layout_config = opts.layout_config,
		attach_mappings = function(prompt_bufnr)
			actions.select_default:replace(function()
				actions.close(prompt_bufnr)
				on_confirm(selection:get_directories())
			end)
			actions.toggle_selection:replace(function()
				local telescope_entry = action_state.get_selected_entry()
				if telescope_entry == nil then return end
				local entry = telescope_entry.value
				selection:toggle(entry)
				picker:update(telescope_entry)
			end)
			actions.add_selection:replace(function()
				local telescope_entry = action_state.get_selected_entry()
				if telescope_entry == nil then return end
				local entry = telescope_entry.value
				selection:add(entry)
				picker:update(telescope_entry)
			end)
			actions.remove_selection:replace(function()
				local telescope_entry = action_state.get_selected_entry()
				if telescope_entry == nil then return end
				local entry = telescope_entry.value
				selection:remove(entry)
				picker:update(telescope_entry)
			end)
			actions.select_all:replace(function()
				vim.notify("[neoscopes-telescope] select all: operation not supported", vim.log.levels.WARN)
			end)
			actions.drop_all:replace(function()
				vim.notify("[neoscopes-telescope] drop all: operation not supported", vim.log.levels.WARN)
			end)
			actions.toggle_all:replace(function()
				vim.notify("[neoscopes-telescope] toggle all: operation not supported", vim.log.levels.WARN)
			end)

			return true
		end,
	})

	function picker:update(telescope_entry)
		self.previewer:update(selection)

		local row = self:get_row(telescope_entry.index)
		if selection:contains(telescope_entry.value) then
			vim.api.nvim_buf_add_highlight(self.results_bufnr, hlnamespace_selection, hlgroup_selected, row, 0, -1)
		else
			vim.api.nvim_buf_clear_namespace(self.results_bufnr, hlnamespace_selection, row, row + 1)
		end
	end

	picker:find()
end

return make_dir_picker
