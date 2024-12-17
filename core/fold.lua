local utils = require"core.utils"
local s = require "core.strings"
local str = utils.str
local Section = require "core.section"
local Context = require "core.context"

local M = {}

M.parse = function (context)
	local section = Section:new(
		-1,
		-1,
		-1,
		{},
		nil
	)
	local config = context.config
	local alias_length = config[s.ALIAS_LENGTH]
	local open_section_symbol = config[s.OPEN_SECTION_SYMBOL]
	local close_section_symbol = config[s.CLOSE_SECTION_SYMBOL]
	local note_types =  config[s.NOTE_TYPES]
	utils.print(context)
	for i, line in ipairs(context.lines) do
		if #line < config[s.ALIAS_LENGTH] then
			goto continue
		end
		if line:sub(alias_length + 1, #open_section_symbol + 1) == open_section_symbol then
			local note_key_idx = nil
			for note_idx, note_type in ipairs(note_types) do
				local prefix = note_type[2]
				if (str.starts_with(line, prefix)) then
					note_key_idx = note_idx
					break
				end
			end
			if not note_key_idx then
				goto continue
			end
			local curr = Section:new(
				note_key_idx,
				i,
				nil,
				{},
				section
			)
			if section then
				table.insert(section.children, curr)
			end
			section = curr
		end
		if line:sub(1, #close_section_symbol) == close_section_symbol then
			local note_key_idx = nil
			for note_idx, note_type in ipairs(note_types) do
				local prefix = note_type[2]
				if (line:sub(#close_section_symbol + 1, alias_length + 1) == prefix) then
					note_key_idx = note_idx
					break
				end
			end
			if not note_key_idx then
				goto continue
			end
			section.end_line = i
			section = section.parent
		end
		::continue::
	end
	return section
end

return M
