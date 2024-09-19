local Node = require("graph_machine.node")

local Start = Node:new()

function Start:run(context, done)
	context.name = ""
	context.dirs = {}

	-- default to select a scope and search for files into it
	-- TODO: this could be made customizable in configs
	if context.default_action == nil then
		context.default_action = "file_search"
	end

	-- if we want to create a new scope we obviously don't have to select an existing one
	if context.default_action == "new_scope" then
		done("new_scope")
		return
	end

	-- any other action (search, grep, delete/rename/edit scope) require to select an existing scope first
	-- and `default_action` will determine what to next
	done("select_scope")
end

return Start
