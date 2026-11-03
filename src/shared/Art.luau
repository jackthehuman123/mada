--!strict
-- Làng Vọng's own models (tools/blender/mada_art.py; release council 11-03 B7) at runtime.
--   Art.build() (server, ArtService): turns every mesh into a template once, into ReplicatedStorage.ArtTemplates, so the
--     server and every client can clone an item synchronously.
--   Art.clone(item, at, scale, parent): a copy of the item at `at` (its origin: see mada_art.py), or nil while the
--     templates aren't there yet (the graybox stays then: nothing ever waits on a mesh).
--   Art.place(item, at, parent, scale, after): the same in the background, once the templates are there (world dressing).

local AssetService = game:GetService("AssetService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ArtMeshes = require(script.Parent:WaitForChild("Content"):WaitForChild("ArtMeshes"))

local Art = {}

local M = Enum.Material
local MATERIAL: { [string]: Enum.Material } = {
	Shirt = M.Fabric, Pants = M.Fabric, Body = M.Fabric, Sleeve = M.Fabric, Head = M.Fabric, Rope = M.Fabric, Canopy = M.Fabric,
	Tassel = M.Fabric, Wood = M.Wood, Pole = M.Wood, Hull = M.Wood, Bamboo = M.Wood, Trim = M.Wood, Frame = M.Wood, Stone = M.Slate,
	Tile = M.Slate, Roof = M.Slate, Wall = M.Plaster, Brick = M.Brick, Thatch = M.Fabric, Brass = M.Metal, Earth = M.Ground, Moss = M.Grass, Stem = M.Grass,
}

function Art.build()
	if ReplicatedStorage:FindFirstChild("ArtTemplates") then
		return
	end
	local folder = Instance.new("Folder")
	folder.Name = "ArtTemplates"
	local cache: { [string]: MeshPart | false } = {}
	for item, pieces in ArtMeshes do
		local m = Instance.new("Model")
		m.Name = item
		local complete = true
		for _, piece in pieces do
			local t = cache[piece.id]
			if t == nil then
				local ok, mp = pcall(function()
					return AssetService:CreateMeshPartAsync(piece.id)
				end)
				t = if ok then mp else false
				cache[piece.id] = t
				if not ok then
					warn(`[Art] {item}.{piece.part}: {mp}`)
				end
			end
			if not t then
				complete = false
				break
			end
			local p = (t :: MeshPart):Clone()
			p.Name = piece.part
			p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch = true, false, false, false
			p.Size = piece.size
			p.CFrame = CFrame.new(piece.at)
			p.Color = piece.color
			p.Material = MATERIAL[piece.part] or M.SmoothPlastic
			p.Parent = m
		end
		if complete then
			m.Parent = folder
		end
	end
	folder.Parent = ReplicatedStorage -- (all at once: a client never sees half the set)
	print(`[Art] {#folder:GetChildren()} models ready`)
end

function Art.template(item: string): Model?
	local folder = ReplicatedStorage:FindFirstChild("ArtTemplates")
	return folder and folder:FindFirstChild(item) :: Model?
end

function Art.clone(item: string, at: CFrame, scale: (number | Vector3)?, parent: Instance?): Model?
	local t = Art.template(item)
	if not t then
		return nil
	end
	local s = if typeof(scale) == "Vector3" then scale else Vector3.one * ((scale :: number?) or 1)
	local m = Instance.new("Model")
	m.Name = item
	for _, p in t:GetChildren() do
		if p:IsA("BasePart") then
			local q = p:Clone()
			q.Size = p.Size * s
			q.CFrame = at * CFrame.new(p.CFrame.Position * s) * p.CFrame.Rotation
			q.Parent = m
		end
	end
	m.Parent = parent
	return m
end

-- wait (up to `seconds`) for the templates
function Art.wait(seconds: number): boolean
	local t0 = os.clock()
	while not ReplicatedStorage:FindFirstChild("ArtTemplates") do
		if os.clock() - t0 > seconds then
			return false
		end
		task.wait(0.25)
	end
	return true
end

function Art.place(item: string, at: CFrame, parent: Instance, scale: (number | Vector3)?, after: ((Model) -> ())?)
	task.spawn(function()
		if not Art.wait(60) or not parent.Parent then
			return
		end
		local m = Art.clone(item, at, scale, parent)
		if m and after then
			after(m)
		end
	end)
end

return Art
