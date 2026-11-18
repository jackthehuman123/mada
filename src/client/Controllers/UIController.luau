--!strict
-- The one ScreenGui ("LangVongUI") and its pieces: text cards, the bottom message line, the fade, the clue panel,
-- the journal (key J or the button), the dialogue box, and the camcorder's VHS viewfinder (with tape static). Other controllers call these functions;
-- what the text says comes from Shared.Content, never from here.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Clues = require(Shared:WaitForChild("Content"):WaitForChild("Clues"))
local Text = require(Shared:WaitForChild("Content"):WaitForChild("Text"))

local UI = {}

local rgb = Color3.fromRGB
local INK, PAPER = rgb(30, 26, 22), rgb(232, 222, 198)

local function new(class: string, props: { [string]: any }): any
	local inst = Instance.new(class) :: any
	for k, v in props do
		if k ~= "Parent" then
			inst[k] = v
		end
	end
	inst.Parent = props.Parent
	return inst
end

local function corner(parent: Instance, r: number?)
	new("UICorner", { CornerRadius = UDim.new(0, r or 8), Parent = parent })
end

local gui: ScreenGui
local cardFrame: Frame
local cardText: TextLabel
local messageLabel: TextLabel
local fadeFrame: Frame
local cluePanel: Frame
local clueTitle: TextLabel
local clueBody: TextLabel
local journal: Frame
local journalList: ScrollingFrame
local journalIds: { string } = {}

UI.viewfinder = nil :: Frame?
UI.vfRec = nil :: TextLabel?
UI.vfTime = nil :: TextLabel?
UI.vfBattery = nil :: TextLabel?
UI.vfMode = nil :: TextLabel?
UI.clipChooser = nil :: Frame?
UI.vfStatic = nil :: Frame?
UI.onDialogueClick = nil :: (() -> ())?
UI.onDialogueChoice = nil :: (() -> ())?
UI.onStay = nil :: ((boolean) -> ())?
UI.onLightLantern = nil :: (() -> ())?

local dialogueFrame: Frame
local dialogueChoice: TextButton
local stayPanel: Frame
local stayTimer: TextLabel
local takenPanel: Frame
local takenButton: TextButton
local screenStatic: Frame
local memoryFrame: Frame
local memoryText: TextLabel
local dialogueSpeaker: TextLabel
local dialogueText: TextLabel

function UI.Gui(): ScreenGui
	return gui
end

local cardToken = 0
function UI.Card(text: string, seconds: number?)
	cardToken += 1
	local my = cardToken
	cardText.Text = text
	cardFrame.Visible = true
	task.delay(seconds or 8, function()
		if cardToken == my then
			cardFrame.Visible = false
		end
	end)
end

local messageToken = 0
function UI.Message(text: string, seconds: number?)
	messageToken += 1
	local my = messageToken
	messageLabel.Text = text
	messageLabel.Visible = true
	task.delay(seconds or 6, function()
		if messageToken == my then
			messageLabel.Visible = false
		end
	end)
end

function UI.Fade(seconds: number)
	fadeFrame.BackgroundTransparency = 1
	fadeFrame.Visible = true
	local half = TweenInfo.new(seconds / 2)
	local t = TweenService:Create(fadeFrame, half, { BackgroundTransparency = 0 })
	t:Play()
	t.Completed:Wait()
	local back = TweenService:Create(fadeFrame, half, { BackgroundTransparency = 1 })
	back:Play()
	back.Completed:Wait()
	fadeFrame.Visible = false
end

function UI.ShowDialogue(speaker: string, text: string, choice: string?)
	-- a conversation has the screen: the clue paper and the journal close (the letter sat over "Write: Sen", the choice
	-- dimmed behind it; Studio pass 2026-11-03)
	cluePanel.Visible = false
	if journal then
		journal.Visible = false
	end
	dialogueSpeaker.Text = speaker
	dialogueText.Text = text
	dialogueChoice.Text = choice or ""
	dialogueChoice.Visible = choice ~= nil
	if not dialogueFrame.Visible and UI.dialogueSkip then
		UI.dialogueSkip.Text = Text.UI.skip -- a new conversation
	end
	if UI.dialogueSkip then
		UI.dialogueSkip.Visible = choice == nil
	end
	dialogueFrame.Visible = true
end

-- the Stay ending: Sen reaching for your hand; hold on or let go (seconds left shown)
function UI.ShowStay(open: boolean, seconds: number?)
	stayPanel.Visible = open
	if open and seconds then
		local t0 = os.clock()
		task.spawn(function()
			while stayPanel.Visible do
				stayTimer.Text = tostring(math.max(0, math.ceil(seconds - (os.clock() - t0))))
				task.wait(0.2)
			end
		end)
	end
end

-- a taken player's screen: the drowned festival, and the "Light a lantern" button (with its cooldown)
function UI.SetTaken(on: boolean)
	takenPanel.Visible = on
end

function UI.SetLanternCooldown(seconds: number)
	takenButton.AutoButtonColor = seconds <= 0
	takenButton.Text = if seconds > 0
		then string.format("%s (%d)", Text.UI.lightLantern, math.ceil(seconds))
		else Text.UI.lightLantern
end

-- full-screen static (the Im lặng ending)
function UI.ScreenStatic(on: boolean)
	screenStatic.Visible = on
	if on then
		for _, bar in screenStatic:GetChildren() do
			if bar:IsA("Frame") then
				local g = math.random(40, 200)
				bar.BackgroundColor3 = rgb(g, g, g)
			end
		end
	end
end

-- a memento's memory: black screen, lines of text one after another (yields)
function UI.Memory(lines: { string }, perLine: number)
	memoryFrame.BackgroundTransparency = 1
	memoryFrame.Visible = true
	memoryText.Text = ""
	TweenService:Create(memoryFrame, TweenInfo.new(0.6), { BackgroundTransparency = 0 }):Play()
	task.wait(0.7)
	for _, line in lines do
		memoryText.Text = line
		memoryText.TextTransparency = 1
		TweenService:Create(memoryText, TweenInfo.new(0.4), { TextTransparency = 0 }):Play()
		task.wait(perLine)
	end
	memoryText.Text = ""
	local back = TweenService:Create(memoryFrame, TweenInfo.new(0.6), { BackgroundTransparency = 1 })
	back:Play()
	back.Completed:Wait()
	memoryFrame.Visible = false
end

function UI.MemoryShowing(): boolean
	return memoryFrame.Visible
end

function UI.HideDialogue()
	dialogueFrame.Visible = false
end

-- the end of a tape: grey bars flicker over the viewfinder (call every frame while it lasts)
function UI.Static(on: boolean)
	local s = UI.vfStatic :: Frame
	s.Visible = on
	if on then
		for _, bar in s:GetChildren() do
			if bar:IsA("Frame") then
				local g = math.random(60, 230)
				bar.BackgroundColor3 = rgb(g, g, g)
				bar.BackgroundTransparency = math.random() * 0.5
			end
		end
	end
end

function UI.ShowClue(clueId: string)
	local clue = Clues[clueId]
	if not clue then
		return
	end
	clueTitle.Text = clue.title
	clueBody.Text = clue.text
	cluePanel.Visible = true
	-- (it stayed open over a whole walk to the lake: it closes once you've walked off)
	local lp = game:GetService("Players").LocalPlayer
	local root = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local from = root and root.Position
	local shown = clueTitle.Text
	task.spawn(function()
		while cluePanel.Visible and clueTitle.Text == shown and from do
			task.wait(0.5)
			local r = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
			if not r or (r.Position - from).Magnitude > 14 then
				cluePanel.Visible = false
			end
		end
	end)
end

function UI.HideClue()
	cluePanel.Visible = false
end

-- the journal is a scrapbook, grouped by place; no counts, no checklist (brief §5.1)
local function redrawJournal()
	for _, c in journalList:GetChildren() do
		if c:IsA("GuiObject") then
			c:Destroy()
		end
	end
	if #journalIds == 0 then
		new("TextLabel", {
			Name = "Empty",
			Size = UDim2.new(1, -8, 0, 30),
			BackgroundTransparency = 1,
			Text = Text.UI.journalEmpty,
			TextColor3 = INK,
			Font = Enum.Font.Garamond,
			TextSize = 20,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = journalList,
		})
		return
	end
	local byPlace: { [string]: { string } } = {}
	local places: { string } = {}
	for _, id in journalIds do
		local clue = Clues[id]
		if clue then
			if not byPlace[clue.location] then
				byPlace[clue.location] = {}
				table.insert(places, clue.location)
			end
			table.insert(byPlace[clue.location], id)
		end
	end
	local n = 0
	for _, place in places do
		n += 1
		new("TextLabel", {
			Name = "Place_" .. place,
			LayoutOrder = n,
			Size = UDim2.new(1, -8, 0, 28),
			BackgroundTransparency = 1,
			Text = (Text.Places :: any)[place] or place,
			TextColor3 = rgb(120, 30, 24),
			Font = Enum.Font.Merriweather,
			TextSize = 22,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = journalList,
		})
		for _, id in byPlace[place] do
			n += 1
			local b = new("TextButton", {
				Name = "Entry_" .. id,
				LayoutOrder = n,
				Size = UDim2.new(1, -8, 0, 26),
				BackgroundTransparency = 1,
				Text = "  " .. Clues[id].title,
				TextColor3 = INK,
				Font = Enum.Font.Garamond,
				TextSize = 20,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = journalList,
			})
			b.Activated:Connect(function()
				UI.ShowClue(id)
			end)
		end
	end
end

function UI.SetJournal(ids: { string })
	journalIds = ids
	redrawJournal()
end

function UI.ToggleJournal(open: boolean?)
	if open == nil then
		open = not journal.Visible
	end
	journal.Visible = open :: boolean
end

function UI.JournalIds(): { string }
	return journalIds
end

local function build()
	local player = Players.LocalPlayer
	gui = new("ScreenGui", {
		Name = "LangVongUI",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = player:WaitForChild("PlayerGui"),
	})

	-- the camcorder's VHS viewfinder (shown by CamcorderController)
	local vf = new("Frame", {
		Name = "Viewfinder",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Visible = false,
		ZIndex = 2,
		Parent = gui,
	})
	for _, c in { { 0, 0 }, { 1, 0 }, { 0, 1 }, { 1, 1 } } do -- the four corner brackets
		local f = new("Frame", {
			Size = UDim2.fromOffset(60, 60),
			AnchorPoint = Vector2.new(c[1], c[2]),
			Position = UDim2.new(c[1], c[1] == 0 and 40 or -40, c[2], c[2] == 0 and 40 or -40),
			BackgroundTransparency = 1,
			Parent = vf,
		})
		new("Frame", {
			Size = UDim2.new(1, 0, 0, 3),
			Position = UDim2.fromScale(0, c[2]),
			AnchorPoint = Vector2.new(0, c[2]),
			BorderSizePixel = 0,
			BackgroundColor3 = rgb(230, 230, 230),
			Parent = f,
		})
		new("Frame", {
			Size = UDim2.new(0, 3, 1, 0),
			Position = UDim2.fromScale(c[1], 0),
			AnchorPoint = Vector2.new(c[1], 0),
			BorderSizePixel = 0,
			BackgroundColor3 = rgb(230, 230, 230),
			Parent = f,
		})
	end
	new("Frame", {
		Name = "Tint",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = rgb(40, 70, 60),
		BackgroundTransparency = 0.86,
		BorderSizePixel = 0,
		Parent = vf,
	})
	local function vhs(name: string, pos: UDim2, anchor: Vector2, color: Color3?): TextLabel
		return new("TextLabel", {
			Name = name,
			Size = UDim2.fromOffset(260, 34),
			Position = pos,
			AnchorPoint = anchor,
			BackgroundTransparency = 1,
			Font = Enum.Font.Code,
			TextSize = 26,
			TextColor3 = color or rgb(235, 235, 235),
			TextStrokeTransparency = 0.4,
			TextXAlignment = anchor.X == 0 and Enum.TextXAlignment.Left or Enum.TextXAlignment.Right,
			Text = "",
			Parent = vf,
		})
	end
	UI.vfRec = vhs("Rec", UDim2.fromOffset(70, 70), Vector2.new(0, 0), rgb(255, 60, 50))
	UI.vfMode = vhs("Mode", UDim2.fromOffset(70, 104), Vector2.new(0, 0))
	UI.vfTime = vhs("Time", UDim2.new(1, -70, 0, 70), Vector2.new(1, 0))
	UI.vfBattery = vhs("Battery", UDim2.new(1, -70, 1, -70), Vector2.new(1, 1))
	UI.viewfinder = vf
	local static = new("Frame", {
		Name = "Static",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Visible = false,
		ZIndex = 3,
		Parent = vf,
	})
	for k = 0, 39 do
		new("Frame", {
			Name = "Bar",
			Size = UDim2.new(1, 0, 1 / 40, 1),
			Position = UDim2.fromScale(0, k / 40),
			BorderSizePixel = 0,
			BackgroundColor3 = rgb(128, 128, 128),
			ZIndex = 3,
			Parent = static,
		})
	end
	UI.vfStatic = static

	-- clip chooser for playback (T)
	local chooser = new("Frame", {
		Name = "Clips",
		Size = UDim2.fromOffset(240, 190),
		Position = UDim2.new(0.5, 0, 1, -40),
		AnchorPoint = Vector2.new(0.5, 1),
		BackgroundColor3 = rgb(16, 18, 22),
		BackgroundTransparency = 0.15,
		Visible = false,
		ZIndex = 5,
		Parent = gui,
	})
	corner(chooser)
	new("UIListLayout", {
		Padding = UDim.new(0, 6),
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = chooser,
	})
	new("UIPadding", { PaddingTop = UDim.new(0, 8), Parent = chooser })
	UI.clipChooser = chooser

	-- text cards (the teller's narration, the rumor video)
	cardFrame = new("Frame", {
		Name = "Card",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = rgb(0, 0, 0),
		BackgroundTransparency = 0.15,
		Visible = false,
		ZIndex = 21,
		Parent = gui,
	})
	cardText = new("TextLabel", {
		Name = "Text",
		Size = UDim2.fromScale(0.6, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		TextColor3 = rgb(230, 220, 200),
		Font = Enum.Font.Garamond,
		TextSize = 30,
		TextWrapped = true,
		Text = "",
		ZIndex = 22,
		Parent = cardFrame,
	}) -- (above the fade: the ending text was dark grey under a half-done fade)

	-- (on a dark backing, sized to the line: thin light text alone vanished on dark frames; release council 11-03)
	messageLabel = new("TextLabel", {
		Name = "Message",
		Size = UDim2.fromOffset(0, 44),
		AutomaticSize = Enum.AutomaticSize.X,
		Position = UDim2.new(0.5, 0, 1, -110),
		AnchorPoint = Vector2.new(0.5, 1),
		BackgroundColor3 = rgb(10, 12, 16),
		BackgroundTransparency = 0.35,
		TextColor3 = rgb(248, 242, 228),
		TextStrokeTransparency = 0.5,
		Font = Enum.Font.Garamond,
		TextSize = 28,
		Visible = false,
		ZIndex = 6,
		Parent = gui,
	})
	corner(messageLabel, 8)
	new("UIPadding", { PaddingLeft = UDim.new(0, 18), PaddingRight = UDim.new(0, 18), Parent = messageLabel })

	-- the dialogue box: who's speaking and their line; click it (or press Enter) to move on
	dialogueFrame = new("TextButton", {
		Name = "Dialogue",
		Size = UDim2.new(0.62, 0, 0, 130),
		Position = UDim2.new(0.5, 0, 1, -170),
		AnchorPoint = Vector2.new(0.5, 1),
		BackgroundColor3 = rgb(14, 16, 20),
		BackgroundTransparency = 0.2,
		AutoButtonColor = false,
		Text = "",
		Visible = false,
		ZIndex = 7,
		Parent = gui,
	})
	corner(dialogueFrame, 6)
	dialogueSpeaker = new("TextLabel", {
		Name = "Speaker",
		Size = UDim2.new(1, -40, 0, 30),
		Position = UDim2.fromOffset(20, 10),
		BackgroundTransparency = 1,
		TextColor3 = rgb(240, 170, 100),
		Font = Enum.Font.Merriweather,
		TextSize = 22,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = "",
		ZIndex = 8,
		Parent = dialogueFrame,
	})
	dialogueText = new("TextLabel", {
		Name = "Line",
		Size = UDim2.new(1, -40, 1, -70),
		Position = UDim2.fromOffset(20, 40),
		BackgroundTransparency = 1,
		TextColor3 = rgb(236, 228, 210),
		Font = Enum.Font.Garamond,
		TextSize = 26,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		Text = "",
		ZIndex = 8,
		Parent = dialogueFrame,
	})
	new("TextLabel", {
		Name = "Hint",
		Size = UDim2.new(1, -40, 0, 20),
		Position = UDim2.new(0, 20, 1, -26),
		BackgroundTransparency = 1,
		TextColor3 = rgb(150, 150, 150),
		Font = Enum.Font.Garamond,
		TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Right,
		Text = Text.UI.next,
		ZIndex = 8,
		Parent = dialogueFrame,
	})
	dialogueFrame.Activated:Connect(function()
		if UI.onDialogueClick then
			UI.onDialogueClick()
		end
	end)
	-- skip the whole conversation (release council 11-03 B6)
	local skip = new("TextButton", {
		Name = "Skip",
		Size = UDim2.fromOffset(0, 30),
		AutomaticSize = Enum.AutomaticSize.X,
		Position = UDim2.new(1, -12, 0, 10),
		AnchorPoint = Vector2.new(1, 0),
		BackgroundColor3 = rgb(40, 44, 52),
		BackgroundTransparency = 0.2,
		TextColor3 = rgb(210, 204, 190),
		Font = Enum.Font.Garamond,
		TextSize = 18,
		Text = Text.UI.skip,
		ZIndex = 9,
		Parent = dialogueFrame,
	})
	corner(skip, 6)
	new("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), Parent = skip })
	skip.Activated:Connect(function()
		skip.Text = Text.UI.skipWaiting
		if UI.onDialogueSkip then
			UI.onDialogueSkip()
		end
	end)
	UI.dialogueSkip = skip
	dialogueChoice = new("TextButton", {
		Name = "Choice",
		Size = UDim2.fromOffset(220, 40),
		Position = UDim2.new(1, -20, 1, -10),
		AnchorPoint = Vector2.new(1, 1),
		BackgroundColor3 = rgb(200, 140, 70),
		TextColor3 = rgb(20, 16, 12),
		Font = Enum.Font.Merriweather,
		TextSize = 22,
		Text = "",
		Visible = false,
		ZIndex = 9,
		Parent = dialogueFrame,
	})
	corner(dialogueChoice, 6)
	dialogueChoice.Activated:Connect(function()
		if UI.onDialogueChoice then
			UI.onDialogueChoice()
		end
	end)

	-- the Stay ending's choice
	stayPanel = new("Frame", {
		Name = "Stay",
		Size = UDim2.fromOffset(460, 170),
		Position = UDim2.fromScale(0.5, 0.7),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = rgb(10, 14, 18),
		BackgroundTransparency = 0.15,
		Visible = false,
		ZIndex = 12,
		Parent = gui,
	})
	corner(stayPanel, 8)
	new("TextLabel", {
		Name = "Prompt",
		Size = UDim2.new(1, -30, 0, 50),
		Position = UDim2.fromOffset(15, 12),
		BackgroundTransparency = 1,
		Text = Text.Messages.holdOrLet,
		TextColor3 = rgb(230, 222, 205),
		Font = Enum.Font.Garamond,
		TextSize = 26,
		TextWrapped = true,
		ZIndex = 13,
		Parent = stayPanel,
	})
	stayTimer = new("TextLabel", {
		Name = "Timer",
		Size = UDim2.fromOffset(40, 24),
		Position = UDim2.new(1, -12, 0, 8),
		AnchorPoint = Vector2.new(1, 0),
		BackgroundTransparency = 1,
		Text = "",
		TextColor3 = rgb(150, 150, 150),
		Font = Enum.Font.Code,
		TextSize = 18,
		ZIndex = 13,
		Parent = stayPanel,
	})
	for i, choice in { { "Hold", Text.UI.holdOn, true }, { "Let", Text.UI.letGo, false } } do
		local b = new("TextButton", {
			Name = choice[1] :: string,
			Size = UDim2.fromOffset(190, 50),
			Position = UDim2.new(i == 1 and 0.27 or 0.73, 0, 1, -24),
			AnchorPoint = Vector2.new(0.5, 1),
			BackgroundColor3 = i == 1 and rgb(70, 90, 110) or rgb(110, 70, 60),
			TextColor3 = rgb(240, 235, 225),
			Font = Enum.Font.Merriweather,
			TextSize = 22,
			Text = choice[2] :: string,
			ZIndex = 13,
			Parent = stayPanel,
		})
		corner(b, 6)
		b.Activated:Connect(function()
			stayPanel.Visible = false
			if UI.onStay then
				UI.onStay(choice[3] :: boolean)
			end
		end)
	end

	-- a taken player's button
	takenPanel = new("Frame", {
		Name = "Taken",
		Size = UDim2.fromOffset(260, 60),
		Position = UDim2.new(0.5, 0, 1, -40),
		AnchorPoint = Vector2.new(0.5, 1),
		BackgroundTransparency = 1,
		Visible = false,
		ZIndex = 6,
		Parent = gui,
	})
	takenButton = new("TextButton", {
		Name = "LightLantern",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = rgb(200, 120, 50),
		TextColor3 = rgb(25, 18, 10),
		Font = Enum.Font.Merriweather,
		TextSize = 22,
		Text = Text.UI.lightLantern,
		ZIndex = 7,
		Parent = takenPanel,
	})
	corner(takenButton, 8)
	takenButton.Activated:Connect(function()
		if UI.onLightLantern then
			UI.onLightLantern()
		end
	end)

	-- full-screen static
	screenStatic = new("Frame", {
		Name = "ScreenStatic",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Visible = false,
		ZIndex = 15,
		Parent = gui,
	})
	for k = 0, 59 do
		new("Frame", {
			Name = "Bar",
			Size = UDim2.new(1, 0, 1 / 60, 1),
			Position = UDim2.fromScale(0, k / 60),
			BorderSizePixel = 0,
			BackgroundColor3 = rgb(128, 128, 128),
			ZIndex = 15,
			Parent = screenStatic,
		})
	end

	-- a memento's memory
	memoryFrame = new("Frame", {
		Name = "Memory",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = rgb(0, 0, 0),
		BackgroundTransparency = 1,
		Visible = false,
		ZIndex = 16,
		Parent = gui,
	})
	memoryText = new("TextLabel", {
		Name = "Text",
		Size = UDim2.fromScale(0.6, 0.3),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Text = "",
		TextColor3 = rgb(225, 215, 195),
		Font = Enum.Font.Garamond,
		TextSize = 30,
		TextWrapped = true,
		ZIndex = 17,
		Parent = memoryFrame,
	})

	-- the clue panel: a scrap of paper
	cluePanel = new("Frame", {
		Name = "CluePanel",
		Size = UDim2.fromOffset(520, 340),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = PAPER,
		Visible = false,
		ZIndex = 10,
		Parent = gui,
	})
	corner(cluePanel, 4)
	clueTitle = new("TextLabel", {
		Name = "Title",
		Size = UDim2.new(1, -40, 0, 40),
		Position = UDim2.fromOffset(20, 16),
		BackgroundTransparency = 1,
		TextColor3 = rgb(120, 30, 24),
		Font = Enum.Font.Merriweather,
		TextSize = 28,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 11,
		Parent = cluePanel,
	})
	clueBody = new("TextLabel", {
		Name = "Body",
		Size = UDim2.new(1, -40, 1, -120),
		Position = UDim2.fromOffset(20, 60),
		BackgroundTransparency = 1,
		TextColor3 = INK,
		Font = Enum.Font.Garamond,
		TextSize = 22,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		ZIndex = 11,
		Parent = cluePanel,
	})
	local close = new("TextButton", {
		Name = "Close",
		Size = UDim2.fromOffset(110, 36),
		Position = UDim2.new(1, -20, 1, -16),
		AnchorPoint = Vector2.new(1, 1),
		BackgroundColor3 = rgb(120, 30, 24),
		TextColor3 = PAPER,
		Font = Enum.Font.Merriweather,
		TextSize = 20,
		Text = Text.UI.close,
		ZIndex = 11,
		Parent = cluePanel,
	})
	corner(close, 4)
	close.Activated:Connect(UI.HideClue)

	-- the journal
	journal = new("Frame", {
		Name = "Journal",
		Size = UDim2.fromOffset(420, 460),
		Position = UDim2.new(0, 30, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundColor3 = PAPER,
		Visible = false,
		ZIndex = 7,
		Parent = gui,
	})
	corner(journal, 4)
	new("TextLabel", {
		Name = "Heading",
		Size = UDim2.new(1, -30, 0, 44),
		Position = UDim2.fromOffset(16, 10),
		BackgroundTransparency = 1,
		Text = Text.UI.journal,
		TextColor3 = INK,
		Font = Enum.Font.Merriweather,
		TextSize = 30,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 8,
		Parent = journal,
	})
	journalList = new("ScrollingFrame", {
		Name = "List",
		Size = UDim2.new(1, -30, 1, -70),
		Position = UDim2.fromOffset(16, 58),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 4,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		ZIndex = 8,
		Parent = journal,
	})
	new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Parent = journalList })
	local button = new("TextButton", {
		Name = "JournalButton",
		Size = UDim2.fromOffset(120, 44),
		Position = UDim2.new(0, 20, 1, -20),
		AnchorPoint = Vector2.new(0, 1),
		BackgroundColor3 = PAPER,
		BackgroundTransparency = 0.1,
		TextColor3 = INK,
		Font = Enum.Font.Merriweather,
		TextSize = 22,
		Text = Text.UI.journal .. " (J)",
		ZIndex = 6,
		Parent = gui,
	})
	corner(button, 6)
	button.Activated:Connect(function()
		UI.ToggleJournal()
	end)

	fadeFrame = new("Frame", {
		Name = "Fade",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = rgb(0, 0, 0),
		BackgroundTransparency = 1,
		Visible = false,
		ZIndex = 20,
		Parent = gui,
	})
	redrawJournal()
end

function UI.Init()
	build()
end

return UI
