local Suite = require("tests.suite")
local Section = require("crazywall.core.section")
local fold = require("crazywall.core.fold")
local Path = require("crazywall.core.path")
local MockFilesystem = require("crazywall.core.mock_filesystem.mock_filesystem")
local MockFilesystemIO = require("crazywall.core.mock_filesystem.io")

local TEST_fold = Suite:new("fold")

TEST_fold["parse (indents)"] = function()
	local config = Suite.make_simple_config()
	local mock_filesystem = Suite.make_simple_filesystem()
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
	local ctx = Suite.make_simple_ctx(config, mock_filesystem)

	assert(fold.fold(ctx))

	local expected_filesystem = MockFilesystem:new({
		home = {
			tests = {
				["note.txt"] = [[curly fruit
	curly vegetable
]],
				["angle golden delicious.txt"] = "golden delicious",
				["angle granny smith.txt"] = "granny smith",
				["paren apple.txt"] = [[apple
	angle golden delicious
	angle granny smith
]],
				["curly fruit.txt"] = [[fruit
	paren apple
	paren banana
]],
				["paren banana.txt"] = "banana",
				["curly vegetable.txt"] = "vegetable",
			},
		},
	})
	Suite.expect_equal(mock_filesystem, expected_filesystem)
end

---@param ctx Context
---@return Section
local make_dummy_root = function(ctx)
	return assert(Section:new(0, { "ROOT", "", "" }, ctx, 1, #ctx.lines, {}))
end

---@param ctx Context
---@return Section
local make_dummy_section = function(ctx)
	return assert(Section:new(0, { "", "", "" }, ctx, 0, 0, {}))
end

TEST_fold["errors.unterminated_section"] = function()
	local config = Suite.make_simple_config()
	local mock_filesystem = Suite.make_simple_filesystem()
	mock_filesystem.table.home.tests["note.txt"] = [[{foo]]
	local ctx = Suite.make_simple_ctx(config, mock_filesystem)

	local unterminated_section = Section:new(
		1,
		{ "curly", "{", "}" },
		ctx,
		1,
		nil,
		{},
		make_dummy_root(ctx)
	)

	Suite.expect_error(fold.parse(ctx))(
		fold.errors.unterminated_section(unterminated_section)
	)

	mock_filesystem.table.home.tests["note.txt"] = [[{foo
(bar)]]
	ctx = Suite.make_simple_ctx(config, mock_filesystem)
	unterminated_section.parent = make_dummy_root(ctx)
	--- Note: only the number of children is relevant
	unterminated_section.children = { make_dummy_section(ctx) }
	Suite.expect_error(fold.parse(ctx))(
		fold.errors.unterminated_section(unterminated_section)
	)

	mock_filesystem.table.home.tests["note.txt"] = [[$$]]
	ctx = Suite.make_simple_ctx(config, mock_filesystem)
	local latex_unterminated_section = Section:new(
		1,
		{ "latex", "$$", "$$" },
		ctx,
		1,
		nil,
		{},
		make_dummy_root(ctx)
	)
	Suite.expect_error(fold.parse(ctx))(
		fold.errors.unterminated_section(latex_unterminated_section)
	)
end

TEST_fold["errors.inconsistent_indent"] = function()
	local config = Suite.make_simple_config()
	local mock_filesystem = Suite.make_simple_filesystem()

	mock_filesystem.table.home.tests["note.txt"] = [[
{foo
    (bar
   )
}]]
	local ctx = Suite.make_simple_ctx(config, mock_filesystem)
	Suite.expect_error(fold.parse(ctx))(fold.errors.inconsistent_indent(3))

	mock_filesystem.table.home.tests["note.txt"] = [[
{foo
		(bar
	)
}]]
	ctx = Suite.make_simple_ctx(config, mock_filesystem)
	Suite.expect_error(fold.parse(ctx))(fold.errors.inconsistent_indent(3))

	mock_filesystem.table.home.tests["note.txt"] = [[
{foo
	(bar
    )
}]]
	ctx = Suite.make_simple_ctx(config, mock_filesystem)
	Suite.expect_error(fold.parse(ctx))(fold.errors.inconsistent_indent(3))

	mock_filesystem.table.home.tests["note.txt"] = [[
{foo
	(bar
	)
}]]
	ctx = Suite.make_simple_ctx(config, mock_filesystem)
	assert(fold.parse(ctx))
end

TEST_fold["errors.cannot_write"] = function()
	local config = Suite.make_simple_config()
	local note_path = assert(Path:new("/home/tests/new_directory/note.txt"))
	config.resolve_path = function()
		return note_path
	end
	config.allow_local_overwrite = true
	local mock_filesystem = Suite.make_simple_filesystem()
	local ctx = Suite.make_simple_ctx(config, mock_filesystem)

	local _, err, root = fold.fold(ctx)
	Suite.expect_error(_, err)(
		fold.errors.cannot_write(tostring(note_path), assert(root).children[3])
	)
end

TEST_fold["errors.maximum_retry_count"] = function()
	local config_tests = require("tests.config")
	local tests_ran = 0
	for _, test in ipairs(config_tests.tests) do
		if test.name == "retry_count" or test.name == "local_retry_count" then
			tests_ran = tests_ran + 1
			test.func()
		end
	end
	Suite.expect_equal(tests_ran, 2)
end

TEST_fold["errors.command_failed"] = function()
	local config = Suite.make_simple_config()
	local mock_filesystem = Suite.make_simple_filesystem()
	config.resolve_path = function()
		return assert(Path:new("/home/tests/new_directory/note.txt"))
	end
	config.allow_local_overwrite = true
	config.allow_makedir = true
	mock_filesystem._debug_error_on_all_commands = true
	local ctx = Suite.make_simple_ctx(config, mock_filesystem)

	Suite.expect_error(fold.fold(ctx))(
		fold.errors.command_failed(
			"mkdir -p '/home/tests/new_directory/' 2>&1",
			MockFilesystemIO.errors.manually_forced_error()
		)
	)
end

TEST_fold["errors.path_should_not_be_directory"] = function()
	local config = Suite.make_simple_config()
	config.resolve_path = function()
		return assert(Path:new("/some/directory/"))
	end
	local mock_filesystem = Suite.make_simple_filesystem()
	local ctx = Suite.make_simple_ctx(config, mock_filesystem)

	Suite.expect_error(fold.fold(ctx))(
		fold.errors.path_should_not_be_directory(
			assert(Path:new("/some/directory/"))
		)
	)
end

TEST_fold["prepare (resolve_reference returns false)"] = function()
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

return TEST_fold
