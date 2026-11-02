--!strict
-- Sen, the ma da (PROTOTYPE_BRIEF §5.5) and being taken (§5.6). Active only in the Open phase, never in the shrine.
--   Every 60-120 s she picks a target: a player who is alone (nobody within 25 studs) and within 30 studs of water.
--   Warning ramp, ~5 s a step, cancelled the moment the condition breaks:
--     1 a child crying from the water  2 carp gather at the edge  3 small wet footprints behind them (camera only)
--     4 humming, with their name in the tune  5 taken
--   Counters: another player close, away from the water, the shrine, or incense (2 each; Sen withdraws for 60 s).
--   Taken: fade, wake in the drowned festival (Y -400). From there "Light a lantern" (once per 60 s) makes a lantern
--   flicker near a place with clues left. Teammates light incense at the shrine altar (hold 3 s) to bring them back,
--   once per player per night; a second taking keeps them below until the ending. Everyone taken = Im lặng.
-- She is never seen: only carp, footprints and sounds. She never chases on land.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Analytics = require(Shared:WaitForChild("Analytics"))
local Config = require(Shared:WaitForChild("Config"))
local Pace = require(Shared:WaitForChild("Pace"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Tags = require(Shared:WaitForChild("Tags"))
local Text = require(Shared:WaitForChild("Content"):WaitForChild("Text"))

local SenService = {}

local rgb = Color3.fromRGB
local GameState: any, Mystery: any, Ending: any
local hunting: Player? = nil
local hunt = 0 -- bumped to cancel a running ramp
local takenOrder: { Player } = {}
local lastLantern: { [Player]: number } = {}
local nextHunt = 0

local function rootOf(p: Player): BasePart?
	return p.Character and p.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function nearestWater(pos: Vector3): (Vector3?, number)
	local best, bestD = nil, math.huge
	for _, w in CollectionService:GetTagged(Tags.WaterEdge) do
		if w:IsA("BasePart") then
			local d = (w.Position * Vector3.new(1, 0, 1) - pos * Vector3.new(1, 0, 1)).Magnitude
			if d < bestD then
				best, bestD = w.Position, d
			end
		end
	end
	return best, bestD
end

local function taken(p: Player): boolean
	return p:GetAttribute("Taken") == true
end

function SenService.Alone(p: Player): boolean
	local r = rootOf(p)
	if not r then
		return false
	end
	for _, o in Players:GetPlayers() do
		local ro = rootOf(o)
		if o ~= p and ro and not taken(o) and (ro.Position - r.Position).Magnitude <= Config.AloneRadius then
			return false
		end
	end
	return true
end

-- can Sen go after this player right now?
function SenService.Exposed(p: Player): boolean
	local r = rootOf(p)
	if not r or taken(p) or GameState.GetPhase() ~= "Open" or GameState.InShrine(p) or r.Position.Y < -100 then
		return false
	end
	if ((p:GetAttribute("SenWithdrawUntil") :: number?) or 0) > os.clock() then
		return false
	end
	local _, d = nearestWater(r.Position)
	return d <= Config.WaterDangerRadius and SenService.Alone(p)
end

local function footprints(p: Player)
	local r = rootOf(p)
	if not r then
		return
	end
	local m = Instance.new("Model")
	m.Name = "SenFootprints"
	local back = -r.CFrame.LookVector * Vector3.new(1, 0, 1)
	back = if back.Magnitude > 0.1 then back.Unit else Vector3.new(0, 0, 1)
	local side = back:Cross(Vector3.yAxis)
	for k = 1, 6 do
		local pos = r.Position * Vector3.new(1, 0, 1) + back * (1.5 + k * 1.3) + side * ((k % 2) * 0.7 - 0.35) + Vector3.new(0, 0.06, 0)
		local f = Instance.new("Part")
		f.Name = "Footprint"
		f.Size = Vector3.new(0.5, 0.06, 0.9)
		f.CFrame = CFrame.lookAt(pos, pos - back)
		f.Color = rgb(30, 40, 50)
		f.Anchored, f.CanCollide, f.CanQuery = true, false, false
		f.Parent = m
	end
	CollectionService:AddTag(m, Tags.CameraOnly)
	m.Parent = Workspace:FindFirstChild("World") or Workspace
	task.delay(Pace.seconds(40), function()
		m:Destroy()
	end)
end

-- take this player: they wake in the drowned festival
function SenService.Take(p: Player)
	local r = rootOf(p)
	if not r or taken(p) then
		return
	end
	local final = ((p:GetAttribute("Rescues") :: number?) or 0) >= Config.RescuesPerPlayerPerNight
	p:SetAttribute("Taken", true)
	p:SetAttribute("TakenFinal", final)
	table.insert(takenOrder, p)
	local where = r.Position
	Analytics.track("player_taken", { player = p.Name, final = final })
	print(`[Sen] {p.Name} was taken{final and " (for good)" or ""}`)
	Remotes.event(Remotes.Names.Fade):FireClient(p, 1.6)
	Remotes.event(Remotes.Names.Sfx):FireClient(p, "taken", nil)
	task.delay(0.8, function()
		local fest = nil
		for _, m in CollectionService:GetTagged(Tags.Location) do
			if m:GetAttribute("Location") == "DrownedFestival" then
				fest = m
			end
		end
		if fest and r.Parent then
			r.AssemblyLinearVelocity = Vector3.zero
			r.CFrame = CFrame.new((fest :: Model):GetPivot().Position + Vector3.new(0, 3, 0)) * CFrame.Angles(0, math.pi, 0)
		end
		-- the letter drops where they stood (after they're gone, or they'd just pick it up again)
		Mystery.DropLetter(p, where)
		Remotes.event(Remotes.Names.Message):FireClient(p, Text.Messages.taken)
	end)
	-- everyone taken: Im lặng now (§5.6)
	local anyone = false
	for _, o in Players:GetPlayers() do
		if not taken(o) then
			anyone = true
		end
	end
	-- (tests with one player can keep the run going with the Studio-only attribute DebugKeepRun)
	if not anyone and not (RunService:IsStudio() and ReplicatedStorage:GetAttribute("DebugKeepRun") == true) then
		task.delay(2, function()
			Ending.AllTaken()
		end)
	end
end

-- bring the first rescuable taken player back to the shrine
function SenService.Rescue(by: Player?): Player?
	for i, p in takenOrder do
		if p.Parent and taken(p) and p:GetAttribute("TakenFinal") ~= true then
			table.remove(takenOrder, i)
			p:SetAttribute("Taken", false)
			p:SetAttribute("Rescues", ((p:GetAttribute("Rescues") :: number?) or 0) + 1)
			Analytics.track("player_rescued", { player = p.Name, by = by and by.Name or "?" })
			print(`[Sen] {p.Name} was brought back`)
			local r = rootOf(p)
			local shrine = nil
			for _, z in CollectionService:GetTagged(Tags.ShrineZone) do
				shrine = z
			end
			Remotes.event(Remotes.Names.Fade):FireClient(p, 1.2)
			task.delay(0.6, function()
				if r and shrine then
					r.AssemblyLinearVelocity = Vector3.zero
					r.CFrame = CFrame.new((shrine :: BasePart).Position + Vector3.new(0, -2, 6))
				end
				Remotes.event(Remotes.Names.Message):FireClient(p, Text.Messages.rescued)
			end)
			return p
		end
	end
	return nil
end

function SenService.Rescuable(): boolean
	for _, p in takenOrder do
		if p.Parent and taken(p) and p:GetAttribute("TakenFinal") ~= true then
			return true
		end
	end
	return false
end

-- the warning ramp on one player; returns true if they were taken
function SenService.Hunt(p: Player): boolean
	hunt += 1
	local my = hunt
	hunting = p
	print(`[Sen] hunting {p.Name}`)
	local function still(): boolean
		return hunt == my and p.Parent ~= nil and SenService.Exposed(p)
	end
	for step = 1, 5 do
		if not still() then
			print(`[Sen] warning cancelled at step {step}`)
			Analytics.track("sen_warning", { step = step, cancelled = true, player = p.Name })
			hunting = nil
			return false
		end
		Analytics.track("sen_warning", { step = step, player = p.Name })
		print(`[Sen] warning {step}`)
		local r = rootOf(p) :: BasePart
		local water = nearestWater(r.Position) or r.Position
		Remotes.event(Remotes.Names.SenWarning):FireClient(p, step)
		if step == 1 then
			Remotes.event(Remotes.Names.Sfx):FireClient(p, "child_crying_water", water + Vector3.new(0, 0, -8))
		elseif step == 2 then
			Mystery.SpawnCarp(Vector3.new(water.X, 0, math.min(water.Z, r.Position.Z) - 6), 8, 4, 20)
		elseif step == 3 then
			footprints(p)
			Remotes.event(Remotes.Names.Sfx):FireClient(p, "wet_footsteps", r.Position)
		elseif step == 4 then
			Remotes.event(Remotes.Names.Message):FireClient(p, string.format(Text.Messages.humming, p.DisplayName))
		else
			SenService.Take(p)
			hunting = nil
			return true
		end
		Pace.wait(Config.SenWarningStepSeconds)
	end
	hunting = nil
	return false
end

function SenService.Hunting(): string?
	return hunting and hunting.Name or nil
end

-- incense: a Tool each player carries with a count (2 a night); using it makes Sen withdraw from them for 60 s ------
local function giveIncense(p: Player)
	local count = (p:GetAttribute("Incense") :: number?) or 0
	local backpack = p:FindFirstChildOfClass("Backpack")
	if count <= 0 or not backpack or backpack:FindFirstChild("Incense") or (p.Character and p.Character:FindFirstChild("Incense")) then
		return
	end
	local tool = Instance.new("Tool")
	tool.Name = "Incense"
	tool.ToolTip = `{Text.UI.incense} ({count})`
	tool.RequiresHandle = false
	tool.CanBeDropped = false
	tool.Activated:Connect(function()
		SenService.UseIncense(p)
	end)
	tool.Parent = backpack
end

function SenService.UseIncense(p: Player): boolean
	local count = (p:GetAttribute("Incense") :: number?) or 0
	if count <= 0 or taken(p) then
		return false
	end
	count -= 1
	p:SetAttribute("Incense", count)
	p:SetAttribute("SenWithdrawUntil", os.clock() + Pace.seconds(Config.IncenseWithdrawSeconds))
	Analytics.track("incense_used", { player = p.Name, left = count })
	Remotes.event(Remotes.Names.Message):FireClient(p, Text.Messages.incenseUsed)
	local r = rootOf(p)
	Remotes.event(Remotes.Names.Sfx):FireClient(p, "incense", r and r.Position)
	for _, place in { p.Character, p:FindFirstChildOfClass("Backpack") } do
		local tool = place and place:FindFirstChild("Incense") :: Tool?
		if tool then
			if count <= 0 then
				tool:Destroy()
			else
				tool.ToolTip = `{Text.UI.incense} ({count})`
			end
		end
	end
	if hunting == p then
		hunt += 1 -- she withdraws
		hunting = nil
		print("[Sen] withdraws (incense)")
	end
	return true
end

local function setupPlayer(p: Player)
	p:SetAttribute("Taken", false)
	p:SetAttribute("TakenFinal", false)
	p:SetAttribute("Rescues", 0)
	p:SetAttribute("Incense", Config.IncensePerPlayer)
	p.CharacterAdded:Connect(function()
		task.wait(0.2)
		giveIncense(p)
	end)
	if p.Character then
		giveIncense(p)
	end
end

function SenService.Reset()
	hunt += 1
	hunting = nil
	table.clear(takenOrder)
	nextHunt = 0
	for _, p in Players:GetPlayers() do
		p:SetAttribute("Taken", false)
		p:SetAttribute("TakenFinal", false)
		p:SetAttribute("Rescues", 0)
		p:SetAttribute("Incense", Config.IncensePerPlayer)
		p:SetAttribute("SenWithdrawUntil", 0)
	end
end

-- the rescue prompt on the shrine altar (hold 3 s), shown only when someone can be brought back
local function rescuePrompt()
	for _, altar in CollectionService:GetTagged(Tags.ShrineAltar) do
		if altar:IsA("BasePart") and not altar:FindFirstChild("Rescue") then
			local prompt = Instance.new("ProximityPrompt")
			prompt.Name = "Rescue"
			prompt.ActionText = Text.UI.lightIncense
			prompt.ObjectText = Text.Objects.shrineAltar
			prompt.HoldDuration = Config.RescueHoldSeconds
			prompt.MaxActivationDistance = Config.PromptDistance
			prompt.RequiresLineOfSight = false
			prompt.Enabled = false
			prompt.Triggered:Connect(function(player: Player)
				if not taken(player) then
					SenService.Rescue(player)
				end
			end)
			prompt.Parent = altar
			task.spawn(function()
				while prompt.Parent do
					prompt.Enabled = SenService.Rescuable()
					task.wait(0.5)
				end
			end)
		end
	end
end

-- the drowned festival's puppet show: it never ends
local function puppetShow()
	local fest: Model? = nil
	for _, m in CollectionService:GetTagged(Tags.Location) do
		if m:GetAttribute("Location") == "DrownedFestival" then
			fest = m :: Model
		end
	end
	local stage = fest and fest:FindFirstChild("Stage") :: BasePart?
	if not stage then
		return
	end
	local puppets = {}
	for k = -1, 1 do
		local p = Instance.new("Part")
		p.Name = "Puppet"
		p.Size = Vector3.new(1.2, 1.8, 0.8)
		p.Color = if k == 0 then rgb(200, 60, 40) else rgb(60, 120, 90)
		p.Anchored, p.CanCollide = true, false
		p.Parent = fest
		table.insert(puppets, { part = p, x = k * 5 })
	end
	task.spawn(function()
		while true do
			local t = os.clock()
			for i, pp in puppets do
				pp.part.CFrame = CFrame.new(stage.Position + Vector3.new(pp.x + math.sin(t * 0.8 + i) * 2, 2.6 + math.abs(math.sin(t * 2 + i)) * 0.8, 0))
					* CFrame.Angles(0, 0, math.sin(t * 3 + i) * 0.3)
			end
			task.wait(1 / 15)
		end
	end)
end

function SenService.Init()
	for _, name in { Remotes.Names.SenWarning, Remotes.Names.PlayerTaken, Remotes.Names.LightLantern } do
		Remotes.event(name)
	end
	Players.PlayerAdded:Connect(setupPlayer)
	for _, p in Players:GetPlayers() do
		setupPlayer(p)
	end
	Players.PlayerRemoving:Connect(function(p)
		lastLantern[p] = nil
		local i = table.find(takenOrder, p)
		if i then
			table.remove(takenOrder, i)
		end
	end)
	Remotes.event(Remotes.Names.LightLantern).OnServerEvent:Connect(function(p: Player)
		if not taken(p) or os.clock() - (lastLantern[p] or -math.huge) < Pace.seconds(Config.TakenLanternCooldown) then
			return
		end
		lastLantern[p] = os.clock()
		Analytics.track("taken_lantern", { player = p.Name })
		Mystery.Hint("taken")
	end)
end

function SenService.Start()
	GameState = require(script.Parent:WaitForChild("GameStateService"))
	Mystery = require(script.Parent:WaitForChild("MysteryService"))
	Ending = require(script.Parent:WaitForChild("EndingService"))
	GameState.OnReset(SenService.Reset)
	rescuePrompt()
	puppetShow()
	local rng = Random.new()
	while true do
		task.wait(0.5)
		if GameState.GetPhase() ~= "Open" or ReplicatedStorage:GetAttribute("SenOff") == true then
			nextHunt = os.clock() + Pace.seconds(rng:NextNumber(Config.SenTargetIntervalMin, Config.SenTargetIntervalMax))
		elseif not hunting and os.clock() >= nextHunt then
			nextHunt = os.clock() + Pace.seconds(rng:NextNumber(Config.SenTargetIntervalMin, Config.SenTargetIntervalMax))
			local targets = {}
			for _, p in Players:GetPlayers() do
				if SenService.Exposed(p) then
					table.insert(targets, p)
				end
			end
			if #targets > 0 then
				task.spawn(SenService.Hunt, targets[rng:NextInteger(1, #targets)])
			end
		end
	end
end

return SenService
