local M = {}

-- TODO(gitpushjoe): just turn this into a class

M.errors = {

	---@param kwarg_name string
	missing_argument_for_kwarg = function(kwarg_name)
		return "Missing argument for " .. kwarg_name
	end,
}

--- @alias ArgTable {args: string[], flags: string[], kwargs: {[string]: string}}

---@param args string[]
---@param kwarg_names string[]
---@return ArgTable?, string?
M.get_arg_table = function(args, kwarg_names)
	---@type string?
	local kwarg_key = nil
	---@type ArgTable
	local arg_table = { args = {}, flags = {}, kwargs = {} }
	for _, arg in ipairs(args) do
		local is_kwarg = false
		for _, kwarg in ipairs(kwarg_names) do
			if kwarg == arg then
				is_kwarg = true
				break
			end
		end
		local group = arg:sub(1, 1) == "-" and "flags" or "args"
		group = group == "flags" and is_kwarg and "kwargs" or group
		if kwarg_key ~= nil then
			if group ~= "args" then
				return nil, M.errors.missing_argument_for_kwarg(kwarg_key)
			end
			arg_table.kwargs[kwarg_key] = arg
			kwarg_key = nil
		else
			if group == "kwargs" then
				kwarg_key = arg
			else
				table.insert(arg_table[group], arg)
			end
		end
	end
	if kwarg_key ~= nil then
		return nil, M.errors.missing_argument_for_kwarg(kwarg_key)
	end
	return arg_table
end

---@param handlers {[1]: string|string[], [2]: function}[]
---@param args string[]
M.handle_flags = function(handlers, args)
	local handler_table = {}
	for _, pair in ipairs(handlers) do
		local strings = type(pair[1]) == type({}) and pair[1] or { pair[1] }
		---@cast strings string[]
		local func = pair[2]
		for str in ipairs(strings) do
			handler_table[str] = func
		end
	end
	for _, arg in ipairs(args) do
		local func = handler_table[arg]
		if func then
			func()
		end
	end
end

---@param arg_table ArgTable
---@param keys string[]
---@return string?
M.arg_table_find = function(arg_table, keys)
	for _, key in ipairs(keys) do
		if arg_table.kwargs[key] then
			return arg_table.kwargs[key]
		end
		for _, v in ipairs(arg_table.flags) do
			if v == key then
				return v
			end
		end
	end
	return nil
end

return M
