local utils = require "core.utils"
local default_config = require "core.defaults.config"
local config_module = require "core.config"
local fold = require "core.fold"

-- utils.tprint(arg)
--
-- local config_file = loadfile(arg[1])
-- if config_file then
-- 	config_file()
-- end

local example_file =
[[# My File

r> Reference #1

<r

r> Reference #2
This one has a body.

<r

r> Reference #3
<r

>
<
o> This is something else 
<o
]]

local config = default_config.config
config_module.expand_partial_config(config)

-- utils.print(config)
-- print(#fold.fold(example_file, config).children)
local parsed = fold.parse(example_file, config)
utils.print(parsed)
