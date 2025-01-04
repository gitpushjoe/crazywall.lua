#!/usr/bin/env lua

local script_path = arg[0]

local script_dir = script_path:match("^(.*)/")

if not script_dir then
	script_dir = debug.getinfo(1, "S").source:match("^@(.*/)")
end

if script_dir then
	package.path = script_dir .. "/?.lua;" .. package.path
end

local fold = require("core.fold")
local Config = require("core.config")
local Path = require("core.path")
local custom_configs = require("configs")
local Parser = require("core.parser")
local streams = require("core.streams")
local utils = require("core.utils")

---@param handle file*?
---@param err string?
local read_from_handle = function(handle, err)
	if not handle then
		error(err)
	end
	local res = handle:read("*a")
	handle:close()
	res = res:sub(1, #res - 1)
	return res
end

---@param err string?
local error = function(err)
	io.stderr:write(
		"\27[1;31m" .. "ERROR: \27[0;91m" .. (err or "") .. "\n \27[0m"
	)
	os.exit(1)
end

---@param warning string?
local warn = function(warning)
	io.stderr:write(
		"\27[1;33m" .. "Warning: \27[0;93m" .. (warning or "") .. "\n \27[0m"
	)
	os.exit(1)
end

---@param text string
---@param stream Stream
local print_to_stream = function(text, stream)
	if stream == streams.STDOUT then
		print(text)
	end
	if stream == streams.STDERR then
		io.stderr:write(text .. "\n")
	end
end

local parser = assert(Parser:new({
	{
		"--dry-run",
		"-dr",
		"Enable dry-run, which will not modify or add any new files or directories.",
	},
	{
		"--help",
		"-h",
		"Prints this helptext.",
	},
	{
		"--yes",
		"-y",
		"Automatically confirm all prompts.",
	},
	{
		"--preserve",
		"-p",
		"Will not edit the source file.",
	},
}, {
	{
		"--plan-stream <stream>",
		"-ps <stream>",
		"The stream to print the crazywall plan object to. (0 for none, 1 for stdout, 2 for stderr.)  Defaults to 1.",
	},
	{
		"--text-stream <stream>",
		"-ts <stream>",
		"The stream to print the updated source text to. (0 for none, 1 for stdout, 2 for stderr.)  Defaults to 1.",
	},
	{
		"--out <file>",
		"-o <file>",
		"Sets the destination for the new source file text to <file>. Defaults to the path to the source file. Set to 1 for stdout and 2 for stderr.",
	},
	{
		"--config <config>",
		"-c <config>",
		'Uses the config named <config> in `configs.lua`. Defaults to "DEFAULT".',
	},
}))

local success, err = parser:parse(arg)
if not success then
	error(err)
end

if parser:find("--help") then
	print(parser:get_helptext())
	os.exit(0)
end

if #parser.data.args == 0 then
	error("No filename passed.")
end

local filename = read_from_handle(
	io.popen("realpath " .. Path:new(parser.data.args[1]):escaped())
)

local dest_path = parser:find("--out")
		and read_from_handle(
			io.popen(
				"realpath " .. Path:new(assert(parser:find("--out"))):escaped()
			)
		)
	or filename

local text = read_from_handle(io.open(filename, "r"))

local config_name = parser:find("--config") or "DEFAULT"
if not custom_configs[config_name] then
	error('User-defined config "' .. config_name .. '" not found')
end

local config
config, err = Config:new(custom_configs[config_name])
if not config then
	error(err)
end

local source_dir = tostring(assert(Path:new(filename):directory()))

local ctx
ctx, err = Context:new(
	config,
	filename,
	dest_path,
	text,
	nil,
	parser:find("--dry-run") ~= nil,
	parser:find("--yes") ~= nil,
	--- TODO(gitpushjoe): add nil-checking here
	math.tointeger(parser:find("--plan-stream")) or streams.STDOUT,
	math.tointeger(parser:find("--text-stream")) or streams.STDOUT,
	parser:find("--preserve") ~= nil
)

if not ctx then
	error(err)
end

local root
root, err = fold.parse(ctx)
if not root then
	error(err)
end

_, err = fold.prepare(root, ctx)
if err then
	error(err)
end

local plan
plan, err = fold.execute(root, ctx, true)
if err then
	error(err)
end

print_to_stream(
	"PLAN"
		.. (ctx.is_dry_run and "(dry-run)" or "")
		.. ": \n"
		.. string.gsub(tostring(plan), source_dir, "./")
		.. "\n",
	ctx.plan_stream
)
if ctx.is_dry_run then
	print_to_stream(
		"TEXT (dry run): \n" .. utils.str.join_lines(root:get_lines()),
		ctx.text_stream
	)
	os.exit(0)
end

if not ctx.auto_confirm then
	io.write("Confirm? [Y/N]: ")
	---@type string
	local result = io.read()
	if not result or result:sub(1, 1):lower() ~= "y" then
		print("Exiting.")
		os.exit(0)
	end
end

plan, err = fold.execute(root, ctx, false)
if err then
	error(err)
end

print_to_stream(
	"TEXT: \n" .. utils.str.join_lines(root:get_lines()),
	ctx.text_stream
)
