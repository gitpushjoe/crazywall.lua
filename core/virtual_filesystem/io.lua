local vfs_utils = require("core.virtual_filesystem.utils")
local Handle = require("core.virtual_filesystem.handle")
local ProcessHandle = require("core.virtual_filesystem.process_handle")

---@class VirtualIO
local VirtualIO = {}
VirtualIO.__index = VirtualIO

local function make_function_open(self)
	return function(path, mode)
		if path == nil then
			return nil, "Virtual path is nil"
		end
		if type(path) ~= type("") then
			return nil, "Virtual path is not a string"
		end
		if #path == 0 then
			return nil, "Virtual path is empty"
		end
		if path:sub(1, 1) ~= "/" then
			return nil, 'Virtual path should begin with "/"'
		end
		if not (mode == "r" or mode == "w" or mode == "a") then
			return nil, "Invalid mode"
		end
		local parts = vfs_utils.split_to_table(path)
		local curr = self.virtual_filesystem.structure
		for i = 1, #parts - 1 do
			local part = parts[i]
			curr = curr[part]
			if curr == nil then
				return nil, "Virtual sub-directory " .. part .. " not found"
			end
		end
		if
			(mode == "w" or mode == "a")
			and type(curr[parts[#parts]]) == type({})
		then
			return nil, parts[#parts] .. " is a directory"
		end
		if mode == "r" and curr[parts[#parts]] == nil then
			return nil, path .. " does not exist"
		end
		return Handle:new(curr, parts[#parts])
	end
end

---@param self VirtualIO
local function make_function_popen(self)
	return function(cmd)
		local match = string.gmatch(cmd, "mkdir %-p '(.*)' 2>%&1")()
		if not match then
			return nil, "Command is currently unimplemented"
		end
		local path = Path:new(match)
		local curr = self.virtual_filesystem.structure
		for _, part in ipairs(path.parts) do
			if part ~= "" then
				if curr[part] and type(curr[part]) ~= type({}) then
					-- TODO(gitpushjoe): improve error message
					return nil, "Path already exists"
				end
				curr[part] = curr[part] or {}
				---@cast curr any
				curr = curr[part]
			end
		end
		return ProcessHandle:new("", true, 0)
	end
end

---@param virtual_filesystem VirtualFilesystem
---@return VirtualIO
function VirtualIO:new(virtual_filesystem)
	self = {}
	setmetatable(self, VirtualIO)
	self.virtual_filesystem = virtual_filesystem
	self.open = make_function_open(self)
	self.popen = make_function_popen(self)
	return self
end

return VirtualIO
