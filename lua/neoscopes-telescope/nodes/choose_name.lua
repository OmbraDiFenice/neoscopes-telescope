local Node = require("graph_machine.node")
local neoscopes = require("neoscopes")

local ChooseName= Node:new()

function ChooseName:run(context, done)
	vim.ui.input({
		prompt = "New scope name: ",
	}, function(scope_name)
		if scope_name == nil then
			done("cancel")
			return
		end

		if neoscopes.get_all_scopes()[scope_name] ~= nil then
			vim.notify("Scope name already exists, please provide another one", vim.log.levels.ERROR)
			done("invalid_name")
			return
		end

		context.name = scope_name
		done("persist_scope")
	end)
end

return ChooseName
