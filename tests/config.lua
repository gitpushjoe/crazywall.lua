local Suite = require("tests.suite")
local Config = require("core.config")
local streams = require("core.streams")
local fold = require("core.fold")
local MockFilesystem = require("core.mock_filesystem.mock_filesystem")

local TEST_Config = Suite:new("Config")

local make_simple_filesystem = function()
	return MockFilesystem:new({
		home = {
			tests = {
				["note.txt"] = "{foo}\n(bar)\n<baz>",
			},
		},
	})
end

local make_simple_expected_filesystem = function()
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

local make_simple_config = function()
	return assert(Config:new({
		note_schema = {
			{ "curly", "{", "}" },
			{ "paren", "(", ")" },
			{ "angle", "<", ">" },
		},
		resolve_path = function(section, ctx)
			local path = ctx.src_path:copy()
			local first_line = section:get_lines()[1]
			path:set_filename(section.type[1] .. " " .. first_line .. ".txt")
			return path
		end,
		resolve_reference = function(section)
			return assert(section.path:get_filename():gsub(".txt", ""))
		end,
		allow_makedir = false,
	}))
end

local make_simple_ctx = function(config, mock_filesystem)
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
			false
		)
	)
end

local do_fold = function(ctx)
	local root = assert(fold.parse(ctx))
	assert(fold.prepare(root, ctx) == nil)
	assert(fold.execute(root, ctx, false))
end

TEST_Config["(simple)"] = function()
	local config = make_simple_config()
	local mock_filesystem = make_simple_filesystem()
	local ctx = make_simple_ctx(config, mock_filesystem)

	do_fold(ctx)

	local expected_filesystem = make_simple_expected_filesystem()
	Suite.expect_equal(tostring(expected_filesystem), tostring(mock_filesystem))
end

TEST_Config["(note_schema priority)"] = function()
	local config = make_simple_config()
	table.insert(config.note_schema, 1, { "2xcurly", "{{", "}}" })
	local mock_filesystem = make_simple_filesystem()
	mock_filesystem.table.home.tests["note.txt"] =
		"{foo}\n(bar)\n<baz>\n{{foo2}}"
	local ctx = make_simple_ctx(config, mock_filesystem)

	do_fold(ctx)

	local expected_filesystem = make_simple_expected_filesystem()
	local directory = expected_filesystem.table.home.tests
	directory["note.txt"] = directory["note.txt"] .. "\n2xcurly foo2"
	directory["2xcurly foo2.txt"] = "foo2"
	Suite.expect_equal(tostring(expected_filesystem), tostring(mock_filesystem))
end

TEST_Config["(indents)"] = function()
	local config = make_simple_config()
	local mock_filesystem = make_simple_filesystem()
	mock_filesystem.table.home.tests["note.txt"] = [[
{fruit
	(apple
		<golden delicious>
		<granny smith>
	)
	(banana)
}
	{vegetable}
]]
	local ctx = make_simple_ctx(config, mock_filesystem)

	do_fold(ctx)

	local expected_filesystem = MockFilesystem:new({
		home = {
			tests = {
				["note.txt"] = "curly fruit\n\tcurly vegetable",
				["angle golden delicious.txt"] = "golden delicious",
				["angle granny smith.txt"] = "granny smith",
				["paren apple.txt"] = "apple\n\tangle golden delicious\n\tangle granny smith\n",
				["curly fruit.txt"] = "fruit\n\tparen apple\n\tparen banana\n",
				["paren banana.txt"] = "banana",
				["curly vegetable.txt"] = "vegetable",
			},
		},
	})
	Suite.expect_equal(tostring(expected_filesystem), tostring(mock_filesystem))
end

TEST_Config["(resolve_reference returns false)"] = function()
	local config = make_simple_config()
	config.resolve_reference = function(section)
		if section.type[1] == "paren" then
			return false
		end
		return assert(section.path:get_filename():gsub(".txt", ""))
	end
	local mock_filesystem = make_simple_filesystem()
	local ctx = make_simple_ctx(config, mock_filesystem)

	do_fold(ctx)

	local expected_filesystem = make_simple_expected_filesystem()
	expected_filesystem.table.home.tests["note.txt"] = "curly foo\nangle baz"
	Suite.expect_equal(tostring(expected_filesystem), tostring(mock_filesystem))
end

TEST_Config["allow_makedir"] = function()
	local config = make_simple_config()
	config.allow_makedir = true
	config.resolve_path = function(section, ctx)
		local path = ctx.src_path:copy()
		local first_line = section:get_lines()[1]
		path:push_directory(section.type[1] .. " " .. first_line)
		path:set_filename("note.txt")
		return path
	end
	config.resolve_reference = function()
		return false
	end
	local mock_filesystem = make_simple_filesystem()
	local ctx = make_simple_ctx(config, mock_filesystem)

	do_fold(ctx)

	local expected_filesystem = MockFilesystem:new({
		home = {
			tests = {
				["note.txt"] = "",
				["curly foo"] = { ["note.txt"] = "foo" },
				["paren bar"] = { ["note.txt"] = "bar" },
				["angle baz"] = { ["note.txt"] = "baz" },
			},
		},
	})
	Suite.expect_equal(tostring(expected_filesystem), tostring(mock_filesystem))
end

TEST_Config["resolve_collision"] = function()
	local config = make_simple_config()
	config.retry_count = 2
	local mock_filesystem = make_simple_filesystem()
	config.resolve_path = function(_, context)
		local path = context.src_path:copy()
		path:set_filename("foo.txt")
		return path
	end
	config.resolve_reference = function()
		return false
	end
	config.resolve_collision = function(path, _, _, retry_count)
		path:set_filename("foo " .. retry_count .. ".txt")
		return path
	end
	local ctx = make_simple_ctx(config, mock_filesystem)

	do_fold(ctx)

	local expected_filesystem = MockFilesystem:new({
		home = {
			tests = {
				["note.txt"] = "",
				["foo.txt"] = "foo",
				["foo 1.txt"] = "bar",
				["foo 2.txt"] = "baz",
			},
		},
	})
	Suite.expect_equal(tostring(expected_filesystem), tostring(mock_filesystem))
end

TEST_Config["allow_overwrite"] = function()
	local config = make_simple_config()
	config.allow_overwrite = true
	config.resolve_path = function(_, ctx)
		local path = ctx.src_path:copy()
		path:set_filename("foo.txt")
		return path
	end
	config.resolve_reference = function()
		return false
	end
	local mock_filesystem = make_simple_filesystem()
	local ctx = make_simple_ctx(config, mock_filesystem)

	do_fold(ctx)

	local expected_filesystem = MockFilesystem:new({
		home = {
			tests = {
				["note.txt"] = "",
				["foo.txt"] = "baz",
			},
		},
	})
	Suite.expect_equal(tostring(expected_filesystem), tostring(mock_filesystem))
end

TEST_Config["errors.missing_item_in_note_schema_list"] = function()
	local note_schema = { { "missing close tag", "" } }
	local _, err = Config:new({
		note_schema = note_schema,
	})
	Suite.expect_equal(
		err,
		Config.errors.missing_item_in_note_schema_list(note_schema[1], 1)
	)
end

return TEST_Config
