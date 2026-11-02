--!strict
-- Every tunable number lives here. Values match docs/PROTOTYPE_BRIEF.md; change them here, not inline.

local Config = {
	MaxPlayers = 4,
	WalkSpeed = 12, -- slower than Roblox's 16: the lane (~590 studs) takes ~50 s end to end (brief §8: ~60 s)

	-- Run structure (§3)
	IntroSeconds = 30,
	ArrivalStartHour = 18.5,
	Night1StartHour = 19,
	Night1PlaceholderSeconds = 8, -- until the Night 1 director exists (M3): Night1 just waits this long
	OpenPhaseRealSeconds = 35 * 60, -- in-game 21:00 -> 24:00
	OpenPhaseStartHour = 21,
	MidnightHour = 24,
	SecondLanternDriftHour = 23,
	FinaleSeconds = 4, -- placeholder until the endings exist (M6)
	EndingResetSeconds = 30,

	-- Lanterns and hints (§5.4)
	LanternDriftSeconds = 75,
	HintAfterSeconds = 240,

	-- Camcorder (§5.2)
	CameraBatterySeconds = 300, -- seconds of viewfinder time on a full battery (see DECISIONS: the drain follows this)
	CameraDrainPerSecond = 100 / 300, -- percent per second = 100 / CameraBatterySeconds
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

	-- Boundaries
	BoundaryFadeSeconds = 0.6,
	BoundaryCooldownSeconds = 2,

	-- Prompts
	CluePromptHold = 0.5,
	AltarPromptHold = 1.5,
	PromptDistance = 9,
}

return Config
