local mock_fs_utils = require("core.mock_filesystem.utils")
local Handle = require("core.mock_filesystem.handle")
local ProcessHandle = require("core.mock_filesystem.process_handle")

---@class MockFS_IO
MockFS_IO = {}
MockFS_IO.__index = MockFS_IO

local function make_function_open(self)
	return function(path, mode)
		if path == nil then
			return nil, "Mock path is nil"
		end
		if type(path) ~= type("") then
			return nil, "Mock path is not a string"
		end
		if #path == 0 then
			return nil, "Mock path is empty"
		end
		if path:sub(1, 1) ~= "/" then
			return nil, 'Mock path should begin with "/"'
		end
		if not (mode == "r" or mode == "w" or mode == "a") then
			return nil, "Invalid mode"
		end
		local parts = mock_fs_utils.split_to_table(path)
		local curr = self.mock_filesystem.table
		for i = 1, #parts - 1 do
			local part = parts[i]
			curr = curr[part]
			if curr == nil then
				return nil, "Mock sub-directory " .. part .. " not found"
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

---@param self MockFS_IO
local function make_function_popen(self)
	return function(cmd)
		local match = string.gmatch(cmd, "mkdir %-p '(.*)' 2>%&1")()
		if not match then
			return nil, "Command is currently unimplemented"
		end
		local path, err = Path:new(match)
		if not path then
			return nil, err
		end
		local curr = self.mock_filesystem.table
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

---@param mock_filesystem MockFilesystem
---@return MockFS_IO
function MockFS_IO:new(mock_filesystem)
	self = {}
	setmetatable(self, MockFS_IO)
	self.mock_filesystem = mock_filesystem
	self.open = make_function_open(self)
	self.popen = make_function_popen(self)
	return self
end

return MockFS_IO
