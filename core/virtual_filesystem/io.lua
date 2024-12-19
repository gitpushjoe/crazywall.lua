local vfs_utils = require "core.virtual_filesystem.utils"
local Handle = require "core.virtual_filesystem.handle"

local VirtualIO = {}
VirtualIO.__index = VirtualIO

function VirtualIO:new(virtual_filesystem)
	self = {}
	setmetatable(self, VirtualIO)
	self.virtual_filesystem = virtual_filesystem
	return self
end

function VirtualIO:open(path, mode)
	if (path == nil) then
		return nil, "Virtual path is nil"
	end
	if (type(path) ~= type("")) then
		return nil, "Virtual path is not a string"
	end
	if (#path == 0) then
		return nil, "Virtual path is empty"
	end
	if (path:sub(1, 1) ~= "/") then
		return nil, 'Virtual path should begin with "/"'
	end
	if (not (mode == "r" or mode == "w" or mode == "a")) then
		return nil, "Invalid mode"
	end
	local parts = vfs_utils.split_to_table(path)
	local curr = self.virtual_filesystem.structure
	for i = 1, #parts - 1 do
		local part = parts[i]
		curr = curr[part]
		if (curr == nil) then
			return nil, "Virtual sub-directory " .. part .. " not found"
		end
	end
	if (mode == "w" or mode == "a") and type(curr[parts[#parts]]) == type({}) then
		return nil, parts[#parts] .. " is a directory"
	end
	return Handle:new(curr, parts[#parts])
end

return VirtualIO
