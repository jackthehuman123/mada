--!strict
-- The lanterns (PROTOTYPE_BRIEF §4 beat 3, §5.4): Bà Thu sets four lanterns on the water in front of the shrine. Each
-- drifts along its house's LanternPath to the LanternStop below a lost child's house; when it gets there, that
-- house's window lights up and a faint child's sound plays inside. Sen's house has no stop: it stays dark.
-- Night 1, and again at 23:00 so players can watch a second time. Windows stay lit for the rest of the night.

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Pace = require(Shared:WaitForChild("Pace"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Tags = require(Shared:WaitForChild("Tags"))

local LanternService = {}

local rgb = Color3.fromRGB
local DARK, LIT = rgb(30, 34, 40), rgb(255, 196, 120)
local folder: Folder? = nil
local drift = 0 -- bumped by every new drift and by Reset, so an old drift stops moving its lanterns

local function pathFor(house: string): { Vector3 }
	local pts = {}
	for _, p in CollectionService:GetTagged(Tags.LanternPath) do
		if p:GetAttribute("House") == house and p:IsA("BasePart") then
			table.insert(pts, p)
		end
	end
	table.sort(pts, function(a, b)
		return (a:GetAttribute("Index") :: number) < (b:GetAttribute("Index") :: number)
	end)
	local out = {}
	for _, p in pts do
		table.insert(out, Vector3.new(p.Position.X, Config.LanternFloatY, p.Position.Z))
	end
	return out
end

local function newLantern(parent: Instance, house: string, pos: Vector3): BasePart
	local base = Instance.new("Part")
	base.Name = "Lantern_" .. house
	base.Size = Vector3.new(1.6, 0.4, 1.6)
	base.Color = rgb(200, 60, 40)
	base.Material = Enum.Material.SmoothPlastic
	base.Anchored, base.CanCollide, base.CanQuery = true, false, false
	base.CFrame = CFrame.new(pos)
	local glow = Instance.new("Part")
	glow.Name = "Glow"
	glow.Shape = Enum.PartType.Ball
	glow.Size = Vector3.new(1.3, 1.3, 1.3)
	glow.Color = rgb(255, 170, 90)
	glow.Material = Enum.Material.Neon
	glow.Anchored, glow.CanCollide, glow.CanQuery = true, false, false
	glow.CFrame = CFrame.new(pos + Vector3.new(0, 0.8, 0))
	glow.Parent = base
	local light = Instance.new("PointLight")
	light.Color = rgb(255, 170, 100)
	light.Range = 16
	light.Brightness = 1.4
	light.Parent = glow
	base:SetAttribute("House", house)
	base.Parent = parent
	return base
end

function LanternService.Windows(): { [string]: boolean }
	local out = {}
	for _, w in CollectionService:GetTagged(Tags.HouseWindow) do
		out[w:GetAttribute("House") :: string] = w:GetAttribute("Lit") == true
	end
	return out
end

local function setWindow(house: string, lit: boolean)
	for _, w in CollectionService:GetTagged(Tags.HouseWindow) do
		if w:GetAttribute("House") == house and w:IsA("BasePart") then
			w:SetAttribute("Lit", lit)
			w.Color = if lit then LIT else DARK
			w.Material = if lit then Enum.Material.Neon else Enum.Material.Glass
			local light = w:FindFirstChild("WindowLight")
			if lit and not light then
				local l = Instance.new("PointLight")
				l.Name = "WindowLight"
				l.Color = LIT
				l.Range = 18
				l.Brightness = 1.2
				l.Parent = w
			elseif not lit and light then
				light:Destroy()
			end
			if lit then
				Remotes.event(Remotes.Names.Sfx):FireAllClients("child_inside", w.Position)
			end
		end
	end
end

-- move one lantern along its path at a steady speed so it arrives after LanternDriftSeconds (game time)
local function float(lantern: BasePart, points: { Vector3 }, myDrift: number)
	local total = 0
	for i = 2, #points do
		total += (points[i] - points[i - 1]).Magnitude
	end
	local glow = lantern:FindFirstChild("Glow") :: BasePart
	local done, t0 = 0, os.clock()
	local seg = 2
	while seg <= #points and drift == myDrift and lantern.Parent do
		local speed = total / Pace.seconds(Config.LanternDriftSeconds)
		local dt = task.wait()
		done += speed * dt
		local walked = 0
		local pos = points[#points]
		for i = 2, #points do
			local len = (points[i] - points[i - 1]).Magnitude
			if walked + len >= done then
				pos = points[i - 1]:Lerp(points[i], (done - walked) / math.max(len, 1e-3))
				seg = i
				break
			end
			walked += len
			seg = i + 1
		end
		local bob = math.sin((os.clock() - t0) * 1.6) * 0.08
		lantern.CFrame = CFrame.new(pos + Vector3.new(0, bob, 0))
		glow.CFrame = CFrame.new(pos + Vector3.new(0, 0.8 + bob, 0))
	end
end

-- set four lanterns on the water and let them drift; yields until every one has reached its house
function LanternService.DriftAll()
	drift += 1
	local myDrift = drift
	if folder then
		folder:Destroy()
	end
	local f = Instance.new("Folder")
	f.Name = "NightLanterns"
	f.Parent = Workspace:FindFirstChild("World") or Workspace
	folder = f
	local stops = CollectionService:GetTagged(Tags.LanternStop)
	table.sort(stops, function(a, b)
		return (a :: BasePart).Position.X < (b :: BasePart).Position.X
	end)
	local remaining = #stops
	for k, stop in stops do
		local house = stop:GetAttribute("House") :: string
		local points = pathFor(house)
		table.insert(points, Vector3.new((stop :: BasePart).Position.X, Config.LanternFloatY, (stop :: BasePart).Position.Z))
		local lantern = newLantern(f, house, points[1])
		Remotes.event(Remotes.Names.Sfx):FireAllClients("lantern_on_water", points[1])
		print(`[Lanterns] {house}'s lantern is on the water`)
		task.spawn(function()
			float(lantern, points, myDrift)
			if drift == myDrift then
				print(`[Lanterns] {house}'s lantern arrived; window lit`)
				setWindow(house, true)
			end
			remaining -= 1
		end)
		if k < #stops then
			Pace.wait(Config.LanternStaggerSeconds)
		end
	end
	while remaining > 0 and drift == myDrift do
		task.wait(0.2)
	end
end

function LanternService.Reset()
	drift += 1
	if folder then
		folder:Destroy()
		folder = nil
	end
	for house in LanternService.Windows() do
		setWindow(house, false)
	end
end

function LanternService.Init()
	Remotes.event(Remotes.Names.Sfx)
end

function LanternService.Start()
	local GameState = require(script.Parent:WaitForChild("GameStateService")) :: any
	GameState.OnReset(LanternService.Reset)
end

return LanternService
