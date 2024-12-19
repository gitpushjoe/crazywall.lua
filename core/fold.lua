local utils = require"core.utils"
local s = require "core.strings"
local str = utils.str
local Context = require "core.context"
local Section = require "core.section"
local traverse = require "core.traverse"

local M = {}

---@param context Context
M.parse = function (context)
	local section = Section:new(
		utils.read_only({"ROOT"}),
		-1,
		-1,
		{},
		nil
	)
	local config = context.config
	local open_section_symbol = config.open_section_symbol
	local close_section_symbol = config.close_section_symbol
	local note_schema =  config.note_schema
	for i, line in ipairs(context.lines) do
		for note_idx, note_type in ipairs(note_schema) do
			local prefix = note_type[2] .. open_section_symbol
			if (str.starts_with(line, prefix)) then
				local curr = Section:new(
					utils.read_only(config.note_schema[note_idx]),
					i,
					nil,
					{},
					section
				)
				table.insert(section.children, curr)
				section = curr
				break
			end
		end
		for _, note_type in ipairs(note_schema) do
			local suffix = close_section_symbol .. note_type[2]
			if (str.ends_with(line, suffix)) then
				section.end_line = i
				section = section.parent
				break
			end
		end
	end
	return section
end

---@param section_root Section
---@param _context Context
M.prepare = function (section_root, _context)
	traverse.preorder_traverse(section_root,
	function (section)
		print(
			"type: " .. section.type[1],
			"lines: " .. section.start_line .. " " .. section.end_line,
			"parent_type: " .. (section.parent and section.parent.type[1] or "nil"))
	end
	)
end

return M
