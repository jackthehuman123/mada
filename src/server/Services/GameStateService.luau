--!strict
--!nolint DeprecatedApi
-- (DeprecatedApi off: LoadCharacter/IsInGroup kept on purpose until a playtest, see docs/ISSUES.md)
-- Owns the run's phase and clock (PROTOTYPE_BRIEF §3).
-- Phase is replicated as an attribute on ReplicatedStorage ("Phase"), clock as "ClockHour" (number, e.g. 21.5).
-- The machine reacts to the current phase every tick, so a debug jump to any phase just works.
--   Lobby (the menu; MenuService calls BeginRun when a team begins) -> Intro (text card) -> Arrival (until a player reaches the shrine) -> Night1 (NightOneDirector's beats;
--   it moves on to Open itself) -> Open (21:00 -> 24:00) -> Finale -> Ending (text card) -> reset -> Intro
-- Other services follow the phase through OnPhase(fn).

local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Analytics = require(Shared:WaitForChild("Analytics"))
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Tags = require(Shared:WaitForChild("Tags"))
local Text = require(Shared:WaitForChild("Content"):WaitForChild("Text"))

export type Phase = "Lobby" | "Intro" | "Arrival" | "Night1" | "Open" | "Finale" | "Ending"

local GameStateService = {}

local phaseStart = os.clock()
local resetHooks: { () -> () } = {}
local phaseHooks: { (Phase) -> () } = {}
local leaving = false -- the Ending phase is sending the team back to the menu

local function setClock(hour: number)
	ReplicatedStorage:SetAttribute("ClockHour", hour)
	Lighting.ClockTime = hour % 24
end

local function message(text: string)
	Remotes.event(Remotes.Names.Message):FireAllClients(text)
end

local function card(id: string)
	Remotes.event(Remotes.Names.ShowTextCard):FireAllClients(id)
end

function GameStateService.GetPhase(): Phase
	return ReplicatedStorage:GetAttribute("Phase") :: Phase
end

function GameStateService.GetClock(): number
	return ReplicatedStorage:GetAttribute("ClockHour") :: number
end

function GameStateService.SetClock(hour: number)
	setClock(hour)
end

function GameStateService.SetPhase(phase: Phase)
	leaving = false
	ReplicatedStorage:SetAttribute("Phase", phase)
	phaseStart = os.clock()
	Analytics.track("phase_change", { phase = phase })
	print(`[LangVong] phase -> {phase}`)
	if phase == "Intro" then
		setClock(Config.ArrivalStartHour)
		card("intro")
	elseif phase == "Arrival" then
		setClock(Config.ArrivalStartHour)
	elseif phase == "Night1" then
		setClock(Config.Night1StartHour)
	elseif phase == "Open" then
		setClock(Config.OpenPhaseStartHour)
		message(Text.Messages.findBin)
	elseif phase == "Finale" then
		setClock(Config.MidnightHour)
	elseif phase == "Ending" then
		local kind = (ReplicatedStorage:GetAttribute("Ending") :: string?) or "silence"
		card("ending_" .. kind)
		Analytics.track("ending", { type = kind })
	end
	for _, fn in phaseHooks do
		task.spawn(fn, phase)
	end
end

-- called (in its own thread) every time the phase changes, with the new phase
function GameStateService.OnPhase(fn: (Phase) -> ())
	table.insert(phaseHooks, fn)
end

-- is this point inside a part's box?
local function inside(pos: Vector3, part: BasePart): boolean
	local rel = part.CFrame:PointToObjectSpace(pos)
	local half = part.Size / 2
	return math.abs(rel.X) <= half.X and math.abs(rel.Y) <= half.Y and math.abs(rel.Z) <= half.Z
end

function GameStateService.InShrine(player: Player): boolean
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return false
	end
	for _, z in CollectionService:GetTagged(Tags.ShrineZone) do
		if z:IsA("BasePart") and inside(root.Position, z) then
			return true
		end
	end
	return false
end

-- other services clear their state on a reset (clues found, batteries)
function GameStateService.OnReset(fn: () -> ())
	table.insert(resetHooks, fn)
end

-- the players in the run (MenuService sets InRun; players still in the menu don't count)
local function inRun(): { Player }
	local list = {}
	for _, p in Players:GetPlayers() do
		if p:GetAttribute("InRun") then
			table.insert(list, p)
		end
	end
	return list
end

-- a team has begun (MenuService): the run starts
function GameStateService.BeginRun()
	if GameStateService.GetPhase() == "Lobby" then
		GameStateService.SetPhase("Intro")
	end
end

function GameStateService.Reset()
	Analytics.track("session_end")
	for _, fn in resetHooks do
		task.spawn(fn)
	end
	local players = inRun()
	for _, p in players do
		task.spawn(function()
			-- selene: allow(deprecated)
			p:LoadCharacter()
		end)
	end
	Analytics.reset()
	Analytics.track("session_start")
	GameStateService.SetPhase(#players > 0 and "Intro" or "Lobby")
end

local function tick(dt: number)
	local phase = GameStateService.GetPhase()
	local t = os.clock() - phaseStart
	if phase == "Intro" then
		if t >= Config.IntroSeconds then
			GameStateService.SetPhase("Arrival")
		end
	elseif phase == "Arrival" then
		for _, p in Players:GetPlayers() do
			if GameStateService.InShrine(p) then
				GameStateService.SetPhase("Night1")
				break
			end
		end
	elseif phase == "Open" then
		local hour = GameStateService.GetClock()
			+ (Config.MidnightHour - Config.OpenPhaseStartHour) / Config.OpenPhaseRealSeconds * dt
		setClock(math.min(hour, Config.MidnightHour))
		if hour >= Config.MidnightHour then
			GameStateService.SetPhase("Finale")
		end
	elseif phase == "Finale" then
		-- EndingService plays the finale and moves on to Ending itself; this only catches a finale that got stuck
		if t >= Config.FinaleFailsafeSeconds then
			warn("[LangVong] the finale never finished: Ending")
			GameStateService.SetPhase("Ending")
		end
	elseif phase == "Ending" then
		if t >= Config.EndingResetSeconds and not leaving then
			-- a team's own server: back to the menu; Studio (and a failed trip): the night starts again
			local Menu = require(script.Parent:WaitForChild("MenuService")) :: any
			if Menu.Kind() == "Run" then
				leaving = true
				task.spawn(function()
					if not Menu.SendAllBack() then
						GameStateService.Reset()
					end
				end)
			else
				GameStateService.Reset()
			end
		end
	end
end

function GameStateService.Init()
	for _, name in { Remotes.Names.Message, Remotes.Names.ShowTextCard, Remotes.Names.Fade } do
		Remotes.event(name) -- made before any client asks for them (no "infinite yield" warning at start)
	end
	-- analytics events that happen on a client (§10): only these names are accepted
	local fromClient = { camera_record = true, camera_playback = true, bin_tape_played = true }
	local lastTrack: { [Player]: number } = {}
	Players.PlayerRemoving:Connect(function(p)
		lastTrack[p] = nil
	end)
	Remotes.event(Remotes.Names.Track).OnServerEvent:Connect(function(p: Player, name: any, data: any)
		-- at most one every half second, and only a few plain fields (a client could otherwise fill the server's memory)
		if os.clock() - (lastTrack[p] or 0) < 0.5 then
			return
		end
		lastTrack[p] = os.clock()
		if typeof(name) == "string" and fromClient[name] then
			local d = {}
			if typeof(data) == "table" then
				local n = 0
				for k, v in data do
					n += 1
					if n > 6 then
						break
					end
					if
						typeof(k) == "string"
						and (typeof(v) == "number" or typeof(v) == "boolean" or (typeof(v) == "string" and #v <= 60))
					then
						d[k] = v
					end
				end
			end
			d.player = p.Name
			Analytics.track(name, d)
		end
	end)
	ReplicatedStorage:SetAttribute("Phase", "Lobby")
	setClock(Config.ArrivalStartHour)
	Players.PlayerRemoving:Connect(function()
		task.defer(function()
			if #inRun() == 0 and GameStateService.GetPhase() ~= "Lobby" then
				GameStateService.SetPhase("Lobby")
				local Menu = require(script.Parent:WaitForChild("MenuService")) :: any
				Menu.RunEnded()
			end
		end)
	end)
end

function GameStateService.Start()
	Analytics.track("session_start")
	local last = os.clock()
	while true do
		task.wait(0.25)
		local now = os.clock()
		local ok, err = pcall(tick, now - last)
		if not ok then
			warn(`[LangVong] phase tick failed: {err}`)
		end
		last = now
	end
end

return GameStateService
