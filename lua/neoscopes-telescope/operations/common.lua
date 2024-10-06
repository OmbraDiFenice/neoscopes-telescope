local config = require("neoscopes-telescope.config")
local DirPicker = require("neoscopes-telescope.pickers.dir_picker")
local ScopePicker = require("neoscopes-telescope.pickers.scope_picker")
local scopes_handler = require("neoscopes-telescope.scopes_handler")

local neoscopes = require("neoscopes")
local a = require("neoscopes-telescope.vendor.async")

local M = {}

M.persist = function()
	local persist_file = config.get().scopes.persist_file
	scopes_handler.persist_all({
		persist_file = persist_file,
	})
	vim.notify("scopes persisted in " .. persist_file, vim.log.levels.INFO)
end

M.select_scope = a.wrap(1, function(cb)
	ScopePicker:new(
		{ initial_mode = 'normal' },
		cb, cb
	):find()
end)

M.choose_name = function()
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

M.confirm = a.wrap(1, function(cb)
	vim.ui.select({ true, false }, {
		prompt = "Are you sure?",
		format_item = function(item)
			return item and "Yes" or "No"
		end,
	}, cb)
end)

M.choose_dir = a.wrap(2, function(opts, cb)
	DirPicker:new(vim.tbl_extend("force", {
			initial_mode = 'normal',
			enable_highlighting = false, -- TODO this feature doesn't work properly
		}, opts or {}),
		cb, cb
	):find()
end)

--This function is here just because it can be called also from telescope environment
--but it really belong to scope_mgmt.
--It MUST be called from within an async context anyway.
M.new_scope = function()
	local dirs = M.choose_dir()
	if dirs == nil then return end

	local scope_name = M.choose_name()
	if scope_name == nil then
		vim.notify("Canceled", vim.log.levels.INFO)
		return
	end

	neoscopes.add({
		dirs = dirs,
		name = scope_name,
	})
	M.persist()

	return neoscopes.get_all_scopes()[scope_name]
end

return M
