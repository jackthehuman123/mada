--!strict
-- No runtime require (Roblox cannot resolve a relative path into ReplicatedStorage); Mood.validate checks it.
-- Night horror baseline: dark, short grey-green fog. Builder's taste call; Catlyn adjusts.
local mood: {
	clockTime: number,
	brightness: number,
	fogStart: number,
	fogEnd: number,
	fogColor: { number },
	ambient: { number },
	atmosphereDensity: number?,
} =
	{
		clockTime = 0,
		brightness = 0.4,
		fogStart = 20,
		fogEnd = 160,
		fogColor = { 52, 64, 58 },
		ambient = { 18, 22, 24 },
		atmosphereDensity = 0.35,
	}

return mood
