require "core.section"
local utils = require "core.utils"

local M = {}

---@param section Section
---@param callback fun(section: Section): nil
---@return nil
M.preorder_traverse = function (section, callback)
	callback(section)
	if not ipairs(section.children) then
		return
	end
	for _, child in ipairs(section.children) do
		M.preorder_traverse(child, callback)
	end
end

return M
