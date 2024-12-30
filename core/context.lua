local utils = require("core.utils")
local Path = require("core.path")
local validate = require("core.validate")
require("core.mock_filesystem.mock_filesystem")
local str = utils.str

---@class (exact) Context
---@field config Config
---@field lines (string|boolean)[]
---@field use_mock_filesystem boolean
---@field src_path Path
---@field dest_path Path
---@field mock_filesystem MockFilesystem?
---@field auto_confirm boolean
---@field dry_run_opts 0|1|2|3
---@field preserve boolean
---@field io iolib

Context = {}
Context.__index = Context
Context.__name = "Context"

Context.DRY_RUN = {
	NO_DRY_RUN = 0,
	TEXT_ONLY = 1,
	PLAN_ONLY = 2,
	TEXT_AND_PLAN = 3,
}

---@param config Config
---@param src_path string
---@param dest_path string
---@param inp string|string[]
---@param mock_filesystem MockFilesystem?
---@param auto_confirm boolean
---@param dry_run_opts 0|1|2|3
---@param preserve boolean
---@return Context?, string?
function Context:new(
	config,
	src_path,
	dest_path,
	inp,
	mock_filesystem,
	auto_confirm,
	dry_run_opts,
	preserve
)
	self = {}
	---@cast self Context
	setmetatable(self, Context)

	local err = validate.are_instances("Context:new", {
		{ config, Config, "config" },
		mock_filesystem
				and { mock_filesystem, MockFilesystem, "mock_filesystem" }
			or nil,
	})
	if err then
		return nil, err
	end

	self.config = config or {}
	self.use_mock_filesystem = not not mock_filesystem
	self.mock_filesystem = mock_filesystem

	---@type unknown
	err = validate.types("Context:new", {
		{ src_path, "string", "src_path" },
		{ dest_path, "string?", "dest_path" },
		{ inp, "table|string", "inp" },
		{ auto_confirm, "boolean", "auto_confirm" },
		{ dry_run_opts, "number", "dry_run_opts" },
		{ preserve, "boolean", "preserve" },
	})
	if err then
		return nil, err
	end

	--- TODO(gitpushjoe): add error message
	assert(
		0 <= dry_run_opts
			and dry_run_opts <= 3
			and math.floor(dry_run_opts) == dry_run_opts
	)

	self.lines = {}
	self.io = mock_filesystem and mock_filesystem.io or io
	self.preserve = preserve

	local lines = {}
	if type(inp) == type("") then
		---@cast inp string
		local data = str.split_lines(inp, true)
		for line in data do
			table.insert(lines, line)
		end
	else
		---@cast inp string[]
		for i, line in ipairs(inp) do
			---@type unknown
			err = validate.types("Context:new", {
				{ line, "string", "inp[" .. i .. "]" },
			})
			if err then
				return nil, err
			end

			table.insert(lines, tostring(line))
		end
	end
	self.lines = lines
	self.auto_confirm = auto_confirm
	self.dry_run_opts = dry_run_opts
	local source, dest
	source, err = Path:new(src_path)
	if not source then
		return nil, err
	end
	self.src_path = source
	if not dest_path then
		return self
	end
	dest, err = Path:new(dest_path)
	if not dest then
		return nil, err
	end
	self.dest_path = dest
	return self
end

return Context
