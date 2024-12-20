local utils = require "core.utils"
require "core.path"
require "core.context"

---@class Section
---@field type [string, string]
---@field context Context
---@field start_line number?
---@field end_line number?
---@field children Section[]
---@field parent Section?
---@field path Path?
---@field filename string?
---@field lines string[]?
Section = {}
Section.__index = Section

---@param type [string, string]
---@param context Context
---@param start_line number?
---@param end_line number?
---@param children Section[]
---@param parent Section?
function Section:new(type, context, start_line, end_line, children, parent)
	self = {}
	setmetatable(self, Section)
	---@cast self Section
	self.type = type
	self.context = utils.read_only(context)
	self.start_line = start_line
	self.end_line = end_line
	self.children = children
	self.parent = parent
	return self
end

---@return string[]
function Section:get_lines()
	local lines = {}
	for i = self.start_line,self.end_line do
		table.insert(lines, self.context.lines[i])
	end
	lines[1] = string.sub(lines[1], #self:prefix() + 1, #lines[1])
	local last_line = lines[#lines]
	lines[#lines] = string.sub(last_line, 1, #last_line - #self:suffix())
	return lines
end

---@return string
function Section:prefix()
	return self.type[2] .. self.context.config.open_section_symbol
end

---@return string
function Section:suffix()
	return self.context.config.close_section_symbol .. self.type[2]
end

return Section
