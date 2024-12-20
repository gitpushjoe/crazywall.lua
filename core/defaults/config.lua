require("core.config")

---@type ConfigTable
local config = {
	["note_schema"] = {
		{ "permanent" },
		{ "reference" },
		{ "literature" },
		{ "question" },
		{ "idea" },
	},
}

config.open_section_symbol = "> "
config.close_section_symbol = "<"

config.resolve_directory = function(_, conf)
	local src_path = conf.src_path:copy()
	src_path:pop()
	return src_path
end

config.resolve_filename = function(section)
	return section:get_lines()[1]
end

config.allow_makedir = true

config.transform_lines = function (section)
	local lines = section:get_lines()
	table.insert(lines, "")
	local from_text = "From:"
	local curr = section.parent
	while curr ~= nil do
		if curr.filename then
			from_text = from_text .. " [[" .. curr.filename .. "]]"
		end
		curr = curr.parent
	end
	table.insert(lines, from_text)
	return lines
end

return {
	config = config,
}
