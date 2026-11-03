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
-- In the water (I-16): a pale small shape under the surface, with carp around her, that everyone can see. She drifts
-- round the middle of the lake; when she hunts she follows her target along the shore, still, then suddenly closer,
-- rising nearer the surface. Her wet footprints walk out of the water toward the target (camera only). The last
-- warning waits until she's at the edge by them. Taken: everyone sees the body slide into the water there (a
-- splash); the taken player sees the grab (her hair-hidden face, a sting), the pull, sinking under the lanterns,
-- then wakes in the drowned festival. Her face is never shown; nothing violent, no struggle.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Analytics = require(Shared:WaitForChild("Analytics"))
local Config = require(Shared:WaitForChild("Config"))
local Figures = require(Shared:WaitForChild("Figures"))
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

-- Sen in the water --------------------------------------------------------------------------------------------------
local flat = Vector3.new(1, 0, 1)
local senPos = Config.LakeMiddle * flat -- x, z; she's always under the surface
local senDepth = Config.SenIdleDepth
local goal: Vector3? = nil -- hunting: the water point by the target
local wanderAngle = 0
local dartUntil, stillUntil = 0, 0
local shape: Model? = nil
local carp: { BasePart } = {}

-- a point in the water just off the shore nearest this position
local function waterPointBy(pos: Vector3): Vector3?
	local edge = nearestWater(pos)
	if not edge then
		return nil
	end
	local out = (Config.LakeMiddle - edge) * flat
	out = if out.Magnitude > 0.1 then out.Unit else Vector3.zero
	return edge * flat + out * Config.SenOffshore
end

local function makeShape(): Model
	local m = Figures.Sen(CFrame.new(Config.LakeMiddle), nil, 30)
	m.Name = "SenInTheWater"
	for _, d in m:GetDescendants() do
		if d:IsA("BasePart") then
			d.Transparency = 0.4
			d.CanQuery, d.CanTouch, d.CastShadow = false, false, false
		end
	end
	local glow = Instance.new("PointLight")
	glow.Color = rgb(170, 205, 215)
	glow.Brightness = 0.8
	glow.Range = 10
	glow.Shadows = false
	glow.Parent = m.PrimaryPart
	for k = 1, 6 do
		local f = Instance.new("Part")
		f.Name = "Carp"
		f.Shape = Enum.PartType.Ball
		f.Size = Vector3.new(0.6, 0.45, 1.6)
		f.Color = if k % 3 == 0 then rgb(230, 230, 220) else rgb(225, 130, 40)
		f.Material = Enum.Material.SmoothPlastic
		f.Anchored, f.CanCollide, f.CanQuery, f.CanTouch = true, false, false, false
		f.Parent = m
		table.insert(carp, f)
	end
	m.Parent = Workspace:FindFirstChild("World") or Workspace
	return m
end

-- one step of her movement (dt in game seconds)
local function swim(dt: number)
	local now = os.clock()
	local target: Vector3
	local speed: number
	if goal then
		target = goal
		-- stillness, then sudden closeness
		if now < dartUntil then
			speed = Config.SenDartSpeed
		elseif now < stillUntil then
			speed = 0
		else
			dartUntil = now + Pace.seconds(Config.SenDartSeconds)
			stillUntil = dartUntil + Pace.seconds(Config.SenStillSeconds)
			speed = Config.SenDartSpeed
		end
	else
		wanderAngle += dt * Config.SenSwimSpeed / Config.SenWanderRadius
		target = Config.LakeMiddle * flat + Vector3.new(math.cos(wanderAngle), 0, math.sin(wanderAngle)) * Config.SenWanderRadius
		speed = Config.SenSwimSpeed
	end
	local to = target - senPos
	local step = math.min(to.Magnitude, speed * dt)
	local facing = if to.Magnitude > 0.5 then to.Unit else Vector3.new(0, 0, -1)
	if step > 0 then
		senPos += facing * step
	end
	local wantDepth = if goal then Config.SenHuntDepth else Config.SenIdleDepth
	senDepth += (wantDepth - senDepth) * math.min(1, dt * 0.8)
	local m = shape
	if m and m.Parent then
		local at = Vector3.new(senPos.X, Config.WaterY - senDepth, senPos.Z)
		m:PivotTo(CFrame.lookAt(at, at + facing))
		local t = os.clock()
		for i, f in carp do
			local a = t * 0.9 + i * (math.pi * 2 / #carp)
			local p = at + Vector3.new(math.cos(a) * 3.2, senDepth * 0.6, math.sin(a) * 3.2)
			f.CFrame = CFrame.lookAt(p, p + Vector3.new(-math.sin(a), 0, math.cos(a)))
		end
	end
end

function SenService.Position(): Vector3
	return Vector3.new(senPos.X, Config.WaterY - senDepth, senPos.Z)
end

-- how far she still is from the water point she's going to
local function arrived(): boolean
	return goal ~= nil and ((goal :: Vector3) - senPos).Magnitude <= Config.SenReachDistance
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

-- small wet footprints walking up out of the water toward the player, one at a time (camera only), over `seconds`;
-- each print aims at where the player is now, so they follow
local function footprints(p: Player, seconds: number)
	local r = rootOf(p)
	local from = r and nearestWater(r.Position)
	if not (r and from) then
		return
	end
	local folder = Instance.new("Folder")
	folder.Name = "SenFootprints"
	folder.Parent = Workspace:FindFirstChild("World") or Workspace
	task.delay(Pace.seconds(40), function()
		folder:Destroy()
	end)
	task.spawn(function()
		local start = (from :: Vector3) * flat
		for k = 1, Config.SenFootprints do
			local root = rootOf(p)
			if not root or not folder.Parent then
				return
			end
			local to = root.Position * flat
			local dir = to - start
			if dir.Magnitude < 0.5 then
				return
			end
			-- the last print lands just behind them
			local along = math.min(dir.Magnitude - 1.5, dir.Magnitude * k / Config.SenFootprints)
			local side = dir.Unit:Cross(Vector3.yAxis) * ((k % 2) * 0.7 - 0.35)
			local pos = start + dir.Unit * along + side + Vector3.new(0, 0.06, 0)
			local m = Instance.new("Model")
			m.Name = "Footprint"
			local f = Instance.new("Part")
			f.Name = "Print"
			f.Size = Vector3.new(0.5, 0.06, 0.9)
			f.CFrame = CFrame.lookAt(pos, pos + dir.Unit)
			f.Color = rgb(30, 40, 50)
			f.Anchored, f.CanCollide, f.CanQuery = true, false, false
			f.Parent = m
			CollectionService:AddTag(m, Tags.CameraOnly)
			m.Parent = folder
			task.wait(Pace.seconds(seconds / Config.SenFootprints))
		end
	end)
end

local function festivalSpot(): CFrame?
	for _, m in CollectionService:GetTagged(Tags.Location) do
		if m:GetAttribute("Location") == "DrownedFestival" then
			return CFrame.new((m :: Model):GetPivot().Position + Vector3.new(0, 3, 0)) * CFrame.Angles(0, math.pi, 0)
		end
	end
	return nil
end

-- everyone left in the game is taken: Im lặng (§5.6). Also after someone leaves, so the taken aren't left waiting.
-- (tests with one player can keep the run going with the Studio-only attribute DebugKeepRun)
local function checkAllTaken()
	local players = Players:GetPlayers()
	if #players == 0 then
		return
	end
	for _, o in players do
		if not taken(o) then
			return
		end
	end
	if not (RunService:IsStudio() and ReplicatedStorage:GetAttribute("DebugKeepRun") == true) then
		task.delay(Pace.seconds(Config.SenTakeSeconds) + 2, function() -- after the last one has gone under
			Ending.AllTaken()
		end)
	end
end

-- take this player: pulled into the water where they stand (everyone sees it), then the drowned festival.
-- quiet: no sting (the Im lặng ending, where all sound dies)
function SenService.Take(p: Player, quiet: boolean?)
	local r = rootOf(p)
	if not r or taken(p) then
		return
	end
	local final = ((p:GetAttribute("Rescues") :: number?) or 0) >= Config.RescuesPerPlayerPerNight
	p:SetAttribute("Taken", true)
	p:SetAttribute("TakenFinal", final)
	table.insert(takenOrder, p)
	local where = r.Position
	local water = waterPointBy(where) or where
	Analytics.track("player_taken", { player = p.Name, final = final })
	print(`[Sen] {p.Name} was taken{final and " (for good)" or ""}`)
	Remotes.event(Remotes.Names.SenGrab):FireClient(p, water, quiet == true)
	Remotes.event(Remotes.Names.PlayerTaken):FireAllClients(p.UserId, water)
	Remotes.event(Remotes.Names.Sfx):FireClient(p, "taken", nil)
	-- she has them by the leg: a beat (they look down at her hand), then pulled backward, falling forward, across the
	-- ground to the water and under (everyone sees it); the player's own view is SenController's
	r.Anchored = true
	task.spawn(function()
		Pace.wait(Config.SenGrabSeconds)
		local edge = Vector3.new(water.X, Config.WaterY + 0.5, water.Z)
		local under = Vector3.new(water.X, Config.WaterY - 6, water.Z)
		local from = r.Position
		local away = (where - water) * flat
		local face = CFrame.lookAt(where, where + (if away.Magnitude > 0.1 then away.Unit else Vector3.new(0, 0, 1)))
		local t0 = os.clock()
		local drag = Pace.seconds(Config.SenDragSeconds)
		local splashed = false
		while r.Parent and taken(p) do
			local a = (os.clock() - t0) / drag
			if a >= 1 then
				break
			end
			local pos = if a < 0.7 then from:Lerp(edge, (a / 0.7) ^ 1.6) else edge:Lerp(under, (a - 0.7) / 0.3)
			if a >= 0.7 and not splashed then
				splashed = true
				Remotes.event(Remotes.Names.Sfx):FireAllClients("sen_splash", edge)
			end
			local fall = math.rad(-75) * math.min(1, a / 0.25) -- face down, dragged feet first
			r.CFrame = face.Rotation * CFrame.Angles(fall, 0, 0) + pos
			task.wait()
		end
	end)
	task.delay(Pace.seconds(Config.SenTakeSeconds), function()
		local fest = nil
		for _, m in CollectionService:GetTagged(Tags.Location) do
			if m:GetAttribute("Location") == "DrownedFestival" then
				fest = m
			end
		end
		if r.Parent then
			r.Anchored = false
			if fest and taken(p) then
				r.AssemblyLinearVelocity = Vector3.zero
				r.CFrame = CFrame.new((fest :: Model):GetPivot().Position + Vector3.new(0, 3, 0)) * CFrame.Angles(0, math.pi, 0)
			end
		end
		-- the letter drops where they stood (after they're gone, or they'd just pick it up again)
		Mystery.DropLetter(p, where)
		if taken(p) then
			Remotes.event(Remotes.Names.Message):FireClient(p, Text.Messages.taken)
		end
	end)
	checkAllTaken()
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
	local function stop()
		if hunt == my then
			hunting = nil
			goal = nil -- she sinks back toward the middle
		end
	end
	-- she follows them along the shore from the start
	task.spawn(function()
		while hunt == my and hunting == p do
			local r = rootOf(p)
			goal = if r then waterPointBy(r.Position) else nil
			task.wait(0.25)
		end
	end)
	for step = 1, 5 do
		if step == 5 then
			-- the grab needs her at the edge by them
			local t0 = os.clock()
			while still() and not arrived() and os.clock() - t0 < Pace.seconds(Config.SenArriveTimeout) do
				task.wait(0.1)
			end
		end
		if not still() then
			print(`[Sen] warning cancelled at step {step}`)
			Analytics.track("sen_warning", { step = step, cancelled = true, player = p.Name })
			stop()
			return false
		end
		Analytics.track("sen_warning", { step = step, player = p.Name })
		print(`[Sen] warning {step}`)
		local r = rootOf(p) :: BasePart
		local water = waterPointBy(r.Position) or r.Position
		Remotes.event(Remotes.Names.SenWarning):FireClient(p, step)
		if step == 1 then
			Remotes.event(Remotes.Names.Sfx):FireClient(p, "child_crying_water", SenService.Position())
		elseif step == 2 then
			Mystery.SpawnCarp(Vector3.new(water.X, 0, water.Z), 8, 4, 20)
		elseif step == 3 then
			footprints(p, Config.SenWarningStepSeconds * 2)
			Remotes.event(Remotes.Names.Sfx):FireClient(p, "wet_footsteps", r.Position)
		elseif step == 4 then
			Remotes.event(Remotes.Names.Message):FireClient(p, string.format(Text.Messages.humming, p.DisplayName))
		else
			SenService.Take(p)
			stop()
			return true
		end
		Pace.wait(Config.SenWarningStepSeconds)
	end
	stop()
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
		goal = nil
		print("[Sen] withdraws (incense)")
	end
	return true
end

local function setupPlayer(p: Player)
	p:SetAttribute("Taken", false)
	p:SetAttribute("TakenFinal", false)
	p:SetAttribute("Rescues", 0)
	p:SetAttribute("Incense", Config.IncensePerPlayer)
	p.CharacterAdded:Connect(function(char)
		task.wait(0.2)
		giveIncense(p)
		-- a taken player who resets their character wakes in the festival again, not on the shore
		local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?
		local spot = festivalSpot()
		if taken(p) and root and spot then
			root.CFrame = spot
		end
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
	goal = nil
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
		task.defer(checkAllTaken)
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
	shape = makeShape()
	task.spawn(function()
		local last = os.clock()
		while true do
			task.wait(1 / 15)
			local now = os.clock()
			swim((now - last) * Pace.scale())
			last = now
		end
	end)
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
