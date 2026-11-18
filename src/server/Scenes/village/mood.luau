--!strict
local Mood = require("../../../shared/Scene/Mood")

-- Night horror baseline: dark, short grey-green fog. Builder's taste call; Catlyn adjusts.
local mood: Mood.Mood = {
	clockTime = 0,
	brightness = 0.4,
	fogStart = 20,
	fogEnd = 160,
	fogColor = { 52, 64, 58 },
	ambient = { 18, 22, 24 },
	atmosphereDensity = 0.35,
}

return mood
