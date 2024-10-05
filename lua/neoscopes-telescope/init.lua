local config = require("neoscopes-telescope.config")
local operations = require('neoscopes-telescope.operations')

return {
	setup = function(opts)
		config.setup(opts)
	end,

	new_scope = operations.new_scope,
	delete_scope = operations.delete_scope,
	clone_scope = operations.clone_scope,
	file_search = operations.file_search,
	grep_search = operations.grep_search,
}
