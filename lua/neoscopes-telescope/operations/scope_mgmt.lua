local op = require("neoscopes-telescope.operations.common")
local neoscopes = require("neoscopes")
local a = require("neoscopes-telescope.vendor.async")

return {
	new_scope = a.sync(0, function()
			local dirs = op.choose_dir()
			if dirs == nil then return end

			local scope_name = op.choose_name()
			if scope_name == nil then
				vim.notify("Canceled", vim.log.levels.INFO)
				return
			end

			neoscopes.add({
				dirs = dirs,
				name = scope_name,
			})
			op.persist()
	end),

	delete_scope = a.sync(0, function()
			local scope = op.select_scope()
			if scope == nil or not op.confirm() then
				vim.notify("Canceled", vim.log.levels.INFO)
				return
			end

			local scopes = neoscopes.get_all_scopes()
			scopes[scope.name] = nil
			neoscopes.clear()
			neoscopes.add_all(vim.tbl_values(scopes))

			op.persist()
	end),

	clone_scope = a.sync(0, function()
			local scope = op.select_scope()
			if scope == nil then return end

			local new_name = op.choose_name()
			if new_name == nil then
				vim.notify("Canceled", vim.log.levels.INFO)
				return
			end

			neoscopes.add({
				dirs = scope.dirs,
				name = new_name,
			})
			op.persist()
	end),
}
