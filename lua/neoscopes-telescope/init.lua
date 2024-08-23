local scopes = require("neoscopes")
local telescope_builtin = require("telescope.builtin")
local make_picker = require("neoscopes-telescope.picker")

return {
	search_in_scopes = function(opts)
		return make_picker(opts.picker, function(directories)
			scopes.add({
				name = "last manual scope",
				dirs = directories,
			})
			scopes.set_current("last manual scope")

			local find_opts = vim.tbl_deep_extend("force", opts.find or {}, {
				search_dirs = scopes.get_current_dirs()
			})
			telescope_builtin.find_files(find_opts)
		end)
	end
}
