local M = {}
M.__index = M

function M:new(parent_directory, filename)
	self = {}
	setmetatable(self, M)
	self.parent_directory = parent_directory
	self.filename = filename
	self.opened = true
	return self
end

function M:write(text)
	if not self.opened then
		return nil, "Cannot write to a closed file"
	end
	self.parent_directory[self.filename] = text
	return self, nil
end

function M:close()
	self.opened = false
	return true, "exit", 0
end

return M
