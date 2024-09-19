local Node = require("graph_machine.node")
local DirPicker = require("neoscopes-telescope.pickers.dir_picker")

local SelectDir = Node:new()

function SelectDir:run(context, done)
	local opts = {
		initial_mode = 'normal',
		enable_highlighting = false, -- TODO this feature doesn't work properly
	}

	DirPicker:new(opts,
		function(dirs)
			context.dirs = dirs
			done('choose_scope_name')
		end,
		function() done('cancel') end
	):find()
end

return SelectDir
