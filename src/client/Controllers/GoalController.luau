--!strict
-- The goal line, the counts, the rules, the recap (release council 11-03 B1, B2, B5; owner's yes 11-04).
--   Goal: top left, the server's ReplicatedStorage.Goal (Text.Goals); while this player is taken, their own line.
--   Counts under it: clues, mementos, incense left.
--   Rules: each taught once a run, on the message line, the first time it matters (the Open phase, the first warning,
--     the shrine, a friend taken).
--   Recap: after the ending's card, what the night came to; then the run server sends everyone to the menu.

local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Remotes"))
local Tags = require(Shared:WaitForChild("Tags"))
local Text = require(Shared:WaitForChild("Content"):WaitForChild("Text"))

local GoalController = {}

local lp = Players.LocalPlayer
local rgb = Color3.fromRGB
local UI: any
local frame: Frame
local goalLabel: TextLabel
local countsLabel: TextLabel
local recapPanel: Frame
local recapText: TextLabel
local taught: { [string]: boolean } = {}

local function new(class: string, props: { [string]: any }): any
	local inst = Instance.new(class)
	for k, v in props do
		if k ~= "Parent" then
			(inst :: any)[k] = v
		end
	end
	inst.Parent = props.Parent
	return inst
end

local function teach(key: string, ...: any)
	if taught[key] then
		return
	end
	taught[key] = true
	local line = (Text.Rules :: any)[key]
	if line then
		UI.Message(if select("#", ...) > 0 then string.format(line, ...) else line, 9)
	end
end

local function solo(): boolean
	return #Players:GetPlayers() == 1
end

local function goalText(): string
	if lp:GetAttribute("Taken") == true then
		return if lp:GetAttribute("TakenFinal") == true
			then Text.Goals.takenFinal
			elseif solo() then Text.Goals.takenSolo
			else Text.Goals.takenTeam
	end
	local key = ReplicatedStorage:GetAttribute("Goal")
	return if typeof(key) == "string" and key ~= "" then ((Text.Goals :: any)[key] or "") else ""
end

local lastGoal = ""
local function refresh()
	local phase = ReplicatedStorage:GetAttribute("Phase")
	local g = goalText()
	local show = g ~= ""
		and lp:GetAttribute("InRun") == true
		and lp:GetAttribute("SenCinematic") ~= true
		and not (UI.viewfinder and UI.viewfinder.Visible) -- (top right: the chat window has the top left)
	frame.Visible = show
	if not show then
		return
	end
	goalLabel.Text = g
	if g ~= lastGoal then
		lastGoal = g
		-- a new goal: it glows for a moment
		goalLabel.TextColor3 = rgb(255, 214, 150)
		TweenService:Create(goalLabel, TweenInfo.new(2.5), { TextColor3 = rgb(240, 232, 214) }):Play()
	end
	if phase == "Open" or phase == "Finale" then
		countsLabel.Visible = true
		countsLabel.Text = string.format(
			Text.Goals.counts,
			(ReplicatedStorage:GetAttribute("CluesFound") :: number?) or 0,
			(ReplicatedStorage:GetAttribute("CluesTotal") :: number?) or 0,
			(ReplicatedStorage:GetAttribute("MementosFound") :: number?) or 0,
			(ReplicatedStorage:GetAttribute("MementosTotal") :: number?) or 0,
			(lp:GetAttribute("Incense") :: number?) or 0
		)
	else
		countsLabel.Visible = false
	end
end

local function inShrine(): boolean
	local root = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return false
	end
	for _, z in CollectionService:GetTagged(Tags.ShrineZone) do
		if z:IsA("BasePart") then
			local rel = z.CFrame:PointToObjectSpace(root.Position)
			local half = z.Size / 2
			if math.abs(rel.X) <= half.X and math.abs(rel.Y) <= half.Y and math.abs(rel.Z) <= half.Z then
				return true
			end
		end
	end
	return false
end

local function showRecap()
	local raw = ReplicatedStorage:GetAttribute("Recap")
	if typeof(raw) ~= "string" or raw == "" or ReplicatedStorage:GetAttribute("Phase") ~= "Ending" then
		recapPanel.Visible = false
		return
	end
	local ok, r = pcall(HttpService.JSONDecode, HttpService, raw)
	if not ok or typeof(r) ~= "table" then
		return
	end
	local R = Text.Recap
	local lines = {
		string.format(R.clues, r.clues or 0, r.cluesTotal or 0),
		string.format(R.mementos, r.mementos or 0, r.mementosTotal or 0),
		if r.letter then R.letter else R.noLetter,
		if typeof(r.taken) == "table" and #r.taken > 0
			then string.format(R.taken, table.concat(r.taken, ", "))
			else R.nobody,
		string.format(R.minutes, r.minutes or 1),
		"",
		if ReplicatedStorage:GetAttribute("ServerKind") == "Run" then R.backSoon else R.again,
	}
	recapText.Text = table.concat(lines, "\n")
	local card = UI.Gui():FindFirstChild("Card") -- (the ending's card is read by now: the recap takes its place, not over it)
	if card then
		(card :: GuiObject).Visible = false
	end
	recapPanel.Visible = true
end

function GoalController.Start()
	UI = require(script.Parent:WaitForChild("UIController"))
	local gui = UI.Gui()
	frame = new("Frame", {
		Name = "Goal",
		Size = UDim2.fromOffset(0, 0),
		AutomaticSize = Enum.AutomaticSize.XY,
		Position = UDim2.new(1, -20, 0, 64),
		AnchorPoint = Vector2.new(1, 0),
		BackgroundColor3 = rgb(10, 12, 16),
		BackgroundTransparency = 0.4,
		Visible = false,
		ZIndex = 5,
		Parent = gui,
	})
	new("UICorner", { CornerRadius = UDim.new(0, 8), Parent = frame })
	new("UIPadding", {
		PaddingLeft = UDim.new(0, 14),
		PaddingRight = UDim.new(0, 14),
		PaddingTop = UDim.new(0, 8),
		PaddingBottom = UDim.new(0, 8),
		Parent = frame,
	})
	new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 2), Parent = frame })
	new("UISizeConstraint", { MaxSize = Vector2.new(420, 400), Parent = frame })
	goalLabel = new("TextLabel", {
		Name = "Text",
		Size = UDim2.fromOffset(0, 0),
		AutomaticSize = Enum.AutomaticSize.XY,
		BackgroundTransparency = 1,
		TextColor3 = rgb(240, 232, 214),
		Font = Enum.Font.Garamond,
		TextSize = 22,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = 1,
		ZIndex = 5,
		Text = "",
		Parent = frame,
	})
	new("UISizeConstraint", { MaxSize = Vector2.new(392, 200), Parent = goalLabel })
	countsLabel = new("TextLabel", {
		Name = "Counts",
		Size = UDim2.fromOffset(0, 18),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		TextColor3 = rgb(176, 168, 150),
		Font = Enum.Font.Garamond,
		TextSize = 17,
		TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = 2,
		ZIndex = 5,
		Text = "",
		Parent = frame,
	})

	-- the recap, over the ending's card (which it replaces after a few seconds)
	recapPanel = new("Frame", {
		Name = "Recap",
		Size = UDim2.fromOffset(520, 300),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = rgb(8, 9, 12),
		BackgroundTransparency = 0.05,
		Visible = false,
		ZIndex = 23,
		Parent = gui,
	})
	new("UICorner", { CornerRadius = UDim.new(0, 10), Parent = recapPanel })
	new("TextLabel", {
		Name = "Title",
		Size = UDim2.new(1, -40, 0, 44),
		Position = UDim2.fromOffset(20, 16),
		BackgroundTransparency = 1,
		Text = Text.Recap.title,
		TextColor3 = rgb(236, 200, 150),
		Font = Enum.Font.Merriweather,
		TextSize = 28,
		ZIndex = 24,
		Parent = recapPanel,
	})
	recapText = new("TextLabel", {
		Name = "Text",
		Size = UDim2.new(1, -40, 1, -80),
		Position = UDim2.fromOffset(20, 66),
		BackgroundTransparency = 1,
		TextColor3 = rgb(236, 230, 214),
		Font = Enum.Font.Garamond,
		TextSize = 22,
		TextWrapped = true,
		TextYAlignment = Enum.TextYAlignment.Top,
		Text = "",
		ZIndex = 24,
		Parent = recapPanel,
	})

	ReplicatedStorage:GetAttributeChangedSignal("Phase"):Connect(function()
		local phase = ReplicatedStorage:GetAttribute("Phase")
		recapPanel.Visible = false
		if phase == "Intro" or phase == "Lobby" then
			table.clear(taught)
		elseif phase == "Open" then
			task.delay(7, function()
				if ReplicatedStorage:GetAttribute("Phase") == "Open" then
					teach("water")
				end
			end)
			task.delay(18, function()
				if ReplicatedStorage:GetAttribute("Phase") == "Open" and lp:GetAttribute("Taken") ~= true then
					teach("incense")
				end
			end)
		elseif phase == "Ending" then
			task.delay(9, showRecap) -- after the ending's card has been read
		end
	end)
	Remotes.event(Remotes.Names.SenWarning).OnClientEvent:Connect(function(step: number)
		if step == 1 then
			teach("warning")
		end
	end)
	Remotes.event(Remotes.Names.PlayerTaken).OnClientEvent:Connect(function(userId: number)
		local who = Players:GetPlayerByUserId(userId)
		if who and who ~= lp and lp:GetAttribute("Taken") ~= true then
			task.delay(5, function()
				teach("rescue", who.DisplayName)
			end)
		end
	end)
	task.spawn(function()
		while true do
			task.wait(0.5)
			refresh()
			if ReplicatedStorage:GetAttribute("Phase") == "Open" and not taught.shrine and inShrine() then
				teach("shrine")
			end
		end
	end)
end

return GoalController
