---@alias VirtualFile { [string]: VirtualFile|string }

---@class VirtualFilesystem
---@field structure VirtualFile
---@field io iolib

local VirtFS_IO = require "core.virtual_filesystem.io"

VirtualFilesystem = {}
VirtualFilesystem.__index = VirtualFilesystem

--- @param structure VirtualFile
function VirtualFilesystem:new(structure)
	self = {}
	setmetatable({}, self)
	self.structure = structure
	self.io = VirtFS_IO:new(self)
	return self
end

return VirtualFilesystem

