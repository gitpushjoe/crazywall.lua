local utils = require("core.utils")
local str = utils.str
local Section = require("core.section")
local traverse = require("core.traverse")
local validate = require("core.validate")
local Plan = require("core.plan.plan")
local Action = require("core.plan.action")

local M = {}

M.errors = {

	---@param section Section?
	---@return string
	unterminated_section = function(section)
		return "Unterminated section: " .. (tostring(section) or "nil")
	end,

	---@param line number
	---@return string
	inconsistent_indent = function(line)
		return "Inconsistent indent on line " .. line
	end,

	---@param section Section?
	---@return string
	maximum_retry_count = function(section)
		return "Maximum retry count reached: " .. (tostring(section) or "nil")
	end,

	---@param path string
	---@param section Section?
	---@return string
	cannot_write = function(path, section)
		return "Cannot write to path " .. path .. "\n" .. tostring(section)
	end,

	---@param command string
	---@param err string?
	---@return string
	command_failed = function(command, err)
		return "Failed to execute command: "
			.. command
			.. "\nError: "
			.. (err or "")
	end,
}

---@param ctx Context
---@return Section?, string?
M.parse = function(ctx)
	local section, err =
		Section:new(0, utils.read_only({ "ROOT" }), ctx, 0, #ctx.lines, {}, nil)
	local id = 1
	local root = section
	if not section then
		return nil, err
	end
	local config = ctx.config
	local note_schema = config.note_schema
	for i, line in ipairs(ctx.lines) do
		---@cast line string
		if section ~= nil and #section.indent > 0 then
			local indent = section.indent
			-- TODO(gitpushjoe): maybe ignoring empty lines should be config option?
			if #line ~= 0 and not str.starts_with(line, indent) then
				return nil, M.errors.inconsistent_indent(i)
			end
		end

		local indent_chars = 0
		for j = 1, #line do
			local char = string.sub(line, j, j)
			if char ~= " " and char ~= "\t" then
				break
			end
			indent_chars = indent_chars + 1
		end
		local indent = string.sub(line, 1, indent_chars)
		line = string.sub(line, indent_chars + 1)

		for note_idx, note_type in ipairs(note_schema) do
			local prefix = note_type[2]
			if str.starts_with(line, prefix) then
				local curr
				curr, err = Section:new(
					id,
					utils.read_only(config.note_schema[note_idx]),
					ctx,
					i,
					nil,
					{},
					section,
					indent
				)
				id = id + 1
				if not curr then
					return nil, err
				end
				table.insert(section.children, curr)
				section = curr
				break
			end
		end
		-- TODO(gitpushjoe): maybe still check if a suffix for another note type slipped through?
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
		return nil, M.errors.unterminated_section(section)
	end
	return section
end

---@param section_root Section
---@param ctx Context
---@return nil, string?
M.prepare = function(section_root, ctx)
	local _, err = traverse.preorder(section_root, function(section)
		if section.type[1] == "ROOT" then
			return
		end

		local path = ctx.config.resolve_path(
			utils.read_only(section),
			utils.read_only(ctx)
		)

		local err = validate.are_instances(
			"config.resolve_directory",
			{ { path, Path } }
		)
		if err then
			return nil, err
		end

		section.path = path
	end)
	if err then
		return _, err
	end

	_, err = traverse.postorder(section_root, function(section)
		if section.type[1] == "ROOT" then
			section.lines = ctx.lines
			return
		end

		local lines = ctx.config.transform_lines(
			utils.read_only(section),
			utils.read_only(ctx)
		)

		local _err = validate.types_in_list(
			"config.transform_lines",
			lines,
			validate.RETVAL,
			"string"
		)
		if _err then
			return nil, _err
		end

		local reference = ctx.config.resolve_reference(section, ctx)
		ctx.lines[section.start_line] = string.sub(
			section.indent,
			section.parent and #section.parent.indent or 0
		) .. reference
		for i = section.start_line + 1, section.end_line do
			ctx.lines[i] = false
		end

		section.lines = lines
	end)
	if err then
		return nil, err
	end
	-- print("lines: \n" .. str.join_lines(section_root:get_lines()))
end

---@param section_root Section
---@param ctx Context
---@param is_dry_run boolean?
---@return Plan?, string?
M.execute = function(section_root, ctx, is_dry_run)
	is_dry_run = is_dry_run or false
	local io = ctx.io
	local plan = Plan:new()

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
	---@param path_str string?
	---@return file*?
	local function get_write_handle(path_str)
		return io.open(path_str or "", "w")
	end

	---@param handle file*?
	---@param lines string[]
	---@param path Path
	---@param is_overwrite boolean?
	---@return nil
	local function write(handle, lines, path, is_overwrite)
		is_overwrite = is_overwrite or false
		if not is_dry_run and handle then
			-- TODO(gitpushjoe): handle possibility of write failure
			handle:write(str.join_lines(lines))
			handle:close()
		end
		plan:add(
			(is_overwrite and Action.overwrite or Action.create)(path, lines)
		)
	end

	---@param directory Path
	---@return string?
	local function mkdir(directory)
		if not is_dry_run then
			local command = "mkdir -p "
				.. tostring(directory:escaped())
				.. " 2>&1"
			local handle, err = io.popen(command)
			if not handle then
				return M.errors.command_failed(command, err)
			end

			local succeeded
			succeeded, err = handle:close()
			if succeeded ~= true then
				return M.errors.command_failed(command, err)
			end
		end
		plan:add(Action.mkdir(directory))
	end

	local _, err = traverse.preorder(section_root, function(section)
		local retry_count = 0
		local write_handle
		local full_path = tostring(section.path) or ""
		local is_overwrite = false
		if section.type[1] == "ROOT" then
			return
			-- full_path = tostring(ctx.src_path)
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
				is_overwrite = true
				if write_handle then
					break
				end
			end
			retry_count = retry_count + 1
			if retry_count > ctx.config.retry_count then
				break
			end
			local path = ctx.config.resolve_collision(
				section.path,
				section,
				ctx,
				retry_count
			)
			section.path = path
			full_path = tostring(section.path) or ""
		end

		if retry_count > ctx.config.retry_count then
			return nil, M.errors.maximum_retry_count(section)
		end
		write_handle = write_handle or get_write_handle(full_path)

		if write_handle then
			write(write_handle, section.lines, section.path, is_overwrite)
			return
		end

		if not ctx.config.allow_makedir then
			return nil, M.errors.cannot_write(full_path, section)
		end

		local err = mkdir(section.path:directory())
		if err then
			return nil, err
		end

		write_handle = get_write_handle(full_path)
		write(write_handle, section.lines, section.path, is_overwrite)

		M.errors.cannot_write(full_path, section)
	end)
	if err then
		return nil, err
	end
	return plan
end

return M
