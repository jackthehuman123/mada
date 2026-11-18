--!strict
-- Exports the art layer of the shared place into git, so the factory tests can run on the dressed world
-- (DECISIONS 2026-11-02: art is tested both ways, by these files and by a hand playthrough).
--
--   1. In Studio, with the shared place open: File > Save to File As... > build/art-source.rbxl
--   2. lune run tools/art/export                (or: lune run tools/art/export path/to/place.rbxl [out dir])
--   3. Commit art/ . Then: python tools/factory/test.py --art
--
-- Writes art/World.rbxm (Workspace.World) and art/Environment.rbxm (the Terrain, and the Lighting settings and
-- effects). Scripts inside free models never go into git (docs/ASSETS.md): they are removed and listed.
-- Runs in Lune (rokit), not in Roblox. It works on a copy read from the file; the place itself is never touched.

local fs = require("@lune/fs")
local process = require("@lune/process")
local roblox = require("@lune/roblox")

local SRC = process.args[1] or "build/art-source.rbxl"
local OUT = process.args[2] or "art"
local SCRIPTS = { Script = true, LocalScript = true, ModuleScript = true }
-- the Lighting properties the art pass may tune (stored as attributes on Environment.Lighting)
local LIGHT_PROPS = {
	"Ambient",
	"OutdoorAmbient",
	"Brightness",
	"ColorShift_Bottom",
	"ColorShift_Top",
	"EnvironmentDiffuseScale",
	"EnvironmentSpecularScale",
	"ExposureCompensation",
	"FogColor",
	"FogEnd",
	"FogStart",
	"GeographicLatitude",
	"GlobalShadows",
	"ShadowSoftness",
}

if not fs.isFile(SRC) then
	print(`No place file at {SRC}.`)
	print("In Studio, with the shared place open: File > Save to File As... > build/art-source.rbxl")
	process.exit(1)
end

local game = roblox.deserializePlace(fs.readFile(SRC))
local workspace = game:GetService("Workspace")
local world = workspace:FindFirstChild("World")
if not world then
	print(`{SRC} has no Workspace.World: is it the shared place?`)
	process.exit(1)
end

-- free models can bring scripts: none of them goes into git
local function strip(root: any): { string }
	local found = {}
	for _, d in root:GetDescendants() do
		if SCRIPTS[d.ClassName] then
			table.insert(found, d)
		end
	end
	local names = {}
	for _, d in found do
		local ok, name = pcall(function()
			return d:GetFullName()
		end)
		table.insert(names, if ok then name else d.Name)
		pcall(function()
			d:Destroy()
		end)
	end
	return names
end

-- the environment: the Terrain itself, and the Lighting's settings (as attributes) and children (Sky, Atmosphere...)
local env = roblox.Instance.new("Folder")
env.Name = "Environment"
local terrain = workspace:FindFirstChildOfClass("Terrain")
if terrain then
	terrain.Parent = env -- (a copy read from the file, so moving it is safe)
end
local lightingSrc = game:GetService("Lighting")
local lighting = roblox.Instance.new("Folder")
lighting.Name = "Lighting"
for _, p in LIGHT_PROPS do
	local ok, v = pcall(function()
		return lightingSrc[p]
	end)
	if ok and v ~= nil then
		lighting:SetAttribute(p, v)
	end
end
for _, c in lightingSrc:GetChildren() do
	c.Parent = lighting
end
lighting.Parent = env

local removed = strip(world)
for _, n in strip(env) do
	table.insert(removed, n)
end

if not fs.isDir(OUT) then
	fs.writeDir(OUT)
end
fs.writeFile(`{OUT}/World.rbxm`, roblox.serializeModel({ world }))
fs.writeFile(`{OUT}/Environment.rbxm`, roblox.serializeModel({ env }))

local parts = 0
for _, d in world:GetDescendants() do
	if d:IsA("BasePart") then
		parts += 1
	end
end
print(`Exported Workspace.World ({#world:GetDescendants()} instances, {parts} parts) -> {OUT}/World.rbxm`)
print(
	`Exported {terrain and "the Terrain" or "no Terrain"} and {#lighting:GetChildren()} Lighting effects -> {OUT}/Environment.rbxm`
)
if #removed > 0 then
	print(`Removed {#removed} script(s) that came with models (they stay in the place; delete them there too):`)
	for _, n in removed do
		print("  " .. n)
	end
end
print("Next: python tools/factory/test.py --art, then commit art/ if it passes.")
