local s = require "core.strings"

local config = {
	[s.NOTE_TYPES] = {
		{'permanent'},
		{'reference'},
		{'literature'},
		{'question'},
		{'idea'},
	},
}

return {
	config=config
}
