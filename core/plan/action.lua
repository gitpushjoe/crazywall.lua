local utils = require "core.utils"
require "core.path"


---@alias CREATE_ACTION { type: "CREATE", path: Path, lines: string[] }
---@alias OVERWRITE_ACTION { type: "OVERWRITE", path: Path, lines: string[] }
---@alias MKDIR_ACTION { type: "MKDIR", path: Path, lines: string[] }

---@alias Action CREATE_ACTION|OVERWRITE_ACTION|MKDIR_ACTION

local M = {}

M.CREATE = "CREATE"
M.OVERWRITE = "OVERWRITE"
M.MKDIR = "MKDIR"

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
		lines = corrected_lines
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
		lines = corrected_lines
	}
	return utils.read_only(action)
end

---@param dir Path
---@return MKDIR_ACTION
function M.mkdir(dir)
	---@type MKDIR_ACTION
	local action = {
		type = M.MKDIR,
		path = dir
	}
	return utils.read_only(action)
end

return M
