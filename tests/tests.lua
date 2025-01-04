local suites = {
	require("tests.config"),
}

--- TODO(gitpushjoe): make this automatic
local modules_with_errors = {
	require("core.config"),
	require("core.fold"),
	require("core.parser"),
	require("core.path"),
	require("core.section"),
	require("core.traverse"),
	require("core.validate"),
	require("core.context"),
	require("core.plan.action"),
	require("core.plan.plan"),
	require("core.mock_filesystem.io"),
	require("core.mock_filesystem.handle"),
	require("core.mock_filesystem.process_handle"),
	require("core.mock_filesystem.utils"),
	require("core.mock_filesystem.mock_filesystem"),
	require("core.streams"),
	require("core.utils"),
}

local total = 0
local successes = 0
local failures = {}

local uninvoked_errors = {}
local total_invokable_error_count = 0
for _, module in ipairs(modules_with_errors) do
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
				print(name .. ": SUCCESS")
			else
				table.insert(failures, { suite.name, test.name })
				print(name .. ": FAILURE")
				print("\t" .. result:gsub("\n", "\n\t"))
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
