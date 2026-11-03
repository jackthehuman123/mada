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
	if entry.module.Init then
		local ok, err = pcall(entry.module.Init)
		if not ok then
			warn(`[LangVong] {entry.name}.Init failed: {err}`)
		end
	end
end

for _, entry in loaded do
	if entry.module.Start then
		task.spawn(entry.module.Start)
	end
end

print(`[LangVong] server started ({#loaded} services)`)
