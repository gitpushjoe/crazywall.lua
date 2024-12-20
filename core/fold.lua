local utils = require("core.utils")
local str = utils.str
local Section = require("core.section")
local traverse = require("core.traverse")

local M = {}

M.error = {

	---@param section Section?
	---@return string
	unterminated_section = function(section)
		return "Unterminated section: " .. (tostring(section) or "nil")
	end,
}

---@param ctx Context
---@return Section?, string?
M.parse = function(ctx)
	local section, err =
		Section:new(utils.read_only({ "ROOT" }), ctx, 0, #ctx.lines, {}, nil)
	local root = section
	if not section then
		return nil, err
	end
	local config = ctx.config
	local open_section_symbol = config.open_section_symbol
	local note_schema = config.note_schema
	for i, line in ipairs(ctx.lines) do
		for note_idx, note_type in ipairs(note_schema) do
			local prefix = note_type[2] .. open_section_symbol
			if str.starts_with(line, prefix) then
				local curr
				curr, err = Section:new(
					utils.read_only(config.note_schema[note_idx]),
					ctx,
					i,
					nil,
					{},
					section
				)
				if not curr then
					return nil, err
				end
				table.insert(section.children, curr)
				section = curr
				break
			end
		end
		---TODO(gitpushjoe): maybe still check if a suffix for another note type slipped through?
		if
			section
			and section.type[1] ~= "ROOT"
			and str.ends_with(line, section:suffix())
		then
			section.end_line = i
			section = section.parent
		end
	end
	if section ~= root then
		return nil, M.error.unterminated_section(section)
	end
	return section
end

---@param section_root Section
---@param ctx Context
M.prepare = function(section_root, ctx)
	traverse.preorder_traverse(section_root, function(section)
		if section.type[1] == "ROOT" then
			local path_copy = ctx.src_path:copy()
			path_copy:pop()
			section.path = path_copy
			return
		end
		section.path = ctx.config.resolve_directory(
			utils.read_only(section),
			utils.read_only(ctx)
		)
		print("set path to -> " .. tostring(section.path))
	end)
	traverse.preorder_traverse(section_root, function(section)
		if section.type[1] == "ROOT" then
			section.filename = ctx.src_path:copy():pop()
			return
		end
		section.filename = ctx.config.resolve_filename(
			utils.read_only(section),
			utils.read_only(ctx)
		)
		print("set filename to -> " .. section.filename)
	end)
	traverse.postorder_traverse(section_root, function(section)
		if section.type[1] == "ROOT" then
			section.lines = ctx.lines
			return
		end
		section.lines = ctx.config.transform_lines(
			utils.read_only(section),
			utils.read_only(ctx)
		)
		ctx.lines[section.start_line] =
			ctx.config.resolve_reference(section, ctx)
		for i = section.start_line + 1, section.end_line do
			ctx.lines[i] = false
		end
		print("set text for " .. section.filename .. " to:")
		print(str.join_lines(section.lines) .. "\n-----")
	end)
	print("lines: \n" .. str.join_lines(section_root:get_lines()))
end

---@param section_root Section
---@param ctx Context
M.execute = function(section_root, ctx)
	local io = ctx.io
	---@param path_str string?
	---@return boolean
	local function file_exists(path_str)
		local file = io.open(path_str or "", "r")
		if file == nil then
			return false
		end
		file:close()
		return true
	end
	local function get_write_handle(path_str)
		print(path_str or "", "path_str")
		return io.open(path_str or "", "w")
	end
	traverse.preorder_traverse(section_root, function(section)
		local retry_count = 0
		local write_handle
		local full_path = section:get_full_path() or ""
		if section.type[1] == "ROOT" then
			full_path = tostring(ctx.src_path)
		end
		while retry_count <= ctx.config.retry_count do
			if section.type[1] == "ROOT" then
				break
			end
			if not file_exists(full_path) then
				break
			end
			if ctx.config.allow_overwrite then
				write_handle = get_write_handle(full_path)
				if write_handle then
					break
				end
			end
			retry_count = retry_count + 1
			if retry_count > ctx.config.retry_count then
				break
			end
			local path, filename = ctx.config.resolve_collision(
				section.path,
				section.filename,
				section,
				ctx,
				retry_count
			)
			section.path = path
			section.filename = filename
			full_path = section:get_full_path() or ""
		end
		if retry_count > ctx.config.retry_count then
			error("Max retry count reached")
		end
		write_handle = write_handle or get_write_handle(full_path)
		if write_handle then
			write_handle:write(str.join_lines(section.lines))
			write_handle:close()
			return
		end
		if not ctx.config.allow_makedir then
			error("Cannot write to file and not allowed to make directories")
		end
		local process = io.popen("mkdir " .. tostring(section.path) .. "  2>&1")
		if not process then
			error("Unexpected error when making directory")
		end
		process:close()
		write_handle = get_write_handle(full_path)
		if write_handle then
			write_handle:write(str.join_lines(section.lines))
			write_handle:close()
			return
		end
		error("Could not write to the file after making directory")
	end)
end

return M
