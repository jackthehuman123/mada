--!strict
local fs = require("@lune/fs")
local process = require("@lune/process")

type TestFn = (name: string, fn: () -> ()) -> ()
type Spec = (test: TestFn) -> ()

local function findSpecs(dir: string, out: { string })
	for _, name in fs.readDir(dir) do
		local path = `{dir}/{name}`
		if fs.isDir(path) then
			findSpecs(path, out)
		elseif name:match("%.spec%.luau$") then
			table.insert(out, path)
		end
	end
end

local specs: { string } = {}
findSpecs("tests", specs)
table.sort(specs)

local failures = 0
for _, path in specs do
	local loaded, spec = pcall(require, `../{path:gsub("%.luau$", "")}`)
	if not loaded then
		print(`{path}: <load>: {spec}`)
		failures += 1
		continue
	end
	local run = spec :: Spec
	run(function(name, fn)
		local ok, err = pcall(fn)
		if not ok then
			print(`{path}: {name}: {err}`)
			failures += 1
		end
	end)
end

if failures > 0 then
	process.exit(1)
end
