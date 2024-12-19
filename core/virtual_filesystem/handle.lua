local M = {}
M.__index = M

function M:new(parent_directory, filename)
	self = {}
	setmetatable(self, M)
	self.parent_directory = parent_directory
	self.filename = filename
	return self
end

return M
