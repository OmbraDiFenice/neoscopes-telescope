local Node = require("graph_machine.node")
local ScopePicker = require("neoscopes-telescope.pickers.scope_picker")

local SelectScope = Node:new()

function SelectScope:run(context, done)
	local opts = {
		initial_mode = 'normal',
	}

	ScopePicker:new(opts,
		function(scope)
			context.scope = scope
			done(context.default_action)
		end,
		function() done('cancel') end
	):find()
end

return SelectScope
