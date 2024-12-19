local M = {}

M.split = function (path)
	return path:gmatch("([^/]+)")
end

M.split_to_table = function (path)
	local tbl = {}
	for v in path:gmatch("([^/]+)") do
		table.insert(tbl, v)
	end
	return tbl
end

return M
