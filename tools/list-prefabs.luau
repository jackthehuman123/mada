--!strict
-- Usage: lune run tools/list-prefabs [dir]
-- Prints the prefab names a layout may use (file stems in assets/prefabs), one per line, sorted.
-- Agents use this instead of Glob/ls: *.rbxm files are off limits to read tools.
local fs = require("@lune/fs")
local process = require("@lune/process")

local dir = process.args[1] or "assets/prefabs"
if not fs.isDir(dir) then
	return
end

local names: { string } = {}
for _, file in fs.readDir(dir) do
	local stem = string.match(file, "^([^.].*)%.rbxmx?$")
	if stem then
		table.insert(names, stem)
	end
end
table.sort(names)
for _, name in names do
	print(name)
end
