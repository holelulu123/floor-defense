-- Runs every tests/*.spec.luau in its own Lune process. Usage: lune run test
local fs = require("@lune/fs")
local process = require("@lune/process")

local failed = 0
local names = fs.readDir("tests")
table.sort(names)

for _, name in names do
	if name:match("%.spec%.luau$") then
		local result = process.exec("lune", { "run", "tests/" .. name })
		if result.ok then
			print((result.stdout:gsub("%s+$", "")))
		else
			failed += 1
			print(`FAIL {name}`)
			print(result.stderr)
		end
	end
end

if failed > 0 then
	print(`{failed} spec file(s) failed`)
	process.exit(1)
end
print("all specs passed")
