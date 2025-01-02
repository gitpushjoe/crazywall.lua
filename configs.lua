local utils = require("core.utils")

---@type { [string]: PartialConfigTable }
local configs = {

	DEFAULT = {
		note_schema = {
			{ "h1", "# ", "[!h1]" },
			{ "h2", "## ", "[!h2]" },
			{ "h3", "### ", "[!h3]" },
			{ "h4", "#### ", "[!h4]" },
			{ " - h1", "- # ", "[!h1]" },
			{ " - h2", "- ## ", "[!h2]" },
			{ " - h3", "- ### ", "[!h3]" },
			{ " - h4", "- #### ", "[!h4]" },
		},

		resolve_path = function(section, ctx)
			local path = (
				(section.parent and section.parent.path) or ctx.src_path
			):directory()

			if not path then
				return Path:void()
			end

			if
				utils.str.starts_with(section:get_lines()[1], "{")
				and utils.str.ends_with(section:get_lines()[1], "}")
			then
				return Path:void()
			end

			local title = utils.str.trim(section:get_lines()[1])
				or ("Untitled " .. section.id)

			if #section.children > 0 then
				path:push_directory(title)
				path:set_filename("_index.md")
				return path
			end
			path:set_filename(title .. ".md")
			return path
		end,

		resolve_reference = function(section)
			if section.path:is_void() then
				return false
			end
			local filename = section.path:get_filename()
			if filename == "_index.md" then
				filename = section.path.parts[#section.path.parts - 1]
			end
			if section.type[2]:sub(1, 1) == "-" then
				return "- [[" .. filename .. "]]"
			end
			return "[[" .. filename .. "]]"
		end,

		transform_lines = function(section)
			local lines = section:get_lines()
			lines[1] = section.type[2]:gsub("^- ", "")
				.. utils.str.trim(lines[1])
			return lines
		end,
	},
}

return configs
