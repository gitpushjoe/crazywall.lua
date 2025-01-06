local validate = require("core.validate")
local utils = require("core.utils")

---@class Path
---@field parts string[]
Path = {}
Path.__index = Path
Path.__name = "Path"

Path.errors = {

	--- @return string
	cannot_modify_void = function()
		return "Cannot modify void path."
	end,

	--- @param path string
	--- @return string
	path_should_begin_with_slash = function(path)
		return "Path " .. path .. ' should begin with "/" or "~/"'
	end,
}

---@param path Path
local handle_is_void = function(path)
	if path:is_void() then
		error(Path.errors.cannot_modify_void())
	end
end

---@param path string|string[]
---@return Path?, string?
function Path:new(path)
	self = {}
	setmetatable(self, Path)

	local err = validate.types("Path:new", { { path, "string|table", "path" } })
	if err then
		return nil, err
	end

	self.parts = {}
	if type(path) == type({}) then
		---@cast path string[]
		err = validate.types_in_list("Path:new", path, "path", "string")
		if err then
			return nil, err
		end

		for _, part in ipairs(path) do
			table.insert(self.parts, part)
		end
	else
		---@cast path string
		if path:sub(1, 1) == "~" and path:sub(2, 2) == "/" then
			path = assert(utils.get_home_directory()) .. path:sub(3)
		end
		if path:sub(1, 1) ~= "/" then
			return nil, Path.errors.path_should_begin_with_slash(path)
		end
		for part in string.gmatch(path, "[^/]*") do
			table.insert(self.parts, part)
		end
		if #self.parts == 1 and self.parts[1] == nil then
			self.parts = {}
		end
	end
	return self
end

---@return Path
function Path.void()
	return assert(Path:new("/dev/null"))
end

---@return boolean
function Path:is_void()
	return #self.parts == 3
		and self.parts[1] == ""
		and self.parts[2] == "dev"
		and self.parts[3] == "null"
end

---@return boolean
function Path:is_directory()
	return self.parts[#self.parts] == ""
end

---@return Path
function Path:to_directory()
	handle_is_void(self)
	self.parts[#self.parts] = ""
	return self
end

---@return string?
function Path:pop_directory()
	handle_is_void(self)
	if #self.parts <= 2 then
		return
	end
	return table.remove(self.parts, #self.parts - 1)
end

---@param part string
---@return string?
function Path:push_directory(part)
	handle_is_void(self)
	if #self.parts == 0 then
		table.insert(self.parts, part)
		return
	end
	table.insert(self.parts, #self.parts, part)
end

---@param filename string
---@return string
function Path:set_filename(filename)
	handle_is_void(self)
	if #self.parts < 1 then
		return ""
	end
	local old_filename = self.parts[#self.parts]
	self.parts[#self.parts] = filename
	return old_filename
end

---@return string
function Path:get_filename()
	if self:is_void() then
		return ""
	end
	return self.parts[#self.parts]
end

---@return string
function Path:__tostring()
	local out = ""
	for i, part in ipairs(self.parts) do
		out = out .. part:gsub("/", "") .. (i ~= #self.parts and "/" or "")
	end
	return out
end

---@return string
function Path:escaped()
	return "'" .. tostring(self):gsub("'", "'\\''") .. "'"
end

--- If the `path` given is a relative path (like `"./foo"` or `"../bar"`), then
--- the `path` is expanded, with the self directory as the base `"./"` path.
--- Otherwise, behaves identically to `Path:new(path)`.
---
--- Examples:
--- ```lua
--- assert(Path:new("/foo/"):join("bar") == Path:new("/foo/bar"))
--- assert(Path:new("/foo/bar"):join("./baz") == Path:new("/foo/baz"))
--- ```
--- @param path string
--- @return Path?
--- @return string? errmsg
function Path:join(path)
	local err = validate.types("Path:join", { { path, "string", "path" } })
	if err then
		return nil, err
	end
	if
		path:sub(1, 1) == "."
		and path:sub(2, 2) == "."
		and path:sub(3, 3) == "/"
	then
		local copy = self:copy()
		copy:pop_directory()
		path = assert(tostring(copy:directory())) .. path:sub(4)
	elseif path:sub(1, 1) == "." and path:sub(2, 2) == "/" then
		path = assert(tostring(self:directory())) .. path:sub(3)
	elseif path.sub(1, 1) ~= "/" then
		path = assert(tostring(self:directory())) .. path
	end
	return Path:new(path)
end

---@return Path
function Path:copy()
	return assert(Path:new(self.parts))
end

---@param rhs Path
---@return boolean
function Path:__eq(rhs)
	if #self.parts ~= #rhs.parts then
		return false
	end
	for i = 1, #self.parts do
		if self.parts[i] ~= rhs.parts[i] then
			return false
		end
	end
	return true
end

---@return Path?
function Path:directory()
	if self:is_void() then
		return nil
	end
	local copy = self:copy()
	return copy:to_directory()
end

return Path
