local M = {}

M.str = {
	starts_with = function(inp, prefix)
		return string.sub(inp, 1, #prefix) == prefix
	end,

	ends_with = function (str, suffix)
		return string.sub(str, -string.len(suffix)) == suffix
	end,

	split_lines = function(str, include_empty)
		include_empty = include_empty or false
		return include_empty and str:gmatch("([^\n]*)\n?") or str:gmatch("[^\r\n]+")
	end,

	join = function(list, delim)
		delim = delim or ""
		local result = ""
		for i, str in ipairs(list) do
			if str ~= false then
				result = result .. (i == 1 and "" or delim) .. str
			end
		end
		return result
	end,

	join_lines = function(list)
		return M.str.join(list, "\n")
	end,
}

M.inspect = require "core.inspect"

M.print = function (tbl, indent_level)
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

M.read_only = function (tbl)
	local proxy = {}
	local mt = {
		__index = tbl,
		__newindex = function ()
			error("attempt to update a read-only table", 2)
		end
	}
	setmetatable(proxy, mt)
	return proxy
end

return M
