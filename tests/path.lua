local Path = require("crazywall.core.path")
local utils = require("crazywall.core.utils")

local TEST_path = Suite:new("Path")

TEST_path["errors.cannot_modify_void"] = function()
	local _, err = pcall(function()
		Path.void():to_directory()
	end)
	assert(utils.str.ends_with(err or "", Path.errors.cannot_modify_void()))

	_, err = pcall(function()
		Path.void():pop_directory()
	end)
	assert(utils.str.ends_with(err or "", Path.errors.cannot_modify_void()))

	_, err = pcall(function()
		Path.void():push_directory("")
	end)
	assert(utils.str.ends_with(err or "", Path.errors.cannot_modify_void()))

	_, err = pcall(function()
		Path.void():set_filename("")
	end)
	assert(utils.str.ends_with(err or "", Path.errors.cannot_modify_void()))
end

TEST_path["errors.path_should_begin_with_slash"] = function()
	Suite.expect_error(Path:new("home/gitpushjoe"))(
		Path.errors.path_should_begin_with_slash("home/gitpushjoe")
	)
	assert(Path:new("~/"))
	assert(Path:new("/"))
end

return TEST_path
