local utils = require("core.utils")
local Path = require("core.path")
local validate = require("core.validate")
require("core.mock_filesystem.mock_filesystem")
local str = utils.str

---@class (exact) Context
---@field config Config
---@field lines (string|boolean)[]
---@field use_mock_filesystem boolean
---@field src_path Path
---@field mock_filesystem MockFilesystem?
---@field io iolib

Context = {}
Context.__index = Context
Context.__name = "Context"

---@param config Config
---@param path string
---@param inp string|string[]
---@param mock_filesystem MockFilesystem?
---@return Context?, string?
function Context:new(config, path, inp, mock_filesystem)
	self = {}
	---@cast self Context
	setmetatable(self, Context)

	local err = validate.are_instances("Context:new", {
		{ config, Config, "config" },
		mock_filesystem
				and { mock_filesystem, MockFilesystem, "mock_filesystem" }
			or nil,
	})
	if err then
		return nil, err
	end

	self.config = config or {}
	self.use_mock_filesystem = not not mock_filesystem
	self.mock_filesystem = mock_filesystem

	---@type unknown
	err = validate.types("Context:new", {
		{ path, "string", "path" },
		{ inp, "table|string", "inp" },
	})
	if err then
		return nil, err
	end

	self.lines = {}
	self.io = mock_filesystem and mock_filesystem.io or io

	local lines = {}
	if type(inp) == type("") then
		---@cast inp string
		local data = str.split_lines(inp, true)
		for line in data do
			table.insert(lines, line)
		end
	else
		---@cast inp string[]
		for i, line in ipairs(inp) do
			---@type unknown
			err = validate.types("Context:new", {
				{ line, "string", "inp[" .. i .. "]" },
			})
			if err then
				return nil, err
			end

			table.insert(lines, tostring(line))
		end
	end
	self.lines = lines
	local src_path
	src_path, err = Path:new(path)
	if not src_path then
		return nil, err
	end
	self.src_path = src_path
	return self
end

return Context
