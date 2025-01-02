local validate = require("core.validate")
local utils = require("core.utils")
local default_config = require("core.defaults.config")
require("core.context")

---@alias NoteSchema [string, string][]

---@class (exact) PartialConfigTable
---@field note_schema NoteSchema?
---@field resolve_path (fun(section: Section, context: Context): Path)|nil
---@field transform_lines (fun(section: Section, context: Context): string[])|nil
---@field resolve_reference (fun(section: Section, context: Context): string|boolean)|nil
---@field retry_count number?
---@field resolve_collision (fun(path: Path, section: Section, context: Context, retry_count: number): Path?)|nil
---@field allow_overwrite boolean?
---@field allow_makedir boolean?

---@class Config
---@field note_schema NoteSchema
---@field resolve_path fun(section: Section, context: Context): Path
---@field transform_lines fun(section: Section, context: Context): string[]
---@field resolve_reference fun(section: Section, context: Context): string|boolean
---@field retry_count number
---@field resolve_collision fun(path: Path, section: Section, context: Context, retry_count: number): Path?
---@field allow_overwrite boolean
---@field allow_makedir boolean
Config = {}
Config.__index = Config
Config.__name = "Config"

Config.errors = utils.read_only({

	---@param list table
	---@return string
	missing_item_in_note_schema_list = function(list, idx)
		return "Missing "
			.. (#list <= 1 and "open-tag" or "close-tag")
			.. "in config.note_schema["
			.. idx
			.. "]."
	end,
})

---@param config_table PartialConfigTable
---@return Config?, string?
function Config:new(config_table)
	self = {}
	---@cast self Config
	setmetatable(self, Config)
	local err = validate.types("Config:new", {
		{ config_table.note_schema, "table?", "note_schema" },
		{ config_table.resolve_path, "function?", "resolve_path" },
		{ config_table.transform_lines, "function?", "transform_lines" },
		{ config_table.resolve_reference, "function?", "resolve_reference" },
		{ config_table.retry_count, "number?", "retry_count" },
		{ config_table.resolve_collision, "function?", "resolve_collision" },
		{ config_table.allow_overwrite, "boolean?", "allow_overwrite" },
		{ config_table.allow_makedir, "boolean?", "allow_makedir" },
	})
	if err then
		return nil, err
	end
	local note_schema = config_table.note_schema or default_config.note_schema
	for i, note_type in ipairs(note_schema) do
		local curr_string = "config_table.note_schema[" .. i .. "]"
		err = validate.types("Config:new", {
			{ note_type[1], "string", curr_string .. "[1]" },
			{ note_type[2], "string", curr_string .. "[2]" },
			{ note_type[3], "string", curr_string .. "[3]" },
		})
		if err then
			return nil, err
		end
		if #note_type < 3 then
			return nil,
				Config.errors.missing_item_in_note_schema_list(note_type, i)
		end
	end
	self.note_schema = note_schema
	self.resolve_path = config_table.resolve_path or default_config.resolve_path
	self.transform_lines = config_table.transform_lines
		or default_config.transform_lines
	self.resolve_reference = config_table.resolve_reference
		or default_config.resolve_reference
	self.retry_count = config_table.retry_count or default_config.retry_count
	self.resolve_collision = config_table.resolve_collision
		or default_config.resolve_collision
	self.allow_overwrite = config_table.allow_overwrite
		or default_config.allow_overwrite
	self.allow_makedir = config_table.allow_makedir
		or default_config.allow_makedir
	return self
end

return Config
