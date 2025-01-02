local Action = require("core.plan.action")
local utils = require("core.utils")
require("core.plan.action")

---@class Plan
---@field actions Action[]
Plan = {}
Plan.__index = Plan
Plan.__name = "Plan"

---@return Plan
function Plan:new()
	self = {}
	setmetatable(self, Plan)
	self.actions = {}
	return self
end

---@param action Action
---@return Plan
function Plan:add(action)
	table.insert(self.actions, action)
	return self
end

---@return string
function Plan:__tostring()
	local text = "action         lines   chars   path"
	for _, action in ipairs(self.actions) do
		text = text .. "\n" .. action:tostring()
	end
	return text
end

return Plan
