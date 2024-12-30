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
local argparse = require("core.argparse")
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

local kwarg_names = {
	"--out",
	"-o",
	"--config",
	"-c",
}
local arg_table, err = argparse.get_arg_table(arg, kwarg_names)
if not arg_table then
	error(err)
end

---@param table ArgTable
local print_arg_table = function(table)
	for k, v in pairs(table) do
		print(k)
		for k2, v2 in pairs(v) do
			io.write("\t")
			if type(k2) ~= type(1) then
				io.write(k2 .. ": ")
			end
			print(v2)
		end
	end
end

if #arg_table.args == 0 then
	-- TODO(gitpushjoe): this can actually be okay
	error("No filenames passed.")
end

local DRY_RUN = { "--dry-run", "-dr" }
local PLAN_ONLY = { "--plan-only", "-po" }
local TEXT_ONLY = { "--text-only", "-to" }
local AUTO_CONFIRM = { "--yes", "-y" }
local OUT = { "--out", "-o" }
local CONFIG = { "--config", "-c" }
local PRESERVE = { "--preserve", "-p" }

local po_flag = argparse.arg_table_find(arg_table, PLAN_ONLY)
local to_flag = argparse.arg_table_find(arg_table, TEXT_ONLY)
local dr_flag = argparse.arg_table_find(arg_table, DRY_RUN)
local y_flag = argparse.arg_table_find(arg_table, AUTO_CONFIRM)
local p_flag = argparse.arg_table_find(arg_table, PRESERVE)
local dest_path = argparse.arg_table_find(arg_table, OUT)

local dry_run_opts = 0
if not dr_flag then
	for _, opt in ipairs({ PLAN_ONLY, TEXT_ONLY }) do
		local flag = argparse.arg_table_find(arg_table, opt)
		if flag then
			error(flag .. " used without specifying --dry-run")
		end
	end
else
	if po_flag and to_flag then
		warn(
			"Mutually exclusive flags "
				.. po_flag
				.. " and "
				.. to_flag
				.. " found. Both ignored."
		)
	end
	dry_run_opts = (po_flag and Context.DRY_RUN.PLAN_ONLY)
		or (to_flag and Context.DRY_RUN.TEXT_ONLY)
		or Context.DRY_RUN.TEXT_AND_PLAN
end

if dest_path and p_flag then
	error(
		"Mutually exclusive flags " .. "--out" .. " and " .. p_flag .. " found."
	)
end

local filename =
	read_from_handle(io.popen("realpath " .. Path:new(arg[1]):escaped()))
local home_dir = read_from_handle(io.popen("eval echo ~$USER"))
local text = read_from_handle(io.open(filename, "r"))

local config_name = argparse.arg_table_find(arg_table, CONFIG) or "DEFAULT"
if not custom_configs[config_name] then
	error('User-defined config "' .. config_name .. '" not found')
end

local config
config, err = Config:new(custom_configs[config_name] or {})
if not config then
	error(err)
end

local ctx
ctx, err = Context:new(
	config,
	filename,
	PRESERVE and filename or dest_path or filename,
	text,
	nil,
	y_flag ~= nil,
	dry_run_opts,
	p_flag ~= nil
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

if
	ctx.dry_run_opts == Context.DRY_RUN.PLAN_ONLY
	or ctx.dry_run_opts == Context.DRY_RUN.TEXT_AND_PLAN
then
	print("PLAN (dry run): \n" .. string.gsub(tostring(plan), home_dir, "~"))
end

if
	ctx.dry_run_opts == Context.DRY_RUN.NO_DRY_RUN
then
	print("PLAN: \n" .. string.gsub(tostring(plan), home_dir, "~"))
end

if
	ctx.dry_run_opts == Context.DRY_RUN.TEXT_ONLY
	or ctx.dry_run_opts == Context.DRY_RUN.TEXT_AND_PLAN
then
	print(utils.str.join_lines(root:get_lines()))
end

if ctx.dry_run_opts ~= Context.DRY_RUN.NO_DRY_RUN then
	os.exit(0)
end

if not ctx.auto_confirm then
	io.write("Confirm? [Y/N]: ")
	---@type string
	local result = io.read()
	if result:sub(1, 1):lower() ~= "y" then
		print("Exiting.")
		os.exit(0)
	end
end

plan, err = fold.execute(root, ctx, false)
if err then
    error(err)
end

if ctx.preserve then
	print(utils.str.join_lines(root:get_lines()))
end
