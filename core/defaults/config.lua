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

config.resolve_path = function(section)
	local path, err = Path:new("/home/user/.crazywall/notes/test")
	if not path then
		error(err)
	end
	path:push_directory(section.type[2])
	path:replace_filename(section:get_lines()[1])
	return path
end

config.allow_makedir = true

config.transform_lines = function(section)
	local lines = section:get_lines()
	if section.parent.type[1] == "ROOT" then
		return lines
	end
	table.insert(lines, "")
	local from_text = "From:"
	local curr = section.parent
	while curr ~= nil and curr.type[1] ~= "ROOT" do
		if curr.path:get_filename() then
			from_text = from_text .. " [[" .. curr.path:get_filename() .. "]]"
		end
		curr = curr.parent
	end
	table.insert(lines, from_text)
	return lines
end

config.resolve_reference = function(section)
	return "[[" .. section.path:get_filename() .. "]]"
end

config.retry_count = 1

config.resolve_collision = function(path, _, _, retry_count)
	path:replace_filename(path:get_filename() .. " (" .. retry_count .. ")")
	return path
end

config.allow_overwrite = false

return {
	config = config,
}
