--!strict
-- Owns the run's phase and clock (PROTOTYPE_BRIEF §3).
-- Phase is replicated as an attribute on ReplicatedStorage ("Phase"), clock as "ClockHour" (number, e.g. 21.5).
-- TODO(M2): phase machine Intro -> Arrival -> Night1 -> Open -> Finale -> Ending, clock, lighting per phase, reset.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Analytics = require(Shared:WaitForChild("Analytics"))

export type Phase = "Lobby" | "Intro" | "Arrival" | "Night1" | "Open" | "Finale" | "Ending"

local GameStateService = {}

function GameStateService.GetPhase(): Phase
	return ReplicatedStorage:GetAttribute("Phase") :: Phase
end

function GameStateService.SetPhase(phase: Phase)
	ReplicatedStorage:SetAttribute("Phase", phase)
	Analytics.track("phase_change", { phase = phase })
	print(`[LangVong] phase -> {phase}`)
end

function GameStateService.Init()
	ReplicatedStorage:SetAttribute("Phase", "Lobby")
	ReplicatedStorage:SetAttribute("ClockHour", 18.5)
end

function GameStateService.Start()
	Analytics.track("session_start")
end

return GameStateService
