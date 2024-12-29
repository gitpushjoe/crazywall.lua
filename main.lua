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

local filename = (function()
    local handle, err = io.popen("realpath " .. Path:new(arg[1]):escaped())
    if not handle then
	error(err)
    end
    local res = handle:read("*a")
    handle:close()
    if res:sub(#res, #res) == "\n" then
	res = res:sub(1, #res - 1)
    end
    return res
end)()

local home_dir = (function()
    local handle, err = io.popen("eval echo ~$USER")
    if not handle then
	error(err)
    end
    local res = handle:read("*a")
    handle:close()
    if res:sub(#res, #res) == "\n" then
	res = res:sub(1, #res - 1)
    end
    return res
end)()

local text = (function()
    local handle, err = io.open(filename, "r")
    if not handle then
	error(err)
    end
    local res = handle:read("*a")
    handle:close()
    if res:sub(#res, #res) == "\n" then
	res = res:sub(1, #res - 1)
    end
    return res
end)()

local config, err = Config:new(custom_configs["DEFAULT"] or {})
if not config then
    error(err)
end

local context
context, err = Context:new(config, filename, text)

if not context then
    error(err)
end

local root
root, err = fold.parse(context)
if not root then
    error(err)
end

_, err = fold.prepare(root, context)
if err then
    error(err)
end

local plan
plan, err = fold.execute(root, context, true)
if err then
    error(err)
end
print("PLAN (dry run): \n" .. string.gsub(tostring(plan), home_dir, "~"))

plan, err = fold.execute(root, context, false)
if err then
    error(err)
end

print()
print("Success")
