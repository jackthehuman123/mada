--!strict
-- What to do next (release council 11-03 B1, owner's yes 11-04): one line for the whole team, worked out from the
-- run's state, and the clue and memento counts. Replicated on ReplicatedStorage: Goal (a key of Text.Goals, "" for
-- none), CluesFound, CluesTotal, MementosFound, MementosTotal. The client shows them (GoalController) and swaps the
-- line for its own while its player is taken.
-- Also the recap after an ending (B5): ReplicatedStorage.Recap, a JSON string, set when the Ending phase starts.

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Clues = require(Shared:WaitForChild("Content"):WaitForChild("Clues"))
local Config = require(Shared:WaitForChild("Config"))
local Mementos = require(Shared:WaitForChild("Content"):WaitForChild("Mementos"))

local GoalService = {}

local GameState: any, ClueService: any, Mystery: any, Ending: any

local CLUES_TOTAL, MEMENTOS_TOTAL = 0, 0
for id in Clues do
	if id ~= "sen_letter" then -- (the letter is its own step)
		CLUES_TOTAL += 1
	end
end
for _ in Mementos do
	MEMENTOS_TOTAL += 1
end

local function cluesFound(): number
	local n = 0
	for _, id in ClueService.Found() do
		if id ~= "sen_letter" then
			n += 1
		end
	end
	return n
end

local function mementosFound(): number
	local n = 0
	for _ in Mystery.State().mementos do
		n += 1
	end
	return n
end

function GoalService.Current(): string
	local phase = GameState.GetPhase()
	if phase == "Arrival" then
		return "arrival"
	elseif phase == "Night1" then
		local beat = (ReplicatedStorage:GetAttribute("Night1Beat") :: number?) or 0
		return if beat <= 2 then "listen" elseif beat == 3 then "lanterns" elseif beat <= 5 then "binGone" else "camera"
	elseif phase == "Open" then
		local e = Ending.State()
		if e.thuAtSteps then
			return "midnight"
		elseif e.nameWritten then
			return "walkThu"
		elseif Mystery.LetterFound() then
			return "letter"
		elseif cluesFound() >= Config.GoalCluesBeforeSenHouse then
			return "senHouse"
		end
		return "search"
	elseif phase == "Finale" then
		return "finale"
	end
	return ""
end

local function recap()
	local taken = {}
	for _, p in Players:GetPlayers() do
		if
			p:GetAttribute("InRun") ~= false
			and (p:GetAttribute("Taken") == true or ((p:GetAttribute("Rescues") :: number?) or 0) > 0)
		then
			table.insert(taken, p.DisplayName)
		end
	end
	local started = (ReplicatedStorage:GetAttribute("RunStart") :: number?) or os.clock()
	ReplicatedStorage:SetAttribute(
		"Recap",
		HttpService:JSONEncode({
			ending = ReplicatedStorage:GetAttribute("Ending") or "silence",
			clues = cluesFound(),
			cluesTotal = CLUES_TOTAL,
			mementos = mementosFound(),
			mementosTotal = MEMENTOS_TOTAL,
			letter = Mystery.LetterFound(),
			taken = taken,
			minutes = math.max(1, math.floor((os.clock() - started) / 60 + 0.5)),
		})
	)
end

function GoalService.Init()
	ReplicatedStorage:SetAttribute("Goal", "")
	ReplicatedStorage:SetAttribute("CluesTotal", CLUES_TOTAL)
	ReplicatedStorage:SetAttribute("MementosTotal", MEMENTOS_TOTAL)
	ReplicatedStorage:SetAttribute("CluesFound", 0)
	ReplicatedStorage:SetAttribute("MementosFound", 0)
	ReplicatedStorage:SetAttribute("Recap", "")
end

function GoalService.Start()
	GameState = require(script.Parent:WaitForChild("GameStateService"))
	ClueService = require(script.Parent:WaitForChild("ClueService"))
	Mystery = require(script.Parent:WaitForChild("MysteryService"))
	Ending = require(script.Parent:WaitForChild("EndingService"))
	GameState.OnPhase(function(phase: string)
		if phase == "Ending" then
			recap()
		elseif phase == "Intro" or phase == "Lobby" then
			ReplicatedStorage:SetAttribute("Recap", "")
		end
	end)
	while true do
		task.wait(0.5)
		local ok, err = pcall(function()
			ReplicatedStorage:SetAttribute("Goal", GoalService.Current())
			ReplicatedStorage:SetAttribute("CluesFound", cluesFound())
			ReplicatedStorage:SetAttribute("MementosFound", mementosFound())
		end)
		if not ok then
			warn(`[Goal] {err}`)
		end
	end
end

return GoalService
