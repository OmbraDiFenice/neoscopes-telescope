local make_picker = require("neoscopes-telescope.picker")

return {
	search_in_scopes = function(opts)
		return make_picker(opts)
	end
}
