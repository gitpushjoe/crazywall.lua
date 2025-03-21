#!/usr/bin/env lua

local script_path = arg[0]

local script_dir = script_path:match("^(.*)/")

if not script_dir then
	script_dir = debug.getinfo(1, "S").source:match("^@(.*/)")
end

if script_dir then
	package.path = script_dir .. "/?.lua;" .. package.path
end

local fold = require("crazywall.core.fold")
local Config = require("crazywall.core.config")
local Context = require("crazywall.core.context")
local Path = require("crazywall.core.path")
local custom_configs = require("configs")
local Parser = require("crazywall.core.parser")
local streams = require("crazywall.core.streams")
local utils = require("crazywall.core.utils")
local ansi = require("crazywall.core.ansi")
local version = require("crazywall.core.version")

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
	{
		"--no-ansi",
		"-na",
		"Disables ANSI coloring.",
	},
	{
		"--version",
		"-v",
		"Prints the current version.",
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
		"Sets the destination for the new source file text to <file>. Defaults to the path to the source file.",
	},
	{
		"--config <config>",
		"-c <config>",
		'Uses the config named <config> in `configs.lua`. Defaults to "DEFAULT".',
	},
}))

local ansi_enabled = false

---@param err string?
local error = function(err)
	local red = ansi_enabled and ansi.red or ansi.none
	local bold = ansi_enabled and ansi.bold or ansi.none
	io.stderr:write(red("ERROR: " .. bold(err or "")))
	os.exit(1)
end

local success, err = parser:parse(arg)
if not success then
	error(err)
end

ansi_enabled = parser:find("--no-ansi") == nil

if parser:find("--help") then
	print(parser:get_helptext())
	os.exit(0)
end

if parser:find("--version") then
	print("crazywall " .. version)
	os.exit(0)
end

if #parser.data.args == 0 then
	error("No filename passed.")
end

local filename = utils.read_from_handle(
	io.popen("realpath " .. Path:new(parser.data.args[1], true):escaped())
) or error("Expected realpath command to be available")

local dest_path = parser:find("--out")
		and tostring(Path:new(filename):join(assert(parser:find("--out"))))
	or filename

local text = utils.read_from_handle(io.open(filename, "r"))
	or error("Failed to read source file")

local config_name = parser:find("--config") or "DEFAULT"
if config_name ~= "DEFAULT" and not custom_configs[config_name] then
	error('User-defined config "' .. config_name .. '" not found')
end

local config
config, err = Config:new(custom_configs[config_name] or {})
if not config then
	error(err)
end

local source_dir = tostring(assert(Path:new(filename):get_directory()))

local plan_stream = tonumber(parser:find("--plan-stream"))
if parser:find("--plan-stream") and plan_stream == nil then
	error("Plan stream value is invalid.")
end
local text_stream = tonumber(parser:find("--text-stream"))
if parser:find("--text-stream") and text_stream == nil then
	error("Text stream value is invalid.")
end

local ctx
ctx, err = Context:new(
	config,
	filename,
	dest_path,
	text,
	nil,
	parser:find("--dry-run") ~= nil,
	parser:find("--yes") ~= nil,
	plan_stream or streams.STDOUT,
	text_stream or streams.STDOUT,
	parser:find("--preserve") ~= nil,
	ansi_enabled
)

if not ctx then
	error(err)
end

---@param plan Plan
---@param is_dry_run boolean
local display_plan = function(_, plan, is_dry_run)
	return print_to_stream(
		("PLAN%s:\n%s\n"):format(
			(is_dry_run and " (dry-run)" or ""),
			string.gsub(tostring(plan), source_dir, "./")
		),
		ctx.plan_stream
	)
end

---@param lines string[]
---@param is_dry_run boolean
local display_lines = function(_, lines, is_dry_run)
	return print_to_stream(
		("TEXT%s:\n%s\n"):format(
			(is_dry_run and " (dry-run)" or ""),
			utils.str.join_lines(lines)
		),
		ctx.plan_stream
	)
end

---@return boolean
local get_confirmation = function ()
	io.write("Confirm? [Y/N]: ")
	io.flush()
	---@type string
	local result = io.read()
	return result and result:sub(1, 1):lower() == "y"
end

_, err = fold.fold(ctx, display_plan, display_lines, get_confirmation)

if err then
	error(err)
end
