local config = require("neoscopes-telescope.config")

local graph_machine = require("graph_machine")
local node = require("graph_machine.node")

local Start = require("neoscopes-telescope.nodes.start")
local SelectScope = require("neoscopes-telescope.nodes.select_scope")
local SelectDir = require("neoscopes-telescope.nodes.select_dir")
local ChooseName = require("neoscopes-telescope.nodes.choose_name")
local Persist = require("neoscopes-telescope.nodes.persist")

local function make_graph()
	local graph = graph_machine:new()

	local start = Start:new("start")
	local select_scope = SelectScope:new("select scope")
	local select_dir = SelectDir:new("select dir")
	local confirm = node:new("confirm", function(self, ctx, done)
		vim.ui.select({ true, false }, {
			prompt = "Are you sure?",
			format_item = function(item)
				return item and "Yes" or "No"
			end,
		}, function(choice)
			if choice == true then done("confirmed") return end
			done("cancel")
		end)
	end)
	local choose_name = ChooseName:new("choose name")
	local persist = Persist:new("persist")
	local cancel = node:new("cancel", function(self, ctx, done)
		vim.notify("Canceled", vim.log.levels.WARN)
		done()
	end)
	local file_search = node:new("file search", function(self, ctx, done)
		require('telescope.builtin').find_files({
			search_dirs = ctx.dirs
		})
		done()
	end)
	local grep_search = node:new("grep search", function(self, ctx, done)
		require('telescope.builtin').live_grep({
			search_dirs = ctx.dirs
		})
		done()
	end)

	graph:add_starting_node(start)
	graph:add_ending_node(persist)
	graph:add_ending_node(cancel)
	graph:add_ending_node(file_search)
	graph:add_ending_node(grep_search)

	graph:add_transition(start, select_scope, "select_scope")
	graph:add_transition(start, select_dir, "new_scope")

	graph:add_transition(select_scope, select_dir, "new_scope")
	-- graph:add_transition(select_scope, select_dir, "edit_scope")
	graph:add_transition(select_scope, choose_name, "clone_scope")
	graph:add_transition(select_scope, confirm, "delete_scope")
	graph:add_transition(select_scope, file_search, "file_search")
	graph:add_transition(select_scope, grep_search, "grep_search")

	graph:add_transition(confirm, persist, "confirmed")

	graph:add_transition(select_dir, choose_name, "choose_scope_name")

	graph:add_transition(choose_name, choose_name, "invalid_name")
	graph:add_transition(choose_name, persist, "persist_scope")

	graph:add_transition(select_scope, cancel, "cancel")
	graph:add_transition(select_dir, cancel, "cancel")
	graph:add_transition(choose_name, cancel, "cancel")
	graph:add_transition(confirm, cancel, "cancel")

	return graph
end

local graph

return {
	setup = function(opts)
		config.setup(opts)
		graph = make_graph()
	end,

	new_scope = function()
		assert(graph ~= nil, "Please initialize the plugin first")
		graph:run_async({ default_action = "new_scope" })
	end,

	delete_scope = function()
		assert(graph ~= nil, "Please initialize the plugin first")
		graph:run_async({ default_action = "delete_scope" })
	end,

	clone_scope = function()
		assert(graph ~= nil, "Please initialize the plugin first")
		graph:run_async({ default_action = "clone_scope" })
	end,

	file_search = function()
		assert(graph ~= nil, "Please initialize the plugin first")
		graph:run_async({ default_action = "file_search" })
	end,

	grep_search = function()
		assert(graph ~= nil, "Please initialize the plugin first")
		graph:run_async({ default_action = "grep_search" })
	end,
}
