local pickers = require("telescope.pickers")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local previewers = require("telescope.previewers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local sorters = require("telescope.sorters")
local strings = require("plenary.strings")

local entries = require "neoscopes-telescope.entries"
local config = require "neoscopes-telescope.config"

local DirPicker = {}

local hlnamespace_selection = vim.api.nvim_create_namespace("neoscopes-telescope")
local hlgroup_selected = "Keyword"

local make_dir_finder = function(opts, selection)
	local function make_entry(entry)
		local type = entry:sub(1, 1)
		local path = entry:sub(3)

		local value
		if type == "d" then
			value = entries.Entry:new("dir", path)
		elseif type == "f" then
			value = entries.Entry:new("file", path)
		else
			return
		end

		local hl_group = nil
		if opts.enable_highlighting and selection:contains(value) then
			hl_group = hlgroup_selected
		end

		local ret = {
			value = value,
			ordinal = entry,
			path = entry,
			display = function(e)
				local icon = opts.icons[e.value.type] or "?"
				local txt = icon .. ' ' .. e.value.value
				if hl_group then
					return txt, { { { 0, #conf.selection_caret + strings.strdisplaywidth(txt) }, hl_group } }
				else
					return txt
				end
			end,
		}

		return ret
	end

	return finders.new_async_job({
		command_generator = function(prompt) --return the command broken down in an array + optionally a cwd field and an env field
			return {
				"find",
				"-iname", "*" .. prompt .. "*",
				"-not", "-path", "*/.git*",
				"-not", "-path", "*/.mypy_cache*",
				"-not", "-path", "*/.venv",
				"-not", "-path", "*/__pycache__*",
				"-mindepth", "1",
				"-printf", "%y %P\\n"
			}
		end,
		entry_maker = make_entry,
		cwd = nil, -- fallback if cwd field is not returned by command_generator
		env = nil, -- fallback if env field is not returned by command_generator
		writer = nil, -- not supported for async job finders
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
		if self.state ~= nil then -- might be nil if the previewer is not rendered because of the zoom being too high
			set_content(self.state.bufnr, selection)
		end
	end

	return previewer
end

function DirPicker:new(opts, on_confirm, on_cancel)
	on_confirm = on_confirm or function() end
	on_cancel = on_cancel or function() end

	local default_picker_opts = vim.tbl_deep_extend("force", config.get().picker, {
		prompt_title = "Directories",
		results_title = false,
	})

	local picker
	local selection = entries.EntrySet:new()
	local previewer = make_selection_previewer(default_picker_opts)

	local cancelled = true

	picker = pickers.new(opts, vim.tbl_deep_extend("force", default_picker_opts, {
		prompt_title = opts.prompt_title or "Select directories",
		results_title = opts.results_title or "Directories",
		finder = make_dir_finder(default_picker_opts, selection),
		previewer = previewer,
		sorter = sorters.highlighter_only(default_picker_opts),
		attach_mappings = function(prompt_bufnr)
			actions.select_default:replace(function()
				if selection:is_empty() then
					vim.notify("Please select at least one directory. To cancel exit the dialog", vim.log.levels.WARN)
					return
				end
				cancelled = false
				actions.close(prompt_bufnr)
				on_confirm(selection:get_directories())
			end)
			actions.close:enhance({
				post = function()
					if cancelled then on_cancel() end
				end
			})
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
		end
	}))

	function picker:_highlight_result(telescope_entry)
		local row = self:get_row(telescope_entry.index)
		if selection:contains(telescope_entry.value) then
			vim.api.nvim_buf_add_highlight(self.results_bufnr, hlnamespace_selection, hlgroup_selected, row, 0, -1)
		else
			vim.api.nvim_buf_clear_namespace(self.results_bufnr, hlnamespace_selection, row, row+1)
		end
	end

	function picker:update(telescope_entry)
		self.previewer:update(selection)

		if default_picker_opts.enable_highlighting == false or opts.enable_highlighting == false then return end
		self:_highlight_result(telescope_entry)
	end

	function picker:update_all()
		self.previewer:update(selection)

		if default_picker_opts.enable_highlighting == false or opts.enable_highlighting == false then return end
		vim.api.nvim_buf_clear_namespace(self.results_bufnr, hlnamespace_selection, 0, -1)
		for entry in self.manager:iter() do
			self:_highlight_result(entry)
		end
	end

	return picker
end

return DirPicker
