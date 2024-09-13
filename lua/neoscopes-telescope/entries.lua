local scopes = require "neoscopes"

---@class Entry
---@field type "dir"|"scope"
---@field value string

local Entry = {}

---@param type "dir"|"scope"
---@param value string
---@return Entry
function Entry:new(type, value)
	local obj = {
		type = type,
		value = value,
	}
	setmetatable(obj, self)
	self.__index = self
	return obj
end

---@class EntrySet
---@field add function(entry: Entry): nil
---@field remove function(entry: Entry): nil
---@field toggle function(entry: Entry): nil
---@field clear function(): nil
---@field contains function(entry: Entry): boolean
---@field get_directories function(): strin[]
---@field is_empty() function(): boolean

local EntrySet = {}

---@return EntrySet
function EntrySet:new()
	local obj = {
		_entries = {},
	}
	setmetatable(obj, self)
	self.__index = self
	return obj
end

---@param entry Entry
---@return string
local function to_key(entry)
	return entry.type .. " " .. entry.value
end

function EntrySet:add(entry)
	self._entries[to_key(entry)] = entry
end

function EntrySet:remove(entry)
	self._entries[to_key(entry)] = nil
end

function EntrySet:clear()
	self._entries = {}
end

function EntrySet:toggle(entry)
	if self._entries[to_key(entry)] == nil then
		self:add(entry)
	else
		self:remove(entry)
	end
end

function EntrySet:contains(entry)
	return self._entries[to_key(entry)] ~= nil
end

function EntrySet:get_directories()
	local dirs_dict = {}
	for _, entry in pairs(self._entries) do
		if entry.type == "dir" then
			dirs_dict[entry.value] = true
		elseif entry.type == "scope" then
			local scope = scopes.get_all_scopes()[entry.value]
			if scope == nil then goto continue end
			for _, dir in ipairs(scope.dirs) do
				dirs_dict[dir] = true
			end
		end

		::continue::
	end

	local dirs = vim.tbl_keys(dirs_dict)
	table.sort(dirs)
	return dirs
end

function EntrySet:is_empty()
	return next(self._entries) == nil
end

return {
	Entry = Entry,
	EntrySet = EntrySet,
}
