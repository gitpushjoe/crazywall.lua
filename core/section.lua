local utils = require("core.utils")
local validate = require("core.validate")
local Context = require("core.context")

--- Represents a section text in the source file.
--- Sections may be nested within other sections.
--- @class Section
---
--- Unique, monotonically increasing identifier for this section.
--- @field id number
---
--- The type of the current section. A list of three strings:
---  [1] = The name of the type (e.g. `"h1"`, `"code"`, etc.)
---  [2] = The open tag (the text that signals the start of the section).
---  [3] = The close tag (the text that signals the end of the section).
--- @field type [string, string, string]
---
--- The `Context` object currently being used. Used internally for things such
--- as `Section:get_lines()` and `Section:get_text()`
--- @field context Context
---
--- The line that the section starts on in `Context`. Remains accurate, even
--- while sections are being resolved.
--- @field start_line number
---
--- The line that the section ends on in `Context`. Remains accurate, even
--- while sections are being resolved.
--- @field end_line number?
---
--- A list of child sections nested within this section.
--- @field children Section[]
---
--- The parent section containing this section, if there is one.
--- @field parent Section?
---
--- The path currently associated with this section. `nil` on initialization.
--- @field path Path?
---
--- The text generated by `config.transform_lines`, intended to be saved to
--- `section.path`.
--- @field lines string[]?
---
--- The number of indent characters for this section.
--- @field indent string
local Section = {}
Section.__index = Section
Section.__name = "Section"
Section.ROOT = "ROOT"

---@param id number
---@param type [string, string, string]
---@param context Context
---@param start_line number
---@param end_line number?
---@param children Section[]
---@param parent Section?
---@param indent string?
---@return Section?, string?
function Section:new(
	id,
	type,
	context,
	start_line,
	end_line,
	children,
	parent,
	indent
)
	self = {}
	setmetatable(self, Section)

	local err = validate.types("Section:new", {
		{ type, "table", "type" },
		{ id, "number", "id" },
		{ start_line, "number", "start_line" },
		{ end_line, "number?", "end_line" },
		{ children, "table?", "children" },
	}) or validate.are_instances("Section:new", {
		{ context, Context, "context" },
		parent and { parent, Section, "parent" },
	})
	if err then
		return nil, err
	end

	self.id = id
	self.type = type
	self.context = utils.read_only(context)
	self.start_line = start_line
	self.end_line = end_line
	self.children = children
	self.parent = parent
	self.indent = indent or ""
	return self
end

--- Returns an array of strings.
---
--- Returns the lines of text associated with this section in the source file.
--- It will automatically remove the open tag and the close tag. If this method
--- is called in `config.transform_lines` or `config.resolve_reference`, then
--- it is guaranteed that all of the child nodes will have been resolved into
--- references.
--- @return string[]
function Section:get_lines()
	local lines = {}
	if not self.end_line then
		return {}
	end
	for i = self.start_line, self.end_line do
		local line = self.context.lines[i]
		if line ~= nil and line ~= false then
			---@cast line string
			table.insert(lines, line:sub(#self.indent + 1))
		end
	end
	if #lines == 0 then
		return {}
	end
	lines[1] = string.sub(lines[1], #self:open_tag() + 1, #lines[1])
	local last_line = lines[#lines]
	lines[#lines] = string.sub(last_line, 1, #last_line - #self:close_tag())
	return lines
end

--- Returns an array of strings.
---
--- If `config.transform_lines` has been called on this section, this method
--- will return the "transformed lines" (the lines intended to be saved to
--- another file). Otherwise, will return nil.
--- @return string[]?
function Section:get_transformed_lines()
	if not self.lines then
		return nil
	end
	local lines = {}
	for _, line in ipairs(self.lines) do
		table.insert(lines, line)
	end
	return lines
end

--- Returns the text associated with this section in the source file. It will
--- automatically remove the open tag and the close tag. If this method
--- is called in `config.transform_lines` or `config.resolve_reference`, then
--- it is guaranteed that all of the child nodes will have been resolved into
--- references.
--- @return string
function Section:get_text()
	return utils.str.join_lines(self:get_lines())
end

--- If `config.transform_lines` has been called on this section, this method
--- will return the "transformed text" (the text intended to be saved to
--- another file). Otherwise, will return nil.
--- @return string?
function Section:get_transformed_text()
	if not self.lines then
		return nil
	end
	return utils.str.join_lines(assert(self:get_transformed_lines()))
end

--- Returns true if the section is the ROOT section.
--- @return boolean
function Section:is_root()
	return self.type[1] == Section.ROOT
end

--- Returns the open tag for this section.
--- @return string
function Section:open_tag()
	return self.type[2]
end

--- Returns the close tag for this section.
---@return string
function Section:close_tag()
	return self.type[3]
end

--- Returns the name of the type of this section.
--- @return string
function Section:type_name()
	return self.type[1]
end

--- Checks if the name of the type of this section is the same as `name`, and
--- also checks if `name` is one of the available type names in `note_schema`.
--- If `name` isn't present in `note_schema`, throws an error.
--- @param name string
--- @return boolean
function Section:type_name_is(name)
	(function()
		if name == Section.ROOT then
			return
		end
		for _, note_type in ipairs(self.context.config.note_schema) do
			if note_type[1] == name then
				return
			end
		end
		error("Section name " .. name .. " not found in `config.note_schema`.")
	end)()
	return name == self:type_name()
end

---@return string?
function Section:__tostring()
	return "Section {"
		.. '\n\ttype = {"'
		.. self.type[1]
		.. '", "'
		.. self.type[2]
		.. '", "'
		.. self.type[3]
		.. '"}'
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
		.. ",\n\tpath = "
		.. (self.path and ('"' .. tostring(self.path) .. '"') or "nil")
		.. ",\n\tlines = "
		.. (function()
			local text = "{"
			local lines = self:get_lines()
			for i, line in ipairs(lines) do
				if line then
					text = text
						.. '"'
						.. line:gsub("\\", "\\\\")
							:gsub("\n", "\\n")
							:gsub("\r", "\\r")
							:gsub("\t", "\\t")
							:gsub('"', '\\"')
						.. '"'
						.. (i ~= #lines and ", " or "")
				end
			end
			return text .. "}"
		end)()
		.. ",\n\ttransformed_lines = "
		.. (function()
			local text = "{"
			local lines = self:get_transformed_lines()
			if not lines then
				return "nil"
			end
			for i, line in ipairs(lines) do
				if line then
					text = text
						.. '"'
						.. line:gsub("\\", "\\\\")
							:gsub("\n", "\\n")
							:gsub("\r", "\\r")
							:gsub("\t", "\\t")
							:gsub('"', '\\"')
						.. '"'
						.. (i ~= #lines and ", " or "")
				end
			end
			return text .. "}"
		end)()
		.. "\n}"
end

return Section
