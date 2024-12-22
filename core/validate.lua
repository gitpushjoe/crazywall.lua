local utils = require("core.utils")

local M = {}

---@param data [any, string, string?][]
---@return [any, string, string?]?
M.types = function(data)
	for _, item in ipairs(data) do
		local elem = item[1]
		local expected_types = {}
		for type in item[2]:gmatch("[^|]*") do
			table.insert(expected_types, type)
		end
		local is_correct = true
		for _, expected_type in ipairs(expected_types) do
			if utils.str.ends_with(expected_type, "?") then
				if elem == nil then
					goto continue
				end
				expected_type = string.sub(expected_type, 1, #expected_type - 1)
			end
			if type(elem) == expected_type then
				goto continue
			end
		end
		is_correct = false
	    ::continue::
		if not is_correct then
			return item
		end
	end
	return nil
end

---@param data [any, table, string?][]
---@return [any, table, string?]?
M.are_instances = function(data)
	for _, item in ipairs(data) do
		if not item[1] then
			return item
		end
		if type(item[1]) ~= type({}) then
			return item
		end
		if item[1].__index ~= item[2] then
			return item
		end
	end
	return nil
end


return M
