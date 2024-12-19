---@class Section
---@field type [string, string]
---@field start_line number?
---@field end_line number?
---@field children Section[]
---@field parent Section?
Section = {}
Section.__index = Section

---@param type [string, string]
---@param start_line number?
---@param end_line number?
---@param children Section[]
---@param parent Section?
function Section:new(type, start_line, end_line, children, parent)
	self = {}
	setmetatable(self, Section)
	self.type = type
	self.start_line = start_line
	self.end_line = end_line
	self.children = children
	self.parent = parent
	return self
end

return Section
