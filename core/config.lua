local s = require "core.strings"

---@class (exact) ConfigTable 
---@field note_schema [string, string][]
--- ["note_schema"]: [string, string][]?,
--- ["open_section_symbol"]: string?,
--- ["close_section_symbol"]: string?,
--- [string]: number}

---@class Config
---@field open_section_symbol string
---@field close_section_symbol string
Config = {}
Config.__index = Config

---@param config_table ConfigTable
---@return Config
function Config:new(config_table)
	self = {}
	setmetatable(self, Config)
	self.open_section_symbol = config_table[s.OPEN_SECTION_SYMBOL] or "> "
	self.close_section_symbol = config_table[s.CLOSE_SECTION_SYMBOL] or "<"
	for _, note_type in ipairs(config_table["note_schema"]) do
		if (type(note_type) ~= "table") then
			error("Expected all note types in config to be tables")
		end
		if #note_type < 2 then
			local prefix = note_type[1]:sub(1, 1)
			table.insert(note_type, prefix)
		end
	end
	self.note_schema = config_table[s.NOTE_SCHEMA]
	return self
end

return Config
