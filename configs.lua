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
			local path = (function()
				if section.parent and section.parent.path then
					return section.parent.path:directory()
				else
					return ctx.src_path:directory()
				end
			end)()

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
