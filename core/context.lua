local utils = require"core.utils"
local str = utils.str
Context = {}
Context.__index = Context

function Context:new(config, path, inp, virt_filesystem)
	self = {}
	setmetatable({}, self)
	self.config = config or {}
	self.path = path
	self.use_virt = not not virt_filesystem
	self.virt_filesystem = virt_filesystem
	self.lines = {}
	if (inp == nil) then
		return self
	end
	local lines = {}
	if (type(inp) == type("")) then
		local data = str.split_lines(inp, true)
		for line in data do
			table.insert(lines, line)
		end
	elseif (type(inp) == type({})) then
		lines = inp
	else
		error "Invalid type for input"
	end
	self.lines = lines
	return self
end

return Context

