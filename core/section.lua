local utils = require("core.utils")
local validate = require("core.validate")
local errors = require("core.errors")
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
---@field filename string?
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

	local invalid_type = errors.invalid_type("Section:new")
	local invalid_instance = errors.invalid_instance("Section:new")

	local err = validate.types({
		{ start_line, "number", "start_line" },
		{ end_line, "number?", "end_line" },
		{ children, "table?", "children" },
	})
	if err then
		return nil, invalid_type(err)
	end

	---@type unknown
	err = validate.are_instances({
		{ context, Context, "context" },
		parent and { parent, Section, "parent" },
	})
	if err then
		return nil, invalid_instance(err)
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
		if line ~= nil then
			table.insert(lines, self.context.lines[i])
		end
	end
	print(#lines)
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
function Section:get_full_path()
	if not self.path or not self.filename then
		return nil
	end
	return tostring(self.path:copy():insert(self.filename))
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
		.. ",\n\tparent = {type = "
		.. (self.parent and self.parent.type and self.parent.type[1] or "nil")
		.. ", start_line = "
		.. (self.parent and self.parent.start_line or "nil")
		.. ", end_line = "
		.. (self.parent and self.parent.end_line or "nil")
		.. "}"
		.. ",\n\tpath = "
		.. (tostring(self.path) or "nil")
		.. ",\n\tfilename = "
		.. (self.filename or "nil")
		.. ",\n\tlines = "
		.. (self:get_lines() and '"' .. utils.str.join_lines(self:get_lines() or {}) .. '"' or "nil")
		.. "\n}"
end

return Section
