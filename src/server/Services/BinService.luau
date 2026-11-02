--!strict
-- Bin, the channel's camera friend (PROTOTYPE_BRIEF §4 beats 1, 2, 4; characters.md: bright jacket, headlamp, the
-- camcorder always in his hand). A graybox NPC the server walks with Humanoid:MoveTo:
--   Follow(): walks with the players (Arrival), keeping a few studs behind the nearest one
--   StandAt(pos, look): goes to a spot and faces something (filming Bà Thu at the shrine)
--   WanderOff(): walks east along the shore and vanishes once no player can see him, or after 20 s; a child cries
--   from the water where he was. Returns where he vanished.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Pace = require(Shared:WaitForChild("Pace"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Tags = require(Shared:WaitForChild("Tags"))

local BinService = {}

local rgb = Color3.fromRGB
local bin: Model? = nil
local mode = "none" -- none | follow | stand | wander
local job = 0 -- bumped whenever Bin gets a new order, so an old walking loop stops

-- along the shore, west to east, from the shrine (§4 beat 4: "walks east along the shore")
local WANDER = {
	Vector3.new(-318, 0, -46), Vector3.new(-290, 0, -46), Vector3.new(-250, 0, -46), Vector3.new(-210, 0, -46),
	Vector3.new(-170, 0, -46), Vector3.new(-120, 0, -46), Vector3.new(-80, 0, -46), Vector3.new(-40, 0, -46),
}

local function part(parent: Instance, props: { [string]: any }): BasePart
	local p = Instance.new("Part")
	p.CanCollide = false
	p.Massless = true
	p.Material = Enum.Material.SmoothPlastic
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	for k, v in props do
		(p :: any)[k] = v
	end
	p.Parent = parent
	return p
end

local function weld(a: BasePart, b: BasePart)
	local w = Instance.new("WeldConstraint")
	w.Part0, w.Part1 = a, b
	w.Parent = a
end

local function build(at: Vector3): Model
	local m = Instance.new("Model")
	m.Name = "Bin"
	local root = part(m, { Name = "HumanoidRootPart", Size = Vector3.new(2, 2, 1), Transparency = 1, CanCollide = true, Massless = false,
		CFrame = CFrame.new(at + Vector3.new(0, 3, 0)) })
	local function on(name: string, size: Vector3, offset: Vector3, color: Color3, extra: { [string]: any }?): BasePart
		local props: { [string]: any } = { Name = name, Size = size, CFrame = root.CFrame * CFrame.new(offset), Color = color }
		for k, v in extra or {} do
			props[k] = v
		end
		local p = part(m, props)
		weld(root, p)
		return p
	end
	on("Jacket", Vector3.new(2, 2, 1), Vector3.zero, rgb(255, 140, 30)) -- the most colourful of the group
	on("LegL", Vector3.new(0.9, 2, 0.9), Vector3.new(-0.5, -2, 0), rgb(40, 50, 70))
	on("LegR", Vector3.new(0.9, 2, 0.9), Vector3.new(0.5, -2, 0), rgb(40, 50, 70))
	on("ArmL", Vector3.new(0.8, 1.9, 0.8), Vector3.new(-1.4, 0, 0), rgb(255, 140, 30))
	on("ArmR", Vector3.new(0.8, 1.9, 0.8), Vector3.new(1.4, 0.2, -0.6), rgb(255, 140, 30))
	local head = on("Head", Vector3.new(1.2, 1.2, 1.2), Vector3.new(0, 1.6, 0), rgb(222, 184, 150), { Shape = Enum.PartType.Ball })
	local lamp = on("Headlamp", Vector3.new(0.5, 0.3, 0.2), Vector3.new(0, 1.85, -0.6), rgb(255, 255, 230), { Material = Enum.Material.Neon })
	local beam = Instance.new("SpotLight")
	beam.Face = Enum.NormalId.Front
	beam.Range = 26
	beam.Angle = 50
	beam.Brightness = 2
	beam.Parent = lamp
	on("Camcorder", Vector3.new(0.6, 0.6, 1.2), Vector3.new(1.4, 0.9, -1.2), rgb(30, 30, 34))
	local hum = Instance.new("Humanoid")
	hum.RigType = Enum.HumanoidRigType.R15
	hum.HipHeight = 2
	hum.WalkSpeed = Config.BinWalkSpeed
	hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	hum.Parent = m
	m.PrimaryPart = root
	CollectionService:AddTag(m, Tags.NpcBin)
	m.Parent = Workspace:FindFirstChild("World") or Workspace
	root:SetNetworkOwner(nil)
	return m
end

local function rootOf(): BasePart?
	return bin and bin.PrimaryPart
end

local function humanoid(): Humanoid?
	return bin and bin:FindFirstChildOfClass("Humanoid")
end

local function playerRoots(): { BasePart }
	local out = {}
	for _, p in Players:GetPlayers() do
		local r = p.Character and p.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if r then
			table.insert(out, r)
		end
	end
	return out
end

function BinService.Exists(): boolean
	return bin ~= nil and bin.Parent ~= nil
end

function BinService.Position(): Vector3?
	local r = rootOf()
	return r and r.Position
end

function BinService.Spawn(at: Vector3?)
	BinService.Remove()
	local spawn = Workspace:FindFirstChild("Spawn", true) :: BasePart?
	bin = build(at or (spawn and spawn.Position + Vector3.new(4, 0, 4)) or Vector3.new(-284, 0, 34))
	print("[Bin] here")
end

-- dawn after the finale: Bin asleep on the bank, his camera in his arms (story.md §15)
function BinService.SpawnAsleep(at: Vector3)
	BinService.Remove()
	local m = build(at)
	bin = m
	local root = m.PrimaryPart :: BasePart
	root.Anchored = true
	root.CFrame = CFrame.new(at + Vector3.new(0, 0.7, 0)) * CFrame.Angles(0, math.rad(70), math.rad(90))
	print("[Bin] asleep on the bank")
end

function BinService.Remove()
	job += 1
	mode = "none"
	if bin then
		bin:Destroy()
		bin = nil
	end
end

local function face(look: Vector3)
	local r = rootOf()
	if r then
		r.CFrame = CFrame.lookAt(r.Position, Vector3.new(look.X, r.Position.Y, look.Z))
	end
end

-- walk with the players: a few studs behind the nearest; jump to them if they're suddenly far away
function BinService.Follow()
	job += 1
	local my = job
	mode = "follow"
	task.spawn(function()
		while job == my and BinService.Exists() do
			local r, hum = rootOf(), humanoid()
			local best: BasePart? = nil
			local bestD = math.huge
			for _, pr in playerRoots() do
				local d = r and (pr.Position - r.Position).Magnitude or math.huge
				if d < bestD then
					best, bestD = pr, d
				end
			end
			if r and hum and best then
				local target = best :: BasePart
				if bestD > Config.BinCatchUpDistance then
					r.CFrame = CFrame.new(target.Position - target.CFrame.LookVector * Config.BinFollowDistance)
				elseif bestD > Config.BinFollowDistance + 2 then
					local dir = (r.Position - target.Position).Unit
					hum:MoveTo(target.Position + dir * Config.BinFollowDistance)
				end
			end
			task.wait(0.4)
		end
	end)
end

-- go to a spot and face something; yields until there (or puts him there after a few seconds)
function BinService.StandAt(pos: Vector3, look: Vector3)
	job += 1
	mode = "stand"
	local r, hum = rootOf(), humanoid()
	if not r or not hum then
		return
	end
	hum:MoveTo(pos)
	local t0 = os.clock()
	while (r.Position * Vector3.new(1, 0, 1) - pos * Vector3.new(1, 0, 1)).Magnitude > 2.5 and os.clock() - t0 < Pace.seconds(8) do
		task.wait(0.2)
	end
	if (r.Position - pos).Magnitude > 4 then
		r.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))
	end
	face(look)
end

-- can any player see him? (in range, nothing solid in between)
function BinService.Seen(): boolean
	local r = rootOf()
	if not r then
		return false
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local ignore: { Instance } = { bin :: Model }
	for _, p in Players:GetPlayers() do
		if p.Character then
			table.insert(ignore, p.Character)
		end
	end
	params.FilterDescendantsInstances = ignore
	local target = r.Position + Vector3.new(0, 1.6, 0)
	for _, pr in playerRoots() do
		local eye = pr.Position + Vector3.new(0, 1.5, 0)
		local d = target - eye
		if d.Magnitude <= Config.BinSeenDistance and not Workspace:Raycast(eye, d, params) then
			return true
		end
	end
	return false
end

-- §4 beat 4: east along the shore; gone once nobody can see him (after a few seconds of walking) or after 20 s.
-- Yields until he's gone; returns where he vanished
function BinService.WanderOff(): Vector3
	job += 1
	local my = job
	mode = "wander"
	local hum = humanoid()
	local t0 = os.clock()
	local i = 1
	local r = rootOf()
	-- start from the shore waypoint nearest to him
	if r then
		local best = math.huge
		for k, w in WANDER do
			local d = (w - r.Position).Magnitude
			if d < best then
				best, i = d, k
			end
		end
	end
	while job == my and BinService.Exists() do
		local t = os.clock() - t0
		r = rootOf()
		if hum and r then
			local w = WANDER[math.min(i, #WANDER)]
			if (r.Position * Vector3.new(1, 0, 1) - w * Vector3.new(1, 0, 1)).Magnitude < 3 then
				i += 1
			end
			hum:MoveTo(WANDER[math.min(i, #WANDER)])
		end
		if t >= Pace.seconds(Config.BinWanderMaxSeconds) or (t >= Pace.seconds(Config.BinWanderMinSeconds) and not BinService.Seen()) then
			break
		end
		task.wait(0.25)
	end
	local where = BinService.Position() or WANDER[#WANDER]
	BinService.Remove()
	print("[Bin] gone")
	-- a child crying from the water, out from where he was
	Remotes.event(Remotes.Names.Sfx):FireAllClients("child_crying_water", Vector3.new(where.X, -1, -70))
	return where
end

function BinService.Mode(): string
	return mode
end

function BinService.Start()
	local GameState = require(script.Parent:WaitForChild("GameStateService")) :: any
	GameState.OnReset(BinService.Remove)
end

return BinService
