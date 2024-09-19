local pickers = require("telescope.pickers")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local previewers = require("telescope.previewers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local neoscopes = require("neoscopes")

local config = require("neoscopes-telescope.config")

local ScopePicker = {}

local function get_scope_list()
	local scope_list = {}
	for _, scope in pairs(neoscopes.get_all_scopes()) do
		table.insert(scope_list, scope)
	end
	return scope_list
end

function ScopePicker:new(opts, on_confirm, on_cancel)
	local default_picker_opts = vim.tbl_deep_extend("force", config.get().picker, {
		prompt_title = "Select scope",
	})

	local scope_list = get_scope_list()

	local cancelled = true

	return pickers.new(opts, vim.tbl_deep_extend("force", default_picker_opts, {
		finder = finders.new_table({
			results = scope_list,
			entry_maker = function(scope)
				return {
					value = scope,
					ordinal = scope.name,
					display = scope.name,
				}
			end
		}),
		sorter = conf.file_sorter({}),
		previewer = previewers.new_buffer_previewer({
			title = "Directories in scope",
			define_preview = function(picker_self, entry)
				vim.api.nvim_buf_set_lines(picker_self.state.bufnr, 0, -1, false,
					entry.value.dirs)
			end
		}),
		attach_mappings = function(prompt_bufnr)
			actions.select_default:replace(function()
				local selected_entry = action_state.get_selected_entry()
				cancelled = selected_entry == nil
				actions.close(prompt_bufnr)
				if not cancelled then
					on_confirm(selected_entry.value)
				end
			end)

			actions.close:enhance({
				post = function()
					if cancelled then on_cancel() end
				end
			})

			return true
		end
	}))
end

return ScopePicker
