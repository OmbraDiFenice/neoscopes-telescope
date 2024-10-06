local op = require("neoscopes-telescope.operations.common")
local neoscopes = require("neoscopes")
local a = require("neoscopes-telescope.vendor.async")

---@class NeoscopeTelescope_TelescopeOperationOptions
---@field use_last_scope boolean
---@field remember_last_scope_used boolean
---@field telescope_options table?

---Uses op.select_scope or op.new_scope internally but check if the specified options
---to control the flow e.g. to avoid the selection UI and use the last
---selected scope instead or if we want to remember the last scope in the future.
---
---@param opts NeoscopeTelescope_TelescopeOperationOptions
local function select_scope_for_search(opts)
	local scope = nil

	if opts.use_last_scope then
		scope = neoscopes.get_current_scope()
		if scope == nil then
			local all_scopes = neoscopes.get_all_scopes()
			if all_scopes == nil or #vim.tbl_keys(all_scopes) == 0 then
				vim.notify("No scope defined, please create one", vim.log.levels.WARN)
				scope = op.new_scope({ prompt_title = "Create a new scope" })
			else
				vim.notify("No active scope found, please select one", vim.log.levels.WARN)
				scope = op.select_scope()
			end
		end
	end

	if scope ~= nil and opts.remember_last_scope_used then
		neoscopes.set_current(scope.name)
	end

	return scope
end


return {
	---@param opts NeoscopeTelescope_TelescopeOperationOptions
	file_search = a.sync(1, function(opts)
		local scope = select_scope_for_search(opts)
		if scope == nil then return end

		require('telescope.builtin').find_files(vim.tbl_deep_extend("force",
		opts.telescope_options or {},
		{
			search_dirs = scope.dirs,
		}))
	end),

	---@param opts NeoscopeTelescope_TelescopeOperationOptions
	grep_search = a.sync(1, function(opts)
		local scope = select_scope_for_search(opts)
		if scope == nil then return end

		require('telescope.builtin').live_grep(vim.tbl_deep_extend("force",
		opts.telescope_options or {},
		{
			search_dirs = vim.tbl_flatten({ scope.dirs, scope.files }), -- use tbl_flatten instead of list_extend to avoid mutating the arguments
		}))
	end),
}
