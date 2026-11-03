--!strict
-- The letter, the walk to the steps, midnight and the three endings (PROTOTYPE_BRIEF §5.7, §7; gameplay.md).
--   Giving Bà Thu the letter: talk to her while holding it (Open phase). The players read it out; she cries,
--     finishes the paper fish and asks for the name: "Write: Sen". Then she walks through the lane, her back yard and
--     down the carp steps; players follow. At the bottom step the clock jumps to midnight: Về nhà.
--   Midnight without that, or everyone taken -> Im lặng: every lantern goes out and Sen takes the players one by one
--     (story.md §16). Ở lại (players at the carp steps choose: hold on, or let go) is cut; Config.StayEnding brings it back.
-- Each finale is a short scripted scene (camera shots on the clients through ReplicatedStorage attributes
-- FinaleCamPos / FinaleCamLook), then the Ending phase shows the teller's card and the playtest summary prints.

local CollectionService = game:GetService("CollectionService")
local PathfindingService = game:GetService("PathfindingService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Analytics = require(Shared:WaitForChild("Analytics"))
local Config = require(Shared:WaitForChild("Config"))
local Figures = require(Shared:WaitForChild("Figures"))
local Pace = require(Shared:WaitForChild("Pace"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Tags = require(Shared:WaitForChild("Tags"))

local EndingService = {}

local rgb = Color3.fromRGB
local GameState: any, Dialogue: any, Mystery: any, Bin: any, Director: any, Lanterns: any, Sen: any
local LAKE_CENTRE = Vector3.new(0, -1, -265)
local STEPS_BOTTOM = Vector3.new(350, -7.3, -16) -- the last carp step (World/Build.luau: cove)
local STEPS_TOP = Vector3.new(350, 1, 14)

local thuHome: CFrame? = nil
local letterGiven = false
local thuAtSteps = false
local walking = 0
local finale: Folder? = nil
local stayAnswers: { [Player]: boolean } = {}
local fin = 0 -- bumped by Reset: a finale that is still playing stops at its next pause
local running = 0
local ABORT = "finale aborted"

local function pause(s: number)
	Pace.wait(s)
	if fin ~= running then
		error(ABORT, 0)
	end
end

local function thu(): Model?
	return CollectionService:GetTagged(Tags.NpcBaThu)[1] :: Model?
end

local function shot(pos: Vector3, look: Vector3)
	ReplicatedStorage:SetAttribute("FinaleCamPos", pos)
	ReplicatedStorage:SetAttribute("FinaleCamLook", look)
end

local function setEnding(kind: string)
	ReplicatedStorage:SetAttribute("Ending", kind)
end

local function folder(): Folder
	if not finale then
		local f = Instance.new("Folder")
		f.Name = "Finale"
		f.Parent = Workspace:FindFirstChild("World") or Workspace
		finale = f
	end
	return finale :: Folder
end

local function holds(player: Player): boolean
	return Mystery.LetterHolder() == player
end

function EndingService.LetterGiven(): boolean
	return letterGiven
end

function EndingService.CanGiveLetter(player: Player): boolean
	return not letterGiven and holds(player) and GameState.GetPhase() == "Open"
end

-- Bà Thu walks from the shrine, along the lane, through her own back yard and down the carp steps
local function walkPath(from: Vector3): { Vector3 }
	local pts: { Vector3 } = {}
	local path = PathfindingService:CreatePath({ AgentRadius = 2, AgentHeight = 5, AgentCanJump = false, WaypointSpacing = 6 })
	local ok = pcall(function()
		path:ComputeAsync(from, STEPS_TOP)
	end)
	if ok and path.Status == Enum.PathStatus.Success then
		for _, w in path:GetWaypoints() do
			table.insert(pts, w.Position)
		end
	else
		warn("[Ending] no walking path for Bà Thu; she takes the lane")
		for _, p in { Vector3.new(-330, 1, -50), Vector3.new(-296, 0, -20), Vector3.new(272, 0, -20), Vector3.new(272, 0, 70),
			Vector3.new(330, 0, 70), Vector3.new(345, 0, 44), STEPS_TOP } do
			table.insert(pts, p)
		end
	end
	for k = 0, 6 do
		table.insert(pts, Vector3.new(350, 1 - k * 1.3, 8 - k * 4))
	end
	return pts
end

local function walkThu()
	walking += 1
	local my = walking
	local m = thu()
	if not m then
		return
	end
	local body = m.PrimaryPart :: BasePart
	local lift = body.Position.Y - 1 -- the body's height above the ground she sits/stands on
	local pts = walkPath(m:GetPivot().Position - Vector3.new(0, lift, 0))
	print(`[Ending] Bà Thu walks to the steps ({#pts} points)`)
	ReplicatedStorage:SetAttribute("ThuWalking", true)
	local pos = m:GetPivot().Position - Vector3.new(0, lift, 0)
	for _, target in pts do
		while walking == my and (target - pos).Magnitude > 0.3 do
			local dt = task.wait()
			local step = math.min(Config.ThuWalkSpeed * Pace.scale() * dt, (target - pos).Magnitude)
			pos += (target - pos).Unit * step
			local ahead = Vector3.new(target.X, pos.Y, target.Z)
			m:PivotTo(if (ahead - pos).Magnitude > 0.1 then CFrame.lookAt(pos + Vector3.new(0, lift, 0), ahead + Vector3.new(0, lift, 0))
				else CFrame.new(pos + Vector3.new(0, lift, 0)))
		end
		if walking ~= my then
			return
		end
	end
	ReplicatedStorage:SetAttribute("ThuWalking", false)
	thuAtSteps = true
	print("[Ending] Bà Thu reached the bottom step")
	Analytics.track("thu_at_steps")
	if GameState.GetPhase() == "Open" then
		setEnding("home")
		GameState.SetClock(Config.MidnightHour)
		GameState.SetPhase("Finale")
	end
end

-- §5.7: the letter given to Bà Thu
function EndingService.GiveLetter(player: Player)
	if not EndingService.CanGiveLetter(player) then
		return
	end
	letterGiven = true
	Analytics.track("letter_given", { by = player.Name })
	print("[Ending] the letter was given to Bà Thu")
	local done = Dialogue.Play("bathu_letter")
	if not done or GameState.GetPhase() ~= "Open" then
		return
	end
	Mystery.ConsumeLetter()
	ReplicatedStorage:SetAttribute("NameWritten", true)
	Analytics.track("name_written")
	walkThu()
end

-- everyone taken: Im lặng now
function EndingService.AllTaken()
	local phase = GameState.GetPhase()
	if phase == "Open" or phase == "Night1" then
		setEnding("silence")
		GameState.SetPhase("Finale")
	end
end

-- the finales -------------------------------------------------------------------------------------------------------
local function lanternParts(): { BasePart }
	local out = {}
	local w = Workspace:FindFirstChild("World")
	for _, d in (w and w:GetDescendants() or {}) do
		if d:IsA("BasePart") and d.Material == Enum.Material.Neon and (d.Name == "PaperLantern" or d.Name == "Glow" or d.Name == "HintLantern") then
			table.insert(out, d)
		end
	end
	return out
end

local function silence()
	setEnding("silence")
	shot(Vector3.new(-60, 12, -38), LAKE_CENTRE + Vector3.new(0, 4, 0))
	pause(2.5)
	-- every lantern on the lake goes out at once; every window goes dark
	for _, p in lanternParts() do
		p.Material = Enum.Material.SmoothPlastic
		p.Color = rgb(60, 50, 40)
		local l = p:FindFirstChildOfClass("PointLight")
		if l then
			l.Enabled = false
		end
	end
	for _, w in CollectionService:GetTagged(Tags.HouseWindow) do
		if w:IsA("BasePart") then
			w.Material = Enum.Material.Glass
			w.Color = rgb(30, 34, 40)
			local l = w:FindFirstChild("WindowLight")
			if l then
				l:Destroy()
			end
		end
	end
	print("[Ending] every lantern goes out")
	ReplicatedStorage:SetAttribute("FinaleStatic", false)
	pause(2)
	-- and Sen comes for them one by one
	for _, p in Players:GetPlayers() do
		if p:GetAttribute("Taken") ~= true then
			Sen.Take(p, true) -- quiet: no sting in the silence
			pause(Config.SilenceTakeGapSeconds)
		end
	end
	pause(1)
	ReplicatedStorage:SetAttribute("FinaleStatic", true) -- the clients fade to static
	Remotes.event(Remotes.Names.Sfx):FireAllClients("festival_static", nil)
	pause(Config.FinaleSilenceSeconds - 5.5)
end

local function riseAt(model: Model, from: number, to: number, seconds: number)
	task.spawn(function()
		local t0 = os.clock()
		local base = model:GetPivot()
		local my = fin
		while model.Parent and fin == my do
			local f = math.clamp((os.clock() - t0) / Pace.seconds(seconds), 0, 1)
			model:PivotTo(base + Vector3.new(0, (to - from) * f, 0))
			if f >= 1 then
				break
			end
			task.wait()
		end
	end)
end

local function moveTo(model: Model, to: Vector3, seconds: number)
	task.spawn(function()
		local t0 = os.clock()
		local start = model:GetPivot()
		local my = fin
		while model.Parent and fin == my do
			local f = math.clamp((os.clock() - t0) / Pace.seconds(seconds), 0, 1)
			model:PivotTo(start.Rotation + start.Position:Lerp(to, f))
			if f >= 1 then
				break
			end
			task.wait()
		end
	end)
end

local function home()
	setEnding("home")
	local f = folder()
	Remotes.event(Remotes.Names.Sfx):FireAllClients("finale_home", nil)
	-- the fish lantern goes out of the cove, past the reeds, to the middle where the lanterns gather
	shot(Vector3.new(350, 4, 4), Vector3.new(300, 0, -90))
	local fish = Instance.new("Model")
	fish.Name = "FishLantern"
	local fp = Instance.new("Part")
	fp.Name = "Glow"
	fp.Size = Vector3.new(0.8, 0.9, 1.8)
	fp.Color = rgb(255, 160, 80)
	fp.Material = Enum.Material.Neon
	fp.Anchored, fp.CanCollide = true, false
	fp.Position = Vector3.new(350, -0.4, -20)
	local light = Instance.new("PointLight")
	light.Color = rgb(255, 170, 100)
	light.Range = 20
	light.Brightness = 2
	light.Parent = fp
	fp.Parent = fish
	fish.PrimaryPart = fp
	fish.Parent = f
	moveTo(fish, LAKE_CENTRE + Vector3.new(14, 0.6, 10), 14)
	pause(6)
	shot(LAKE_CENTRE + Vector3.new(10, 6, 28), LAKE_CENTRE + Vector3.new(0, 2.5, 0))
	-- the gathered lanterns light the water around the middle
	for k = 0, 2 do
		local glow = Instance.new("Part")
		glow.Name = "LakeLight"
		glow.Transparency, glow.Anchored, glow.CanCollide, glow.CanQuery = 1, true, false, false
		glow.Position = LAKE_CENTRE + Vector3.new(-10 + k * 10, 4, 6)
		local l = Instance.new("PointLight")
		l.Color = rgb(255, 180, 110)
		l.Range = 24
		l.Brightness = 1.6
		l.Parent = glow
		glow.Parent = f
	end
	-- the lanterns gather; the water moves; Sen comes up holding hands with every child she took
	for k = 1, 36 do
		local a = k / 36 * math.pi * 2
		local p = Instance.new("Part")
		p.Name = "Glow"
		p.Shape = Enum.PartType.Ball
		p.Size = Vector3.new(1.3, 1.3, 1.3)
		p.Color = rgb(255, 170, 90)
		p.Material = Enum.Material.Neon
		p.Anchored, p.CanCollide = true, false
		p.Position = LAKE_CENTRE + Vector3.new(math.cos(a) * (18 + k % 3 * 6), 0.6, math.sin(a) * (14 + k % 4 * 5))
		p.Parent = f
	end
	pause(8)
	local row = Instance.new("Model")
	row.Name = "Children"
	row.Parent = f
	local face = CFrame.lookAt(LAKE_CENTRE, LAKE_CENTRE + Vector3.new(0, 0, 1))
	Figures.Sen(face + Vector3.new(0, -4, 0), row, 6)
	local names = { { "Minh", 4.2 }, { "Hạnh", 3.8 }, { "Tí", 3.3 }, { "Khoa", 4.4 }, { "Bin", 5 } }
	for i, c in names do
		local x = (if i % 2 == 0 then 1 else -1) * (2.2 * math.ceil(i / 2))
		Figures.Child(face * CFrame.new(x, -4 + c[2] * 0.25, 0), c[1], c[2], row)
	end
	-- lit by the gathered lanterns, so they read as children and not as dark shapes (her face stays under her hair)
	local rim = Instance.new("Highlight")
	rim.DepthMode = Enum.HighlightDepthMode.Occluded
	rim.FillColor, rim.FillTransparency = rgb(255, 190, 130), 0.8
	rim.OutlineColor, rim.OutlineTransparency = rgb(255, 215, 170), 0.35
	rim.Parent = row
	local lamp = Instance.new("Part")
	lamp.Name = "Lamp"
	lamp.Transparency, lamp.Anchored, lamp.CanCollide, lamp.CanQuery = 1, true, false, false
	lamp.Size = Vector3.new(0.2, 0.2, 0.2)
	lamp.CFrame = face * CFrame.new(0, -1, -7)
	local warm = Instance.new("PointLight")
	warm.Color, warm.Range, warm.Brightness = rgb(255, 180, 120), 14, 1.5
	warm.Parent = lamp
	lamp.Parent = row
	riseAt(row, 0, 3.6, 4)
	print("[Ending] Sen comes up, holding hands with Minh, Hạnh, Tí, Khoa and Bin")
	pause(5)
	-- Thu walks down the steps and out onto the water, and takes her daughter's hand
	local m = thu()
	if m then
		m:PivotTo(CFrame.lookAt(LAKE_CENTRE + Vector3.new(0, 2.4, 40), LAKE_CENTRE + Vector3.new(0, 2.4, 0)))
		moveTo(m, LAKE_CENTRE + Vector3.new(0, 2.4, 2.5), 6)
	end
	Mystery.SpawnCarp(LAKE_CENTRE + Vector3.new(0, 1, 0), 90, 34, 30)
	pause(7)
	print("[Ending] Bà Thu takes her daughter's hand")
	-- the carp carry every lantern across the lake; mother and girl follow the paper fish out into the dark
	for _, p in f:GetChildren() do
		if p:IsA("BasePart") then
			local start = p.Position
			task.spawn(function()
				local t0 = os.clock()
				while p.Parent do
					local k = math.clamp((os.clock() - t0) / Pace.seconds(10), 0, 1)
					p.Position = start + Vector3.new(0, 0, -160 * k)
					if k >= 1 then
						break
					end
					task.wait()
				end
			end)
		end
	end
	moveTo(fish, LAKE_CENTRE + Vector3.new(0, 0.6, -170), 10)
	moveTo(row, row:GetPivot().Position + Vector3.new(0, 0, -150), 10)
	if m then
		moveTo(m, LAKE_CENTRE + Vector3.new(0, 2.4, -148), 10)
	end
	pause(8)
	-- dawn: the causeway dry, Bin asleep on the bank with his camera, the radio in the quiet house clicks off
	ReplicatedStorage:SetAttribute("FinaleFade", true)
	pause(1.5)
	GameState.SetClock(6.3)
	Director.Dry()
	Bin.SpawnAsleep(Vector3.new(-120, 0, -46))
	Remotes.event(Remotes.Names.Sfx):FireAllClients("radio_off", nil)
	shot(Vector3.new(-112, 5, -36), Vector3.new(-120, 0.5, -46))
	ReplicatedStorage:SetAttribute("FinaleFade", false)
	pause(4)
end

local function stay(atSteps: { Player })
	setEnding("stay")
	shot(Vector3.new(350, 6, 16), Vector3.new(350, -1, -13))
	local f = folder()
	local sen = Figures.Sen(CFrame.lookAt(Vector3.new(350, -5, -13), Vector3.new(350, -5, 2)), f, 24)
	riseAt(sen, 0, 3.9, 3)
	pause(3.5)
	print(`[Ending] Sen reaches up at the steps ({#atSteps} there)`)
	table.clear(stayAnswers)
	for _, p in atSteps do
		Remotes.event(Remotes.Names.StayChoice):FireClient(p, true, Pace.seconds(Config.StayChoiceSeconds))
	end
	local t0 = os.clock()
	while os.clock() - t0 < Pace.seconds(Config.StayChoiceSeconds) do
		local all = true
		for _, p in atSteps do
			if stayAnswers[p] == nil and p.Parent then
				all = false
			end
		end
		if all then
			break
		end
		task.wait(0.1)
	end
	local held = {}
	for _, p in atSteps do
		Remotes.event(Remotes.Names.StayChoice):FireClient(p, false)
		if stayAnswers[p] == true then
			table.insert(held, p)
		end
	end
	Analytics.track("stay_choice", { held = #held, at = #atSteps })
	if #held == 0 then
		-- everyone pulls away from Sen: Im lặng (gameplay.md)
		sen:Destroy()
		print("[Ending] everyone let go")
		silence()
		return
	end
	for _, p in held do
		p:SetAttribute("Taken", true)
		p:SetAttribute("TakenFinal", true)
		p:SetAttribute("Stayed", true)
		Remotes.event(Remotes.Names.Fade):FireClient(p, 2)
	end
	print(`[Ending] {#held} held on; Bin goes free`)
	riseAt(sen, 3.9, -2, 4)
	pause(5)
	ReplicatedStorage:SetAttribute("FinaleFade", true)
	pause(1.5)
	GameState.SetClock(6.3)
	Director.Dry()
	Bin.SpawnAsleep(Vector3.new(-120, 0, -46))
	shot(Vector3.new(-112, 5, -36), Vector3.new(-120, 0.5, -46))
	ReplicatedStorage:SetAttribute("FinaleFade", false)
	pause(Config.FinaleStaySeconds - 14)
end

local function atTheSteps(): { Player }
	local out = {}
	for _, p in Players:GetPlayers() do
		local r = p.Character and p.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if r and p:GetAttribute("Taken") ~= true
			and (r.Position * Vector3.new(1, 0, 1) - Vector3.new(350, 0, -2)).Magnitude <= Config.StayRadius then
			table.insert(out, p)
		end
	end
	return out
end

local function playFinale()
	local kind = ReplicatedStorage:GetAttribute("Ending")
	if kind == nil and not thuAtSteps and ReplicatedStorage:GetAttribute("NameWritten") == true then
		-- the name was written but midnight came while she was still on her way: she is at the steps (Về nhà, not Im lặng)
		local m = thu()
		if m and m.PrimaryPart then
			local lift = (m.PrimaryPart :: BasePart).Position.Y - 1
			local pts = walkPath(m:GetPivot().Position - Vector3.new(0, lift, 0))
			local last = pts[#pts]
			if last then
				m:PivotTo(CFrame.new(last + Vector3.new(0, lift, 0)))
			end
		end
		ReplicatedStorage:SetAttribute("ThuWalking", false)
		thuAtSteps = true
	end
	if kind == nil then
		local there = atTheSteps()
		kind = if thuAtSteps then "home" elseif Config.StayEnding and #there > 0 then "stay" else "silence"
		setEnding(kind :: string)
		if kind == "stay" then
			stay(there)
		elseif kind == "home" then
			home()
		else
			silence()
		end
	elseif kind == "home" then
		home()
	else
		silence()
	end
	print(`[Ending] {ReplicatedStorage:GetAttribute("Ending")}`)
	if GameState.GetPhase() == "Finale" then
		GameState.SetPhase("Ending")
	end
end

local function runFinale()
	running = fin
	local ok, err = pcall(playFinale)
	if not ok and err ~= ABORT then
		warn(`[Ending] the finale failed: {err}`)
		if GameState.GetPhase() == "Finale" then
			GameState.SetPhase("Ending")
		end
	end
end

function EndingService.Reset()
	walking += 1
	fin += 1
	letterGiven = false
	thuAtSteps = false
	table.clear(stayAnswers)
	for _, a in { "Ending", "NameWritten", "ThuWalking", "FinaleCamPos", "FinaleCamLook", "FinaleStatic", "FinaleFade" } do
		ReplicatedStorage:SetAttribute(a, nil)
	end
	if finale then
		finale:Destroy()
		finale = nil
	end
	local m = thu()
	if m and thuHome then
		m:PivotTo(thuHome)
	end
	-- lanterns that went out in Im lặng come back (the world isn't rebuilt between runs)
	local w = Workspace:FindFirstChild("World")
	for _, d in (w and w:GetDescendants() or {}) do
		if d:IsA("BasePart") and d.Name == "PaperLantern" and d:FindFirstChildOfClass("PointLight") then
			d.Material = Enum.Material.Neon
			d.Color = rgb(255, 170, 90)
			d:FindFirstChildOfClass("PointLight").Enabled = true
		end
	end
	for _, p in Players:GetPlayers() do
		p:SetAttribute("Stayed", nil)
	end
end

function EndingService.State(): { [string]: any }
	return { letterGiven = letterGiven, thuAtSteps = thuAtSteps, walking = ReplicatedStorage:GetAttribute("ThuWalking") == true,
		ending = ReplicatedStorage:GetAttribute("Ending"), nameWritten = ReplicatedStorage:GetAttribute("NameWritten") == true }
end

function EndingService.AnswerStay(p: Player, hold: boolean)
	if stayAnswers[p] == nil then
		stayAnswers[p] = hold
	end
end

function EndingService.Init()
	Remotes.event(Remotes.Names.StayChoice).OnServerEvent:Connect(function(p: Player, hold: any)
		if typeof(hold) == "boolean" then
			EndingService.AnswerStay(p, hold)
		end
	end)
end

function EndingService.Start()
	GameState = require(script.Parent:WaitForChild("GameStateService"))
	Dialogue = require(script.Parent:WaitForChild("DialogueService"))
	Mystery = require(script.Parent:WaitForChild("MysteryService"))
	Bin = require(script.Parent:WaitForChild("BinService"))
	Director = require(script.Parent:WaitForChild("NightOneDirector"))
	Lanterns = require(script.Parent:WaitForChild("LanternService"))
	Sen = require(script.Parent:WaitForChild("SenService"))
	local m = thu()
	thuHome = m and m:GetPivot()
	GameState.OnReset(EndingService.Reset)
	GameState.OnPhase(function(phase: string)
		if phase == "Finale" then
			walking += 1
			runFinale()
		elseif phase == "Ending" then
			Analytics.summary(ReplicatedStorage:GetAttribute("Ending") or "silence")
		end
	end)
end

return EndingService
