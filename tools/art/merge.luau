--!strict
-- Puts the exported art layer (art/World.rbxm, art/Environment.rbxm; see export.luau) into a place built by Rojo,
-- so the factory tests run on the dressed world. Called by `python tools/factory/test.py --art`.
--
--   lune run tools/art/merge <in.rbxl> <out.rbxl>
--
-- Sets Workspace's WorldBuilt attribute, so WorldService keeps the art and doesn't build the graybox over it.

local fs = require("@lune/fs")
local process = require("@lune/process")
local roblox = require("@lune/roblox")

local IN = process.args[1] or "build/langvong.rbxl"
local OUT = process.args[2] or IN
local ART = "art"

for _, f in { `{ART}/World.rbxm`, `{ART}/Environment.rbxm` } do
	if not fs.isFile(f) then
		print(`Missing {f}: export the art first (lune run tools/art/export).`)
		process.exit(1)
	end
end

local place = roblox.deserializePlace(fs.readFile(IN))
local workspace = place:GetService("Workspace")

local old = workspace:FindFirstChild("World")
if old then
	old:Destroy()
end
local world = roblox.deserializeModel(fs.readFile(`{ART}/World.rbxm`))[1]
world.Parent = workspace

local env = roblox.deserializeModel(fs.readFile(`{ART}/Environment.rbxm`))[1]
local terrain = env:FindFirstChildOfClass("Terrain")
if terrain then
	local t0 = workspace:FindFirstChildOfClass("Terrain")
	if t0 then
		t0:Destroy()
	end
	terrain.Parent = workspace
end
local lightingArt = env:FindFirstChild("Lighting")
if lightingArt then
	local lighting = place:GetService("Lighting")
	for name, v in lightingArt:GetAttributes() do
		local ok = pcall(function()
			lighting[name] = v
		end)
		if not ok then
			print(`(skipped Lighting.{name})`)
		end
	end
	lighting:ClearAllChildren()
	for _, c in lightingArt:GetChildren() do
		c.Parent = lighting
	end
end

workspace:SetAttribute("WorldBuilt", "LangVong")
fs.writeFile(OUT, roblox.serializePlace(place))
print(`Art merged into {OUT}: Workspace.World{terrain and ", Terrain" or ""}{lightingArt and ", Lighting" or ""}`)
