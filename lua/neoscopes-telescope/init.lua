local scopes_handler = require("neoscopes-telescope.scopes_handler")
local config = require("neoscopes-telescope.config")
local operations = require("neoscopes-telescope.operations")

return {
	setup = function(opts)
		config.setup(opts)
	end,

	select_scope = operations.scope_mgmt.select_scope,
	new_scope = operations.scope_mgmt.new_scope,
	delete_scope = operations.scope_mgmt.delete_scope,
	clone_scope = operations.scope_mgmt.clone_scope,

	file_search = operations.telescope.file_search,
	grep_search = operations.telescope.grep_search,

	get_last_scope = scopes_handler.get_last_scope,
}
