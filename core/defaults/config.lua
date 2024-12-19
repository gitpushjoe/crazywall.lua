local s = require "core.strings"
require "core.config"

local config = {}
---@cast config ConfigTable

config.note_schema = {
	{'permanent'},
	{'reference'},
	{'literature'},
	{'question'},
	{'idea'},
}

return {
	config=config
}
