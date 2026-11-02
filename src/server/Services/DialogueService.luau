--!strict
-- Dialogue (PROTOTYPE_BRIEF §9 step 5): linear lines from Content/Dialogue, one at a time, to an audience of
-- players. Any player in the audience moves it on (click / Enter); a line also moves on by itself after
-- Config.DialogueAutoSeconds, so one player who walked away can't stall the group. Play() yields until the
-- conversation ends or is stopped. Barks (Bin's lines) are shown as a message without stopping anyone.
-- Bà Thu can be talked to again in the Open phase (§5.4): a "Talk" prompt on her, one new detail per repeat.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Analytics = require(Shared:WaitForChild("Analytics"))
local Config = require(Shared:WaitForChild("Config"))
local Dialogue = require(Shared:WaitForChild("Content"):WaitForChild("Dialogue"))
local Pace = require(Shared:WaitForChild("Pace"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Tags = require(Shared:WaitForChild("Tags"))
local Text = require(Shared:WaitForChild("Content"):WaitForChild("Text"))

type Session = { id: string, audience: { Player }, advanced: boolean, stopped: boolean, lastAdvance: number }

local DialogueService = {}

local sessions: { Session } = {}
local repeatCount = 0

local function speakerName(key: string): string
	return (Text.Speakers :: any)[key] or key
end

local function sessionOf(player: Player): Session?
	for _, s in sessions do
		if table.find(s.audience, player) then
			return s
		end
	end
	return nil
end

function DialogueService.Busy(player: Player): boolean
	return sessionOf(player) ~= nil
end

-- the conversation `id` to these players (default: everyone). Yields until it's over; returns false if stopped
function DialogueService.Play(id: string, audience: { Player }?): boolean
	local conv = (Dialogue :: any)[id]
	assert(conv, `unknown conversation {id}`)
	local who = audience or Players:GetPlayers()
	local s: Session = { id = id, audience = who, advanced = false, stopped = false, lastAdvance = 0 }
	table.insert(sessions, s)
	local show, done = Remotes.event(Remotes.Names.DialogueShow), Remotes.event(Remotes.Names.DialogueEnd)
	for i, line in conv.lines do
		if s.stopped then
			break
		end
		s.advanced = false
		print(`[Dialogue] {id} {i}/{#conv.lines} {line.speaker}`)
		for _, p in who do
			if p.Parent then
				show:FireClient(p, speakerName(line.speaker), line.text, i, #conv.lines)
			end
		end
		local t0 = os.clock()
		while not s.advanced and not s.stopped and os.clock() - t0 < Pace.seconds(Config.DialogueAutoSeconds) do
			task.wait(0.1)
		end
	end
	for _, p in who do
		if p.Parent then
			done:FireClient(p)
		end
	end
	local k = table.find(sessions, s)
	if k then
		table.remove(sessions, k)
	end
	Analytics.track("dialogue", { id = id, finished = not s.stopped })
	return not s.stopped
end

function DialogueService.Advance(player: Player)
	local s = sessionOf(player)
	if s and os.clock() - s.lastAdvance >= Config.DialogueAdvanceCooldown then
		s.lastAdvance = os.clock()
		s.advanced = true
	end
end

-- stop one conversation wherever it's playing
function DialogueService.Stop(id: string)
	for _, s in sessions do
		if s.id == id then
			s.stopped = true
		end
	end
end

-- stop every conversation (a reset, a debug phase jump)
function DialogueService.StopAll()
	for _, s in sessions do
		s.stopped = true
	end
end

-- a one-line remark that doesn't stop anyone (Bin): shown on the message line
function DialogueService.Bark(id: string)
	local conv = (Dialogue :: any)[id]
	assert(conv, `unknown conversation {id}`)
	local line = conv.lines[1]
	print(`[Dialogue] bark {id}`)
	Remotes.event(Remotes.Names.Message):FireAllClients(`{speakerName(line.speaker)}: {line.text}`)
end

-- §5.4: talk to Bà Thu again; each time the next repeat, then round again
function DialogueService.TalkToThu(player: Player)
	if DialogueService.Busy(player) then
		return
	end
	local order = (Dialogue :: any).RepeatOrder :: { string }
	repeatCount += 1
	DialogueService.Play(order[(repeatCount - 1) % #order + 1], { player })
end

function DialogueService.Reset()
	DialogueService.StopAll()
	repeatCount = 0
end

local function setupThuPrompt(thu: Instance)
	local part = if thu:IsA("Model") then thu.PrimaryPart else nil
	if not part or part:FindFirstChildOfClass("ProximityPrompt") then
		return
	end
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "Talk"
	prompt.ActionText = Text.UI.talk
	prompt.ObjectText = Text.Speakers.BaThu
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = Config.TalkPromptDistance
	prompt.RequiresLineOfSight = false
	prompt.Enabled = ReplicatedStorage:GetAttribute("Phase") == "Open"
	prompt.Triggered:Connect(function(player: Player)
		if ReplicatedStorage:GetAttribute("Phase") == "Open" then
			DialogueService.TalkToThu(player)
		end
	end)
	prompt.Parent = part
	ReplicatedStorage:GetAttributeChangedSignal("Phase"):Connect(function()
		prompt.Enabled = ReplicatedStorage:GetAttribute("Phase") == "Open"
	end)
end

function DialogueService.Init()
	Remotes.event(Remotes.Names.DialogueShow)
	Remotes.event(Remotes.Names.DialogueEnd)
	Remotes.event(Remotes.Names.DialogueAdvance).OnServerEvent:Connect(function(player: Player)
		DialogueService.Advance(player)
	end)
	Players.PlayerRemoving:Connect(function(p)
		for _, s in sessions do
			local k = table.find(s.audience, p)
			if k then
				table.remove(s.audience, k)
			end
		end
	end)
end

function DialogueService.Start()
	local GameState = require(script.Parent:WaitForChild("GameStateService")) :: any
	GameState.OnReset(DialogueService.Reset)
	for _, thu in CollectionService:GetTagged(Tags.NpcBaThu) do
		setupThuPrompt(thu)
	end
	CollectionService:GetInstanceAddedSignal(Tags.NpcBaThu):Connect(setupThuPrompt)
end

return DialogueService
