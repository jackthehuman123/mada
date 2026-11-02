--!strict
-- Client bootstrap. Requires every ModuleScript in ./Controllers, calls Init() on all, then Start() on all.

local controllersFolder = script:FindFirstChild("Controllers")
assert(controllersFolder, "[LangVong] Controllers folder missing — is Rojo connected?")

type Module = { Init: (() -> ())?, Start: (() -> ())? }

local loaded: { { name: string, module: Module } } = {}

for _, child in controllersFolder:GetChildren() do
	if child:IsA("ModuleScript") then
		local ok, result = pcall(require, child)
		if ok then
			table.insert(loaded, { name = child.Name, module = result :: any })
		else
			warn(`[LangVong] failed to load controller {child.Name}: {result}`)
		end
	end
end

for _, entry in loaded do
	if entry.module.Init then
		entry.module.Init()
	end
end

for _, entry in loaded do
	if entry.module.Start then
		task.spawn(entry.module.Start)
	end
end

print(`[LangVong] client started ({#loaded} controllers)`)
