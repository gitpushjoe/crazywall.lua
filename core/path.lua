local validate = require("core.validate")

---@class Path
---@field parts string[]
Path = {}
Path.__index = Path
Path.__name = "Path"

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
		for part in string.gmatch(path, "[^/]*") do
			table.insert(self.parts, part)
		end
		if #self.parts == 1 and self.parts[1] == nil then
			self.parts = {}
		end
	end
	return self
end

---@return boolean
function Path:is_directory()
	return self.parts[#self.parts] == ""
end

---@return Path
function Path:to_directory()
	self.parts[#self.parts] = ""
	return self
end

---@return string?
function Path:pop_directory()
	if #self.parts <= 2 then
		return
	end
	return table.remove(self.parts, #self.parts - 1)
end

---@param part string
---@return string?
function Path:push_directory(part)
	if #self.parts == 0 then
		table.insert(self.parts, part)
		return
	end
	table.insert(self.parts, #self.parts, part)
end

---@param filename string
---@return string
function Path:set_filename(filename)
	if #self.parts < 1 then
		return ""
	end
	local old_filename = self.parts[#self.parts]
	self.parts[#self.parts] = filename
	return old_filename
end

---@return string
function Path:get_filename()
	return self.parts[#self.parts]
end

---@return string
function Path:__tostring()
	local out = ""
	for i, part in ipairs(self.parts) do
		out = out .. part .. (i ~= #self.parts and "/" or "")
	end
	return out
end

---@return string
function Path:escaped()
	return "'" .. tostring(self):gsub("'", "'\\''") .. "'"
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
	for i=1,#self.parts do
		if self.parts[i] ~= rhs.parts[i] then
			return false
		end
	end
	return true
end

---@return Path
function Path:directory()
	local copy = self:copy()
	return copy:to_directory()
end

return Path
