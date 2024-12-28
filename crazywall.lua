local example_file = [[# My Notes

r { Chapter 1
Notes:

	a { Article 1
	These are notes on some article.
		n { Note 1 } n
		n { Note 2 } n
		n { Note 3 } n
	Above are three notes.
	} a
	a { Article 2
	These are notes on another article.
	} a

} r

r { Chapter 2

	a { Article 1 
	This is another note titled "Article 1".
	} a
	q { A question } q

} r

q { A question
(This is another question)
} q

o { This is something else 
} o
]]


local script_dir = debug.getinfo(1, "S").source:match("@(.*)/?")
package.path = package.path .. ";" .. script_dir .. "/?.lua"

local utils = require("core.utils")
local default_config = require("core.defaults.config")
local fold = require("core.fold")
local MockFilesystem = require("core.mock_filesystem.mock_filesystem")


local config, err = Config:new(default_config.config)
if not config then
	error(err)
end

local mock_filesystem_table = {
	home = {
		user = {
			p = {
				["main.txt"] = example_file,
				["Article 1.txt"] = "bar",
			},
			r = {},
			f = {},
			["some_file.txt"] = "foo",
		},
	},
}

-- TODO(gitpushjoe): add error checking to virtual filesystem
local mock_fs = MockFilesystem:new(mock_filesystem_table)

-- example_file = utils.str.split_lines_to_list(example_file)
-- table.insert(example_file, false)

local context
context, err =
	Context:new(config, "/home/user/p/main.txt", example_file, mock_fs)

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
plan, err = fold.execute(root, context, false)
if err then
	error(err)
end

print()
print(plan)

print()
print(mock_fs)
