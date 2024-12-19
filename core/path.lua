---@class Path
---@field parts string[]
Path = {}
Path.__index = Path

function Path:new(path)
	self = {}
	setmetatable(self, Path)
	self.parts = {}
	for part in string.gmatch(path, "[^/]*") do
		table.insert(self.parts, part)
	end
	if #self.parts == 1 and self.parts[1] == nil then
		self.parts = {}
	end
	return self
end

function Path:__tostring()
	local out = ""
	for i, part in ipairs(self.parts) do
		out = out .. part .. (i ~= #self.parts and "/" or "")
	end
	return out
end

return Path
