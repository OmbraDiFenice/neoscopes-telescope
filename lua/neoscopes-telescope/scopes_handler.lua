local scopes = require("neoscopes")

local M = {}

function M.add_and_select(scope, opts)
	scopes.add(scope)
	scopes.set_current(scope.name)
end

return M
