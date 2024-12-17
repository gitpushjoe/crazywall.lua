local str = {}

str.starts_with = function(inp, prefix)
	return string.sub(inp, 1, #prefix) == prefix
end

str.split_lines = function(inp, include_empty)
	include_empty = include_empty or false
	return include_empty and inp:gmatch("([^\n]*)\n?") or inp:gmatch("[^\r\n]+")
end

local print = function (tbl, indent_level)
	indent_level = indent_level or 4
	local txt = require "core.inspect"(tbl)
	local indent = 0
	for i = 1, #txt do
		local char = txt:sub(i, i)
		if char == "\n" or char == "\t" or char == " " then
			goto continue
		end
		if char == "{" then
			io.write(char)
			indent = indent + 4
			local curr_indent = indent - ((txt:sub(i + 1, i + 1) == " ") and 1 or 0)
			io.write('\n')
			io.write(string.rep(" ", curr_indent))
		elseif char == "}" then
			indent = indent - 4
			local curr_indent = indent - ((txt:sub(i + 1, i + 1) == " ") and 1 or 0)
			io.write('\n')
			io.write(string.rep(" ", curr_indent))
			io.write(char)
		elseif char == "," then
			io.write(char)
			local curr_indent = indent - ((txt:sub(i + 1, i + 1) == " ") and 1 or 0)
			io.write('\n')
			io.write(string.rep(" ", curr_indent))
		else
			io.write(char)
		end
		::continue::
	end
	io.write('\n')
end



return {
	inspect = require "core.inspect",
	print = print,
	str = str
}
