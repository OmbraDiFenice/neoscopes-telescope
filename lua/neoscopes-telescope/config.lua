local configs = {}

local defaults = {
	picker = {
		prompt_title = "Scopes",
		results_title = "Scopes",
		previewer_title = "Selected Directories",
		layout_strategy = "center",
		layout_config = {
			anchor = "N",
			mirror = true,
		},
		icons = {
			dir = "",
			scope = "󰥨",
		},
	},
	scopes = {
		persist_file = "neoscopes.config.json",
	},
}

return {
	setup = function(opts)
		configs = vim.tbl_deep_extend("force", defaults, opts or {})
	end,

	get = function() return configs end,
}
