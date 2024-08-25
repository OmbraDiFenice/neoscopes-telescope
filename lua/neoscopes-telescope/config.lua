return {
	default = {
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
		find = {
		},
		scopes = {
			persist_file = vim.fn.stdpath("data") .. "/scopes.json",
		},
	}
}
