--!strict
-- The menu (docs/ISSUES.md I-09): what a player sees from joining until their team begins.
--   Home:  Play alone | Create a team | Join a team, over a slow camera drifting on the lake at dusk
--   Team:  up to 4 slots (the leader marked), Open/Private (leader), Invite friends, Leave, Begin (leader)
--   Join:  the teams in this server this player may join
-- In a run server (MenuService "Run") there is no menu: a "waiting for your team" line until the run starts, and
-- "Back to menu" at the ending. The server decides everything (MenuService); this only shows it and sends clicks.

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SocialService = game:GetService("SocialService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Text = require(Shared:WaitForChild("Content"):WaitForChild("Text"))

local T = Text.Menu
local lp = Players.LocalPlayer
local rgb = Color3.fromRGB
local PAPER, DIM = rgb(232, 222, 198), rgb(150, 140, 120)

type Member = { userId: number, name: string }
type TeamView = { id: string, leader: number, members: { Member }, open: boolean, starting: boolean, canJoin: boolean }

local MenuController = {}

local gui: ScreenGui
local shade: Frame
local panel: Frame
local homePage: Frame
local teamPage: Frame
local joinPage: Frame
local teamTitle: TextLabel
local teamSlots: { Frame } = {}
local openButton: TextButton
local beginButton: TextButton
local waitLeader: TextLabel
local joinList: ScrollingFrame
local noticeLabel: TextLabel
local waitingLabel: TextLabel
local backButton: TextButton

local teams: { TeamView } = {}
local lastVersion = -1
local page = "home"
local headshots: { [number]: string } = {}

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

local function send(action: string, arg: any?)
	Remotes.event(Remotes.Names.MenuAction):FireServer(action, arg)
end

local function button(parent: Instance, text: string, order: number, onClick: () -> ()): TextButton
	local b = new("TextButton", {
		Size = UDim2.new(1, 0, 0, 46),
		LayoutOrder = order,
		BackgroundColor3 = rgb(20, 18, 16),
		BackgroundTransparency = 0.25,
		BorderSizePixel = 0,
		Text = text,
		TextColor3 = PAPER,
		Font = Enum.Font.Merriweather,
		TextSize = 22,
		AutoButtonColor = true,
		Parent = parent,
	})
	new("UICorner", { CornerRadius = UDim.new(0, 6), Parent = b })
	new(
		"UIStroke",
		{ Color = rgb(90, 80, 64), Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = b }
	)
	b.Activated:Connect(onClick)
	return b
end

local function label(parent: Instance, text: string, order: number, size: number, color: Color3?): TextLabel
	return new("TextLabel", {
		Size = UDim2.new(1, 0, 0, size + 10),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = order,
		BackgroundTransparency = 1,
		Text = text,
		TextColor3 = color or PAPER,
		Font = Enum.Font.Garamond,
		TextSize = size,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = parent,
	})
end

local function pageFrame(name: string): Frame
	local f = new("Frame", {
		Name = name,
		Size = UDim2.new(1, 0, 1, -170),
		Position = UDim2.fromOffset(0, 170),
		BackgroundTransparency = 1,
		Visible = false,
		Parent = panel,
	})
	new("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder, Parent = f })
	return f
end

local function headshot(userId: number): string
	if headshots[userId] == nil then
		headshots[userId] = ""
		task.spawn(function()
			local ok, img = pcall(
				Players.GetUserThumbnailAsync,
				Players,
				userId,
				Enum.ThumbnailType.HeadShot,
				Enum.ThumbnailSize.Size48x48
			)
			headshots[userId] = if ok then img else ""
			MenuController.Render()
		end)
	end
	return headshots[userId]
end

local function myTeam(): TeamView?
	for _, t in teams do
		for _, m in t.members do
			if m.userId == lp.UserId then
				return t
			end
		end
	end
	return nil
end

local function leaderName(t: TeamView): string
	for _, m in t.members do
		if m.userId == t.leader then
			return m.name
		end
	end
	return "?"
end

local function invite()
	task.spawn(function()
		local ok, can = pcall(SocialService.CanSendGameInviteAsync, SocialService, lp)
		if not (ok and can) then
			return
		end
		local t = myTeam()
		local options = Instance.new("ExperienceInviteOptions")
		options.LaunchData = HttpService:JSONEncode({ inviter = lp.UserId, team = if t then t.id else nil })
		pcall(SocialService.PromptGameInvite, SocialService, lp, options)
	end)
end

local function build()
	gui = new("ScreenGui", {
		Name = "LangVongMenu",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = 20,
		Parent = lp:WaitForChild("PlayerGui"),
	})
	shade = new("Frame", {
		Name = "Shade",
		Size = UDim2.new(0, 560, 1, 0),
		BackgroundColor3 = rgb(0, 0, 0),
		BorderSizePixel = 0,
		Parent = gui,
	})
	new("UIGradient", {
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.15),
			NumberSequenceKeypoint.new(0.7, 0.45),
			NumberSequenceKeypoint.new(1, 1),
		}),
		Parent = shade,
	})
	panel = new("Frame", {
		Name = "Panel",
		Size = UDim2.new(0, 380, 1, -120),
		Position = UDim2.fromOffset(60, 70),
		BackgroundTransparency = 1,
		Parent = gui,
	})
	new("TextLabel", {
		Name = "Title",
		Size = UDim2.new(1, 0, 0, 80),
		BackgroundTransparency = 1,
		Text = T.title,
		TextColor3 = PAPER,
		Font = Enum.Font.Merriweather,
		TextSize = 64,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = panel,
	})
	new("TextLabel", {
		Name = "Tagline",
		Size = UDim2.new(1, 0, 0, 60),
		Position = UDim2.fromOffset(0, 86),
		BackgroundTransparency = 1,
		Text = T.tagline,
		TextColor3 = DIM,
		Font = Enum.Font.Garamond,
		TextSize = 22,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		Parent = panel,
	})

	homePage = pageFrame("Home")
	button(homePage, T.playAlone, 1, function()
		send("solo")
	end)
	button(homePage, T.createTeam, 2, function()
		send("create", false)
	end)
	button(homePage, T.joinTeam, 3, function()
		page = "join"
		MenuController.Render()
	end)

	teamPage = pageFrame("Team")
	teamTitle = label(teamPage, "", 1, 28)
	for i = 1, Config.TeamMax do
		local slot = new("Frame", {
			Name = "Slot" .. i,
			Size = UDim2.new(1, 0, 0, 44),
			LayoutOrder = 1 + i,
			BackgroundColor3 = rgb(20, 18, 16),
			BackgroundTransparency = 0.4,
			BorderSizePixel = 0,
			Parent = teamPage,
		})
		new("UICorner", { CornerRadius = UDim.new(0, 6), Parent = slot })
		new("ImageLabel", {
			Name = "Face",
			Size = UDim2.fromOffset(36, 36),
			Position = UDim2.fromOffset(4, 4),
			BackgroundTransparency = 1,
			Image = "",
			Parent = slot,
		})
		new("TextLabel", {
			Name = "Name",
			Size = UDim2.new(1, -56, 1, 0),
			Position = UDim2.fromOffset(50, 0),
			BackgroundTransparency = 1,
			Text = "",
			TextColor3 = PAPER,
			Font = Enum.Font.Garamond,
			TextSize = 22,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = slot,
		})
		teamSlots[i] = slot
	end
	openButton = button(teamPage, "", 10, function()
		local t = myTeam()
		if t then
			send("setOpen", not t.open)
		end
	end)
	button(teamPage, T.invite, 11, invite)
	beginButton = button(teamPage, T.begin, 12, function()
		send("begin")
	end)
	beginButton.TextColor3 = rgb(255, 214, 160)
	waitLeader = label(teamPage, "", 13, 20, DIM)
	button(teamPage, T.leave, 14, function()
		send("leave")
	end)

	joinPage = pageFrame("Join")
	joinList = new("ScrollingFrame", {
		Name = "List",
		Size = UDim2.new(1, 0, 0, 300),
		LayoutOrder = 1,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 4,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		Parent = joinPage,
	})
	new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = joinList })
	button(joinPage, T.back, 2, function()
		page = "home"
		MenuController.Render()
	end)

	noticeLabel = new("TextLabel", {
		Name = "Notice",
		Size = UDim2.fromOffset(380, 40),
		Position = UDim2.new(0, 60, 1, -60),
		BackgroundTransparency = 1,
		Text = "",
		TextColor3 = rgb(240, 150, 120),
		Font = Enum.Font.Garamond,
		TextSize = 20,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		Visible = false,
		Parent = gui,
	})

	-- the run server's pieces
	waitingLabel = new("TextLabel", {
		Name = "Waiting",
		Size = UDim2.new(1, 0, 0, 40),
		Position = UDim2.new(0, 0, 0.5, -20),
		BackgroundTransparency = 1,
		Text = "",
		TextColor3 = PAPER,
		Font = Enum.Font.Garamond,
		TextSize = 28,
		Visible = false,
		Parent = gui,
	})
	backButton = new("TextButton", {
		Name = "BackToMenu",
		Size = UDim2.fromOffset(200, 40),
		Position = UDim2.new(1, -220, 1, -60),
		BackgroundColor3 = rgb(20, 18, 16),
		BackgroundTransparency = 0.25,
		BorderSizePixel = 0,
		Text = T.backToMenu,
		TextColor3 = PAPER,
		Font = Enum.Font.Merriweather,
		TextSize = 18,
		Visible = false,
		Parent = gui,
	})
	new("UICorner", { CornerRadius = UDim.new(0, 6), Parent = backButton })
	backButton.Activated:Connect(function()
		send("backToMenu")
	end)
end

local function kind(): string
	return (ReplicatedStorage:GetAttribute("ServerKind") :: string?) or "Menu"
end

local function inMenu(): boolean
	return kind() ~= "Run" and not lp:GetAttribute("InRun")
end

local function renderJoinList()
	for _, c in joinList:GetChildren() do
		if c:IsA("GuiObject") then
			c:Destroy()
		end
	end
	local n = 0
	for _, t in teams do
		if t.canJoin and not t.starting then
			n += 1
			local full = #t.members >= Config.TeamMax
			local text = `{string.format(T.teamOf, leaderName(t))}  ({#t.members}/{Config.TeamMax})  {if full
				then T.full
				else T.join}`
			local b = button(joinList, text, n, function()
				send("join", t.id)
			end)
			b.TextSize = 20
			b.AutoButtonColor = not full
		end
	end
	if n == 0 then
		label(joinList, T.noTeams, 1, 20, DIM)
	end
end

function MenuController.Render()
	if not gui then
		return
	end
	local showMenu = inMenu()
	panel.Visible = showMenu
	shade.Visible = showMenu
	local main = lp.PlayerGui:FindFirstChild("LangVongUI") :: ScreenGui?
	if main then
		main.Enabled = not showMenu
	end
	-- run server: waiting for the team, and the way back to the menu
	local phase = ReplicatedStorage:GetAttribute("Phase")
	local run = kind() == "Run"
	waitingLabel.Visible = run and phase == "Lobby"
	if waitingLabel.Visible then
		local expected = (ReplicatedStorage:GetAttribute("TeamExpected") :: number?) or #Players:GetPlayers()
		waitingLabel.Text = string.format(T.waitingTeam, #Players:GetPlayers(), expected)
	end
	backButton.Visible = run and (phase == "Ending" or phase == "Lobby")
	if not showMenu then
		return
	end
	local t = myTeam()
	if t and page == "join" then
		page = "home"
	end
	homePage.Visible = t == nil and page == "home"
	joinPage.Visible = t == nil and page == "join"
	teamPage.Visible = t ~= nil
	if joinPage.Visible then
		renderJoinList()
	end
	if t then
		local lead = t.leader == lp.UserId
		teamTitle.Text = if t.starting then T.starting else string.format(T.teamOf, leaderName(t))
		for i, slot in teamSlots do
			local m = t.members[i]
			local face = slot:FindFirstChild("Face") :: ImageLabel
			local name = slot:FindFirstChild("Name") :: TextLabel
			face.Image = if m then headshot(m.userId) else ""
			name.Text = if m then (if m.userId == t.leader then `{m.name}  ({T.leader})` else m.name) else T.emptySlot
			name.TextColor3 = if m then PAPER else DIM
		end
		openButton.Visible = lead
		openButton.Text = if t.open then `{T.open}  ·  {T.makePrivate}` else `{T.private}  ·  {T.makeOpen}`
		openButton.TextSize = 16
		beginButton.Visible = lead and not t.starting
		waitLeader.Visible = not lead
		waitLeader.Text = string.format(T.waitingLeader, leaderName(t))
	end
end

-- the slow shot over the lake behind the menu (and in a run server until your character loads)
local function cameraStep()
	local cam = Workspace.CurrentCamera
	local wantMenuCamera = not lp:GetAttribute("InRun") or not lp.Character
	if not wantMenuCamera then
		return
	end
	cam.CameraType = Enum.CameraType.Scriptable
	local s = math.sin(os.clock() / Config.MenuCameraDriftSeconds * 2 * math.pi)
	local from = Config.MenuCameraFrom + Vector3.new(-Config.MenuCameraDrift * (s + 1) / 2, 0, 0)
	cam.CFrame = CFrame.lookAt(from, Config.MenuCameraTo)
end

local function onCharacter(char: Model)
	local hum = char:WaitForChild("Humanoid", 10) :: Humanoid?
	local cam = Workspace.CurrentCamera
	cam.CameraType = Enum.CameraType.Custom
	if hum then
		cam.CameraSubject = hum
	end
end

function MenuController.Init()
	build()
	Remotes.event(Remotes.Names.MenuState).OnClientEvent:Connect(function(state: any)
		if typeof(state) ~= "table" or (state.version or 0) < lastVersion then
			return
		end
		lastVersion = state.version or 0
		teams = state.teams or {}
		MenuController.Render()
	end)
	local noticeToken = 0
	Remotes.event(Remotes.Names.MenuNotice).OnClientEvent:Connect(function(text: string)
		noticeToken += 1
		local my = noticeToken
		noticeLabel.Text = text
		noticeLabel.Visible = true
		task.delay(5, function()
			if noticeToken == my then
				noticeLabel.Visible = false
			end
		end)
	end)
	send("sync") -- ask for the menu once we listen (the server's first broadcast can come before)
end

function MenuController.Start()
	lp:GetAttributeChangedSignal("InRun"):Connect(MenuController.Render)
	ReplicatedStorage:GetAttributeChangedSignal("Phase"):Connect(MenuController.Render)
	ReplicatedStorage:GetAttributeChangedSignal("ServerKind"):Connect(MenuController.Render)
	ReplicatedStorage:GetAttributeChangedSignal("TeamExpected"):Connect(MenuController.Render)
	Players.PlayerAdded:Connect(MenuController.Render)
	Players.PlayerRemoving:Connect(MenuController.Render)
	lp.CharacterAdded:Connect(onCharacter)
	if lp.Character then
		task.spawn(onCharacter, lp.Character)
	end
	RunService:BindToRenderStep("LangVongMenuCamera", Enum.RenderPriority.Camera.Value + 1, cameraStep)
	MenuController.Render()
end

return MenuController
