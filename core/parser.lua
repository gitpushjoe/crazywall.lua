local validate = require("core.validate")

---@alias Equivalences { [string]: EquivalenceClass|string|nil }

---@class (exact) EquivalenceClass
---@field equivalences string[]
---@field description string

---@class Parser
---@field flag_equivalences Equivalences
---@field kwarg_equivalences Equivalences
---@field data { args: string[], flags: { [string]: string }, kwargs: { [string]: string } }
Parser = {}
Parser.__index = Parser
Parser.__name = "Parser"

---@param flags string[][]
---@param kwargs string[][]
---@return Parser?, string?
function Parser:new(flags, kwargs)
	self = {}
	setmetatable(self, Parser)
	---@cast self Parser

	local err = validate.types("Parser:new", {
		{ flags, "table", "flags" },
		{ kwargs, "table", "kwargs" },
	}) or validate.types_in_list("Parser:new", flags, "flags", "table") or validate.types_in_list(
		"Parser:new",
		kwargs,
		"kwargs",
		"table"
	) or (function()
		for i, list in ipairs(flags) do
			local _err = validate.types_in_list(
				"Parser:new",
				list,
				"flags[" .. i .. "]",
				"string"
			)
			if _err then
				return _err
			end
		end
	end)() or (function()
		for i, list in ipairs(flags) do
			local _err = validate.types_in_list(
				"Parser:new",
				list,
				"kwargs[" .. i .. "]",
				"string"
			)
			if _err then
				return _err
			end
		end
	end)()
	if err then
		return nil, err
	end

	self.args = {}
	self.flags = {}
	self.kwargs = {}
	self.flag_equivalences = {}
	self.kwarg_equivalences = {}

	for _, flag_names in ipairs(flags) do
		local main_flag = string.match(flag_names[1], "^%S+")
		local description = ""
		for i = 1, #flag_names - 1 do
			description = description
				.. flag_names[i]
				.. (i ~= #flag_names - 1 and ", " or "")
		end
		description = description .. "\n\t" .. flag_names[#flag_names]
		self.flag_equivalences[main_flag] = {
			equivalences = {},
			description = description,
		}
		table.move(
			flag_names,
			2,
			#flag_names,
			1,
			self.flag_equivalences[main_flag].equivalences
		)
		for i = 2, #flag_names - 1 do
			self.flag_equivalences[flag_names[i]] = main_flag
		end
	end

	for _, kwarg_names in ipairs(kwargs) do
		local main_kwarg = string.match(kwarg_names[1], "^%S+")
		local description = ""
		for i = 1, #kwarg_names - 1 do
			description = description
				.. kwarg_names[i]
				.. (i ~= #kwarg_names - 1 and ", " or "")
		end
		description = description .. "\n\t" .. kwarg_names[#kwarg_names]
		self.kwarg_equivalences[main_kwarg] = {
			equivalences = {},
			description = description,
		}
		table.move(
			kwarg_names,
			2,
			#kwarg_names,
			1,
			self.kwarg_equivalences[main_kwarg].equivalences
		)
		for i = 2, #kwarg_names - 1 do
			local kwarg = string.match(kwarg_names[i], "^%S+")
			self.kwarg_equivalences[kwarg] = main_kwarg
		end
	end
	self.data = {
		args = {},
		flags = {},
		kwargs = {},
	}

	return self
end

---@param key string
---@return "flags"|"kwargs"|nil, string?
function Parser:search(key)
	local equivalence_class = self.flag_equivalences[key]
	if type(equivalence_class) == type("") then
		---@cast equivalence_class string
		key = equivalence_class
		equivalence_class = self.flag_equivalences[equivalence_class]
	end
	if equivalence_class then
		return "flags", key
	end

	equivalence_class = self.kwarg_equivalences[key]
	if type(equivalence_class) == type("") then
		---@cast equivalence_class string
		key = equivalence_class
		equivalence_class = self.kwarg_equivalences[equivalence_class]
	end
	if equivalence_class then
		return "kwargs", key
	end
end

---@param args string[]
---@return boolean, string?
function Parser:parse(args)
	---@type string?
	local kwarg_key = nil
	for _, arg in ipairs(args) do
		if arg:sub(1, 1) ~= "-" then
			if kwarg_key then
				self.data.kwargs[kwarg_key] = arg
				kwarg_key = nil
			else
				table.insert(self.data.args, arg)
			end
		else
			if kwarg_key ~= nil then
				return false, "Missing argument for " .. arg
			end
			local type, key = self:search(arg)
			if not type then
				return false, "Unexpected argument: " .. arg
			end
			if type == "flags" then
				self.data.flags[assert(key)] = arg
			else
				kwarg_key = key
			end
		end
	end
	if kwarg_key then
		return false, "Missing argument for " .. arg[#arg]
	end
	return true
end

---@param key string
---@return string?, string?
function Parser:find(key)
	local type, main_key = self:search(key)
	if not type then
		return nil, "Key not found."
	end
	return self.data[type][main_key]
end

---@param key string, string?
function Parser:set(key, value)
	local type, main_key = self:search(key)
	if not type then
		error(key .. " not in args")
	end
	self.data[type][assert(main_key)] = value
end

---@return string
function Parser:get_helptext()
	local res = {}
	for _, tbl in ipairs({ self.flag_equivalences, self.kwarg_equivalences }) do
		for _, value in pairs(tbl) do
			if type(value) == type({}) then
				table.insert(res, value.description .. "\n")
			end
		end
	end
	table.sort(res)
	return table.concat(res, "\n")
end

---@param ... string
---@return table?, string?
function Parser:find_all(...)
	local found = {}
	for _, key in ipairs({...}) do
		local value = self:find(key)
		if not value then
			return nil, key
		end
		table.insert(found, value)
	end
	return found
end

return Parser
-- M.errors = {
--
-- 	---@param kwarg_name string
-- 	missing_argument_for_kwarg = function(kwarg_name)
-- 		return "Missing argument for " .. kwarg_name
-- 	end,
-- }
--
-- --- @alias ArgTable {args: string[], flags: string[], kwargs: {[string]: string}}
--
-- ---@param args string[]
-- ---@param kwarg_names string[]
-- ---@return ArgTable?, string?
-- M.get_arg_table = function(args, kwarg_names)
-- 	---@type string?
-- 	local kwarg_key = nil
-- 	---@type ArgTable
-- 	local arg_table = { args = {}, flags = {}, kwargs = {} }
-- 	for _, arg in ipairs(args) do
-- 		local is_kwarg = false
-- 		for _, kwarg in ipairs(kwarg_names) do
-- 			if kwarg == arg then
-- 				is_kwarg = true
-- 				break
-- 			end
-- 		end
-- 		local group = arg:sub(1, 1) == "-" and "flags" or "args"
-- 		group = group == "flags" and is_kwarg and "kwargs" or group
-- 		if kwarg_key ~= nil then
-- 			if group ~= "args" then
-- 				return nil, M.errors.missing_argument_for_kwarg(kwarg_key)
-- 			end
-- 			arg_table.kwargs[kwarg_key] = arg
-- 			kwarg_key = nil
-- 		else
-- 			if group == "kwargs" then
-- 				kwarg_key = arg
-- 			else
-- 				table.insert(arg_table[group], arg)
-- 			end
-- 		end
-- 	end
-- 	if kwarg_key ~= nil then
-- 		return nil, M.errors.missing_argument_for_kwarg(kwarg_key)
-- 	end
-- 	return arg_table
-- end
--
-- ---@param handlers {[1]: string|string[], [2]: function}[]
-- ---@param args string[]
-- M.handle_flags = function(handlers, args)
-- 	local handler_table = {}
-- 	for _, pair in ipairs(handlers) do
-- 		local strings = type(pair[1]) == type({}) and pair[1] or { pair[1] }
-- 		---@cast strings string[]
-- 		local func = pair[2]
-- 		for str in ipairs(strings) do
-- 			handler_table[str] = func
-- 		end
-- 	end
-- 	for _, arg in ipairs(args) do
-- 		local func = handler_table[arg]
-- 		if func then
-- 			func()
-- 		end
-- 	end
-- end
--
-- ---@param arg_table ArgTable
-- ---@param keys string[]
-- ---@return string?
-- M.arg_table_find = function(arg_table, keys)
-- 	for _, key in ipairs(keys) do
-- 		if arg_table.kwargs[key] then
-- 			return arg_table.kwargs[key]
-- 		end
-- 		for _, v in ipairs(arg_table.flags) do
-- 			if v == key then
-- 				return v
-- 			end
-- 		end
-- 	end
-- 	return nil
-- end
--
-- return M
