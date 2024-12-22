require("core.path")

---@alias VirtualFile { [string]: VirtualFile|string }

local VirtFS_IO = require("core.virtual_filesystem.io")

---@class VirtualFilesystem
---@field structure VirtualFile
---@field io iolib
VirtualFilesystem = {}
VirtualFilesystem.__index = VirtualFilesystem
VirtualFilesystem.__name = "VirtualFilesystem"

--- @param structure VirtualFile
--- @return VirtualFilesystem
function VirtualFilesystem:new(structure)
	self = {}
	setmetatable(self, VirtualFilesystem)
	---@cast self VirtualFilesystem
	self.structure = structure
	self.io = VirtFS_IO:new(self)
	return self
end

---@return string
function VirtualFilesystem:__tostring()
	local out = ""
	---@param path Path
	local function print_elem(path, elem, filename)
		if type(elem) == type({}) then
			path:push_directory(filename)
			for name, child in pairs(elem) do
				local p = path:copy()
				print_elem(p, child, name)
			end
			out = out .. "(directory) " .. tostring(path) .. "\n"
			return
		end
		path:replace_filename(filename)
		out = out .. tostring(path) .. ": \n"
		out = out .. elem .. "\n-----\n"
	end
	print_elem(Path:new(""), self.structure, "")
	return out
end

return VirtualFilesystem
