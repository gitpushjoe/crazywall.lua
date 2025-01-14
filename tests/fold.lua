local Suite = require("tests.suite")
local Config = require("core.config")
local Section = require("core.section")
local fold = require("core.fold")
local Path = require("core.path")
local MockFilesystem = require("core.mock_filesystem.mock_filesystem")

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

	assert(Suite.do_fold(ctx))

	local expected_filesystem = MockFilesystem:new({
		home = {
			tests = {
				["note.txt"] = [[curly fruit
	curly vegetable]],
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

TEST_fold["path_should_not_be_directory"] = function()
	local config = Suite.make_simple_config()
	config.resolve_path = function()
		return assert(Path:new("/some/directory/"))
	end
	local mock_filesystem = Suite.make_simple_filesystem()
	local ctx = Suite.make_simple_ctx(config, mock_filesystem)

	Suite.expect_error(Suite.do_fold(ctx))(
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

	assert(Suite.do_fold(ctx))

	local expected_filesystem = Suite.make_simple_expected_filesystem()
	expected_filesystem.table.home.tests["note.txt"] = "curly foo\nangle baz"
	Suite.expect_equal(mock_filesystem, expected_filesystem)
end

return TEST_fold
