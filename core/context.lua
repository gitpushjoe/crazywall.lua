local utils = require("core.utils")
local Path = require("core.path")
local validate = require("core.validate")
local str = utils.str
local streams = require("core.streams")

---@class (exact) Context
---@field config Config
---@field lines (string|boolean)[]
---@field use_mock_filesystem boolean
---@field src_path Path
---@field dest_path Path
---@field mock_filesystem MockFilesystem?
---@field is_dry_run boolean
---@field auto_confirm boolean
---@field plan_stream Stream
---@field text_stream Stream
---@field preserve boolean
---@field io iolib

Context = {}
Context.__index = Context
Context.__name = "Context"

---@param config Config
---@param src_path string
---@param dest_path string
---@param inp string|string[]
---@param mock_filesystem MockFilesystem?
---@param is_dry_run boolean
---@param auto_confirm boolean
---@param plan_stream Stream
---@param text_stream Stream
---@param preserve boolean
---@return Context?, string?
function Context:new(
	config,
	src_path,
	dest_path,
	inp,
	mock_filesystem,
	is_dry_run,
	auto_confirm,
	plan_stream,
	text_stream,
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
		{ preserve, "boolean", "preserve" },
		{ is_dry_run, "boolean", "is_dry_run" },
	})
	if err then
		return nil, err
	end

	--- TODO(gitpushjoe): add error message
	assert(
		(plan_stream == streams.NONE
			or plan_stream == streams.STDOUT
			or plan_stream == streams.STDERR)
		and
		(text_stream == streams.NONE
		or text_stream == streams.STDOUT
		or text_stream == streams.STDERR)
	)

	self.lines = {}
	self.io = mock_filesystem and mock_filesystem.io or io
	self.preserve = preserve
	self.is_dry_run = is_dry_run

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
	self.plan_stream = plan_stream
	self.text_stream = text_stream
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
