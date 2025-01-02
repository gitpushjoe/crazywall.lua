local utils = require("core.utils")
require("core.path")

---@alias CREATE_ACTION { type: "CREATE", path: Path, lines: string[], tostring: fun(self: CREATE_ACTION): string }
---@alias OVERWRITE_ACTION { type: "OVERWRITE", path: Path, lines: string[], tostring: fun(self: OVERWRITE_ACTION): string }
---@alias MKDIR_ACTION { type: "MKDIR", path: Path, tostring: fun(self: MKDIR_ACTION): string }
---@alias IGNORE_ACTION { type: "IGNORE", path: Path, lines: string[], tostring: fun(self: IGNORE_ACTION): string }

---@alias Action CREATE_ACTION|OVERWRITE_ACTION|MKDIR_ACTION|IGNORE_ACTION

local M = {}

M.CREATE = "CREATE"
M.OVERWRITE = "OVERWRITE"
M.MKDIR = "MKDIR"
M.IGNORE = "IGNORE"

-- TODO(gitpushjoe): add option for no colors
---@param self Action
local tostring = function(self)
	local text = self.type == "CREATE" and "\27[32m"
		or self.type == "MKDIR" and "\27[33m"
		or self.type == "OVERWRITE" and "\27[35m"
		or self.type == "IGNORE" and "\27[31m"
		or error("Unknown action type: " .. self.type)
	text = text
		.. "[ "
		.. string.rep(" ", #"OVERWRITE" - #self.type)
		.. self.type
		.. " ]  "
	local line_count_str = "-"
	local char_count_str = "-"
	if self.lines then
		line_count_str = tostring(#self.lines)
		local char_count = 0
		for _, line in ipairs(self.lines) do
			char_count = char_count + #line
		end
		char_count_str = tostring(char_count)
	end
	return text
		.. string.rep(" ", #"lines " - #line_count_str)
		.. line_count_str
		.. "  "
		.. string.rep(" ", #"chars " - #char_count_str)
		.. char_count_str
		.. "  "
		.. tostring(self.path)
		.. "\27[0m"
end

---@param path Path
---@param lines string[]
---@return CREATE_ACTION
function M.create(path, lines)
	local corrected_lines = {}
	for _, line in ipairs(lines) do
		if line ~= false then
			table.insert(corrected_lines, line)
		end
	end
	---@type CREATE_ACTION
	local action = {
		type = M.CREATE,
		path = path,
		lines = corrected_lines,
		tostring = tostring,
	}
	return utils.read_only(action)
end

---@param path Path
---@param lines string[]
---@return OVERWRITE_ACTION
function M.overwrite(path, lines)
	local corrected_lines = {}
	for _, line in ipairs(lines) do
		if line ~= false then
			table.insert(corrected_lines, line)
		end
	end
	---@type OVERWRITE_ACTION
	local action = {
		type = M.OVERWRITE,
		path = path,
		lines = corrected_lines,
		tostring = tostring,
	}
	return utils.read_only(action)
end

---@param dir Path
---@return MKDIR_ACTION
function M.mkdir(dir)
	---@type MKDIR_ACTION
	local action = {
		type = M.MKDIR,
		path = dir,
		tostring = tostring,
	}
	return utils.read_only(action)
end

---@param lines string[]
---@return IGNORE_ACTION
function M.ignore(lines)
	local corrected_lines = {}
	for _, line in ipairs(lines) do
		if line ~= false then
			table.insert(corrected_lines, line)
		end
	end
	---@type IGNORE_ACTION
	local action = {
		type = M.IGNORE,
		path = Path.void(),
		lines = corrected_lines,
		tostring = tostring,
	}
	return utils.read_only(action)
end

return M
