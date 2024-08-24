local pickers = require "telescope.pickers"
local finders = require "telescope.finders"
local previewers = require "telescope.previewers"
local conf = require("telescope.config").values
local actions = require "telescope.actions"
local action_state = require "telescope.actions.state"
local make_entry = require "telescope.make_entry"

local function linearize_selection_set(selection)
	local selection_array = {}
	for path, _ in pairs(selection) do
		table.insert(selection_array, path)
	end
	return selection_array
end

local make_dir_finder = function(opts)
	return finders.new_async_job({
		command_generator = function(prompt) --return the command broken down in an array + optionally a cwd field and an env field
			return { "find", "-type", "d", "-iname", "*" .. prompt .. "*", "-not", "-path", "*/.git*", "-mindepth", "1", "-printf", "%P\\n" }
		end,
		entry_maker = opts.entry_maker or make_entry.gen_from_file(opts),
		cwd = nil, -- fallback if cwd field is not returned by command_generator
		env = nil, -- fallback if env field is not returned by command_generator
		writer = nil, -- not supported for async job finders
	})
end

local make_selection_previewer = function(opts)
	local cached_selection = {} -- TODO move this in previewer setup config to put it in self.state once 159b8b79666e17c8de0378d5c9dc1bc8c7afabcf is released (probably starting from 0.1.8)

	local function set_content(bufnr, selection)
		local content_lines = linearize_selection_set(selection)
		vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, content_lines)
	end

	local previewer = previewers.new_buffer_previewer {
		define_preview = function(self, _, _) set_content(self.state.bufnr, cached_selection) end,
		title = opts.previewer_title or "Selected Directories",
	}

	function previewer:update(selection)
		cached_selection = selection
		set_content(self.state.bufnr, selection)
	end

	return previewer
end

local make_dir_picker = function(opts, on_confirm)
	opts = opts or {}
	on_confirm = on_confirm or function() end

	local selection = {}

	local picker
	local previewer = make_selection_previewer(opts)

	picker = pickers.new(opts, {
		finder = make_dir_finder(opts),
		previewer = previewer,
		sorter = conf.file_sorter(opts),
		prompt_title = "Search Scope",
		results_title = false,
		layout_strategy = opts.layout_strategy or "center",
		layout_config = opts.layout_config or {
			anchor = "N",
			mirror = true,
		},
		attach_mappings = function(prompt_bufnr)
			actions.select_default:replace(function()
				actions.close(prompt_bufnr)
				on_confirm(linearize_selection_set(selection))
			end)
			actions.toggle_selection:replace(function()
				local path = action_state.get_selected_entry().path
				if selection[path] ~= nil then
					selection[path] = nil
				else
					selection[path] = true
				end
				picker.previewer:update(selection)
			end)
			actions.add_selection:replace(function()
				local path = action_state.get_selected_entry().path
				if selection[path] == nil then
					selection[path] = true
					picker.previewer:update(selection)
				end
			end)
			actions.remove_selection:replace(function()
				local path = action_state.get_selected_entry().path
				if selection[path] ~= nil then
					selection[path] = nil
					picker.previewer:update(selection)
				end
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

	picker:find()
end

return make_dir_picker
