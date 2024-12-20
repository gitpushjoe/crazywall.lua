local M = {}

---TODO(gitpushjoe): Give better/more accurate error messages when encountering nil

---@param function_name string
M.invalid_type = function(function_name)
	---@param arg_name string
	---@param expected_type string
	---@param actual string
	---@overload fun(triplet: [any, string, string?]): string
	return function(arg_name, expected_type, actual)
		if type(arg_name) == type({}) then
			expected_type = arg_name[2]
			actual = type(arg_name[1])
			arg_name = arg_name[3]
		end
		return "Invalid type for `"
			.. arg_name
			.. "` in `"
			.. function_name
			.. "`."
			.. '\nExpected type "'
			.. expected_type
			.. '" but got "'
			.. actual
			.. '".'
	end
end

---@param function_name string
M.invalid_instance = function(function_name)
	---@param arg_name string
	---@param expected_class table
	---@param actual any
	---@overload fun(triplet: [any, table, string?]): string
	return function(arg_name, expected_class, actual)
		if type(arg_name) == type({}) then
			expected_class = arg_name[2]
			actual = arg_name[1]
			arg_name = arg_name[3]
		end
		expected_class = expected_class.__name
		if actual then
			if actual.__index then
				actual = actual.__index.__name or tostring(actual.__index)
			else
				actual = "(actual = " .. tostring(actual) .. ")"
			end
		end
		return "Invalid base class for `"
			.. arg_name
			.. "` in `"
			.. function_name
			.. "`."
			.. '\nExpected base class "'
			.. expected_class
			.. '" and got "'
			.. tostring(actual)
			.. '".'
	end
end

return M
