local s = require "core.strings"

local M = {}

M.expand_partial_config = function (config)
	config[s.ALIAS_LENGTH] = config[s.ALIAS_LENGTH] or 1
	config[s.OPEN_SECTION_SYMBOL] = config[s.OPEN_SECTION_SYMBOL] or "> "
	config[s.CLOSE_SECTION_SYMBOL] = config[s.CLOSE_SECTION_SYMBOL] or "<"
	local alias_length = config[s.ALIAS_LENGTH]
	for _, note_type in ipairs(config[s.NOTE_TYPES]) do
		if (type(note_type) ~= "table") then
			error("Expected all note types in config to be tables")
		end
		if #note_type < 2 then
			local prefix = note_type[1]:sub(1, alias_length)
			table.insert(note_type, prefix)
		end
	end
end

return M
