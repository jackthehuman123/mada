--!strict
-- No runtime require (Roblox cannot resolve a relative path into ReplicatedStorage); Mood.validate checks it.
-- Catlyn's tuned night (moved from World/Build.luau, decision 2026-11-17). Keep the reasons with the numbers.
-- (40/46/66 and 50/58/84 ambient played pitch black on the dock: still night, but the shore, the paths and the water
-- read. Round 2, 2026-11-04: still black frames outdoors on the causeway, the lane and the dock: more moonlight, a
-- little exposure; still night.)
-- clockTime is only the edit-mode starting value; during play GameStateService sets the time of day.
local mood: {
	clockTime: number?,
	brightness: number,
	fogStart: number,
	fogEnd: number,
	fogColor: { number },
	ambient: { number },
	outdoorAmbient: { number }?,
	exposure: number?,
	environmentDiffuse: number?,
	environmentSpecular: number?,
	globalShadows: boolean?,
	atmosphere: {
		density: number,
		offset: number?,
		color: { number }?,
		decay: { number }?,
		glare: number?,
		haze: number?,
	}?,
} =
	{
		clockTime = 0,
		brightness = 1.6,
		ambient = { 74, 82, 108 },
		outdoorAmbient = { 112, 124, 158 },
		exposure = 0.25,
		environmentDiffuse = 0.3,
		environmentSpecular = 0.3,
		fogColor = { 26, 32, 46 },
		fogStart = 40,
		fogEnd = 420,
		globalShadows = true,
		atmosphere = {
			density = 0.3, -- (0.42 hid the karst towers' feet in haze: their tops hung in the sky)
			offset = 0,
			-- (a light haze made distant land brighter than the night sky: the sky between the towers read as a
			-- hanging ceiling)
			color = { 40, 46, 64 },
			decay = { 18, 22, 34 },
			glare = 0,
			haze = 2.2,
		},
	}

return mood
