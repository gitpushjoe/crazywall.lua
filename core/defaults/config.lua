local utils = require("core.utils")

---@type Config
local default_config = {

	--- The first section to try to match against is named "h1", and should
	--- begin with "# "and end with "[!h1]" (possibly on the same line), and
	--- so on.
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
		--- If this section has a parent section, then config.resolve_path will
		--- have been called on the parent already, so we can get the directory
		--- that the parent will be saved to. Otherwise, we get the directory
		--- of the path of the source file.
		--- If the parent path is void (see Path:is_void()), then this will be
		--- nil.
		local path = ((section.parent and section.parent.path) or ctx.src_path):directory()

		--- If the parent path should be ignored, then set this section to be
		--- ignored as well.
		if not path then
			return Path:void()
		end

		--- Ignore this section if the first line starts with "{" and ends with
		--- "}" (not including tags).
		if
			utils.str.starts_with(section:get_lines()[1], "{")
			and utils.str.ends_with(section:get_lines()[1], "}")
		then
			return Path:void()
		end

		--- Set the filename of the note to the first line of the section, or
		--- "Untitled {section.id}", if the first line is empty/whitespace.
		local filename = utils.str.trim(section:get_lines()[1])
			or ("Untitled " .. section.id)

		--- If this section has sub-sections, then create a directory for it,
		--- and title this section "_index.md".
		if #section.children > 0 then
			path:push_directory(filename)
			path:set_filename("_index.md")
			return path
		end

		--- Otherwise, title it "{filename}.md"
		path:set_filename(filename .. ".md")
		return path
	end,

	transform_lines = function(section)
		--- Remove whitespace from the first line of the section, before saving
		--- it to another file.
		local lines = section:get_lines()
		lines[1] = utils.str.trim(lines[1])
		return lines
	end,

	resolve_reference = function(section)
		--- Set the reference for the section to the filename surrounded by
		--- "[[" and "]]". Note that Path:get_filename() returns "" when
		--- path:is_void().
		return "[[" .. assert(section.path):get_filename() .. "]]"
	end,

	resolve_collision = function(path, _, _, retry_count)
		--- Try to split the path into filename and extension, and return
		--- "{basename} ({retry_count}).{extension}" as the new name.
		local filename = path:get_filename()
		local name, extension = filename:match("^(.*)%.(.*)$")
		if name and extension then
			path:set_filename(name .. " (" .. retry_count .. ")." .. extension)
			return path
		end
		path:set_filename(filename .. " (" .. retry_count .. ")")
		return path
	end,

	--- Allow up to 16 config.resolve_collision() calls to be made for each
	--- section that gets mapped to the same path as another section by
	--- config.resolve_path(). After 16 attempts, throw an error.
	local_retry_count = 16,

	--- Allow up to 0 config.resolve_collision() calls to be made when trying
	--- to save a section to a path that already exists in the filesystem.
	retry_count = 0,

	--- Allow crazywall to create new directories and sub-directories if
	--- necessary to save a file.
	allow_makedir = true,

	--- Do not allow any section that gets mapped to the same path as a
	--- previous section to overwrite the previous section.
	allow_local_overwrite = false,

	--- Do not allow any section that gets mapped to the same path as an
	--- existing file in the filesystem to overwrite the file.
	allow_overwrite = false,
}

return default_config
