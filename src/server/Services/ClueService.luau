--!strict
-- Clues (PROTOTYPE_BRIEF §5.1): every object tagged Clue (attribute ClueId) gets a "Look" prompt. What anyone finds,
-- the whole group has: the server keeps one set and sends it to every journal. No counters, no checklists.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Analytics = require(Shared:WaitForChild("Analytics"))
local Clues = require(Shared:WaitForChild("Content"):WaitForChild("Clues"))
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Tags = require(Shared:WaitForChild("Tags"))
local Text = require(Shared:WaitForChild("Content"):WaitForChild("Text"))

local ClueService = {}

local found: { [string]: number } = {}
local order: { string } = {}
local startTime = os.clock()
local foundHooks: { (string) -> () } = {}

-- called with the ClueId every time the group finds a new clue
function ClueService.OnFound(fn: (string) -> ())
	table.insert(foundHooks, fn)
end

function ClueService.Found(): { string }
	return table.clone(order)
end

local function sync(player: Player?)
	local ev = Remotes.event(Remotes.Names.JournalSync)
	if player then
		ev:FireClient(player, ClueService.Found())
	else
		ev:FireAllClients(ClueService.Found())
	end
end

-- a player looked at a clue: the group has it from now on, and that player sees its text
function ClueService.Inspect(player: Player, clueId: string): boolean
	local clue = Clues[clueId]
	if not clue then
		warn(`[LangVong] unknown ClueId {clueId}`)
		return false
	end
	if not found[clueId] then
		found[clueId] = os.clock()
		table.insert(order, clueId)
		Analytics.track("clue_found", { clueId = clueId, t = math.floor(os.clock() - startTime) })
		Remotes.event(Remotes.Names.ClueFound):FireAllClients(clueId)
		sync()
		for _, fn in foundHooks do
			task.spawn(fn, clueId)
		end
	end
	Remotes.event(Remotes.Names.InspectClue):FireClient(player, clueId)
	return true
end

function ClueService.Reset()
	table.clear(found)
	table.clear(order)
	startTime = os.clock()
	sync()
end

local function promptFor(inst: Instance)
	local id = inst:GetAttribute("ClueId")
	local part = if inst:IsA("BasePart") then inst else (inst:IsA("Model") and (inst.PrimaryPart or inst:FindFirstChildWhichIsA("BasePart", true))) or nil
	if typeof(id) ~= "string" or not part or part:FindFirstChildOfClass("ProximityPrompt") then
		return
	end
	local clue = Clues[id]
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = Text.UI.look
	prompt.ObjectText = clue and clue.title or ""
	prompt.HoldDuration = Config.CluePromptHold
	prompt.MaxActivationDistance = Config.PromptDistance
	prompt.RequiresLineOfSight = false
	prompt.Triggered:Connect(function(player: Player)
		ClueService.Inspect(player, id)
	end)
	prompt.Parent = part
end

function ClueService.Init()
	for _, name in { Remotes.Names.ClueFound, Remotes.Names.InspectClue, Remotes.Names.JournalSync } do
		Remotes.event(name)
	end
end

function ClueService.Start()
	local GameState = require(script.Parent:WaitForChild("GameStateService")) :: any
	GameState.OnReset(ClueService.Reset)
	for _, inst in CollectionService:GetTagged(Tags.Clue) do
		promptFor(inst)
	end
	CollectionService:GetInstanceAddedSignal(Tags.Clue):Connect(promptFor)
	Players.PlayerAdded:Connect(function(p)
		sync(p)
	end)
	for _, p in Players:GetPlayers() do
		sync(p)
	end
end

return ClueService
