--!strict
-- Builds the graybox village of PROTOTYPE_BRIEF §8 from code, so the world comes from git (no place file to lose).
-- Plain parts + terrain only (art comes in M7). Everything gameplay touches is tagged (Shared.Tags); code never
-- looks objects up by path.
--
-- Layout (studs; x runs west -> east along the shore, the lake is north = -z):
--   the shore line is z = -50, the lane z = -20, houses stand south of it (z ~ 30), one every 55 studs
--   shrine at the west end on a point by the water; Sen's house is the last on the lane (east)
--   the cove with the carp steps lies east of Sen's house, reached only through her back yard
--   the causeway runs south-west over the marsh from the village end; players spawn there
--   the drowned festival is a separate space at Y = Config.DrownedFestivalY

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Tags = require(Shared:WaitForChild("Tags"))
local Config = require(Shared:WaitForChild("Config"))
local Text = require(Shared:WaitForChild("Content"):WaitForChild("Text"))
local Furniture = require(Shared:WaitForChild("Content"):WaitForChild("Furniture"))
local Land = require(Shared:WaitForChild("Content"):WaitForChild("Land"))
local Art = require(Shared:WaitForChild("Art"))
local AssetService = game:GetService("AssetService")

local SHORE_Z, LANE_Z, HOUSE_Z = -50, -20, 30
local WATER_Y = -1 -- the lake's surface; the land is at y = 0
local DOCK_X = -140

-- the lane, west to east. child = the lost child whose lantern comes to this house (brief §6)
local HOUSES = {
	{ loc = "CommunalHouse", x = -250 },
	{ loc = "HeadHouse", x = -195, child = "Khoa" },
	{ loc = "FishHouse", x = -140, child = "Tí" },
	{ loc = "PuppetHouse", x = -85, child = "Hạnh" },
	{ loc = "TeacherHouse", x = -30, child = "Minh" },
	{ loc = nil, x = 25 },
	{ loc = "TellerHouse", x = 80 }, -- three doors down from Sen's
	{ loc = nil, x = 135 },
	{ loc = nil, x = 190 },
	{ loc = "SenHouse", x = 245 },
}

local rgb = Color3.fromRGB
local M = Enum.Material

local function P(parent: Instance, props: { [string]: any }): BasePart
	local part = Instance.new(props.ClassName or "Part") :: BasePart
	props.ClassName = nil
	part.Anchored = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Material = M.SmoothPlastic
	for k, v in props do
		(part :: any)[k] = v
	end
	part.Parent = parent
	return part
end

local function tag(inst: Instance, name: string, attrs: { [string]: any }?)
	CollectionService:AddTag(inst, name)
	for k, v in attrs or {} do
		inst:SetAttribute(k, v)
	end
end

local function zone(parent: Instance, name: string, cf: CFrame, size: Vector3): BasePart
	return P(parent, { Name = name, CFrame = cf, Size = size, Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = true })
end

local function model(parent: Instance, name: string, loc: string?): Model
	local m = Instance.new("Model")
	m.Name = name
	if loc then
		tag(m, Tags.Location, { Location = loc })
	end
	m.Parent = parent
	return m
end

local function lantern(parent: Instance, pos: Vector3, lit: boolean?)
	-- a paper lantern: an oval of lit paper with a small bright core (one big neon ball each read as a flat yellow disc
	-- covering the screen; release council 11-03), dark caps top and bottom
	local body = P(parent, { Name = "PaperLantern", Size = Vector3.new(1.1, 1.4, 1.1), Position = pos, Color = rgb(214, 120, 70),
		Material = M.SmoothPlastic, CanCollide = false })
	body:SetAttribute("LitColor", body.Color) -- (Im lặng puts it out; a reset lights it again from this)
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = body
	for _, dy in { 0.72, -0.72 } do
		P(parent, { Name = "LanternCap", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.18, 0.55, 0.55), CFrame = CFrame.new(pos + Vector3.new(0, dy, 0))
			* CFrame.Angles(0, 0, math.rad(90)), Color = rgb(40, 30, 24), Material = M.Wood, CanCollide = false })
	end
	if lit ~= false then
		local core = P(parent, { Name = "LanternCore", Shape = Enum.PartType.Ball, Size = Vector3.new(0.5, 0.5, 0.5), Position = pos, Color = rgb(255, 190, 120),
			Material = M.Neon, Transparency = 0.2, CanCollide = false, CastShadow = false })
		core:SetAttribute("LitColor", core.Color)
		local l = Instance.new("PointLight")
		l.Color = rgb(255, 170, 100)
		l.Range = 12
		l.Brightness = 0.9
		l.Parent = body
	end
	-- the Blender lantern (ribbed paper glowing softly, its frame and tassel) in place of the oval and caps
	Art.place("Lantern", CFrame.new(pos) * CFrame.Angles(0, math.random() * math.pi * 2, 0), parent, 1, function(m)
		body.Transparency = 1
		for _, d in parent:GetChildren() do
			if d.Name == "LanternCap" and d:IsA("BasePart") and (d.Position - pos).Magnitude < 1 then
				d:Destroy()
			end
		end
		local paper = m:FindFirstChild("Paper") :: BasePart?
		if paper then
			paper.Name = "LanternPaper"
			if lit ~= false then
				paper.Material, paper.Color, paper.Transparency = M.Neon, rgb(196, 104, 58), 0.4
				paper:SetAttribute("LitColor", paper.Color)
				paper:SetAttribute("LitMaterial", "Neon")
			end
		end
		for _, d in m:GetChildren() do
			d.Parent = parent
		end
		m:Destroy()
	end)
end

-- the land, the lake, the cove and the marsh -------------------------------------------------------------------
local function terrainPass()
	local t = Workspace.Terrain
	t:Clear()
	-- the land: a basin designed in tools/blender/mada_land.py (owner 2026-11-04: "revamp the entire map ... look like a
	-- basin ... build a map in blender then port them in"), written from its height + material grid as smooth voxels
	local H = {}
	for k, row in Land.heights do
		local r = {}
		for v in string.gmatch(row, "-?%d+") do
			r[#r + 1] = tonumber(v) / 4
		end
		H[k] = r
	end
	local STEP, X0, Z0, NX, NZ, WATER = Land.STEP, Land.X0, Land.Z0, Land.NX, Land.NZ, Land.WATER
	local MAT = { G = M.Grass, L = M.LeafyGrass, D = M.Ground, M = M.Mud, R = M.Rock, S = M.Limestone, W = M.Sand }
	local function hAt(x: number, z: number): number
		local fx, fz = (x - X0) / STEP, (z - Z0) / STEP
		local i0, k0 = math.clamp(math.floor(fx), 0, NX - 2), math.clamp(math.floor(fz), 0, NZ - 2)
		local tx, tz = math.clamp(fx - i0, 0, 1), math.clamp(fz - k0, 0, 1)
		local r0, r1 = H[k0 + 1], H[k0 + 2]
		local a = r0[i0 + 1] + (r0[i0 + 2] - r0[i0 + 1]) * tx
		local b = r1[i0 + 1] + (r1[i0 + 2] - r1[i0 + 1]) * tx
		return a + (b - a) * tz
	end
	local function matAt(x: number, z: number): Enum.Material
		local i0 = math.clamp(math.floor((x - X0) / STEP + 0.5), 0, NX - 1)
		local k0 = math.clamp(math.floor((z - Z0) / STEP + 0.5), 0, NZ - 1)
		return MAT[string.sub(Land.mats[k0 + 1], i0 + 1, i0 + 1)] or M.Grass
	end
	local CH, YLO = 128, -24 -- chunk side (studs), the lowest voxel (under the lake's bed)
	local x1, z1 = X0 + (NX - 1) * STEP, Z0 + (NZ - 1) * STEP
	for cx = X0, x1 - 1, CH do
		for cz = Z0, z1 - 1, CH do
			local nx, nz = math.min(CH, x1 - cx) // 4, math.min(CH, z1 - cz) // 4
			local hs, top = {}, WATER
			for ix = 1, nx do
				hs[ix] = {}
				for iz = 1, nz do
					local h = hAt(cx + ix * 4 - 2, cz + iz * 4 - 2)
					hs[ix][iz] = h
					top = math.max(top, h)
				end
			end
			local ny = math.ceil((top + 4 - YLO) / 4)
			local mats, occ = {}, {}
			for ix = 1, nx do
				mats[ix], occ[ix] = {}, {}
				for iy = 1, ny do
					mats[ix][iy], occ[ix][iy] = {}, {}
				end
				for iz = 1, nz do
					local h = hs[ix][iz]
					local surf = matAt(cx + ix * 4 - 2, cz + iz * 4 - 2)
					for iy = 1, ny do
						local lo = YLO + (iy - 1) * 4
						local fill = math.clamp((h - lo) / 4, 0, 1)
						if fill > 0 then
							mats[ix][iy][iz], occ[ix][iy][iz] = (if h < WATER then M.Mud else surf), fill
						elseif lo < WATER then
							mats[ix][iy][iz], occ[ix][iy][iz] = M.Water, math.clamp((WATER - lo) / 4, 0, 1)
						else
							mats[ix][iy][iz], occ[ix][iy][iz] = M.Air, 0
						end
					end
				end
			end
			t:WriteVoxels(Region3.new(Vector3.new(cx, YLO, cz), Vector3.new(cx + nx * 4, YLO + ny * 4, cz + nz * 4)), 4, mats, occ)
		end
		task.wait()
	end
	-- the night's colours for the terrain materials (dark, damp, a little blue)
	t:SetMaterialColor(M.Grass, rgb(58, 82, 48))
	t:SetMaterialColor(M.LeafyGrass, rgb(44, 70, 40))
	t:SetMaterialColor(M.Ground, rgb(92, 74, 56))
	t:SetMaterialColor(M.Mud, rgb(62, 54, 44))
	t:SetMaterialColor(M.Sand, rgb(104, 94, 76))
	t:SetMaterialColor(M.Limestone, rgb(150, 150, 142))
	t:SetMaterialColor(M.Rock, rgb(92, 90, 86))
	-- the rock ridge that hides the cove from the lane and the shore (only the back yard leads round it)
	for z = -70, 40, 10 do
		t:FillBall(Vector3.new(298 + (z % 20) * 0.2, 2, z), 11, M.Rock)
	end
	-- the cut the carp steps go down through, from the back yard to the cove's water
	t:FillBlock(CFrame.new(350, -4, -1), Vector3.new(16, 14, 26), M.Air) -- (wide: voxel smoothing slumps a narrow cut over the steps)
	-- inside each house: the land's surface sits at y ~ 2 (a full voxel fills up to the next one's centre), above the
	-- floor (top y = 1), so grass covered every floor. Clear the top voxel layer inside the walls; the floor hides it
	for _, hs in HOUSES do
		t:FillBlock(CFrame.new(hs.x, 0, HOUSE_Z), Vector3.new(21, 8, 17), M.Air)
	end
end

-- one house on the lane: floor, walls with a door gap toward the lane, a tiled roof, a window ---------------------
-- One piece of the Blender furniture (Content/Furniture) standing at cf (its foot, front toward -Z of cf), aged for the
-- night: darker and greyer than in Lotus Valley. A mesh that won't load is left out (dressing, never gameplay).
local meshCache: { [string]: MeshPart | false } = {}
local function furniture(parent: Instance, id: string, cf: CFrame)
	-- in the background: loading a mesh waits on Roblox, and the world must never wait on dressing (a test place that
	-- couldn't fetch them stalled the whole build)
	task.spawn(function()
	for _, piece in Furniture[id] or {} do
		local t = meshCache[piece.id]
		if t == nil then
			local ok, mp = pcall(function()
				return AssetService:CreateMeshPartAsync(piece.id)
			end)
			t = if ok then mp else false
			meshCache[piece.id] = t
		end
		if t then
			local p = (t :: MeshPart):Clone()
			p.Name = id .. piece.part
			p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, piece.part == "Wood", false, false, true
			p.Size = piece.size
			p.CFrame = cf * CFrame.new(piece.at)
			local h, s, v = piece.color:ToHSV()
			p.Color = Color3.fromHSV(h, s * 0.6, v * 0.62)
			p.Material = if piece.part == "Glass" then M.Glass elseif piece.part == "Wood" then M.Wood else M.SmoothPlastic
			p.Transparency = if piece.part == "Glass" then 0.5 else 0
			p.Parent = parent
		end
	end
	end)
end

local function house(parent: Instance, x: number, loc: string?, child: string?): Model
	local m = model(parent, loc or ("House_" .. tostring(x)), loc)
	local c = Vector3.new(x, 0, HOUSE_Z)
	local W, D, H = 22, 18, 10
	-- aged limewash and old tiles, a little different on every house; Sen's is greyer and neglected
	local k = (x // 55) % 3
	local wall = if loc == "SenHouse" then rgb(150, 140, 120) else ({ rgb(206, 178, 118), rgb(196, 170, 124), rgb(210, 188, 140) })[k + 1]
	local tile = if loc == "SenHouse" then rgb(96, 62, 52) else ({ rgb(150, 70, 52), rgb(138, 74, 56), rgb(160, 82, 58) })[k + 1]
	local wood = rgb(92, 64, 44)
	P(m, { Name = "Floor", Size = Vector3.new(W, 1, D), Position = c + Vector3.new(0, 0.5, 0), Color = rgb(120, 92, 64), Material = M.WoodPlanks })
	-- dressing (no gameplay): a brick plinth, gable ends and a ridge under the roof, a porch with posts, shutters
	local brick = rgb(118, 74, 58)
	-- (the ground outside is at y ~ 2: the plinth shows its top 0.8 studs)
	P(m, { Name = "Plinth", Size = Vector3.new(W + 0.6, 2.8, 0.3), Position = c + Vector3.new(0, 1.4, D / 2 + 0.15), Color = brick, Material = M.Brick, CanCollide = false })
	for _, sx in { -1, 1 } do
		P(m, { Name = "Plinth", Size = Vector3.new(0.3, 2.8, D + 0.6), Position = c + Vector3.new(sx * (W / 2 + 0.15), 1.4, 0), Color = brick, Material = M.Brick, CanCollide = false })
		P(m, { Name = "Plinth", Size = Vector3.new((W - 6) / 2, 2.8, 0.3), Position = c + Vector3.new(sx * (W / 2 - (W - 6) / 4), 1.4, -D / 2 - 0.15), Color = brick, Material = M.Brick, CanCollide = false })
	end
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			-- a wedge's high edge is its local +Z: turn the south halves round so both rise to the ridge
			P(m, { ClassName = "WedgePart", Name = "Gable", Size = Vector3.new(1, 5, D / 2),
				CFrame = CFrame.new(c + Vector3.new(sx * (W / 2 - 0.5), H + 3.5, sz * D / 4)) * CFrame.Angles(0, if sz > 0 then math.pi else 0, 0),
				Color = wall, Material = M.Plaster })
		end
	end
	P(m, { Name = "Ridge", Size = Vector3.new(W + 3.4, 0.7, 0.9), Position = c + Vector3.new(0, H + 6.4, 0), Color = tile:Lerp(rgb(0, 0, 0), 0.25), Material = M.Slate })
	P(m, { Name = "PorchRoof", Size = Vector3.new(W + 3, 0.5, 6), CFrame = CFrame.new(c + Vector3.new(0, H - 0.6, -D / 2 - 2.6)) * CFrame.Angles(math.rad(-12), 0, 0),
		Color = tile, Material = M.Slate })
	for _, px in { -W / 2, -3.5, 3.5, W / 2 } do
		P(m, { Name = "Post", Size = Vector3.new(0.7, H - 2.2, 0.7), Position = c + Vector3.new(px, (H - 2.2) / 2 + 0.8, -D / 2 - 4.6), Color = wood, Material = M.Wood })
	end
	for _, wx in { -8.8, -4.2 } do
		P(m, { Name = "Shutter", Size = Vector3.new(1.2, 2.8, 0.2), Position = c + Vector3.new(wx, 6, -D / 2 - 0.2), Color = wood, Material = M.WoodPlanks, CanCollide = false })
	end
	P(m, { Name = "WallBack", Size = Vector3.new(W, H, 1), Position = c + Vector3.new(0, H / 2 + 1, D / 2 - 0.5), Color = wall, Material = M.Plaster })
	for _, sx in { -1, 1 } do
		P(m, { Name = "WallSide", Size = Vector3.new(1, H, D), Position = c + Vector3.new(sx * (W / 2 - 0.5), H / 2 + 1, 0), Color = wall, Material = M.Plaster })
		-- the front wall: two pieces either side of a 6-stud door gap, facing the lane (north)
		P(m, { Name = "WallFront", Size = Vector3.new((W - 6) / 2, H, 1), Position = c + Vector3.new(sx * (W / 2 - (W - 6) / 4), H / 2 + 1, -D / 2 + 0.5),
			Color = wall, Material = M.Plaster })
		P(m, { Name = "Roof", Size = Vector3.new(W + 3, 0.8, D / 2 + 3), CFrame = CFrame.new(c + Vector3.new(0, H + 3.4, sx * (D / 4 + 0.6)))
			* CFrame.Angles(sx * math.rad(28), 0, 0), Color = tile, Material = M.Slate })
	end
	P(m, { Name = "Lintel", Size = Vector3.new(6, 2, 1), Position = c + Vector3.new(0, H, -D / 2 + 0.5), Color = wall, Material = M.Plaster })
	-- the Blender house over the graybox (owner 2026-11-04: "the map building are horrendous"): the graybox walls stay as
	-- invisible collision, the window keeps its lantern light
	local variant = if loc == "SenHouse" then "HouseSen" elseif loc == "CommunalHouse" then "HouseDinh"
		elseif loc == "FishHouse" or x == 25 or x == 190 then "HouseThatch" else "HouseTile"
	Art.place(variant, CFrame.new(c), m, 1, function(mm)
		local hide = { Gable = true, Ridge = true, PorchRoof = true, Post = true, Shutter = true, Plinth = true, WallBack = true,
			WallSide = true, WallFront = true, Roof = true, Lintel = true }
		for _, d in m:GetChildren() do
			if d:IsA("BasePart") and hide[d.Name] then
				d.Transparency = 1
				d:SetAttribute("Hidden", true)
			end
		end
		for _, d in mm:GetChildren() do
			if d:IsA("BasePart") then
				if d.Name == "Wall" then
					d.Color = wall
				elseif d.Name == "Roof" then
					d.Color = tile
				end
			end
		end
	end)
	-- the window beside the door: dark until a lantern reaches this house (M3); Sen's never lights
	local win = P(m, { Name = "Window", Size = Vector3.new(3.4, 2.6, 0.4), Position = c + Vector3.new(-6.5, 6, -D / 2 - 0.1), Color = rgb(30, 34, 40), Material = M.Glass })
	if loc then
		tag(win, Tags.HouseWindow, { House = loc })
	end
	-- the family altar against the back wall
	local altar = P(m, { Name = "Altar", Size = Vector3.new(6, 3, 2.4), Position = c + Vector3.new(0, 2.5, D / 2 - 2), Color = rgb(110, 40, 32), Material = M.Wood })
	if loc == "SenHouse" then
		tag(altar, Tags.SenAltar)
	end
	-- a lamp burning low inside (interiors were black; release council 11-03); Sen's house is cold and dim
	local lamp = P(m, { Name = "RoomLamp", Size = Vector3.new(0.6, 0.6, 0.6), Position = c + Vector3.new(0, H - 0.5, 2), Transparency = 1, CanCollide = false,
		CanQuery = false, CastShadow = false })
	local rl = Instance.new("PointLight")
	rl.Color = if loc == "SenHouse" then rgb(150, 170, 190) else rgb(238, 220, 190)
	rl.Range, rl.Brightness, rl.Shadows = 22, if loc == "SenHouse" then 0.35 else 0.5, true
	rl.Parent = lamp
	-- the rooms lived in (I-10: "barely any detail"): a platform bed, a cabinet, a mat by the door, a lantern stand, a
	-- bonsai, along the walls clear of the altar, the clue table (right) and the memento stool (left). Sen's stays bare.
	if loc ~= "SenHouse" then
		local f = CFrame.new(c.X, 1, 0)
		furniture(m, "Bed", f * CFrame.new(-8.6, 0, 35) * CFrame.Angles(0, math.rad(-90), 0))
		furniture(m, "Cabinet", f * CFrame.new(8.6, 0, 37.6))
		furniture(m, "Rug", f * CFrame.new(0, 0, 25))
		furniture(m, "Lantern", f * CFrame.new(9, 0, 23.2) * CFrame.Angles(0, math.rad(180), 0))
		furniture(m, "Bonsai", f * CFrame.new(-9, 0, 22.8))
	end
	-- a lost child's house has a lantern stop on the shore below it (brief §5.4)
	if child then
		local sx = if math.abs(x - DOCK_X) < 6 then x + 8 else x -- the fish seller's lantern stops beside the dock, not under it
		local stop = P(parent, { Name = "LanternStop_" .. (loc :: string), Size = Vector3.new(2, 1, 2), Position = Vector3.new(sx, WATER_Y + 0.5, SHORE_Z - 5),
			Transparency = 1, CanCollide = false, CanQuery = false })
		tag(stop, Tags.LanternStop, { House = loc, Child = child })
	end
	-- a door marker for navigation and teleports: just outside the door, on the lane side
	local door = P(m, { Name = "Door", Size = Vector3.new(4, 1, 1), Position = c + Vector3.new(0, 0.5, -D / 2 - 3), Transparency = 1, CanCollide = false, CanQuery = false })
	m.PrimaryPart = door
	return m
end

local function shrine(parent: Instance): Model
	local m = model(parent, "Shrine", "Shrine")
	local c = Vector3.new(-330, 0, -64)
	local stone = rgb(150, 146, 136)
	P(m, { Name = "Platform", Size = Vector3.new(34, 2, 26), Position = c + Vector3.new(0, 0, 0), Color = stone, Material = M.Slate })
	for _, s in { { -1, -1 }, { 1, -1 }, { -1, 1 }, { 1, 1 } } do
		P(m, { Name = "Post", Size = Vector3.new(1.2, 11, 1.2), Position = c + Vector3.new(s[1] * 9, 6.5, s[2] * 7), Color = rgb(104, 34, 28), Material = M.Wood }) -- (old lacquer, not orange plastic)
	end
	P(m, { Name = "Roof", Size = Vector3.new(24, 1, 20), Position = c + Vector3.new(0, 12.5, 0), Color = rgb(60, 70, 64), Material = M.Slate })
	-- the altar stands on the lake side facing the lane; Bà Thu sits in front of it, facing visitors
	local altar = P(m, { Name = "Altar", Size = Vector3.new(8, 3.5, 3), Position = c + Vector3.new(0, 2.75, -8), Color = rgb(88, 30, 26), Material = M.Wood })
	tag(altar, Tags.ShrineAltar)
	-- the Blender shrine and altar (the graybox stays as the floor, the collisions and the altar's prompt)
	Art.place("Shrine", CFrame.new(c), m, 1, function()
		for _, d in m:GetChildren() do
			if d:IsA("BasePart") and (d.Name == "Platform" or d.Name == "Post" or d.Name == "Roof") then
				d.Transparency = 1
			end
		end
	end)
	Art.place("Altar", CFrame.new(c + Vector3.new(0, 1, -8)) * CFrame.Angles(0, math.pi, 0), m, 1, function()
		altar.Transparency = 1
	end)
	local photos = P(m, { Name = "Photos", Size = Vector3.new(6, 2, 0.3), Position = c + Vector3.new(0, 5.6, -9.2), Color = rgb(60, 52, 44) })
	tag(photos, Tags.Clue, { ClueId = "shrine_photos" })
	-- the tea she pours for visitors: the same cups as the dusty ones in Sen's house (§6)
	for k = 0, 1 do
		P(m, { Name = "Teacup", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.5, 0.6, 0.6), CFrame = CFrame.new(c + Vector3.new(-1.5 + k * 0.9, 1.45, 1.6))
			* CFrame.Angles(0, 0, math.rad(90)), Color = rgb(200, 196, 180), Material = M.Marble, CanCollide = false })
	end
	-- the red paper (test clue for M2)
	local paper = P(m, { Name = "RedPaper", Size = Vector3.new(2.2, 3, 0.15), Position = c + Vector3.new(5.6, 4.5, -9.3), Color = rgb(190, 30, 30), Material = M.Fabric })
	tag(paper, Tags.Clue, { ClueId = "shrine_redpaper" })
	-- the mat where Bà Thu sits folding lanterns; lanterns all round: the only light on Night 1
	P(m, { Name = "Mat", Size = Vector3.new(6, 0.2, 4), Position = c + Vector3.new(-4, 1.1, 0), Color = rgb(170, 150, 90), Material = M.Fabric })
	for k = 0, 9 do
		local a = k / 10 * math.pi * 2
		lantern(m, c + Vector3.new(math.cos(a) * 12, 1.8, math.sin(a) * 9))
	end
	-- Bà Thu (graybox): seen by eyes and the live viewfinder, never on playback (brief §5.2)
	local thu = model(m, "BaThu")
	local body = P(thu, { Name = "Body", Size = Vector3.new(2.2, 2.4, 1.6), Position = c + Vector3.new(-4, 2.4, 0), Color = rgb(60, 70, 90), Material = M.Fabric })
	P(thu, { Name = "Head", Shape = Enum.PartType.Ball, Size = Vector3.new(1.3, 1.3, 1.3), Position = c + Vector3.new(-4, 4.2, 0), Color = rgb(220, 196, 170) })
	thu.PrimaryPart = body
	-- her Blender model, standing on the mat facing the lane (the graybox stays as her prompt and the body that walks)
	Art.place("BaThu", CFrame.new(c + Vector3.new(-4, 1.2, 0)) * CFrame.Angles(0, math.pi, 0), thu, 1, function(mm)
		for _, d in thu:GetChildren() do
			if d:IsA("BasePart") and (d.Name == "Body" or d.Name == "Head") then
				d.Transparency = 1
				d:SetAttribute("Hidden", true)
			end
		end
		for _, d in mm:GetChildren() do
			d.Parent = thu
		end
		mm:Destroy()
	end)
	tag(thu, Tags.NpcBaThu)
	tag(thu, Tags.HiddenOnCamera)
	-- safe zone + camcorder recharge
	tag(zone(m, "ShrineZone", CFrame.new(c + Vector3.new(0, 6, 0)), Vector3.new(36, 14, 28)), Tags.ShrineZone)
	-- (inside the ShrineZone, on the platform's lane side: "goto Shrine" and arriving both count as being there)
	local door = P(m, { Name = "Door", Size = Vector3.new(4, 1, 1), Position = c + Vector3.new(0, 1.5, 9), Transparency = 1, CanCollide = false, CanQuery = false })
	m.PrimaryPart = door
	return m
end

local function dock(parent: Instance)
	local m = model(parent, "Dock", "Dock")
	for k = 0, 6 do
		P(m, { Name = "Plank", Size = Vector3.new(6, 0.5, 4.6), Position = Vector3.new(DOCK_X, 0.6, SHORE_Z + 2 - k * 5), Color = rgb(116, 86, 58), Material = M.WoodPlanks })
	end
	for _, sx in { -1, 1 } do
		for k = 0, 2 do
			P(m, { Name = "Pile", Size = Vector3.new(0.8, 8, 0.8), Position = Vector3.new(-140 + sx * 3.2, -2.5, SHORE_Z - 4 - k * 12), Color = rgb(90, 66, 44), Material = M.Wood })
		end
	end
	m.PrimaryPart = P(m, { Name = "Door", Size = Vector3.new(4, 1, 1), Position = Vector3.new(-140, 1, SHORE_Z + 4), Transparency = 1, CanCollide = false, CanQuery = false })
end

local function reeds(parent: Instance, from: Vector3, n: number)
	local rng = Random.new(math.floor(from.X * 7 + from.Z))
	local made: { Instance } = {}
	-- the Blender clumps replace the sticks once they're there
	local clumps = {}
	for _ = 1, math.max(2, math.floor(n / 4)) do
		table.insert(clumps, { at = from + Vector3.new(rng:NextNumber(-13, 13), WATER_Y - 0.6, rng:NextNumber(-5, 5)), a = rng:NextNumber(0, math.pi * 2),
			s = rng:NextNumber(0.85, 1.25) })
	end
	task.spawn(function()
		if not Art.wait(60) then
			return
		end
		for _, r in made do
			r:Destroy()
		end
		for _, c in clumps do
			local m = Art.clone("Reeds", CFrame.new(c.at) * CFrame.Angles(0, c.a, 0), c.s, parent)
			if m then
				m.Name = "Reed"
			end
		end
	end)
	for _ = 1, n do
		local p = from + Vector3.new(rng:NextNumber(-14, 14), 0, rng:NextNumber(-6, 6))
		local h = rng:NextNumber(3, 6)
		table.insert(made, P(parent, { Name = "Reed", Size = Vector3.new(0.25, h, 0.25), CFrame = CFrame.new(p + Vector3.new(0, WATER_Y + h / 2 - 0.5, 0))
			* CFrame.Angles(rng:NextNumber(-0.15, 0.15), 0, rng:NextNumber(-0.15, 0.15)), Color = rgb(96, 120, 70), CanCollide = false }))
	end
end

local function causeway(parent: Instance): BasePart
	local m = model(parent, "Causeway", "Causeway")
	local a, b = Vector3.new(-300, 0.6, 46), Vector3.new(-490, 0.6, 236)
	local n = 12
	for k = 0, n - 1 do
		local p = a:Lerp(b, (k + 0.5) / n)
		local seg = P(m, { Name = "Causeway", Size = Vector3.new(8, 1.2, (b - a).Magnitude / n + 0.3), CFrame = CFrame.lookAt(p, p + (b - a)), Color = rgb(130, 110, 84), Material = M.Ground })
		Art.place("Causeway", seg.CFrame * CFrame.new(0, -0.6, 0), m, Vector3.new(1, 1, seg.Size.Z / 16), function(mm)
			seg.Transparency = 1 -- (it stays as the floor you walk on)
			mm.Name = "CausewayStones"
		end)
	end
	m.PrimaryPart = P(m, { Name = "Door", Size = Vector3.new(4, 1, 1), Position = a + Vector3.new(-10, 0.4, 10), Transparency = 1, CanCollide = false, CanQuery = false })
	-- players arrive at the village end of the causeway
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "Spawn"
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Size = Vector3.new(6, 1, 6)
	spawn.Position = Vector3.new(-288, 0.5, 30) -- on the land just inside the village end
	spawn.Transparency = 1
	spawn.CanCollide = false
	spawn.Parent = m
	return spawn
end

local function cove(parent: Instance)
	-- Sen's back yard: through the bamboo, round the ridge, to the cove and the carp steps
	local yard = model(parent, "BackYard")
	local rng = Random.new(8)
	for _ = 1, 40 do
		local p = Vector3.new(rng:NextNumber(262, 330), 0, rng:NextNumber(52, 92))
		if math.abs(p.Z - 70) > 5 or p.X < 268 then -- leave the path clear
			local h = rng:NextNumber(14, 22)
			P(yard, { Name = "Bamboo", Size = Vector3.new(0.7, h, 0.7), Position = p + Vector3.new(0, h / 2, 0), Color = rgb(110, 150, 70), Material = M.Wood })
		end
	end
	local steps = model(parent, "CarpSteps", "CarpSteps")
	for k = 0, 6 do -- stone steps from the yard down into the cove's water
		P(steps, { Name = "Step", Size = Vector3.new(7, 1, 4), Position = Vector3.new(350, 0.5 - k * 1.3, 8 - k * 4), Color = rgb(140, 136, 126), Material = M.Slate })
	end
	-- a stone landing at the top, level with the grass (y ~ 2), and two weathered posts either side of it
	P(steps, { Name = "Landing", Size = Vector3.new(9, 2, 4), Position = Vector3.new(350, 1, 12), Color = rgb(128, 124, 114), Material = M.Slate })
	for _, sx in { -1, 1 } do
		P(steps, { Name = "StonePost", Size = Vector3.new(1.2, 4, 1.2), Position = Vector3.new(350 + sx * 5.2, 3, 12.5), Color = rgb(112, 110, 100), Material = M.Slate })
		P(steps, { Name = "StoneCap", Size = Vector3.new(1.6, 0.5, 1.6), Position = Vector3.new(350 + sx * 5.2, 5.25, 12.5), Color = rgb(98, 96, 88), Material = M.Slate })
	end
	steps.PrimaryPart = P(steps, { Name = "Door", Size = Vector3.new(4, 1, 1), Position = Vector3.new(350, 1, 14), Transparency = 1, CanCollide = false, CanQuery = false })
	-- the trodden path through the bamboo, on the grass (its surface is at y ~ 2)
	P(parent, { Name = "CovePath", Size = Vector3.new(6, 0.2, 56), CFrame = CFrame.new(Vector3.new(345, 2.05, 44)), Color = rgb(120, 100, 76), Material = M.Ground, CanCollide = false, CanQuery = false })
end

-- Night 1 lantern paths (§4 beat 3, §5.4): from the water in front of the shrine, out onto the lake, along it and in
-- to each lost child's LanternStop. Invisible waypoints tagged LanternPath (attributes House, Index), in order.
local function lanternPaths(parent: Instance)
	local m = model(parent, "LanternPaths")
	for _, stop in CollectionService:GetTagged(Tags.LanternStop) do
		local house = stop:GetAttribute("House")
		local x = (stop :: BasePart).Position.X
		local points = {
			Vector3.new(-330, WATER_Y + 0.6, SHORE_Z - 34),
			Vector3.new(-300, WATER_Y + 0.6, SHORE_Z - 44 - (x + 200) * 0.02),
			Vector3.new(x, WATER_Y + 0.6, SHORE_Z - 44),
			Vector3.new(x, WATER_Y + 0.6, SHORE_Z - 14),
		}
		for i, p in points do
			tag(P(m, { Name = `Path_{house}_{i}`, Size = Vector3.new(1, 1, 1), Position = p, Transparency = 1, CanCollide = false, CanQuery = false }),
				Tags.LanternPath, { House = house, Index = i })
		end
	end
end

-- what each house holds (brief §6): clues (tag Clue, ClueId), the lost child's memento (tag Memento, MementoId),
-- and in Sen's house the things that only mean something once you know the story. Positions are inside the house
-- built by house(): floor top y = 1, the door on the lane side (z = 21), the altar against the back wall.
local function item(parent: Instance, name: string, size: Vector3, pos: Vector3, color: Color3, props: { [string]: any }?): BasePart
	local t: { [string]: any } = { Name = name, Size = size, Position = pos, Color = color, CanCollide = false }
	for k, v in props or {} do
		t[k] = v
	end
	return P(parent, t)
end

local function table_(parent: Instance, x: number): Vector3
	-- a low table on the right as you come in; returns the middle of its top
	item(parent, "Table", Vector3.new(5, 0.4, 3), Vector3.new(x + 6, 2.6, 31), rgb(110, 80, 52), { Material = M.Wood, CanCollide = true })
	for _, s in { { -1, -1 }, { 1, -1 }, { -1, 1 }, { 1, 1 } } do
		item(parent, "Leg", Vector3.new(0.3, 1.6, 0.3), Vector3.new(x + 6 + s[1] * 2.2, 1.8, 31 + s[2] * 1.2), rgb(90, 64, 42), { Material = M.Wood })
	end
	return Vector3.new(x + 6, 2.8, 31)
end

local function stool(parent: Instance, x: number): Vector3
	-- a stool on the left by the window: where the child's memento sits
	item(parent, "Stool", Vector3.new(2, 1.4, 2), Vector3.new(x - 6, 1.7, 26), rgb(120, 88, 58), { Material = M.Wood, CanCollide = true })
	return Vector3.new(x - 6, 2.4, 26)
end

local function memento(m: Model, id: string)
	tag(m, Tags.Memento, { MementoId = id })
end

local function furnish(village: Instance)
	local byLoc: { [string]: Instance } = {}
	for _, h in village:GetChildren() do
		local loc = h:GetAttribute("Location")
		if loc then
			byLoc[loc :: string] = h
		end
	end
	local function x(loc: string): number
		for _, h in HOUSES do
			if h.loc == loc then
				return h.x
			end
		end
		error(loc)
	end
	local paper, ink = rgb(226, 214, 186), rgb(40, 40, 60)

	-- the teacher's house (Minh): the unsent report, Minh's exercise book; the class photo is on the back wall
	do
		local h, hx = byLoc.TeacherHouse, x("TeacherHouse")
		local top = table_(h, hx)
		tag(item(h, "Report", Vector3.new(1.4, 0.06, 1.9), top + Vector3.new(-1.2, 0.03, 0), paper), Tags.Clue, { ClueId = "teacher_report" })
		tag(item(h, "Notebook", Vector3.new(1.2, 0.18, 1.6), top + Vector3.new(1.2, 0.09, 0.1), rgb(50, 80, 130)), Tags.Clue, { ClueId = "minh_notebook" })
		local s = stool(h, hx)
		local m = model(h, "Memento_ReportCard")
		item(m, "Card", Vector3.new(1.1, 0.06, 1.5), s + Vector3.new(0, 0.03, 0), paper)
		item(m, "RedMark", Vector3.new(0.3, 0.07, 0.12), s + Vector3.new(0.2, 0.05, -0.2), rgb(200, 30, 30))
		memento(m, "minh")
	end
	-- the puppet master's house (Hạnh): the diary; a broken water puppet
	do
		local h, hx = byLoc.PuppetHouse, x("PuppetHouse")
		local top = table_(h, hx)
		tag(item(h, "Diary", Vector3.new(1.3, 0.3, 1.8), top + Vector3.new(0, 0.15, 0), rgb(96, 60, 36)), Tags.Clue, { ClueId = "puppet_diary" })
		local s = stool(h, hx)
		local m = model(h, "Memento_Puppet")
		item(m, "Body", Vector3.new(0.7, 1, 0.5), s + Vector3.new(0, 0.5, 0), rgb(200, 60, 40))
		item(m, "Head", Vector3.new(0.6, 0.6, 0.6), s + Vector3.new(0, 1.3, 0), rgb(230, 200, 150), { Shape = Enum.PartType.Ball })
		item(m, "BrokenArm", Vector3.new(0.2, 0.8, 0.2), s + Vector3.new(0.6, 0.12, 0.3), rgb(200, 60, 40), { CFrame = CFrame.new(s + Vector3.new(0.6, 0.12, 0.3)) * CFrame.Angles(0, 0, math.rad(90)) })
		memento(m, "hanh")
	end
	-- the fish seller's house (Tí): the ledger with her notes; a clay whistle
	do
		local h, hx = byLoc.FishHouse, x("FishHouse")
		local top = table_(h, hx)
		tag(item(h, "Ledger", Vector3.new(1.6, 0.25, 2), top + Vector3.new(0, 0.13, 0), rgb(60, 90, 70)), Tags.Clue, { ClueId = "fish_notes" })
		local s = stool(h, hx)
		local m = model(h, "Memento_Whistle")
		item(m, "Whistle", Vector3.new(0.5, 0.5, 0.5), s + Vector3.new(0, 0.25, 0), rgb(180, 100, 60), { Shape = Enum.PartType.Ball, Material = M.Slate })
		memento(m, "ti")
	end
	-- the village head's house (Khoa): the minutes, the spoiled red paper; a festival drumstick
	do
		local h, hx = byLoc.HeadHouse, x("HeadHouse")
		local top = table_(h, hx)
		tag(item(h, "Minutes", Vector3.new(1.4, 0.2, 1.9), top + Vector3.new(-1.2, 0.1, 0), paper), Tags.Clue, { ClueId = "head_minutes" })
		tag(item(h, "RedPaperDraft", Vector3.new(1.4, 0.05, 1.9), top + Vector3.new(1.2, 0.03, 0.2), rgb(180, 30, 30), { Material = M.Fabric }), Tags.Clue,
			{ ClueId = "head_redpaper_draft" })
		local s = stool(h, hx)
		local m = model(h, "Memento_Drumstick")
		item(m, "Stick", Vector3.new(1.6, 0.22, 0.22), s + Vector3.new(0, 0.12, 0), rgb(140, 96, 60), { Shape = Enum.PartType.Cylinder, Material = M.Wood })
		memento(m, "khoa")
	end
	-- Sen's house: no marks on the doorframe; one bowl, freshly washed; the chair facing the door with the dusty
	-- cups; the half-finished paper fish on the shelf. The letter is under the altar (tagged SenAltar in house())
	do
		local h, hx = byLoc.SenHouse, x("SenHouse")
		tag(item(h, "Doorframe", Vector3.new(0.5, 8, 0.7), Vector3.new(hx + 3.2, 5, HOUSE_Z - 8.6), rgb(170, 140, 100), { Material = M.Wood }), Tags.Clue,
			{ ClueId = "sen_doorframe" })
		item(h, "LowTable", Vector3.new(3, 0.3, 2), Vector3.new(hx + 5, 1.8, 30), rgb(110, 80, 52), { Material = M.Wood, CanCollide = true })
		tag(item(h, "Bowl", Vector3.new(0.4, 0.8, 0.8), Vector3.new(hx + 5, 2.15, 30), rgb(220, 220, 210), { Shape = Enum.PartType.Cylinder, Material = M.Marble,
			CFrame = CFrame.new(hx + 5, 2.15, 30) * CFrame.Angles(0, 0, math.rad(90)) }), Tags.Clue, { ClueId = "sen_bowl" })
		item(h, "Chopsticks", Vector3.new(0.08, 0.08, 1.2), Vector3.new(hx + 5.7, 2.0, 30), rgb(150, 110, 70))
		local chair = model(h, "Chair")
		item(chair, "Seat", Vector3.new(2.2, 0.3, 2.2), Vector3.new(hx - 5, 2.5, 34), rgb(96, 70, 46), { Material = M.Wood, CanCollide = true })
		item(chair, "Back", Vector3.new(2.2, 2.6, 0.3), Vector3.new(hx - 5, 3.9, 35.1), rgb(96, 70, 46), { Material = M.Wood })
		for k = 0, 1 do
			item(chair, "DustyCup", Vector3.new(0.5, 0.6, 0.6), Vector3.new(hx - 2.8 + k * 0.8, 2.0, 34),
				rgb(140, 138, 130), { Shape = Enum.PartType.Cylinder, Material = M.Marble, CFrame = CFrame.new(hx - 2.8 + k * 0.8, 2.0, 34) * CFrame.Angles(0, 0, math.rad(90)) })
		end
		item(chair, "Stand", Vector3.new(1.6, 0.9, 1.4), Vector3.new(hx - 2.4, 1.45, 34), rgb(90, 66, 44), { Material = M.Wood, CanCollide = true })
		tag(chair, Tags.Clue, { ClueId = "sen_chair" })
		item(h, "Shelf", Vector3.new(1, 0.3, 4), Vector3.new(hx - 10, 5, 27), rgb(110, 80, 52), { Material = M.Wood })
		tag(item(h, "PaperFish", Vector3.new(0.6, 0.7, 1.4), Vector3.new(hx - 10, 5.5, 27), rgb(230, 150, 70), { Material = M.Fabric }), Tags.Clue,
			{ ClueId = "sen_fishlantern" })
	end
end

-- little sandals lined up on the carp steps, one pair for every lost child (§6)
local function sandals(parent: Instance)
	local m = model(parent, "Sandals")
	for k = 0, 3 do
		for s = 0, 1 do
			P(m, { Name = "Sandal", Size = Vector3.new(0.45, 0.12, 0.9), Position = Vector3.new(347.2 + k * 1.9 + s * 0.55, 1.06, 9), Color = rgb(60, 110, 150),
				CanCollide = false })
		end
	end
	tag(m, Tags.Clue, { ClueId = "steps_sandals" })
end

-- set dressing from parts (brief §8 setting: banana trees, water jars, lotus): no collisions except the jars, nothing
-- on a path. The real art pass (Creator Store models, M7) happens in the shared place: see docs/FACTORY.md.
local function dressing(parent: Instance)
	local m = model(parent, "Dressing")
	local rng = Random.new(15)
	local function banana(at: Vector3)
		-- a tapered trunk, leaves that rise and then droop, one dry brown leaf, and a hanging flower stalk
		local h = rng:NextNumber(6, 9)
		P(m, { Name = "BananaTrunk", Shape = Enum.PartType.Cylinder, Size = Vector3.new(h * 0.55, 1.2, 1.2),
			CFrame = CFrame.new(at + Vector3.new(0, h * 0.275, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = rgb(112, 108, 72), Material = M.Wood, CanCollide = false })
		P(m, { Name = "BananaTrunk", Shape = Enum.PartType.Cylinder, Size = Vector3.new(h * 0.5, 0.85, 0.85),
			CFrame = CFrame.new(at + Vector3.new(0, h * 0.75, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = rgb(124, 122, 78), Material = M.Wood, CanCollide = false })
		local n = rng:NextInteger(6, 8)
		for k = 1, n do
			local a = k / n * math.pi * 2 + rng:NextNumber(-0.3, 0.3)
			local dry = k == 1
			local col = if dry then rgb(122, 98, 58) else rgb(58 + rng:NextInteger(0, 18), 112 + rng:NextInteger(0, 22), 48)
			local up = math.rad(rng:NextNumber(30, 45))
			local base = CFrame.new(at + Vector3.new(0, h, 0)) * CFrame.Angles(0, a, 0)
			local inner = base * CFrame.Angles(up, 0, 0) * CFrame.new(0, 0, -1.6)
			P(m, { Name = "BananaLeaf", Size = Vector3.new(1.9, 0.1, 3.2), CFrame = inner, Color = col, Material = M.Grass, CanCollide = false, CanQuery = false })
			local tip = inner * CFrame.new(0, 0, -1.6) * CFrame.Angles(math.rad(if dry then -110 else -55), 0, 0) * CFrame.new(0, 0, -1.4)
			P(m, { Name = "BananaLeaf", Size = Vector3.new(1.6, 0.1, 2.8), CFrame = tip, Color = col, Material = M.Grass, CanCollide = false, CanQuery = false })
		end
		if rng:NextNumber() < 0.4 then
			P(m, { Name = "BananaFlower", Shape = Enum.PartType.Ball, Size = Vector3.new(0.7, 1.1, 0.7), Position = at + Vector3.new(0.9, h - 1.4, 0.4),
				Color = rgb(110, 40, 60), CanCollide = false, CanQuery = false })
		end
	end
	local function jar(at: Vector3)
		P(m, { Name = "WaterJar", Shape = Enum.PartType.Cylinder, Size = Vector3.new(2.2, 2.4, 2.4),
			CFrame = CFrame.new(at + Vector3.new(0, 1.1, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = rgb(110, 70, 50), Material = M.Slate })
		P(m, { Name = "JarWater", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.1, 2, 2),
			CFrame = CFrame.new(at + Vector3.new(0, 2.15, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = rgb(30, 45, 50), Material = M.Glass, CanCollide = false })
	end
	for _, hs in HOUSES do
		jar(Vector3.new(hs.x - 9.5, 2, HOUSE_Z - 11.5)) -- under the porch roof, on the ground (y ~ 2)
		banana(Vector3.new(hs.x + rng:NextNumber(-8, 8), 0, HOUSE_Z + rng:NextNumber(13, 20)))
	end
	-- the Blender props (in the background; each sits on whatever ground is under it)
	local function ground(x: number, z: number): number
		local hit = workspace:Raycast(Vector3.new(x, 40, z), Vector3.new(0, -80, 0))
		return if hit then hit.Position.Y else 0
	end
	task.spawn(function()
		if not Art.wait(60) then
			return
		end
		Art.clone("Boat", CFrame.new(DOCK_X + 7, WATER_Y + 0.15, SHORE_Z - 14) * CFrame.Angles(0, 0.25, 0), 1, m)
		for _, hs in HOUSES do
			if hs.loc and hs.loc ~= "SenHouse" then
				for _, sx in { -1, 1 } do
					Art.clone("Fence", CFrame.new(hs.x + sx * 14, ground(hs.x + sx * 14, 6), 6) * CFrame.Angles(0, math.pi / 2, 0), 1, m)
				end
			end
			if hs.loc == "FishHouse" or hs.loc == "HeadHouse" then
				Art.clone("FishRack", CFrame.new(hs.x + 9, ground(hs.x + 9, 4), 4), 1, m)
			end
		end
		Art.clone("Well", CFrame.new(-222, ground(-222, 4), 4), 1, m)
	end)
	for k = 1, 8 do -- along the lane's lake side, between the houses' yards and the shore
		banana(Vector3.new(-280 + k * 70 + rng:NextNumber(-10, 10), 0, SHORE_Z + rng:NextNumber(10, 16)))
	end
	-- lotus pads and a few flowers in the shallows, away from the dock and the lantern paths' last stretch
	for _ = 1, 70 do
		local x, z = rng:NextNumber(-320, 320), rng:NextNumber(SHORE_Z - 34, SHORE_Z - 4)
		local nearStop = false
		for _, hs in HOUSES do
			if hs.child and math.abs(x - hs.x) < 6 then
				nearStop = true
			end
		end
		if math.abs(x - DOCK_X) > 8 and not nearStop then
			local d = rng:NextNumber(1.6, 3)
			P(m, { Name = "LotusPad", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.1, d, d),
				CFrame = CFrame.new(x, WATER_Y + 0.08, z) * CFrame.Angles(0, 0, math.rad(90)), Color = rgb(56, 96, 52), Material = M.Grass, CanCollide = false, CanQuery = false })
			if rng:NextNumber() < 0.18 then
				P(m, { Name = "Lotus", Shape = Enum.PartType.Ball, Size = Vector3.new(0.7, 0.6, 0.7), Position = Vector3.new(x, WATER_Y + 0.4, z),
					Color = rgb(230, 150, 170), CanCollide = false, CanQuery = false })
			end
		end
	end
end

local function farShore(parent: Instance)
	-- visible, not reachable: the puppet stage on the water and the festival lights
	local m = model(parent, "FarShore")
	P(m, { Name = "PuppetStage", Size = Vector3.new(30, 2, 16), Position = Vector3.new(40, WATER_Y + 1, -440), Color = rgb(120, 40, 34), Material = M.Wood })
	P(m, { Name = "StageRoof", Size = Vector3.new(32, 1, 18), Position = Vector3.new(40, WATER_Y + 12, -440), Color = rgb(60, 50, 40), Material = M.Slate })
	for k = -6, 6 do
		lantern(m, Vector3.new(k * 40, 4, -500))
	end
end

local function drownedFestival(parent: Instance)
	-- where taken players wake (§5.6): dim, rows of children watching a puppet show that never ends
	local m = model(parent, "DrownedFestival", "DrownedFestival")
	local y = Config.DrownedFestivalY
	P(m, { Name = "Floor", Size = Vector3.new(120, 2, 120), Position = Vector3.new(0, y, 0), Color = rgb(30, 40, 46), Material = M.Mud })
	P(m, { Name = "Stage", Size = Vector3.new(24, 3, 10), Position = Vector3.new(0, y + 2.5, -30), Color = rgb(80, 30, 28), Material = M.Wood })
	for i, name in { "Minh", "Hạnh", "Tí", "Khoa", "Bin" } do
		local s = model(m, "Silhouette_" .. name)
		local p = Vector3.new(-16 + i * 6, y + 1, -12)
		local body = P(s, { Name = "Body", Size = Vector3.new(1.6, 3, 1), Position = p + Vector3.new(0, 1.5, 0), Color = rgb(10, 12, 16) })
		local head = P(s, { Name = "Head", Shape = Enum.PartType.Ball, Size = Vector3.new(1.2, 1.2, 1.2), Position = p + Vector3.new(0, 3.6, 0), Color = rgb(10, 12, 16) })
		Art.place("Child", CFrame.new(p) * CFrame.Angles(0, math.pi, 0), s, 4.2 / 2.8, function(c)
			body.Transparency, head.Transparency = 1, 1
			for _, d in c:GetChildren() do
				if d:IsA("BasePart") then
					d.Color, d.Material = rgb(10, 12, 16), M.SmoothPlastic
				end
			end
		end)
	end
	for k = -2, 2 do
		lantern(m, Vector3.new(k * 10, y + 7, -36))
	end
	-- a dim, cold light over the rows, as if from far above through the water
	local glow = P(m, { Name = "WaterLight", Size = Vector3.new(1, 1, 1), Position = Vector3.new(0, y + 18, -16), Transparency = 1, CanCollide = false, CanQuery = false })
	local l = Instance.new("PointLight")
	l.Color = rgb(110, 160, 190)
	l.Range = 60
	l.Brightness = 2.4
	l.Parent = glow
	local stageLamp = P(m, { Name = "StageLight", Size = Vector3.new(1, 1, 1), Position = Vector3.new(0, y + 10, -24), Transparency = 1,
		CanCollide = false, CanQuery = false })
	local sl = Instance.new("SpotLight")
	sl.Face, sl.Angle, sl.Range, sl.Brightness, sl.Color = Enum.NormalId.Bottom, 70, 26, 3, rgb(255, 200, 140)
	sl.Parent = stageLamp
	m.PrimaryPart = P(m, { Name = "Door", Size = Vector3.new(4, 1, 1), Position = Vector3.new(0, y + 1.5, 10), Transparency = 1, CanCollide = false, CanQuery = false })
end

local function edgesAndBounds(parent: Instance)
	local m = model(parent, "Zones")
	-- where Sen's distance checks measure "near water" (§5.5): the shore, the dock end, the cove, the marsh
	for x = -320, 330, 30 do
		tag(zone(m, "WaterEdge", CFrame.new(x, 0, SHORE_Z), Vector3.new(4, 4, 4)), Tags.WaterEdge)
	end
	tag(zone(m, "WaterEdge", CFrame.new(-140, 0, SHORE_Z - 30), Vector3.new(4, 4, 4)), Tags.WaterEdge)
	tag(zone(m, "WaterEdge", CFrame.new(350, 0, -10), Vector3.new(4, 4, 4)), Tags.WaterEdge)
	for k = 0, 4 do
		tag(zone(m, "WaterEdge", CFrame.new(-320 - k * 40, 0, 70 + k * 40), Vector3.new(4, 4, 4)), Tags.WaterEdge)
	end
	-- boundaries: any way out of the village brings players back to the lake shore (§4 beat 5)
	-- the land ones say so: "Wandering in the forest won't save you." (Catlyn 2026-11-02; the forest itself is I-14)
	local function wall(cf: CFrame, size: Vector3, land: boolean?)
		local z = zone(m, "Boundary", cf, size)
		tag(z, Tags.BoundaryTeleport)
		if land ~= false then
			z:SetAttribute("Message", Text.Messages.forestEdge)
		end
	end
	wall(CFrame.new(0, 0, -140), Vector3.new(1400, 80, 4), false) -- out in the lake
	wall(CFrame.new(410, 0, -20), Vector3.new(4, 80, 260)) -- east, past the cove
	wall(CFrame.new(70, 0, 115), Vector3.new(680, 80, 4)) -- south, behind the houses (x -270 .. 410)
	wall(CFrame.new(-370, 0, -50), Vector3.new(4, 80, 170)) -- west, behind the shrine (z -135 .. 35)
	wall(CFrame.new(-535, 0, 150), Vector3.new(4, 80, 260)) -- the marsh's west side
	wall(CFrame.new(-400, 0, 265), Vector3.new(280, 80, 4)) -- the marsh's south side / the causeway's far end
	wall(CFrame.new(-268, 0, 190), Vector3.new(4, 80, 150)) -- the marsh's east side (z 115 .. 265)
	wall(CFrame.new(-452, 0, 22), Vector3.new(170, 80, 4)) -- between the marsh and the shrine's west wall
	local back = P(m, { Name = "ShoreReturn", Size = Vector3.new(4, 1, 4), Position = Vector3.new(-296, 1, LANE_Z), Transparency = 1, CanCollide = false, CanQuery = false })
	tag(back, Tags.ShoreReturn)
end

local function testMarks(parent: Instance)
	-- M2 test object: Sen's small wet footprints on the lane near the dock, only visible through a camcorder
	local m = model(parent, "WetFootprints")
	for k = 0, 7 do
		P(m, { Name = "Footprint", Size = Vector3.new(0.5, 0.06, 0.9), CFrame = CFrame.new(-150 + k * 2.4, 0.05, LANE_Z - 6 + (k % 2) * 0.8)
			* CFrame.Angles(0, math.rad(90), 0), Color = rgb(30, 40, 50), CanCollide = false, CanQuery = false })
	end
	tag(m, Tags.CameraOnly)
end

local function lighting()
	local L = game:GetService("Lighting")
	-- (40/46/66 and 50/58/84 played pitch black on the dock: still night, but the shore, the paths and the water read)
	-- (round 2, 2026-11-04: still black frames outdoors on the causeway, the lane and the dock: more moonlight, a little
	-- exposure; still night)
	L.Ambient = rgb(74, 82, 108)
	L.OutdoorAmbient = rgb(112, 124, 158)
	L.Brightness = 1.6
	L.ExposureCompensation = 0.25
	L.EnvironmentDiffuseScale = 0.3
	L.EnvironmentSpecularScale = 0.3
	L.FogColor = rgb(26, 32, 46)
	L.FogStart = 40
	L.FogEnd = 420
	L.GlobalShadows = true
	local atm = L:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere")
	atm.Density = 0.3 -- (0.42 hid the karst towers' feet in haze: their tops hung in the sky)
	atm.Offset = 0
	atm.Color = rgb(120, 130, 156)
	atm.Decay = rgb(60, 70, 96)
	atm.Glare = 0
	atm.Haze = 2.2
	atm.Parent = L
end

return function()
	local old = Workspace:FindFirstChild("World")
	if old then
		old:Destroy()
	end
	local world = Instance.new("Folder")
	world.Name = "World"
	terrainPass()
	lighting()
	local village = Instance.new("Folder")
	village.Name = "Village"
	village.Parent = world
	for _, h in HOUSES do
		local m = house(village, h.x, h.loc, h.child)
		if h.loc == "TeacherHouse" then
			local photo = P(m, { Name = "ClassPhoto", Size = Vector3.new(3, 2.2, 0.15), Position = Vector3.new(h.x + 6, 6, HOUSE_Z + 7.9), Color = rgb(200, 190, 170) })
			tag(photo, Tags.Clue, { ClueId = "teacher_classphoto" })
		end
	end
	world.Parent = Workspace -- (the lantern paths read the LanternStops through CollectionService)
	lanternPaths(world)
	furnish(village)
	shrine(world)
	dock(world)
	reeds(world, Vector3.new(-280, 0, SHORE_Z - 8), 26)
	reeds(world, Vector3.new(60, 0, SHORE_Z - 6), 14)
	causeway(world)
	cove(world)
	sandals(world)
	dressing(world)
	farShore(world)
	drownedFestival(world)
	edgesAndBounds(world)
	testMarks(world)
	world.Parent = Workspace
	Workspace:SetAttribute("WorldBuilt", "LangVong")
end
