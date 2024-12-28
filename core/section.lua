local utils = require("core.utils")
local validate = require("core.validate")
require("core.path")
require("core.context")

---@class Section
---@field type [string, string]
---@field context Context
---@field start_line number
---@field end_line number?
---@field children Section[]
---@field parent Section?
---@field path Path?
---@field lines string[]?
Section = {}
Section.__index = Section
Section.__name = "Section"

---@param type [string, string]
---@param context Context
---@param start_line number
---@param end_line number?
---@param children Section[]
---@param parent Section?
---@return Section?, string?
function Section:new(type, context, start_line, end_line, children, parent)
	self = {}
	setmetatable(self, Section)
	---@cast self Section

	local err = validate.types("Section:new", {
		{ start_line, "number", "start_line" },
		{ end_line, "number?", "end_line" },
		{ children, "table?", "children" },
	})
	if err then
		return nil, err
	end

	---@type unknown
	err = validate.are_instances("Section:new", {
		{ context, Context, "context" },
		parent and { parent, Section, "parent" },
	})
	if err then
		return nil, err
	end

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
	if self.lines then
		return self.lines
	end
	local lines = {}
	if not self.end_line then
		return {}
	end
	for i = self.start_line, self.end_line do
		local line = self.context.lines[i]
		if line ~= nil and line ~= false then
			table.insert(lines, self.context.lines[i])
		end
	end
	lines[1] = string.sub(lines[1], #self:prefix() + 1, #lines[1])
	local last_line = lines[#lines]
	lines[#lines] = string.sub(last_line, 1, #last_line - #self:suffix())
	return lines
end

---@return string
function Section:prefix()
	return (self.type[2] or "")
		.. (self.context.config.open_section_symbol or "")
end

---@return string
function Section:suffix()
	return (self.context.config.close_section_symbol or "")
		.. (self.type[2] or "")
end

---@return string?
function Section:__tostring()
	return "Section {"
		.. '\n\ttype = "'
		.. self.type[1]
		.. '"'
		.. ",\n\tstart_line = "
		.. self.start_line
		.. ",\n\tend_line = "
		.. (self.end_line or "nil")
		.. ",\n\tchildren = {table of length "
		.. #self.children
		.. "}"
		.. ',\n\tparent = {type = "'
		.. (self.parent and self.parent.type and self.parent.type[1] or "nil")
		.. '", start_line = '
		.. (self.parent and self.parent.start_line or "nil")
		.. ", end_line = "
		.. (self.parent and self.parent.end_line or "nil")
		.. "}"
		.. ',\n\tpath = "'
		.. (tostring(self.path) or "nil")
		.. '",\n\tlines = '
		.. (self:get_lines() and '"' .. utils.str
			.join_lines((self:get_lines() or {}))
			:gsub("\\", "\\\\")
			:gsub("\n", "\\n")
			:gsub("\r", "\\r")
			:gsub("\t", "\\t") or {} .. '"' or "nil")
		.. '"\n}'
end

return Section
