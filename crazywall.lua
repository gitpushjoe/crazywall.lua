local utils = require "core.utils"

Tprint(arg)

local config = loadfile(arg[1])
if config then
	config()
end
