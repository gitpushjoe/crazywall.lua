---@class Path
---@field parts string[]
Path = {}
Path.__index = Path

---@param path string|string[]|Path
---@return Path
function Path:new(path)
	self = {}
	setmetatable(self, Path)
	self.parts = {}
	if type(path) == type({}) then
		---@cast path string[]
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

---@return string
function Path:__tostring()
	local out = ""
	for i, part in ipairs(self.parts) do
		out = out .. part .. (i ~= #self.parts and "/" or "")
	end
	return out
end

---@return string?
function Path:pop()
	if #self.parts == 0 then
		return
	end
	return table.remove(self.parts)
end

---@return string
function Path:__index(idx)
	if type(idx) == type(1) then
		return self.parts[idx]
	else
		return rawget(Path, idx)
	end
end

---@param value string
function Path:__newindex(idx, value)
	if type(idx) == type(1) then
		self.parts[idx] = value
	else
		rawset(self, idx, value)
	end
end

---@return Path
function Path:copy()
	return Path:new(self)
end


return Path
