local errors = require("core.errors")
local utils = require("core.utils")
local Path = require("core.path")
local validate = require("core.validate")
local str = utils.str

---@class (exact) Context
---@field config Config
---@field path string
---@field lines (string|boolean)[]
---@field use_virt boolean
---@field src_path Path
---@field virt_filesystem VirtualFilesystem?
---@field io iolib

Context = {}
Context.__index = Context
Context.__name = "Context"

---@param config Config
---@param path string
---@param inp string|string[]
---@param virt_filesystem VirtualFilesystem?
---@return Context?, string?
function Context:new(config, path, inp, virt_filesystem)
	self = {}
	---@cast self Context
	local invalid_type = errors.invalid_type("Context:new")
	local invalid_instance = errors.invalid_instance("Context:new")
	setmetatable(self, Context)

	local err = validate.are_instances({
		{ config, Config, "config" },
		virt_filesystem
				and { virt_filesystem, VirtualFilesystem, "virt_filesystem" }
			or nil,
	})
	if err then
		return nil, invalid_instance(err)
	end

	self.config = config or {}
	self.use_virt = not not virt_filesystem
	self.virt_filesystem = virt_filesystem

	---@type unknown
	err = validate.types({
		{ path, "string", "path" },
		{ inp, "table|string", "inp" },
	})
	if err then
		return nil, invalid_type(err)
	end

	self.path = path
	self.lines = {}
	self.io = virt_filesystem and virt_filesystem.io or io

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
			err = validate.types({
				{ line, "string", "inp[" .. i .. "]" },
			})
			if err then
				return nil, invalid_type(err)
			end

			table.insert(lines, tostring(line))
		end
	end
	self.lines = lines
	self.src_path = Path:new(path)
	return self
end

return Context
