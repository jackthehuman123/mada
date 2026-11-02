--!strict
-- The one ScreenGui ("LangVongUI") and its pieces: text cards, the bottom message line, the fade, the clue panel,
-- the journal (key J or the button), and the camcorder's VHS viewfinder. Other controllers call these functions;
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

function UI.ShowClue(clueId: string)
	local clue = Clues[clueId]
	if not clue then
		return
	end
	clueTitle.Text = clue.title
	clueBody.Text = clue.text
	cluePanel.Visible = true
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
		new("TextLabel", { Name = "Empty", Size = UDim2.new(1, -8, 0, 30), BackgroundTransparency = 1, Text = Text.UI.journalEmpty,
			TextColor3 = INK, Font = Enum.Font.Garamond, TextSize = 20, TextXAlignment = Enum.TextXAlignment.Left, Parent = journalList })
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
		new("TextLabel", { Name = "Place_" .. place, LayoutOrder = n, Size = UDim2.new(1, -8, 0, 28), BackgroundTransparency = 1,
			Text = (Text.Places :: any)[place] or place, TextColor3 = rgb(120, 30, 24), Font = Enum.Font.Merriweather, TextSize = 22,
			TextXAlignment = Enum.TextXAlignment.Left, Parent = journalList })
		for _, id in byPlace[place] do
			n += 1
			local b = new("TextButton", { Name = "Entry_" .. id, LayoutOrder = n, Size = UDim2.new(1, -8, 0, 26), BackgroundTransparency = 1,
				Text = "  " .. Clues[id].title, TextColor3 = INK, Font = Enum.Font.Garamond, TextSize = 20,
				TextXAlignment = Enum.TextXAlignment.Left, Parent = journalList })
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
	gui = new("ScreenGui", { Name = "LangVongUI", ResetOnSpawn = false, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = player:WaitForChild("PlayerGui") })

	-- the camcorder's VHS viewfinder (shown by CamcorderController)
	local vf = new("Frame", { Name = "Viewfinder", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false, ZIndex = 2, Parent = gui })
	for _, c in { { 0, 0 }, { 1, 0 }, { 0, 1 }, { 1, 1 } } do -- the four corner brackets
		local f = new("Frame", { Size = UDim2.fromOffset(60, 60), AnchorPoint = Vector2.new(c[1], c[2]),
			Position = UDim2.new(c[1], c[1] == 0 and 40 or -40, c[2], c[2] == 0 and 40 or -40), BackgroundTransparency = 1, Parent = vf })
		new("Frame", { Size = UDim2.new(1, 0, 0, 3), Position = UDim2.fromScale(0, c[2]), AnchorPoint = Vector2.new(0, c[2]), BorderSizePixel = 0,
			BackgroundColor3 = rgb(230, 230, 230), Parent = f })
		new("Frame", { Size = UDim2.new(0, 3, 1, 0), Position = UDim2.fromScale(c[1], 0), AnchorPoint = Vector2.new(c[1], 0), BorderSizePixel = 0,
			BackgroundColor3 = rgb(230, 230, 230), Parent = f })
	end
	new("Frame", { Name = "Tint", Size = UDim2.fromScale(1, 1), BackgroundColor3 = rgb(40, 70, 60), BackgroundTransparency = 0.86, BorderSizePixel = 0, Parent = vf })
	local function vhs(name: string, pos: UDim2, anchor: Vector2, color: Color3?): TextLabel
		return new("TextLabel", { Name = name, Size = UDim2.fromOffset(260, 34), Position = pos, AnchorPoint = anchor, BackgroundTransparency = 1,
			Font = Enum.Font.Code, TextSize = 26, TextColor3 = color or rgb(235, 235, 235), TextStrokeTransparency = 0.4,
			TextXAlignment = anchor.X == 0 and Enum.TextXAlignment.Left or Enum.TextXAlignment.Right, Text = "", Parent = vf })
	end
	UI.vfRec = vhs("Rec", UDim2.new(0, 70, 0, 70), Vector2.new(0, 0), rgb(255, 60, 50))
	UI.vfMode = vhs("Mode", UDim2.new(0, 70, 0, 104), Vector2.new(0, 0))
	UI.vfTime = vhs("Time", UDim2.new(1, -70, 0, 70), Vector2.new(1, 0))
	UI.vfBattery = vhs("Battery", UDim2.new(1, -70, 1, -70), Vector2.new(1, 1))
	UI.viewfinder = vf

	-- clip chooser for playback (T)
	local chooser = new("Frame", { Name = "Clips", Size = UDim2.fromOffset(240, 190), Position = UDim2.new(0.5, 0, 1, -40), AnchorPoint = Vector2.new(0.5, 1),
		BackgroundColor3 = rgb(16, 18, 22), BackgroundTransparency = 0.15, Visible = false, ZIndex = 5, Parent = gui })
	corner(chooser)
	new("UIListLayout", { Padding = UDim.new(0, 6), HorizontalAlignment = Enum.HorizontalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder, Parent = chooser })
	new("UIPadding", { PaddingTop = UDim.new(0, 8), Parent = chooser })
	UI.clipChooser = chooser

	-- text cards (the teller's narration, the rumor video)
	cardFrame = new("Frame", { Name = "Card", Size = UDim2.fromScale(1, 1), BackgroundColor3 = rgb(0, 0, 0), BackgroundTransparency = 0.15,
		Visible = false, ZIndex = 8, Parent = gui })
	cardText = new("TextLabel", { Name = "Text", Size = UDim2.new(0.6, 0, 0.5, 0), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1, TextColor3 = rgb(230, 220, 200), Font = Enum.Font.Garamond, TextSize = 30, TextWrapped = true, Text = "",
		ZIndex = 9, Parent = cardFrame })

	messageLabel = new("TextLabel", { Name = "Message", Size = UDim2.new(0.6, 0, 0, 40), Position = UDim2.new(0.5, 0, 1, -110), AnchorPoint = Vector2.new(0.5, 1),
		BackgroundTransparency = 1, TextColor3 = rgb(236, 228, 210), TextStrokeTransparency = 0.3, Font = Enum.Font.Garamond, TextSize = 28,
		Visible = false, ZIndex = 6, Parent = gui })

	-- the clue panel: a scrap of paper
	cluePanel = new("Frame", { Name = "CluePanel", Size = UDim2.fromOffset(520, 340), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = PAPER, Visible = false, ZIndex = 10, Parent = gui })
	corner(cluePanel, 4)
	clueTitle = new("TextLabel", { Name = "Title", Size = UDim2.new(1, -40, 0, 40), Position = UDim2.fromOffset(20, 16), BackgroundTransparency = 1,
		TextColor3 = rgb(120, 30, 24), Font = Enum.Font.Merriweather, TextSize = 28, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 11, Parent = cluePanel })
	clueBody = new("TextLabel", { Name = "Body", Size = UDim2.new(1, -40, 1, -120), Position = UDim2.fromOffset(20, 60), BackgroundTransparency = 1,
		TextColor3 = INK, Font = Enum.Font.Garamond, TextSize = 22, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top, ZIndex = 11, Parent = cluePanel })
	local close = new("TextButton", { Name = "Close", Size = UDim2.fromOffset(110, 36), Position = UDim2.new(1, -20, 1, -16), AnchorPoint = Vector2.new(1, 1),
		BackgroundColor3 = rgb(120, 30, 24), TextColor3 = PAPER, Font = Enum.Font.Merriweather, TextSize = 20, Text = Text.UI.close, ZIndex = 11, Parent = cluePanel })
	corner(close, 4)
	close.Activated:Connect(UI.HideClue)

	-- the journal
	journal = new("Frame", { Name = "Journal", Size = UDim2.fromOffset(420, 460), Position = UDim2.new(0, 30, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5),
		BackgroundColor3 = PAPER, Visible = false, ZIndex = 7, Parent = gui })
	corner(journal, 4)
	new("TextLabel", { Name = "Heading", Size = UDim2.new(1, -30, 0, 44), Position = UDim2.fromOffset(16, 10), BackgroundTransparency = 1,
		Text = Text.UI.journal, TextColor3 = INK, Font = Enum.Font.Merriweather, TextSize = 30, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 8, Parent = journal })
	journalList = new("ScrollingFrame", { Name = "List", Size = UDim2.new(1, -30, 1, -70), Position = UDim2.fromOffset(16, 58), BackgroundTransparency = 1,
		BorderSizePixel = 0, ScrollBarThickness = 4, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), ZIndex = 8, Parent = journal })
	new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Parent = journalList })
	local button = new("TextButton", { Name = "JournalButton", Size = UDim2.fromOffset(120, 44), Position = UDim2.new(0, 20, 1, -20), AnchorPoint = Vector2.new(0, 1),
		BackgroundColor3 = PAPER, BackgroundTransparency = 0.1, TextColor3 = INK, Font = Enum.Font.Merriweather, TextSize = 22,
		Text = Text.UI.journal .. " (J)", ZIndex = 6, Parent = gui })
	corner(button, 6)
	button.Activated:Connect(function()
		UI.ToggleJournal()
	end)

	fadeFrame = new("Frame", { Name = "Fade", Size = UDim2.fromScale(1, 1), BackgroundColor3 = rgb(0, 0, 0), BackgroundTransparency = 1,
		Visible = false, ZIndex = 20, Parent = gui })
	redrawJournal()
end

function UI.Init()
	build()
end

return UI
