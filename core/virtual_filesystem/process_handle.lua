local M = {}
M.__index = M

function M:new(result, succeeded, code)
	self = {}
	self.opened = true
	setmetatable(self, M)
	self.result = result
	self.succeeded = succeeded
	self.code = code
	return self
end

function M:write()
	error("currently unimplemented")
end

function M:read()
	if self.closed then
		error("attempt to read from a closed file")
	end
	return self.result
end

function M:close()
	self.opened = false
	return self.succeeded, "exit", self.code
end

return M
