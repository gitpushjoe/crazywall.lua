local script_dir = debug.getinfo(1, "S").source:match("@(.*)/?")
package.path = package.path .. ";" .. script_dir .. "/?.lua"

local utils = require("core.utils")
local default_config = require("core.defaults.config")
local fold = require("core.fold")
local VirtualFilesystem = require("core.virtual_filesystem.vfs")

local example_file = [[# My Notes

r> Chapter 1

p> Article 1
These are notes on some article.
<p

p> Article 2
These are notes on another article.
<p

<r

p> Chapter 2
p> Article 1<p

<p

q> A question <q

>
<
o> This is something else 
<o
]]

local config, err = Config:new(default_config.config)
if not config then
	error(err)
end

local virt_filesystem_structure = {
		home = {
			user = {
				p = {
					["main.txt"] = example_file,
				},
				r = {},
				f = {},
				["some_file.txt"] = "foo",
			},
		},
}

-- TODO(gitpushjoe): add error checking to virtual filesystem
local vfs = VirtualFilesystem:new(virt_filesystem_structure)

-- example_file = utils.str.split_lines_to_list(example_file)
-- table.insert(example_file, false)

local context
context, err =
	Context:new(config, "/home/user/p/main.txt", example_file, vfs)

if not context then
	error(err)
end

utils.print(config)
local root
root, err = fold.parse(context)
if not root then
	error(err)
end
_, err = fold.prepare(root, context)
if err then
	error(err)
end
_, err = fold.execute(root, context)
if err then
	error(err)
end

print()
print(vfs)
-- print(utils.inspect(virt_filesystem_structure))
