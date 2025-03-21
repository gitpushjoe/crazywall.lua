local Suite = require("tests.suite")
local Config = require("crazywall.core.config")
local fold = require("crazywall.core.fold")
local Section = require("crazywall.core.section")
local MockFilesystem = require("crazywall.core.mock_filesystem.mock_filesystem")

local TEST_Config = Suite:new("Config")

TEST_Config["(simple)"] = function()
	local config = Suite.make_simple_config()
	local mock_filesystem = Suite.make_simple_filesystem()
	local ctx = Suite.make_simple_ctx(config, mock_filesystem)

	assert(fold.fold(ctx))

	local expected_filesystem = Suite.make_simple_expected_filesystem()
	Suite.expect_equal(mock_filesystem, expected_filesystem)
end

TEST_Config["resolve_reference (returns false)"] = function()
	local config = Suite.make_simple_config()
	config.resolve_reference = function(section)
		if section:type_name_is("paren") then
			return false
		end
		return assert(section.path:get_filename():gsub(".txt", ""))
	end
	local mock_filesystem = Suite.make_simple_filesystem()
	local ctx = Suite.make_simple_ctx(config, mock_filesystem)

	assert(fold.fold(ctx))

	local expected_filesystem = Suite.make_simple_expected_filesystem()
	expected_filesystem.table.home.tests["note.txt"] = "curly foo\nangle baz"
	Suite.expect_equal(mock_filesystem, expected_filesystem)
end

TEST_Config["note_schema (same open and close tag)"] = function()
	local config = Suite.make_simple_config()
	local mock_filesystem = Suite.make_simple_filesystem()
	mock_filesystem.table.home.tests["note.txt"] = [[$$
x = \frac{-b \pm \sqrt{b^{2} - 4ac}}{2a}
$$]]
	local ctx = Suite.make_simple_ctx(config, mock_filesystem)

	assert(fold.fold(ctx))

	local expected_filesystem = MockFilesystem:new({
		home = {
			tests = {
				["note.txt"] = "latex",
				["latex.txt"] = [[

x = \frac{-b \pm \sqrt{b^{2} - 4ac}}{2a}
]],
			},
		},
	})
	Suite.expect_equal(mock_filesystem, expected_filesystem)
end

TEST_Config["empty_close_tag"] = function()
	local config = Suite.make_simple_config()
	local mock_filesystem = Suite.make_simple_filesystem()
	mock_filesystem.table.home.tests["note.txt"] = "&empty_close_tag&"
	local ctx = Suite.make_simple_ctx(config, mock_filesystem)
	local root = fold.parse(ctx)
	assert(root)
	Suite.expect_equal(#root.children, 1)
end

TEST_Config["allow_makedir"] = function()
	local config = Suite.make_simple_config()
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
	local mock_filesystem = Suite.make_simple_filesystem()
	local ctx = Suite.make_simple_ctx(config, mock_filesystem)

	assert(not fold.fold(ctx))
end

TEST_Config["local_retry_count"] = function()
	local config = Suite.make_simple_config()
	config.local_retry_count = 1
	config.resolve_path = function(_, context)
		local path = context.src_path:copy()
		path:set_filename("foo.txt")
		return path
	end
	config.resolve_reference = function()
		return false
	end
	local mock_filesystem = Suite.make_simple_filesystem()
	local ctx = Suite.make_simple_ctx(config, mock_filesystem)

	local _, err, root = fold.fold(ctx)
	Suite.expect_error(_, err)(
		fold.errors.maximum_retry_count(1, assert(root).children[3], true)
	)
	config.local_retry_count = 2
	assert(fold.fold(ctx))

	local expected_filesystem = MockFilesystem:new({
		home = {
			tests = {
				["note.txt"] = "",
				["foo.txt"] = "foo",
				["foo (1).txt"] = "bar",
				["foo (2).txt"] = "baz",
			},
		},
	})
	Suite.expect_equal(mock_filesystem, expected_filesystem)
end

TEST_Config["retry_count"] = function()
	local config = Suite.make_simple_config()
	config.retry_count = 0
	local mock_filesystem = Suite.make_simple_filesystem()
	mock_filesystem.table.home.tests["curly foo.txt"] = "foo"
	mock_filesystem.table.home.tests["paren bar.txt"] = "bar"
	mock_filesystem.table.home.tests["angle baz.txt"] = "baz"
	local ctx = Suite.make_simple_ctx(config, mock_filesystem)

	local _, err, root = fold.fold(ctx)
	Suite.expect_error(_, err)(
		fold.errors.maximum_retry_count(0, assert(root).children[1], false)
	)
	config.retry_count = 2
	ctx = Suite.make_simple_ctx(config, mock_filesystem)
	assert(fold.fold(ctx))

	local expected_filesystem = Suite.make_simple_expected_filesystem()
	expected_filesystem.table.home.tests["curly foo (1).txt"] = "foo"
	expected_filesystem.table.home.tests["paren bar (1).txt"] = "bar"
	expected_filesystem.table.home.tests["angle baz (1).txt"] = "baz"
	Suite.expect_equal(mock_filesystem, expected_filesystem)
end

TEST_Config["allow_overwrite"] = function()
	local config = Suite.make_simple_config()
	config.allow_overwrite = true
	local mock_filesystem = Suite.make_simple_filesystem()
	mock_filesystem.table.home.tests["curly foo.txt"] = "will be overwritten"
	mock_filesystem.table.home.tests["paren bar.txt"] = "will be overwritten"
	mock_filesystem.table.home.tests["angle baz.txt"] = "will be overwritten"
	local ctx = Suite.make_simple_ctx(config, mock_filesystem)

	assert(fold.fold(ctx))

	local expected_filesystem = Suite.make_simple_expected_filesystem()
	Suite.expect_equal(mock_filesystem, expected_filesystem)
end

TEST_Config["allow_local_overwrite"] = function()
	local config = Suite.make_simple_config()
	config.resolve_path = function(_, context)
		local path = context.src_path:copy()
		path:set_filename("foo.txt")
		return path
	end
	config.resolve_reference = function()
		return false
	end
	local mock_filesystem = Suite.make_simple_filesystem()
	local ctx = Suite.make_simple_ctx(config, mock_filesystem)

	assert(not fold.fold(ctx))
	config.allow_local_overwrite = true
	assert(fold.fold(ctx))

	local expected_filesystem = MockFilesystem:new({
		home = {
			tests = {
				["note.txt"] = "",
				["foo.txt"] = "baz",
			},
		},
	})
	Suite.expect_equal(mock_filesystem, expected_filesystem)
end

TEST_Config["errors.missing_item_in_note_schema_list"] = function()
	local note_schema = { { "missing close tag", "" } }
	Suite.expect_error(Config:new({
		note_schema = note_schema,
	}))(Config.errors.missing_item_in_note_schema_list(note_schema[1], 1))
end

TEST_Config["errors.unexpected_key"] = function()
	Suite.expect_error(Config:new({
		unexpected = 1,
	}))(Config.errors.unexpected_key("unexpected"))
end

TEST_Config["errors.root_reserved"] = function()
	Suite.expect_error(Config:new({
		note_schema = { { Section.ROOT, "", "" } },
	}))(Config.errors.root_reserved())
end

return TEST_Config
