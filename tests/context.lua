local Suite = require("tests.suite")
local Config = require("crazywall.core.config")
local Context = require("crazywall.core.context")
local streams = require("crazywall.core.streams")

local TEST_Context = Suite:new("Context")

TEST_Context["errors.invalid_value_for_plan_stream"] = function()
	local invalid_stream = -1
	---@cast invalid_stream Stream
	Suite.expect_error(
		Context:new(
			assert(Config:new({})),
			"",
			"",
			"",
			Suite.make_simple_filesystem(),
			false,
			true,
			invalid_stream,
			streams.NONE,
			false,
			false
		)
	)(Context.errors.invalid_value_for_plan_stream(-1))
end

TEST_Context["errors.invalid_value_for_text_stream"] = function()
	local invalid_stream = -1
	---@cast invalid_stream Stream
	Suite.expect_error(
		Context:new(
			assert(Config:new({})),
			"",
			"",
			"",
			Suite.make_simple_filesystem(),
			false,
			true,
			streams.NONE,
			invalid_stream,
			false,
			false
		)
	)(Context.errors.invalid_value_for_text_stream(-1))
end

return TEST_Context
