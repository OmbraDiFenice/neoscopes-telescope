local config = require("neoscopes-telescope.config")
local scopes = require("neoscopes")

local M = {}

---@param filepath string
---@param data table
local function json_write(filepath, data)
	local json_data = vim.json.encode(data)

	local fh, err = io.open(filepath, "w")
	if err ~= nil then vim.notify(err, vim.log.levels.ERROR) return end
	assert(fh ~= nil)

	_, err = fh:write(json_data)
	if err ~= nil then vim.notify(err, vim.log.levels.ERROR) end

	fh:close()
end

---@param filepath string
---@return table?
local function json_read(filepath)
	local fh, err = io.open(filepath, "r")
	if err ~= nil then vim.notify(err, vim.log.levels.ERROR) return end
	assert(fh ~= nil)

	local neoscopes_json = fh:read("*a")
	fh:close()

	return vim.json.decode(neoscopes_json)
end

function M.persist_all()
	local json_scopes = {
		scopes = vim.tbl_values(scopes.get_all_scopes()),
	}

	local last_scope = scopes.get_current_scope()
	if last_scope ~= nil then
		json_scopes.last_scope = last_scope.name
	end

	json_write(config.get().scopes.persist_file, json_scopes)
end

---@return string? -- last used scope, or nil if none was saved
function M.get_last_scope()
	local json_scopes = json_read(config.get().scopes.persist_file)
	if json_scopes == nil then return nil end
	return json_read(config.get().scopes.persist_file).last_scope
end

return M
