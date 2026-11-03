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
	-- Sen in the water (I-16): a pale shape under the surface; drifts round the middle, follows a hunted player along
	-- the shore (still, then suddenly closer), reaches from the edge
	LakeMiddle = Vector3.new(0, -1, -265), -- where the lanterns gather (move with the I-14 layout)
	WaterY = -1, -- the lake's surface
	SenWanderRadius = 70,
	SenSwimSpeed = 4, -- studs/s drifting
	SenDartSpeed = 40, -- studs/s in a sudden move while hunting
	SenDartSeconds = 1.1,
	SenStillSeconds = 2.2, -- still between darts
	SenIdleDepth = 7, -- studs under the surface (faint)
	SenHuntDepth = 2.5, -- closer to the surface while hunting (clearer)
	SenOffshore = 5, -- she waits this far out from the water's edge
	SenReachDistance = 8, -- step 5 happens once she's this close to the edge by the player
	SenArriveTimeout = 15, -- seconds the last warning waits for her to arrive
	SenFootprints = 8, -- wet prints walking out of the water toward the player (camera only), steps 3-4
	-- being taken lasts SenTakeSeconds in all (Catlyn: 3 s); the parts below add up to it, the rest is the cut to black
	SenTakeSeconds = 3, -- then the drowned festival
	SenGrabSeconds = 0.5, -- her hand on your leg: you look down at it before the pull
	SenDragSeconds = 1.0, -- pulled backward by the leg to the water and under (everyone sees it)
	SenFaceSeconds = 0.6, -- under the water, the glimpse of her face
	SenDrownSeconds = 0.6, -- sinking, the view blurs and darkens
	SenJumpscare = true, -- the glimpse of her face under the water, with a sting (off: the pull and the blur only)

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

	-- Closed playtest: only members of this Roblox group may join a live server (0 = anyone). Studio is never gated.
	-- 5099606 = Raumania (owner Holding_accountx1; Noptable Founder, Catlyn Co-Founder)
	PlaytestGroupId = 5099606,

	-- Menu and teams (docs/ISSUES.md I-09): players join a menu server, form a team, and each team plays in its own
	-- reserved server of this same place. The menu server's size is set on roblox.com (Places > Settings), not here.
	TeamMax = 4, -- = MaxPlayers
	RunWaitForTeamSeconds = 40, -- a run server starts once the whole team has arrived, or this long after the first
	TeleportTries = 3,
	InviteDataTries = 10, -- launch data from an invite can take a few seconds to appear (Roblox docs)
	RespawnSeconds = 3, -- characters don't load by themselves (the menu decides who plays): respawn after a fall
	MenuCameraFrom = Vector3.new(70, 16, -250), -- out on the lake at dusk, looking back at the village
	MenuCameraTo = Vector3.new(-70, 6, 0),
	MenuCameraDrift = 40, -- studs the camera slides west and back
	MenuCameraDriftSeconds = 60,

	-- First person and bodies (I-12): locked first person, your own arms and legs visible, poses everyone sees
	FirstPersonCameraOffset = Vector3.new(0, 0, -1.1), -- forward of the head, so looking down shows the body, not its inside
	LookPitchSendHz = 8, -- how often a client tells the server where it's looking (others' heads and arms follow)
	LookPitchMax = 70, -- degrees up or down
	BobAmount = 0.08, -- studs of head bob at walking speed
	BobSpeed = 7, -- radians per second of head bob at walking speed
	SwayRoll = 1.6, -- degrees the camera leans when strafing
	BreathAmount = 0.025, -- studs of idle breathing
	PoseLerp = 12, -- how fast heads and arms follow (per second)

	-- Music (I-13): a quiet bed in the open village; tension from Sen's warning step 2, a chase from step 4
	MusicFadeSeconds = 2.5,
	MusicTensionStep = 2,
	MusicChaseStep = 4,
	MusicHoldSeconds = 9, -- after the last warning step, how long tension/chase music lasts before fading back
}

return Config
