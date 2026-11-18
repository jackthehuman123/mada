--!strict
-- Server bootstrap. Requires every ModuleScript in ./Services, calls Init() on all, then Start() on all.
-- Each service returns a table with optional Init() and Start() functions (dot-call, no self).

local servicesFolder = script:FindFirstChild("Services")
assert(servicesFolder, "[LangVong] Services folder missing — is Rojo connected?")

type Module = { Init: (() -> ())?, Start: (() -> ())? }

local loaded: { { name: string, module: Module } } = {}

for _, child in servicesFolder:GetChildren() do
	if child:IsA("ModuleScript") then
		local ok, result = pcall(require, child)
		if ok then
			table.insert(loaded, { name = child.Name, module = result :: any })
		else
			warn(`[LangVong] failed to load service {child.Name}: {result}`)
		end
	end
end

-- (each guarded: one service that throws must not stop all the others, which meant a black screen or no menu)
for _, entry in loaded do
	local init = entry.module.Init
	if init then
		local ok, err = pcall(init :: () -> any) -- (cast: pcall of a () -> () types as returning only `ok`)
		if not ok then
			warn(`[LangVong] {entry.name}.Init failed: {err}`)
		end
	end
end

-- Scenes (prefab layout + mood) load after Init and before Start; a failed scene must not stop the game.
local SceneLoader = require(script:WaitForChild("SceneLoader")) :: any
local activeScenes = require(script:WaitForChild("Scenes"):WaitForChild("active")) :: { string }
for _, sceneName in activeScenes do
	local ok, placed, warnings = pcall(SceneLoader.load, sceneName)
	if not ok then
		warn(`[LangVong] scene {sceneName} failed to load: {placed}`)
	else
		for _, w in warnings do
			warn(`[LangVong] {w}`)
		end
		print(`[LangVong] scene {sceneName}: {placed} prefabs placed`)
	end
end

for _, entry in loaded do
	if entry.module.Start then
		task.spawn(entry.module.Start)
	end
end

print(`[LangVong] server started ({#loaded} services)`)
