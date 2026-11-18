--!strict
-- The mystery's moving parts (PROTOTYPE_BRIEF §5.1, §5.4, §5.7, §6):
--   Mementos: a "Pick up" prompt on each lost child's memento plays that child's memory for the player who took it.
--   The letter: "Look under the altar" in Sen's house (hold 1.5 s) gives the letter, a carried item (a Tool): one per
--     run; whoever holds it can drop it (Backspace) for someone else to pick up. A taken holder drops it (SenService).
--   The stuck hint: if the group finds no new clue for 240 s, the window of the nearest house with clues still to
--     find flickers and a lantern pulses on the water near it. Taken players can fire the same flicker (§5.6).
--   The carp: they rise around the bottom of the carp steps when someone climbs down (§6), and gather for Sen (§5.5).

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Analytics = require(Shared:WaitForChild("Analytics"))
local Clues = require(Shared:WaitForChild("Content"):WaitForChild("Clues"))
local Config = require(Shared:WaitForChild("Config"))
local Mementos = require(Shared:WaitForChild("Content"):WaitForChild("Mementos"))
local Pace = require(Shared:WaitForChild("Pace"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Tags = require(Shared:WaitForChild("Tags"))
local Text = require(Shared:WaitForChild("Content"):WaitForChild("Text"))

local MysteryService = {}

local rgb = Color3.fromRGB
local GameState: any, ClueService: any
local letterFound = false
local letterTool: Tool? = nil
local mementosSeen: { [string]: boolean } = {}
local lastProgress = os.clock() -- the last time the group found something new (or a hint fired)
local carpCooldown = 0
local hintFolder: Folder? = nil

local function world(): Instance
	return Workspace:FindFirstChild("World") or Workspace
end

local function location(name: string): Model?
	for _, m in CollectionService:GetTagged(Tags.Location) do
		if m:GetAttribute("Location") == name and m:IsA("Model") then
			return m
		end
	end
	return nil
end

-- carp: small orange-gold fish shapes circling in the water around a point, for a while ---------------------------
function MysteryService.SpawnCarp(center: Vector3, count: number, radius: number, seconds: number)
	local f = Instance.new("Folder")
	f.Name = "Carp"
	f.Parent = world()
	local fish = {}
	for k = 1, count do
		local p = Instance.new("Part")
		p.Name = "Carp"
		p.Shape = Enum.PartType.Ball
		p.Size = Vector3.new(0.6, 0.45, 1.6)
		p.Color = if k % 3 == 0 then rgb(230, 230, 220) else rgb(225, 130, 40)
		p.Material = Enum.Material.SmoothPlastic
		p.Anchored, p.CanCollide, p.CanQuery = true, false, false
		p.Parent = f
		table.insert(fish, {
			part = p,
			a = math.random() * math.pi * 2,
			r = radius * (0.4 + math.random() * 0.6),
			s = 0.4 + math.random() * 0.5,
		})
	end
	Remotes.event(Remotes.Names.Sfx):FireAllClients("carp_splash", center)
	task.spawn(function()
		local t0 = os.clock()
		while f.Parent and os.clock() - t0 < Pace.seconds(seconds) do
			local dt = task.wait(1 / 15)
			for _, c in fish do
				c.a += c.s * dt
				local pos = center + Vector3.new(math.cos(c.a) * c.r, -1.25, math.sin(c.a) * c.r)
				c.part.CFrame = CFrame.lookAt(pos, pos + Vector3.new(-math.sin(c.a), 0, math.cos(c.a)))
			end
		end
		f:Destroy()
	end)
	return f
end

-- mementos -------------------------------------------------------------------------------------------------------------
function MysteryService.ViewMemento(player: Player, id: string)
	local m = Mementos[id]
	if not m then
		return
	end
	if not mementosSeen[id] then
		mementosSeen[id] = true
		Analytics.track("memento_viewed", { child = m.child, by = player.Name })
	end
	Remotes.event(Remotes.Names.Memento):FireClient(player, id)
end

local function mementoPrompt(inst: Instance)
	local id = inst:GetAttribute("MementoId")
	local part = if inst:IsA("BasePart") then inst else inst:FindFirstChildWhichIsA("BasePart", true)
	if typeof(id) ~= "string" or not part or part:FindFirstChildOfClass("ProximityPrompt") or not Mementos[id] then
		return
	end
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = Text.UI.pickUp
	prompt.ObjectText = Mementos[id].object
	prompt.HoldDuration = Config.CluePromptHold
	prompt.MaxActivationDistance = Config.PromptDistance
	prompt.RequiresLineOfSight = false
	prompt.Triggered:Connect(function(player: Player)
		MysteryService.ViewMemento(player, id)
	end)
	prompt.Parent = part
end

-- the letter -----------------------------------------------------------------------------------------------------------
local function makeLetter(): Tool
	local tool = Instance.new("Tool")
	tool.Name = "Letter"
	tool.ToolTip = Text.UI.letter
	tool.CanBeDropped = true
	tool.RequiresHandle = true
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.8, 0.05, 1)
	handle.Color = rgb(226, 214, 186)
	handle.CanCollide = false
	handle.Parent = tool
	tool:SetAttribute("LangVongLetter", true)
	tool.Activated:Connect(function()
		local holder = Players:GetPlayerFromCharacter(tool.Parent)
		if holder then
			Remotes.event(Remotes.Names.InspectClue):FireClient(holder, "sen_letter")
		end
	end)
	return tool
end

function MysteryService.LetterHolder(): Player?
	if not letterTool then
		return nil
	end
	local parent = letterTool.Parent
	if parent and parent:IsA("Backpack") then
		return parent.Parent :: Player
	end
	return parent and Players:GetPlayerFromCharacter(parent) or nil
end

function MysteryService.LetterFound(): boolean
	return letterFound
end

-- a letter on the ground lies still where it landed (its handle doesn't collide, so loose it would fall through
-- the world); picked up, it is loose again
local function settle(tool: Tool)
	local handle = tool:FindFirstChild("Handle") :: BasePart?
	if not handle then
		return
	end
	local parent = tool.Parent
	if parent and not parent:IsA("Backpack") and not parent:FindFirstChildOfClass("Humanoid") then -- (Workspace is a Model too)
		local params = RaycastParams.new()
		params.FilterDescendantsInstances = { tool }
		params.IgnoreWater = false
		params.RespectCanCollide = true -- not the invisible zones
		local from = handle.Position + Vector3.new(0, 3, 0)
		local hit = Workspace:Raycast(from, Vector3.new(0, -60, 0), params)
		handle.Anchored = true
		handle.CFrame = CFrame.new(if hit then hit.Position + Vector3.new(0, 0.1, 0) else handle.Position)
	else
		handle.Anchored = false
	end
end

local function altarsOn()
	for _, altar in CollectionService:GetTagged(Tags.SenAltar) do
		local p = altar:FindFirstChild("LookUnder") :: ProximityPrompt?
		if p then
			p.Enabled = true
		end
	end
end

function MysteryService.TakeLetter(player: Player)
	if letterFound then
		return
	end
	letterFound = true
	local tool = makeLetter()
	letterTool = tool
	tool.AncestryChanged:Connect(function()
		if letterTool ~= tool then
			return
		end
		if tool:IsDescendantOf(game) then
			settle(tool)
		else
			-- lost some other way (fell out of the world): it is back under Sen's altar, as if never taken
			letterTool = nil
			letterFound = false
			altarsOn()
			print("[Mystery] the letter was lost; it is back under the altar")
		end
	end)
	tool.Parent = player:FindFirstChildOfClass("Backpack") or player
	Analytics.track("letter_found", {
		t = math.floor(os.clock() - (ReplicatedStorage:GetAttribute("RunStart") or os.clock()) :: number),
		by = player.Name,
	})
	ClueService.Inspect(player, "sen_letter")
	print("[Mystery] the letter was found")
end

-- drop the letter where this player stands (taken) ----------------------------------------------------------------------
function MysteryService.DropLetter(player: Player, at: Vector3)
	if letterTool and MysteryService.LetterHolder() == player then
		local tool = letterTool :: Tool
		local handle = tool:FindFirstChild("Handle") :: BasePart?
		if handle then
			handle.CFrame = CFrame.new(at + Vector3.new(0, 0.5, 0))
		end
		tool.Parent = world() -- settle() puts it on the ground
		print("[Mystery] the letter dropped")
	end
end

function MysteryService.ConsumeLetter()
	local tool = letterTool
	letterTool = nil -- first, so its AncestryChanged doesn't send it back to the altar
	if tool then
		tool:Destroy()
	end
end

-- whoever holds the letter and leaves or dies drops it where they stood (it would go with them otherwise)
local function dropFrom(p: Player)
	local root = p.Character and p.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if root and MysteryService.LetterHolder() == p then
		MysteryService.DropLetter(p, root.Position - Vector3.new(0, 2.5, 0))
	end
end

local function altarPrompt(altar: Instance)
	if not altar:IsA("BasePart") or altar:FindFirstChildOfClass("ProximityPrompt") then
		return
	end
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "LookUnder"
	prompt.ActionText = Text.UI.lookUnder
	prompt.ObjectText = Text.Objects.altar
	prompt.HoldDuration = Config.AltarPromptHold
	prompt.MaxActivationDistance = Config.PromptDistance
	prompt.RequiresLineOfSight = false
	prompt.Triggered:Connect(function(player: Player)
		if not letterFound then
			MysteryService.TakeLetter(player)
			prompt.Enabled = false
		end
	end)
	prompt.Parent = altar
end

-- hints -----------------------------------------------------------------------------------------------------------------
-- houses (Locations) that still have unfound clues, nearest first to a point
local function unfoundPlaces(): { string }
	local found = {}
	for _, id in ClueService.Found() do
		found[id] = true
	end
	local places, seen = {}, {}
	for id, clue in Clues do
		if not found[id] and id ~= "sen_letter" and not seen[clue.location] then
			seen[clue.location] = true
			table.insert(places, clue.location)
		end
	end
	if not letterFound and not seen.SenHouse then
		table.insert(places, "SenHouse")
	end
	return places
end

local function groupCentre(): Vector3?
	local sum, n = Vector3.zero, 0
	for _, p in Players:GetPlayers() do
		local r = p.Character and p.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if r and p:GetAttribute("Taken") ~= true then
			sum += r.Position
			n += 1
		end
	end
	return if n > 0 then sum / n else nil
end

-- flicker the window of the nearest place with something left to find, and pulse a lantern on the water near it
function MysteryService.Hint(reason: string): string?
	local centre = groupCentre() or Vector3.new(-296, 0, -20)
	local best, bestD = nil, math.huge
	for _, name in unfoundPlaces() do
		local m = location(name)
		if m then
			local d = (m:GetPivot().Position - centre).Magnitude
			if d < bestD then
				best, bestD = name, d
			end
		end
	end
	if not best then
		return nil
	end
	local place = best :: string
	lastProgress = os.clock()
	Analytics.track("hint_fired", { house = place, reason = reason })
	print(`[Hint] {place} ({reason})`)
	if hintFolder then
		hintFolder:Destroy()
	end
	local f = Instance.new("Folder")
	f.Name = "Hint"
	f.Parent = world()
	hintFolder = f
	-- the window (Sen's never lights: only its lantern pulses)
	local window: BasePart? = nil
	for _, w in CollectionService:GetTagged(Tags.HouseWindow) do
		if w:GetAttribute("House") == place and place ~= "SenHouse" then
			window = w :: BasePart
		end
	end
	local m = location(place) :: Model
	local pos = m:GetPivot().Position
	local water = Vector3.new(pos.X, Config.LanternFloatY, math.min(pos.Z, -50) - 8)
	local lantern = Instance.new("Part")
	lantern.Name = "HintLantern"
	lantern.Shape = Enum.PartType.Ball
	lantern.Size = Vector3.new(1.4, 1.4, 1.4)
	lantern.Color = rgb(255, 170, 90)
	lantern.Material = Enum.Material.Neon
	lantern.Anchored, lantern.CanCollide, lantern.CanQuery = true, false, false
	lantern.Position = water + Vector3.new(0, 0.8, 0)
	local light = Instance.new("PointLight")
	light.Color = rgb(255, 170, 100)
	light.Range = 18
	light.Parent = lantern
	lantern.Parent = f
	f:SetAttribute("Place", place)
	task.spawn(function()
		local t0 = os.clock()
		-- the window's own look, kept on it until the last flicker ends (a second hint started mid-flicker used to take
		-- the flicker as the original and leave the window stuck dark or glowing)
		if window then
			if (window:GetAttribute("HintFlickers") or 0) == 0 then
				window:SetAttribute("HintMat", window.Material.Name)
				window:SetAttribute("HintColor", window.Color)
			end
			window:SetAttribute("HintFlickers", (window:GetAttribute("HintFlickers") or 0) + 1)
		end
		while f.Parent and os.clock() - t0 < Pace.seconds(Config.HintFlickerSeconds) do
			local on = math.random() < 0.5
			if window then
				window.Material = if on then Enum.Material.Neon else Enum.Material.Glass
				window.Color = if on then rgb(255, 196, 120) else rgb(60, 50, 40)
			end
			light.Brightness = if on then 3 else 0.6
			lantern.Size = Vector3.one * (if on then 1.8 else 1.2)
			task.wait(0.12 + math.random() * 0.2)
		end
		if window then
			local left = (window:GetAttribute("HintFlickers") or 1) - 1
			window:SetAttribute("HintFlickers", left)
			if left <= 0 then
				local mat = window:GetAttribute("HintMat")
				window.Material = if typeof(mat) == "string" then (Enum.Material :: any)[mat] else window.Material
				window.Color = window:GetAttribute("HintColor") or window.Color
				window:SetAttribute("HintMat", nil)
				window:SetAttribute("HintColor", nil)
			end
		end
		f:Destroy()
	end)
	return place
end

function MysteryService.State(): { [string]: any }
	local holder = MysteryService.LetterHolder()
	return {
		letterFound = letterFound,
		letterHolder = holder and holder.Name or nil,
		mementos = mementosSeen,
		hint = hintFolder and hintFolder.Parent and hintFolder:GetAttribute("Place") or nil,
		unfound = unfoundPlaces(),
	}
end

function MysteryService.Progress()
	lastProgress = os.clock()
end

function MysteryService.Reset()
	letterFound = false
	MysteryService.ConsumeLetter()
	table.clear(mementosSeen)
	lastProgress = os.clock()
	altarsOn()
	for _, d in world():GetChildren() do
		if d.Name == "Carp" or d.Name == "Hint" then
			d:Destroy()
		end
	end
	ReplicatedStorage:SetAttribute("RunStart", os.clock())
end

function MysteryService.Init()
	Remotes.event(Remotes.Names.Memento)
	ReplicatedStorage:SetAttribute("RunStart", os.clock())
end

function MysteryService.Start()
	GameState = require(script.Parent:WaitForChild("GameStateService"))
	ClueService = require(script.Parent:WaitForChild("ClueService"))
	GameState.OnReset(MysteryService.Reset)
	for _, inst in CollectionService:GetTagged(Tags.Memento) do
		mementoPrompt(inst)
	end
	CollectionService:GetInstanceAddedSignal(Tags.Memento):Connect(mementoPrompt)
	for _, altar in CollectionService:GetTagged(Tags.SenAltar) do
		altarPrompt(altar)
	end
	Remotes.event(Remotes.Names.ClueFound) -- (made by ClueService too; we only listen)
	ClueService.OnFound(MysteryService.Progress)
	local function watch(p: Player)
		p.CharacterAdded:Connect(function(char)
			local h = char:WaitForChild("Humanoid", 10) :: Humanoid?
			if h then
				h.Died:Connect(function()
					dropFrom(p)
				end)
			end
		end)
	end
	Players.PlayerAdded:Connect(watch)
	for _, p in Players:GetPlayers() do
		watch(p)
		if p.Character then
			local h = p.Character:FindFirstChildOfClass("Humanoid")
			if h then
				h.Died:Connect(function()
					dropFrom(p)
				end)
			end
		end
	end
	Players.PlayerRemoving:Connect(dropFrom)
	local steps = location("CarpSteps")
	local bottom = Vector3.new(350, 0, -16)
	while true do
		task.wait(0.5)
		local phase = GameState.GetPhase()
		-- the stuck hint, only in the Open phase
		if phase == "Open" and os.clock() - lastProgress >= Pace.seconds(Config.HintAfterSeconds) then
			MysteryService.Hint("stuck")
		elseif phase ~= "Open" then
			lastProgress = os.clock()
		end
		-- the carp come up to the steps when someone climbs down (§6)
		if steps and os.clock() > carpCooldown then
			for _, p in Players:GetPlayers() do
				local r = p.Character and p.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
				local q = r and r.Position
				-- on the steps themselves (World/Build.luau: x 346.5-353.5, from z 10 down to z -18)
				if
					q
					and math.abs(q.X - 350) <= Config.CarpStepsRadius / 2
					and q.Z <= 10
					and q.Z >= -18
					and q.Y < 3.5
				then
					carpCooldown = os.clock() + Pace.seconds(40)
					MysteryService.SpawnCarp(bottom + Vector3.new(0, 0, -4), 10, 7, 30)
					print("[Mystery] the carp rise at the steps")
					break
				end
			end
		end
	end
end

return MysteryService
