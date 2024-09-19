local Node = require("graph_machine.node")
local scopes_handler = require("neoscopes-telescope.scopes_handler")
local config = require("neoscopes-telescope.config")
local neoscopes = require("neoscopes")

local Persist = Node:new()

function Persist:run(context, done)
	if context.default_action == "new_scope" then
		neoscopes.add({
			dirs = context.dirs,
			name = context.name,
		})
	elseif context.default_action == "delete_scope" then
		local scopes = neoscopes.get_all_scopes()
		scopes[context.scope.name] = nil
		neoscopes.clear()
		neoscopes.add_all(vim.tbl_values(scopes))
	elseif context.default_action == "clone_scope" then
		neoscopes.add({
			dirs = context.scope.dirs,
			name = context.name,
		})
	end

	local persist_file = config.get().scopes.persist_file

	scopes_handler.persist_all({
		persist_file = persist_file,
	})

	vim.notify("scopes persisted in " .. persist_file, vim.log.levels.INFO)

	done()
end

return Persist
