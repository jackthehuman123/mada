--!strict
-- Thin engine glue: places prefabs from a scene's layout data and applies its mood.
-- Data lives in ./Scenes/<name>/{layout,mood}; prefabs in ServerStorage.Prefabs.
local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local SceneShared = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Scene")
local Layout = require(SceneShared:WaitForChild("Layout"))
local Mood = require(SceneShared:WaitForChild("Mood"))

local SceneLoader = {}

local function colour(c: { number }): Color3
	return Color3.fromRGB(c[1], c[2], c[3])
end

local function applyMood(mood: Mood.Mood)
	Lighting.ClockTime = mood.clockTime
	Lighting.Brightness = mood.brightness
	Lighting.FogStart = mood.fogStart
	Lighting.FogEnd = mood.fogEnd
	Lighting.FogColor = colour(mood.fogColor)
	Lighting.Ambient = colour(mood.ambient)
	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
	if mood.atmosphereDensity ~= nil then
		atmosphere = atmosphere or Instance.new("Atmosphere")
		assert(atmosphere, "atmosphere")
		atmosphere.Density = mood.atmosphereDensity
		atmosphere.Parent = Lighting
	elseif atmosphere then
		atmosphere:Destroy()
	end
end

function SceneLoader.load(sceneName: string): (number, { string })
	local data = script.Parent:WaitForChild("Scenes"):WaitForChild(sceneName)
	local entries = require(data:WaitForChild("layout")) :: { Layout.Entry }
	local mood = require(data:WaitForChild("mood")) :: Mood.Mood

	local prefabs = ServerStorage:FindFirstChild("Prefabs")
	local known: { [string]: boolean } = {}
	if prefabs then
		for _, p in prefabs:GetChildren() do
			known[p.Name] = true
		end
	end

	-- Unknown prefab names are skipped with a warning below, so count every named prefab as known here
	-- and let validate report only the shape errors (a non-string prefab still fails).
	local shapeKnown = table.clone(known)
	for _, e in entries do
		if type(e.prefab) == "string" then
			shapeKnown[e.prefab] = true
		end
	end
	local errors: { string } = Layout.validate(entries, shapeKnown)
	for _, e in Mood.validate(mood) do
		table.insert(errors, `mood: {e}`)
	end
	if #errors > 0 then
		return 0, errors
	end

	local scenes = workspace:FindFirstChild("Scenes")
	if not scenes then
		scenes = Instance.new("Folder")
		assert(scenes, "scenes")
		scenes.Name = "Scenes"
		scenes.Parent = workspace
	end
	assert(scenes, "scenes")
	local old = scenes:FindFirstChild(sceneName)
	if old then
		old:Destroy()
	end
	local folder = Instance.new("Folder")
	folder.Name = sceneName
	folder.Parent = scenes

	local warnings: { string } = {}
	local placed = 0
	for i, e in entries do
		local prefab = prefabs and prefabs:FindFirstChild(e.prefab)
		if not prefab then
			table.insert(warnings, `scene '{sceneName}' entry {i}: unknown prefab '{e.prefab}', skipped`)
			continue
		end
		local clone = prefab:Clone() :: Model
		clone:PivotTo(CFrame.new(e.at[1], e.at[2], e.at[3]) * CFrame.Angles(0, math.rad(e.rot or 0), 0))
		for _, tag in e.tags or {} do
			CollectionService:AddTag(clone, tag)
		end
		clone.Parent = folder
		placed += 1
	end

	applyMood(mood)
	return placed, warnings
end

return SceneLoader
