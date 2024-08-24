local scopes = require("neoscopes")
local scopes_handler = require("neoscopes-telescope.scopes_handler")
local telescope_builtin = require("telescope.builtin")
local make_picker = require("neoscopes-telescope.picker")
local config = require("neoscopes-telescope.config")

return {
	search_in_scopes = function(opts)
		opts = vim.tbl_deep_extend("force", config.default, opts or {})

		return make_picker(opts.picker, function(directories)
			scopes_handler.add_and_select({
				name = "last manual scope",
				dirs = directories,
			})

			local find_opts = vim.tbl_deep_extend("force", opts.find, {
				search_dirs = scopes.get_current_dirs()
			})
			telescope_builtin.find_files(find_opts)
		end)
	end,
}
