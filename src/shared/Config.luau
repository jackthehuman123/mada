--!strict
-- Every tunable number lives here. Values match docs/PROTOTYPE_BRIEF.md; change them here, not inline.

local Config = {
	MaxPlayers = 4,
	WalkSpeed = 12, -- slower than Roblox's 16: the lane (~590 studs) takes ~50 s end to end (brief §8: ~60 s)

	-- Run structure (§3)
	IntroSeconds = 30,
	ArrivalStartHour = 18.5,
	Night1StartHour = 19,
	Night1BeatHours = { 18.5, 19, 19.5, 20, 20.3, 20.6, 21 }, -- the clock as each Night 1 beat starts (§4: 19:00 -> 21:00)
	OpenPhaseRealSeconds = 35 * 60, -- in-game 21:00 -> 24:00
	OpenPhaseStartHour = 21,
	MidnightHour = 24,
	SecondLanternDriftHour = 23,
	FinaleFailsafeSeconds = 180, -- the finale scenes move on to Ending themselves; this only catches a stuck one
	EndingResetSeconds = 30,

	-- Dialogue (§4 beat 2, §5.4)
	DialogueAutoSeconds = 14, -- a line moves on by itself if nobody clicks (nobody gets stuck on an AFK player)
	DialogueAdvanceCooldown = 0.4,
	TalkPromptDistance = 10,

	-- Lanterns and hints (§5.4)
	LanternDriftSeconds = 75, -- brief: 60-90 s from the shrine to a house
	LanternStaggerSeconds = 4, -- Bà Thu sets them on the water one after another
	LanternFloatY = -0.4, -- the lake's surface is at y = -1

	-- Bin (§4 beats 1, 4)
	BinWalkSpeed = 11,
	BinFollowDistance = 7,
	BinCatchUpDistance = 60, -- further than this from everyone: he jumps to the nearest player (teleports, debug goto)
	BinWanderMinSeconds = 4,
	BinWanderMaxSeconds = 20, -- §4 beat 4: he vanishes when nobody can see him, or after 20 s
	BinSeenDistance = 120,
	BinCameraHintSeconds = 120, -- §1: nobody stuck for long: the camera's light gets a subtitle after this

	-- Mystery (§5.1, §6)
	MementoLineSeconds = 2.6,
	CarpStepsRadius = 14, -- the width (studs) of the strip down the carp steps where a player makes the carp rise
	HintFlickerSeconds = 8,

	-- Endings (§5.7, §7)
	ThuWalkSpeed = 7, -- studs/s, from the shrine through her back yard to the carp steps
	StayEnding = false, -- Ở lại is cut (Catlyn, 2026-11-02): midnight without Về nhà is always Im lặng
	StayRadius = 22, -- players this close to the carp steps at midnight are "at the steps"
	StayChoiceSeconds = 15,
	FinaleHomeSeconds = 40, -- game seconds of the Về nhà finale before the dawn card
	FinaleSilenceSeconds = 10,
	SilenceTakeGapSeconds = 2.5, -- Im lặng: Sen takes the players one by one, this far apart
	FinaleStaySeconds = 22,

	-- Bin's tapes (§5.3)
	TapeStaticSeconds = 1.5,
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
