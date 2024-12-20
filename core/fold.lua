local utils = require("core.utils")
local s = require("core.strings")
local str = utils.str
local Context = require("core.context")
local Section = require("core.section")
local traverse = require("core.traverse")

local M = {}

---@param ctx Context
M.parse = function(ctx)
	local section = Section:new(utils.read_only({ "ROOT" }), ctx, -1, -1, {}, nil)
	local config = ctx.config
	local open_section_symbol = config.open_section_symbol
	local close_section_symbol = config.close_section_symbol
	local note_schema = config.note_schema
	for i, line in ipairs(ctx.lines) do
		for note_idx, note_type in ipairs(note_schema) do
			local prefix = note_type[2] .. open_section_symbol
			if str.starts_with(line, prefix) then
				local curr = Section:new(utils.read_only(config.note_schema[note_idx]), ctx, i, nil, {}, section)
				table.insert(section.children, curr)
				section = curr
				break
			end
		end
		for _, note_type in ipairs(note_schema) do
			local suffix = close_section_symbol .. note_type[2]
			if str.ends_with(line, suffix) then
				section.end_line = i
				section = section.parent
				break
			end
		end
	end
	return section
end

---@param section_root Section
---@param ctx Context
M.prepare = function(section_root, ctx)
	traverse.preorder_traverse(section_root, function(section)
		if section.type[1] == "ROOT" then
			return
		end
		section.path = ctx.config.resolve_directory(utils.read_only(section), utils.read_only(ctx))
		print("set path to -> " .. tostring(section.path))
	end)
	traverse.preorder_traverse(section_root, function(section)
		if section.type[1] == "ROOT" then
			return
		end
		section.filename = ctx.config.resolve_filename(utils.read_only(section), utils.read_only(ctx))
		print("set filename to -> " .. section.filename)
	end)
	traverse.postorder_traverse(section_root, function(section)
		if section.type[1] == "ROOT" then
			return
		end
		section.lines = ctx.config.transform_lines(utils.read_only(section), utils.read_only(ctx))
		print("set text to:\n(begin)\n" .. str.join_lines(section.lines) .. "\n(end)\n---")
	end)
end

return M
