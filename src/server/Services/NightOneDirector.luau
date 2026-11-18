--!strict
-- Night 1 (PROTOTYPE_BRIEF §4): the same seven beats every run. Each beat logs "[Night1] beat N" and waits for its
-- trigger. Beat 1 runs in the Arrival phase; reaching the shrine starts the Night1 phase and beats 2-7; beat 7 starts
-- the Open phase. The replicated attribute ReplicatedStorage.Night1Beat says which beat is running.
--   1 Arrival: Bin walks with the players                       -> any player enters the ShrineZone
--   2 Bà Thu at the shrine: her dialogue, Bin films it (Tape 1) -> the conversation ends
--   3 Lanterns: four drift to the lost children's houses         -> all four arrived, four windows lit
--   4 Bin wanders off east along the shore and vanishes          -> he's gone; a child cries from the water
--   5 Trapped: the causeway floods                               -> (immediately)
--   6 Bin's camera floats in the reeds by the shrine             -> someone picks it up: the group gets Bin's tapes
--   7 Open: "Find Bin."
-- Also: the second lantern drift at 23:00 in the Open phase (§5.4).

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Analytics = require(Shared:WaitForChild("Analytics"))
local Config = require(Shared:WaitForChild("Config"))
local Pace = require(Shared:WaitForChild("Pace"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Tags = require(Shared:WaitForChild("Tags"))
local Text = require(Shared:WaitForChild("Content"):WaitForChild("Text"))

local Director = {}

local GameState: any, Dialogue: any, Lanterns: any, Bin: any
local run = 0 -- bumped on every new Night 1 / reset, so an old sequence stops at its next check
local secondDriftDone = false
local flood: Folder? = nil
-- the marsh around the causeway, saved before the flood so it can be written back exactly
local FLOOD_REGION = Region3.new(Vector3.new(-504, -4, 32), Vector3.new(-288, 8, 252)):ExpandToGrid(4)
local savedMarsh: { any }? = nil
local camera: Model? = nil
local cameraPicked: BindableEvent? = nil

local rgb = Color3.fromRGB
-- where Bin stands to film Bà Thu (Tape 1 is shot from here; see Content/Tapes)
local FILM_SPOT, THU_MAT = Vector3.new(-322, 0, -50), Vector3.new(-334, 1, -64)
-- the reeds by the shrine, a few studs out from the shore (§4 beat 6)
local CAMERA_SPOT = Vector3.new(-286, -0.7, -55)

local function beat(n: number)
	ReplicatedStorage:SetAttribute("Night1Beat", n)
	GameState.SetClock(Config.Night1BeatHours[n])
	print(`[Night1] beat {n}`)
	Analytics.track("night1_beat", { beat = n })
end

local function message(text: string)
	Remotes.event(Remotes.Names.Message):FireAllClients(text)
end

-- beat 5: water over the causeway near the village end, and a boundary there: every way out leads back to the shore
local function floodCauseway()
	if flood then
		return
	end
	local f = Instance.new("Folder")
	f.Name = "Flood"
	local a, b = Vector3.new(-300, 0, 46), Vector3.new(-490, 0, 236)
	-- the marsh itself rises over the road: terrain water to y = 1.7 (the road's top is 1.2), saved first and put back
	-- exactly by unflood() (glass parts read as a black road)
	local terrain = Workspace.Terrain
	savedMarsh = { terrain:ReadVoxels(FLOOD_REGION, 4) }
	local n = 12
	for k = 0, n - 1 do
		local p = a:Lerp(b, (k + 0.5) / n)
		terrain:FillBlock(
			CFrame.lookAt(p + Vector3.new(0, 0.85, 0), p + (b - a) + Vector3.new(0, 0.85, 0)),
			Vector3.new(16, 1.7, (b - a).Magnitude / n + 1),
			Enum.Material.Water
		)
	end
	-- the line players can't cross: 20 studs out along the causeway, the width of the marsh crossing
	local edge = a:Lerp(b, 0.12)
	local zone = Instance.new("Part")
	zone.Name = "FloodBoundary"
	zone.Anchored, zone.CanCollide, zone.CanQuery, zone.CanTouch = true, false, false, true
	zone.Transparency = 1
	zone.Size = Vector3.new(30, 40, 4)
	zone.CFrame = CFrame.lookAt(edge, edge + (b - a))
	zone:SetAttribute("Message", Text.Messages.causewayFlooded)
	CollectionService:AddTag(zone, Tags.BoundaryTeleport)
	zone.Parent = f
	CollectionService:AddTag(f, Tags.Flood)
	f.Parent = Workspace:FindFirstChild("World") or Workspace
	flood = f
	print("[Night1] the causeway is under water")
end

local function unflood()
	if flood then
		flood:Destroy()
		flood = nil
	end
	if savedMarsh then
		Workspace.Terrain:WriteVoxels(FLOOD_REGION, 4, savedMarsh[1], savedMarsh[2])
		savedMarsh = nil
	end
end

-- beat 6: Bin's camera, floating in the reeds, its REC light blinking
local function spawnCamera(picked: BindableEvent)
	local m = Instance.new("Model")
	m.Name = "BinCamera"
	local body = Instance.new("Part")
	body.Name = "Body"
	body.Size = Vector3.new(1.2, 0.9, 2)
	body.Color = rgb(30, 30, 34)
	body.Anchored, body.CanCollide = true, false
	body.CFrame = CFrame.new(CAMERA_SPOT) * CFrame.Angles(0, math.rad(35), math.rad(12))
	body.Parent = m
	local rec = Instance.new("Part")
	rec.Name = "RecLight"
	rec.Shape = Enum.PartType.Ball
	rec.Size = Vector3.new(0.3, 0.3, 0.3)
	rec.Color = rgb(255, 40, 30)
	rec.Material = Enum.Material.Neon
	rec.Anchored, rec.CanCollide, rec.CanQuery = true, false, false
	rec.CFrame = body.CFrame * CFrame.new(0.3, 0.5, -0.8)
	local glow = Instance.new("PointLight")
	glow.Color = rgb(255, 40, 30)
	glow.Range = 6
	glow.Brightness = 2
	glow.Parent = rec
	rec.Parent = m
	m.PrimaryPart = body
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = Text.UI.pickUp
	prompt.ObjectText = Text.Objects.binCamera
	prompt.HoldDuration = Config.CluePromptHold
	prompt.MaxActivationDistance = Config.PromptDistance + 4 -- it floats a few studs out in the reeds
	prompt.RequiresLineOfSight = false
	prompt.Triggered:Connect(function(player: Player)
		Director.PickUpCamera(player)
	end)
	prompt.Parent = body
	CollectionService:AddTag(m, Tags.BinCamera)
	m.Parent = Workspace:FindFirstChild("World") or Workspace
	camera = m
	cameraPicked = picked
	task.spawn(function()
		local on = true
		while m.Parent do
			on = not on
			rec.Transparency = if on then 0 else 0.9
			glow.Enabled = on
			task.wait(0.6)
		end
	end)
end

function Director.PickUpCamera(player: Player?)
	if not camera then
		return
	end
	camera:Destroy()
	camera = nil
	ReplicatedStorage:SetAttribute("BinTapes", true)
	Analytics.track("bin_camera", { by = player and player.Name or "?" })
	message(Text.Messages.binCamera)
	task.delay(4, message, Text.Messages.binTapesHint)
	if cameraPicked then
		cameraPicked:Fire()
	end
end

-- the whole of Night 1 after the shrine (beats 2-7). Stops quietly if the run changes under it.
local function night(my: number)
	local function alive(): boolean
		return run == my and GameState.GetPhase() == "Night1"
	end
	-- 2: Bà Thu at the shrine; Bin films it
	beat(2)
	if not Bin.Exists() then
		Bin.Spawn(FILM_SPOT)
	end
	task.spawn(Bin.StandAt, FILM_SPOT, THU_MAT)
	Dialogue.Play("bathu_night1")
	if not alive() then
		return
	end
	-- 3: the lanterns
	beat(3)
	Lanterns.DriftAll()
	if not alive() then
		return
	end
	-- 4: Bin wanders off
	beat(4)
	Dialogue.Bark("bin_wanders")
	Pace.wait(2)
	if not alive() then
		return
	end
	Bin.WanderOff()
	if not alive() then
		return
	end
	-- 5: trapped
	Pace.wait(3)
	if not alive() then
		return
	end
	beat(5)
	floodCauseway()
	message(Text.Messages.causewayFlooded)
	Pace.wait(4)
	if not alive() then
		return
	end
	-- 6: Bin's camera in the reeds; wait for someone to pick it up (a subtitle for the light if nobody has for a while)
	beat(6)
	local picked = Instance.new("BindableEvent")
	local got = false
	picked.Event:Connect(function()
		got = true
	end)
	spawnCamera(picked)
	local t0 = os.clock()
	local hinted = false
	while not got and alive() do
		if not hinted and os.clock() - t0 >= Pace.seconds(Config.BinCameraHintSeconds) then
			hinted = true
			Remotes.event(Remotes.Names.Sfx):FireAllClients("camera_beep", CAMERA_SPOT)
		end
		task.wait(0.25)
	end
	picked:Destroy()
	if not alive() then
		return
	end
	-- 7: the Open phase ("Find Bin." is its message)
	beat(7)
	GameState.SetPhase("Open")
end

-- dawn after the finale: the causeway is dry again
function Director.Dry()
	unflood()
end

function Director.State(): { [string]: any }
	return {
		beat = ReplicatedStorage:GetAttribute("Night1Beat"),
		bin = Bin.Exists(),
		binMode = Bin.Mode(),
		flooded = flood ~= nil,
		camera = camera ~= nil,
		tapes = ReplicatedStorage:GetAttribute("BinTapes") == true,
		windows = Lanterns.Windows(),
		lanterns = #(CollectionService:GetTagged(Tags.LanternStop)),
	}
end

function Director.Reset()
	run += 1
	secondDriftDone = false
	ReplicatedStorage:SetAttribute("Night1Beat", 0)
	ReplicatedStorage:SetAttribute("BinTapes", false)
	unflood()
	if camera then
		camera:Destroy()
		camera = nil
	end
end

local function onPhase(phase: string)
	if phase == "Arrival" then
		-- 1: Arrival with Bin
		run += 1
		ReplicatedStorage:SetAttribute("Night1Beat", 1)
		print("[Night1] beat 1")
		Analytics.track("night1_beat", { beat = 1 })
		Bin.Spawn()
		Bin.Follow()
		task.delay(2, function()
			if GameState.GetPhase() == "Arrival" then
				Dialogue.Bark("bin_arrival")
			end
		end)
	elseif phase == "Night1" then
		run += 1
		night(run)
	else
		Dialogue.Stop("bathu_night1") -- a jump out of Night 1 (debug) ends her scene
		if phase ~= "Open" then
			Dialogue.StopAll()
		end
	end
end

function Director.Init()
	ReplicatedStorage:SetAttribute("Night1Beat", 0)
	ReplicatedStorage:SetAttribute("BinTapes", false)
end

function Director.Start()
	GameState = require(script.Parent:WaitForChild("GameStateService"))
	Dialogue = require(script.Parent:WaitForChild("DialogueService"))
	Lanterns = require(script.Parent:WaitForChild("LanternService"))
	Bin = require(script.Parent:WaitForChild("BinService"))
	GameState.OnReset(Director.Reset)
	GameState.OnPhase(onPhase)
	-- §5.4: the lanterns go out again at 23:00 so players can watch a second time
	while true do
		task.wait(0.5)
		if
			not secondDriftDone
			and GameState.GetPhase() == "Open"
			and GameState.GetClock() >= Config.SecondLanternDriftHour
		then
			secondDriftDone = true
			print("[Lanterns] second drift (23:00)")
			task.spawn(Lanterns.DriftAll)
		end
	end
end

return Director
