--!strict
-- Usage: lune run tools/extract-prefabs <place.rbxl> [folderName] [outDir]
-- Writes <outDir>/<Name>.rbxm (default assets/prefabs) for each Model in Workspace.<folderName>
-- (default PrefabWorkshop). Overwrites; git is the rollback. Validates all names before writing.
local fs = require("@lune/fs")
local process = require("@lune/process")
local roblox = require("@lune/roblox")

local prefabNames = require("./lib/prefabNames")

local args = process.args
local placePath = args[1]
if not placePath then
	print("usage: lune run tools/extract-prefabs <place.rbxl> [folderName] [outDir]")
	process.exit(1)
end
local folderName = args[2] or "PrefabWorkshop"
local outDir = args[3] or "assets/prefabs"

local game = roblox.deserializePlace(fs.readFile(placePath))
local workshop = game:GetService("Workspace"):FindFirstChild(folderName)
if not workshop then
	print(`no Workspace.{folderName} in {placePath}`)
	process.exit(1)
end

local models: { roblox.Instance } = {}
local names: { string } = {}
local skipped: { string } = {}
for _, child in workshop:GetChildren() do
	if child.ClassName == "Model" then
		table.insert(models, child)
		table.insert(names, child.Name)
	else
		table.insert(skipped, `skipped {child.Name} ({child.ClassName}, not a Model)`)
	end
end

local errors = prefabNames.check(names)
if #errors > 0 then
	for _, e in errors do
		print(e)
	end
	process.exit(1)
end

fs.writeDir(outDir)
for _, model in models do
	fs.writeFile(`{outDir}/{model.Name}.rbxm`, roblox.serializeModel({ model }))
end
print(`wrote {#models} prefabs`)
for _, line in skipped do
	print(line)
end
