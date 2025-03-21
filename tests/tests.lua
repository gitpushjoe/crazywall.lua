local utils = require("crazywall.core.utils")
local ansi = require("crazywall.core.ansi")

local suites = {}
for v in utils.str.split_lines(assert(utils.run_command("ls -1 ./tests/*.lua"))) do
	local match = string.match(v or "", "tests/(.*)%.lua")
	if match ~= "" and match ~= "suite" and match ~= "tests" then
		suites[#suites + 1] = require("tests." .. match)
	end
end

--- TODO(gitpushjoe): make this automatic
local modules = {}
for v in
	utils.str.split_lines(
		assert(utils.run_command("ls -1 ./crazywall/core/*.lua ./crazywall/core/**/*.lua"))
	)
do
	local match = string.match(v or "", "crazywall/core/(.*)%.lua")
	if match ~= "" then
		modules[#modules + 1] = require("crazywall.core." .. match:gsub("/", "."))
	end
end

local total = 0
local successes = 0
local failures = {}

local uninvoked_errors = {}
local total_invokable_error_count = 0
for _, module in ipairs(modules) do
	if module.errors and module.__name then
		for error, _ in pairs(module.errors) do
			uninvoked_errors[module.__name .. ".errors." .. error] = 1
			total_invokable_error_count = total_invokable_error_count + 1
		end
	end
end

for _, suite in ipairs(suites) do
	if suite.__index == Suite.__index then
		for _, test in ipairs(suite.tests) do
			total = total + 1
			local success, result = pcall(test.func)
			local name = test.name:sub(1, 1) == "("
					and suite.name .. " " .. test.name
				or suite.name .. "." .. test.name
			uninvoked_errors[name] = nil
			if success then
				successes = successes + 1
				print(name .. ": " .. ansi.green("SUCCESS"))
			else
				table.insert(failures, { suite.name, test.name })
				print(ansi.red(name .. ": FAILURE"))
				print(ansi.red("\t" .. result:gsub("\n", "\n\t")))
			end
		end
	end
end

local uninvoked_error_count = 0
print("\nUninvoked errors: ")
for error_name in pairs(uninvoked_errors) do
	print("  " .. error_name)
	uninvoked_error_count = uninvoked_error_count + 1
end
print(
	"Error coverage: "
		.. total_invokable_error_count - uninvoked_error_count
		.. " ("
		.. (math.floor(
			(total_invokable_error_count - uninvoked_error_count)
				* 10000
				/ total_invokable_error_count
		) / 100)
		.. "%)"
)
print("Uninvoked error count: " .. uninvoked_error_count)

print("\nTotal tests: " .. total)
print(
	"Successes: "
		.. successes
		.. " ("
		.. (math.floor(successes * 10000 / total) / 100)
		.. "%)"
)
print("Failures: ")
for _, failure in ipairs(failures) do
	print("  " .. failure[1] .. "." .. failure[2])
end

print()

if #failures > 0 then
	os.exit(1)
end
