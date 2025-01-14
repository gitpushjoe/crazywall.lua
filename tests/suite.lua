local MockFilesystem = require("core.mock_filesystem.mock_filesystem")
local Config = require("core.config")
local streams = require("core.streams")
local utils = require("core.utils")
local Context = require("core.context")
local fold = require("core.fold")

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
	if param1 == param2 then
		return
	end
	local diff_a = assert(io.open("/tmp/crazywall-diff-a.txt", "w"))
	diff_a:write(tostring(param1))
	local diff_b = assert(io.open("/tmp/crazywall-diff-b.txt", "w"))
	diff_b:write(tostring(param2))
	error(
		"Suite.expect_equal:\n"
			.. utils.run_command(
				"diff --side-by-side /tmp/crazywall-diff-a.txt /tmp/crazywall-diff-b.txt"
			)
	)
end

---@param err string?
function Suite.expect_error(should_be_nil, err)
	assert(
		not should_be_nil,
		"Suite.expect_error received non-nil value " .. tostring(should_be_nil)
	)
	return function(expected_error)
		Suite.expect_equal(err, expected_error)
	end
end

---@param key string
---@param value function
function Suite:__newindex(key, value)
	table.insert(self.tests, { name = key, func = value })
end

---@return MockFilesystem
function Suite.make_simple_filesystem()
	return MockFilesystem:new({
		home = {
			tests = {
				["note.txt"] = "{foo}\n(bar)\n<baz>",
			},
		},
	})
end

---@return Config
function Suite.make_simple_config()
	return assert(Config:new({
		note_schema = {
			{ "curly", "{", "}" },
			{ "paren", "(", ")" },
			{ "angle", "<", ">" },
			{ "latex", "$$", "$$" },
			{ "empty_close_tag", "&empty_close_tag&", "" },
		},
		resolve_path = function(section, ctx)
			local path = ctx.src_path:copy()
			local first_line = section:get_lines()[1]
			path:set_filename(
				section:type_name()
					.. (#first_line > 0 and " " or "")
					.. first_line
					.. ".txt"
			)
			return path
		end,
		resolve_reference = function(section)
			return assert(section.path:get_filename():gsub(".txt", ""))
		end,
		transform_lines = function(section)
			return section:get_lines()
		end,
		allow_makedir = false,
		allow_overwrite = false,
		local_retry_count = 0,
		retry_count = 0,
	}))
end

---@return MockFilesystem
function Suite.make_simple_expected_filesystem()
	return MockFilesystem:new({
		home = {
			tests = {
				["note.txt"] = "curly foo\nparen bar\nangle baz",
				["curly foo.txt"] = "foo",
				["paren bar.txt"] = "bar",
				["angle baz.txt"] = "baz",
			},
		},
	})
end

---@param config Config
---@param mock_filesystem MockFilesystem
---@return Context
function Suite.make_simple_ctx(config, mock_filesystem)
	return assert(
		Context:new(
			config,
			"/home/tests/note.txt",
			"/home/tests/note.txt",
			mock_filesystem.table.home.tests["note.txt"],
			mock_filesystem,
			false,
			true,
			streams.NONE,
			streams.NONE,
			false,
			false
		)
	)
end

---@param ctx Context
---@param is_dry_run boolean?
---@return Plan?, string?
function Suite.do_fold(ctx, is_dry_run)
	local root, err = assert(fold.parse(ctx))
	if err then
		return nil, err
	end
	_, err = fold.prepare(root, ctx)
	if err then
		return nil, err
	end
	local plan
	plan, err = fold.execute(root, ctx, is_dry_run or false)
	if err then
		return nil, err
	end
	return plan
end

return Suite
