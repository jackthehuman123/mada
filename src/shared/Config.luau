--!strict
-- Every tunable number lives here. Values match docs/PROTOTYPE_BRIEF.md; change them here, not inline.

local Config = {
	MaxPlayers = 4,

	-- Run structure (§3)
	IntroSeconds = 30,
	OpenPhaseRealSeconds = 35 * 60, -- in-game 21:00 -> 24:00
	OpenPhaseStartHour = 21,
	MidnightHour = 24,
	SecondLanternDriftHour = 23,
	EndingResetSeconds = 30,

	-- Lanterns and hints (§5.4)
	LanternDriftSeconds = 75,
	HintAfterSeconds = 240,

	-- Camcorder (§5.2)
	CameraBatterySeconds = 300,
	CameraDrainPerSecond = 1, -- percent
	CameraRechargePerSecond = 5, -- percent, inside ShrineZone
	CameraClipMaxSeconds = 20,
	CameraMaxClips = 3,
	CameraSampleHz = 10,
	CameraViewfinderFov = 55,

	-- Sen (§5.5)
	SenTargetIntervalMin = 60,
	SenTargetIntervalMax = 120,
	AloneRadius = 25, -- studs: no other player within this = alone
	WaterDangerRadius = 30, -- studs from a WaterEdge
	SenWarningStepSeconds = 5,
	IncensePerPlayer = 2,
	IncenseWithdrawSeconds = 60,

	-- Taken / rescue (§5.6)
	RescuesPerPlayerPerNight = 1,
	RescueHoldSeconds = 3,
	TakenLanternCooldown = 60,
	DrownedFestivalY = -400,

	-- Prompts
	CluePromptHold = 0.5,
	AltarPromptHold = 1.5,
}

return Config
