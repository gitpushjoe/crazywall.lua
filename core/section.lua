Section = {}
Section.__index = Section

function Section:new(id, start_line, end_line, children, parent)
	self = {}
	setmetatable({}, self)
	self.id = id
	self.start_line = start_line
	self.end_line = end_line
	self.children = children
	self.parent = parent
	return self
end

return Section
