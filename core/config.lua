local validate = require("core.validate")
local errors = require("core.errors")
require("core.context")

---@alias NoteSchema [string, string][]

---@class (exact) ConfigTable
---@field note_schema NoteSchema
---@field open_section_symbol string?
---@field close_section_symbol string?
---@field resolve_directory (fun(section: Section, context: Context): Path)|nil
---@field resolve_filename (fun(section: Section, context: Context): string?)|nil
---@field transform_lines (fun(section: Section, context: Context): string[])|nil
---@field resolve_reference (fun(section: Section, context: Context): string)|nil
---@field retry_count number?
---@field resolve_collision (fun(path: Path, filename: string, section: Section, context: Context, retry_count: number): Path?, string?)|nil
---@field allow_overwrite boolean?
---@field allow_makedir boolean?

---@class Config
---@field note_schema NoteSchema
---@field open_section_symbol string
---@field close_section_symbol string
---@field resolve_directory (fun(section: Section, context: Context): Path)|nil
---@field resolve_filename (fun(section: Section, context: Context): string?)|nil
---@field transform_lines (fun(section: Section, context: Context): string[])|nil
---@field resolve_reference (fun(section: Section, context: Context): string)|nil
---@field retry_count number
---@field resolve_collision fun(path: Path, filename: string, section: Section, context: Context, retry_count: number): Path?, string?
---@field allow_overwrite boolean
---@field allow_makedir boolean
Config = {}
Config.__index = Config
Config.__name = "Config"

---@param config_table ConfigTable
---@return Config?, string?
function Config:new(config_table)
	self = {}
	---@cast self Config
	setmetatable(self, Config)
	local invaild_type = errors.invalid_type("Config:new")
	local err = validate.types({
		{ config_table.open_section_symbol, "string", "open_section_symbol" },
		{
			config_table.close_section_symbol,
			"string",
			"close_section_symbol",
		},
		{ config_table.note_schema, "table", "note_schema" },
		{ config_table.resolve_directory, "function", "resolve_directory" },
		{ config_table.resolve_filename, "function", "resolve_filename" },
		{ config_table.transform_lines, "function", "transform_lines" },
		{ config_table.resolve_reference, "function", "resolve_reference" },
		{ config_table.retry_count, "number", "retry_count" },
		{ config_table.resolve_collision, "function", "resolve_collision" },
		{ config_table.allow_overwrite, "boolean", "allow_overwrite" },
		{ config_table.allow_makedir, "boolean", "allow_makedir" },
	})
	if err then
		return nil, invaild_type(err)
	end
	self.open_section_symbol = config_table.open_section_symbol or "> "
	self.close_section_symbol = config_table.close_section_symbol or "<"
	for i, note_type in ipairs(config_table.note_schema) do
		local curr_string = "config_table.note_schema[" .. i .. "]"
		err = validate.types({
			{ note_type, "table", curr_string },
			{ note_type[1], "string", curr_string .. "[1]" },
			{ note_type[2], "string?", curr_string .. "[2]" },
		})
		if err then
			return nil, invaild_type(err)
		end
		if #note_type < 2 then
			local prefix = note_type[1]:sub(1, 1)
			table.insert(note_type, prefix)
		end
	end
	self.note_schema = config_table.note_schema
	self.resolve_directory = config_table.resolve_directory
	self.resolve_filename = config_table.resolve_filename
	self.transform_lines = config_table.transform_lines
	self.resolve_reference = config_table.resolve_reference
	self.retry_count = config_table.retry_count
	self.resolve_collision = config_table.resolve_collision
	self.allow_overwrite = config_table.allow_overwrite
	self.allow_makedir = config_table.allow_makedir
	return self
end

return Config
