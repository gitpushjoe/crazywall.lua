local validate = require("core.validate")
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
	local out = {}
	local plan_cache = {
		[Action.CREATE] = {},
		[Action.MKDIR] = {},
		[Action.OVERWRITE] = {},
	}
	for i = #self.actions, 1, -1 do
		local action = self.actions[i]
		if plan_cache[action.type][tostring(action.path)] == nil then
			local text = "[ "
				.. string.rep(" ", #"OVERWRITE" - #action.type)
				.. action.type
				.. " ] "
			-- TODO(gitpushjoe): align this
			if action.type ~= Action.MKDIR then
				local char_count = 0
				for _, line in ipairs(action.lines) do
					char_count = char_count + #line
				end
				text = text
					.. "( "
					.. #action.lines
					.. "l / "
					.. char_count
					.. "c ) "
			end
			text = text .. tostring(action.path)
			table.insert(out, 1, text)
			plan_cache[action.type][tostring(action.path)] = 1
		end
	end
	return utils.str.join_lines(out)
end

return Plan
