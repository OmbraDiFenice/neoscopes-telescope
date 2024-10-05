local scopes = require("neoscopes")

local M = {}

function M.add_and_select(scope, opts)
	scopes.add(scope)
	scopes.set_current(scope.name)
end

function M.persist_all(opts)
	local json_scopes = vim.json.encode({
		scopes = vim.tbl_values(scopes.get_all_scopes())
	})

	local fh, err = io.open(opts.persist_file, "w")
	if err ~= nil then vim.notify(err, vim.log.levels.ERROR) return end
	assert(fh ~= nil)

	_, err = fh:write(json_scopes)
	if err ~= nil then vim.notify(err, vim.log.levels.ERROR) end

	fh:close()
end

function M.load_from_file(opts)
	local fh, err = io.open(opts.persist_file, "r")
	if err ~= nil then vim.notify(err, vim.log.levels.ERROR) return end
	assert(fh ~= nil)

	local neoscopes_json = fh:read("*a")
	fh:close()

	local neoscopes_config = vim.json.decode(neoscopes_json)

	for _, scope in ipairs(neoscopes_config.scopes) do
		scopes.add(scope)
	end
end

return M
