local config = require("neoscopes-telescope.config")
local operations = require("neoscopes-telescope.operations")

return {
	setup = function(opts)
		config.setup(opts)
	end,

	new_scope = operations.scope_mgmt.new_scope,
	delete_scope = operations.scope_mgmt.delete_scope,
	clone_scope = operations.scope_mgmt.clone_scope,

	file_search = operations.telescope.file_search,
	grep_search = operations.telescope.grep_search,
}
