--!strict
-- Studio-only debug commands for testing (AGENTS.md §5). Does nothing in live servers.
-- Two ways in, same commands:
--   chat:   /lv phase Open | /lv time 23.9 | /lv clue all | /lv goto SenHouse | /lv battery 20 | /lv reset
--   agents: the BindableFunction ServerScriptService.Debug, e.g. Debug:Invoke("goto", "Shrine") from execute_luau
--           (Server context). The factory test runner (tools/factory/test.py) uses it.
-- Commands: get | begin (the caller plays alone: skips the menu) | teams | phase <Phase> | time <hour> | clue <ClueId|all> | goto <Location> | battery <0-100> | reset |
--           inshrine | locations | speed <n> (Night 1 runs n times faster) | night1 (the director's state) |
--           pickup (pick up Bin's camera) | talk (talk to Bà Thu) | next (move the dialogue on) |
--           memento <id> | letter (take the letter) | hint | sen <on|off|now> | take | rescue | incense |
--           write (press the dialogue's choice) | stay <hold|let> | mystery | ending (states)

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local TextChatService = game:GetService("TextChatService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Clues = require(Shared:WaitForChild("Content"):WaitForChild("Clues"))
local Tags = require(Shared:WaitForChild("Tags"))

local DebugService = {}

local function locationModel(name: string): Model?
	for _, m in CollectionService:GetTagged(Tags.Location) do
		if m:GetAttribute("Location") == name and m:IsA("Model") then
			return m
		end
	end
	return nil
end

local function run(caller: Player?, cmd: string, arg: any): any
	local GameState = require(script.Parent:WaitForChild("GameStateService")) :: any
	local ClueService = require(script.Parent:WaitForChild("ClueService")) :: any
	local Director = require(script.Parent:WaitForChild("NightOneDirector")) :: any
	local DialogueService = require(script.Parent:WaitForChild("DialogueService")) :: any
	local Mystery = require(script.Parent:WaitForChild("MysteryService")) :: any
	local Sen = require(script.Parent:WaitForChild("SenService")) :: any
	local Ending = require(script.Parent:WaitForChild("EndingService")) :: any
	local player = caller or Players:GetPlayers()[1]
	if cmd == "get" then
		local batteries = {}
		for _, p in Players:GetPlayers() do
			batteries[p.Name] = p:GetAttribute("Battery")
		end
		return { phase = GameState.GetPhase(), clock = GameState.GetClock(), clues = ClueService.Found(), batteries = batteries,
			players = #Players:GetPlayers(), beat = ReplicatedStorage:GetAttribute("Night1Beat") }
	elseif cmd == "begin" then
		assert(player, "no player")
		local Menu = require(script.Parent:WaitForChild("MenuService")) :: any
		Menu.BeginSolo(player)
	elseif cmd == "teams" then
		local Menu = require(script.Parent:WaitForChild("MenuService")) :: any
		return Menu.Snapshot()
	elseif cmd == "speed" then
		ReplicatedStorage:SetAttribute("DebugTimeScale", tonumber(arg) or 1)
	elseif cmd == "night1" then
		return Director.State()
	elseif cmd == "pickup" then
		Director.PickUpCamera(player)
	elseif cmd == "talk" then
		assert(player, "no player")
		task.spawn(DialogueService.TalkToThu, player)
	elseif cmd == "next" then
		for _, p in Players:GetPlayers() do
			DialogueService.Advance(p)
		end
	elseif cmd == "write" then
		for _, p in Players:GetPlayers() do
			DialogueService.Choose(p)
		end
	elseif cmd == "memento" then
		assert(player, "no player")
		Mystery.ViewMemento(player, arg)
	elseif cmd == "letter" then
		assert(player, "no player")
		Mystery.TakeLetter(player)
	elseif cmd == "hint" then
		return Mystery.Hint("debug") or "none"
	elseif cmd == "sen" then
		if arg == "off" then
			ReplicatedStorage:SetAttribute("SenOff", true)
		elseif arg == "on" then
			ReplicatedStorage:SetAttribute("SenOff", false)
		else
			assert(player, "no player")
			task.spawn(Sen.Hunt, player)
		end
	elseif cmd == "keeprun" then
		ReplicatedStorage:SetAttribute("DebugKeepRun", arg == "on")
	elseif cmd == "take" then
		assert(player, "no player")
		Sen.Take(player)
	elseif cmd == "wayback" then -- alone: follow the festival lantern home
		assert(player, "no player")
		return Sen.FindWayBack(player)
	elseif cmd == "goal" then
		return ReplicatedStorage:GetAttribute("Goal")
	elseif cmd == "rescue" then
		local p = Sen.Rescue(nil)
		return p and p.Name or "nobody"
	elseif cmd == "incense" then
		assert(player, "no player")
		return Sen.UseIncense(player)
	elseif cmd == "stay" then
		for _, p in Players:GetPlayers() do
			Ending.AnswerStay(p, arg == "hold")
		end
	elseif cmd == "mystery" then
		local s = Mystery.State()
		s.hunting = Sen.Hunting()
		s.exposed = player and Sen.Exposed(player) or false
		s.taken = player and player:GetAttribute("Taken") or false
		s.incense = player and player:GetAttribute("Incense") or 0
		return s
	elseif cmd == "ending" then
		return Ending.State()
	elseif cmd == "phase" then
		GameState.SetPhase(arg)
	elseif cmd == "time" then
		GameState.SetClock(tonumber(arg) or 21)
	elseif cmd == "clue" then
		assert(player, "no player")
		if arg == "all" then
			for id in Clues do
				ClueService.Inspect(player, id)
			end
		else
			ClueService.Inspect(player, arg)
		end
	elseif cmd == "goto" then
		local m = locationModel(arg)
		local root = player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
		assert(m and root, `no location {arg} or no character`)
		root.AssemblyLinearVelocity = Vector3.zero
		root.CFrame = CFrame.new(m:GetPivot().Position + Vector3.new(0, 3, 0))
	elseif cmd == "battery" then
		for _, p in Players:GetPlayers() do
			p:SetAttribute("Battery", tonumber(arg) or 100)
		end
	elseif cmd == "reset" then
		GameState.Reset()
	elseif cmd == "inshrine" then
		return player and GameState.InShrine(player) or false
	elseif cmd == "locations" then
		local out = {}
		for _, m in CollectionService:GetTagged(Tags.Location) do
			table.insert(out, m:GetAttribute("Location"))
		end
		table.sort(out)
		return out
	else
		error(`unknown debug command {cmd}`)
	end
	return "ok"
end

function DebugService.Init()
	if not RunService:IsStudio() then
		return
	end
	local hook = Instance.new("BindableFunction")
	hook.Name = "Debug"
	hook.OnInvoke = function(cmd: string, arg: any)
		return run(nil, cmd, arg)
	end
	hook.Parent = ServerScriptService
end

function DebugService.Start()
	if not RunService:IsStudio() then
		return
	end
	pcall(function() -- chat commands (TextChatService only)
		local command = Instance.new("TextChatCommand")
		command.Name = "LangVongDebug"
		command.PrimaryAlias = "/lv"
		command.Triggered:Connect(function(source: TextSource, text: string)
			local player = Players:GetPlayerByUserId(source.UserId)
			local words = string.split(text, " ")
			local ok, res = pcall(run, player, words[2] or "get", words[3])
			print(`[LangVong] /lv {words[2] or "get"} {words[3] or ""} -> {ok and "ok" or res}`)
		end)
		command.Parent = TextChatService
	end)
	print("[LangVong] debug commands enabled (Studio only)")
end

return DebugService
