local s = require("core.strings")
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

config.resolve_directory = function(section, src_path)
	src_path:pop()
	return src_path
end

config.resolve_filename = function(section)
	return section:get_lines()[1]
end

return {
	config = config,
}
