local config = require("neoscopes-telescope.config")
local DirPicker = require("neoscopes-telescope.pickers.dir_picker")
local ScopePicker = require("neoscopes-telescope.pickers.scope_picker")
local neoscopes = require("neoscopes")
local scopes_handler = require("neoscopes-telescope.scopes_handler")

local persist = function()
	local persist_file = config.get().scopes.persist_file
	scopes_handler.persist_all({
		persist_file = persist_file,
	})
	vim.notify("scopes persisted in " .. persist_file, vim.log.levels.INFO)
end

return {
	new_scope = function()
		local add = function(scope_name, dirs)
			neoscopes.add({
				dirs = dirs,
				name = scope_name,
			})
			persist()
		end

		local choose_name = function(dirs)
			vim.ui.input({
				prompt = "New scope name: ",
			}, function(scope_name)
				if scope_name == nil then
					vim.notify("Canceled", vim.log.levels.INFO)
					return
				end
				if neoscopes.get_all_scopes()[scope_name] ~= nil then
					vim.notify("Scope name already exists", vim.log.levels.ERROR)
					return
				end
				add(scope_name, dirs)
			end)
		end

		DirPicker:new({
				initial_mode = 'normal',
				enable_highlighting = false, -- TODO this feature doesn't work properly
			},
			choose_name
		):find()
	end,

	delete_scope = function()
		local delete = function(scope)
			local scopes = neoscopes.get_all_scopes()
			scopes[scope.name] = nil
			neoscopes.clear()
			neoscopes.add_all(vim.tbl_values(scopes))

			persist()
		end

		local confirm = function(scope)
			vim.ui.select({ true, false }, {
				prompt = "Are you sure?",
				format_item = function(item)
					return item and "Yes" or "No"
				end,
			}, function(choice)
				if choice == false then
					vim.notify("Canceled", vim.log.levels.INFO)
					return
				end

				delete(scope)
			end)
		end

		ScopePicker:new(
			{ initial_mode = 'normal' },
			confirm
		):find()
	end,

	clone_scope = function()
		local clone = function(scope, new_name)
			neoscopes.add({
				dirs = scope.dirs,
				name = new_name,
			})

			persist()
		end

		local choose_name = function(scope)
			vim.ui.input({
				prompt = "New scope name: ",
			}, function(new_name)
				if new_name == nil then
					vim.notify("Canceled", vim.log.levels.INFO)
					return
				end
				if neoscopes.get_all_scopes()[new_name] ~= nil then
					vim.notify("Scope name already exists", vim.log.levels.ERROR)
					return
				end
				clone(scope, new_name)
			end)
		end

		ScopePicker:new(
			{ initial_mode = 'normal' },
			choose_name
		):find()
	end,

	file_search = function()
		local file_search = function(scope)
			require('telescope.builtin').find_files({
				search_dirs = scope.dirs,
			})
		end

		ScopePicker:new(
			{ initial_mode = 'normal' },
			file_search
		):find()
	end,

	grep_search = function()
		local grep_search = function(scope)
			require('telescope.builtin').live_grep({
				search_dirs = scope.dirs,
			})
		end

		ScopePicker:new(
			{ initial_mode = 'normal' },
			grep_search
		):find()
	end,
}
