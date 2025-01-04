local utils = require("core.utils")

---@type Config
local default_config = {
	note_schema = {
		{ "permanent", "p {", "} p" },
		{ "article", "a {", "} a" },
		{ "reference", "r {", "} r" },
		{ "literature", "l {", "} l" },
		{ "question", "q {", "} q" },
		{ "note", "n {", "} n" },
		{ "idea", "i {", "} i" },
	},

	resolve_path = function(section, ctx)
		local path = ((section.parent and section.parent.path) or ctx.src_path):directory()

		if not path then
			return Path:void()
		end

		local title = utils.str.trim(section:get_lines()[1])
			or ("Untitled " .. section.id)

		if #section.children > 0 then
			path:push_directory(title)
		end

		path:set_filename(title .. ".md")
		return path
	end,

	transform_lines = function(section)
		local lines = section:get_lines()
		lines[1] = utils.str.trim(lines[1])
		return lines
	end,

	resolve_reference = function(section)
		return section.path and "[[" .. section.path:get_filename() .. "]]"
			or false
	end,

	resolve_collision = function(path, _, _, retry_count)
		local filename = path:get_filename()
		local name, extension = filename:match("^(.*)%.(.*)$")
		if name and extension then
			path:set_filename(name .. " (" .. retry_count .. ")." .. extension)
			return path
		end
		path:set_filename(filename .. " (" .. retry_count .. ")")
		return path
	end,

	retry_count = 0,

	local_retry_count = 1,

	allow_makedir = true,

	allow_local_overwrite = false,

	allow_overwrite = false,
}

return default_config
