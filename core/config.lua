local s = require("core.strings")
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
---@field allow_makedir boolean?

---@class Config
---@field note_schema NoteSchema
---@field open_section_symbol string
---@field close_section_symbol string
---@field resolve_directory fun(section: Section, context: Context): Path|nil
---@field resolve_filename (fun(section: Section, context: Context): string?)|nil
---@field transform_lines (fun(section: Section, context: Context): string[])|nil
---@field resolve_reference (fun(section: Section, context: Context): string)|nil
---@field allow_makedir boolean
Config = {}
Config.__index = Config

---@param config_table ConfigTable
---@return Config
function Config:new(config_table)
	self = {}
	---@cast self Config
	setmetatable(self, Config)
	self.open_section_symbol = config_table[s.OPEN_SECTION_SYMBOL] or "> "
	self.close_section_symbol = config_table[s.CLOSE_SECTION_SYMBOL] or "<"
	for _, note_type in ipairs(config_table["note_schema"]) do
		if type(note_type) ~= "table" then
			error("Expected all note types in config to be tables")
		end
		if #note_type < 2 then
			local prefix = note_type[1]:sub(1, 1)
			table.insert(note_type, prefix)
		end
	end
	self.note_schema = config_table[s.NOTE_SCHEMA]
	self.resolve_directory = config_table.resolve_directory
	self.resolve_filename = config_table.resolve_filename
	self.transform_lines = config_table.transform_lines
	self.resolve_reference = config_table.resolve_reference
	self.allow_makedir = config_table.allow_makedir
	return self
end

return Config
