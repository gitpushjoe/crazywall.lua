local utils = require("core.utils")
local Path = require("core.path")
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

---@param config Config
---@param path string
---@param inp string|string[]
---@param virt_filesystem VirtualFilesystem?
---@return Context
function Context:new(config, path, inp, virt_filesystem)
	self = {}
	---@cast self Context
	setmetatable(self, Context)
	self.config = config or {}
	self.path = path
	self.use_virt = not not virt_filesystem
	self.virt_filesystem = virt_filesystem
	self.lines = {}
	self.io = virt_filesystem and virt_filesystem.io or io
	if inp == nil then
		return self
	end
	local lines = {}
	if type(inp) == type("") then
		---@cast inp string
		local data = str.split_lines(inp, true)
		for line in data do
			table.insert(lines, line)
		end
	elseif type(inp) == type({}) then
		---@cast inp string[]
		for _, v in ipairs(inp) do
			table.insert(lines, tostring(v))
		end
	else
		error("Invalid type for input")
	end
	self.lines = lines
	self.src_path = Path:new(path)
	return self
end

return Context
