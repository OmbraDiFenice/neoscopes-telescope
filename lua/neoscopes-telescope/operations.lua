local config = require("neoscopes-telescope.config")
local DirPicker = require("neoscopes-telescope.pickers.dir_picker")
local ScopePicker = require("neoscopes-telescope.pickers.scope_picker")
local neoscopes = require("neoscopes")
local scopes_handler = require("neoscopes-telescope.scopes_handler")

local a = require("neoscopes-telescope.vendor.async")

local persist = function()
	local persist_file = config.get().scopes.persist_file
	scopes_handler.persist_all({
		persist_file = persist_file,
	})
	vim.notify("scopes persisted in " .. persist_file, vim.log.levels.INFO)
end

local select_scope = a.wrap(1, function(cb)
	ScopePicker:new(
		{ initial_mode = 'normal' },
		cb, cb
	):find()
end)

local function choose_name()
	local _async_input = a.wrap(2, vim.ui.input)

	local name_is_valid = false
	local scope_name
	while not name_is_valid do
		scope_name = _async_input({ prompt = "New scope name: " })
		if scope_name == nil then return end
		if neoscopes.get_all_scopes()[scope_name] ~= nil then
			vim.notify("Scope name already exists", vim.log.levels.ERROR)
		else
			name_is_valid = true
		end
	end
	return scope_name
end

local confirm = a.wrap(1, function(cb)
	vim.ui.select({ true, false }, {
		prompt = "Are you sure?",
		format_item = function(item)
			return item and "Yes" or "No"
		end,
	}, cb)
end)

local choose_dir = a.wrap(1, function(cb)
	DirPicker:new({
			initial_mode = 'normal',
			enable_highlighting = false, -- TODO this feature doesn't work properly
		},
		cb, cb
	):find()
end)


return {
	new_scope = a.sync(0, function()
			local dirs = choose_dir()
			if dirs == nil then return end

			local scope_name = choose_name()
			if scope_name == nil then
				vim.notify("Canceled", vim.log.levels.INFO)
				return
			end

			neoscopes.add({
				dirs = dirs,
				name = scope_name,
			})
			persist()
	end),

	delete_scope = a.sync(0, function()
			local scope = select_scope()
			if scope == nil or not confirm() then
				vim.notify("Canceled", vim.log.levels.INFO)
				return
			end

			local scopes = neoscopes.get_all_scopes()
			scopes[scope.name] = nil
			neoscopes.clear()
			neoscopes.add_all(vim.tbl_values(scopes))

			persist()
	end),

	clone_scope = a.sync(0, function()
			local scope = select_scope()
			if scope == nil then return end

			local new_name = choose_name()
			if new_name == nil then
				vim.notify("Canceled", vim.log.levels.INFO)
				return
			end

			neoscopes.add({
				dirs = scope.dirs,
				name = new_name,
			})
			persist()
	end),

	file_search = a.sync(0, function()
		local scope = select_scope()
		if scope == nil then return end

		require('telescope.builtin').find_files({
			search_dirs = scope.dirs,
		})
	end),

	grep_search = a.sync(0, function()
		local scope = select_scope()
		if scope == nil then return end

		require('telescope.builtin').live_grep({
			search_dirs = scope.dirs,
		})
	end),
}
