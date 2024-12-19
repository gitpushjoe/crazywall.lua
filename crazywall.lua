local script_dir = debug.getinfo(1, "S").source:match("@(.*)/?")
package.path = package.path .. ";" .. script_dir .. "/?.lua"

local utils = require "core.utils"
local default_config = require "core.defaults.config"
local config_module = require "core.config"
local fold = require "core.fold"
local VirtualFilesystem = require "core.virtual_filesystem.vfs"
local Path = require "core.path"

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
r> An inner reference
q> Some question <q
<r

<r


r> Reference #3
<r

>
<
o> This is something else 
<o
]]

local config = Config:new(default_config.config)

local virt_filesystem_structure = {
	root={
		home={
			user={
				p={
					["012345.txt"]=example_file,
				},
				r={
				},
				f={
				},
				["some_file.txt"]="foo"
			},
		},
	}
}

local vfs = VirtualFilesystem:new(
	virt_filesystem_structure)

local context = Context:new(
	config,
	"/root/p/012345.txt",
	example_file,
	vfs
)

utils.print(config)
local root = fold.parse(context)
print("\\/")
fold.prepare(root, context)

print(Path:new(arg[#arg]))
