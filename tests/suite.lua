---@class Suite
---@field name string
---@field tests { name: string, func: function }[]
Suite = {}
Suite.__index = Suite
Suite.__name = "Suite"

---@param name string
---@return Suite
function Suite:new(name)
	self = { name = name, tests = {} }
	setmetatable(self, Suite)
	return self
end

function Suite.expect_equal(param1, param2)
	assert(
		param1 == param2,
		"EXPECTED: \n"
			.. tostring(param1)
			.. "\n TO EQUAL: \n"
			.. tostring(param2)
	)
end

---@param key string
---@param value function
function Suite:__newindex(key, value)
	table.insert(self.tests, { name = key, func = value })
end

return Suite
