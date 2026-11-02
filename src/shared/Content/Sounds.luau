--!strict
-- Every sound the game plays, by id (M7 audio pass, 2026-11-02). Assets come from Roblox's licensed sound library on
-- the Creator Store (uploaded by ProSoundEffects for use in any experience; logged in docs/ASSETS.md), chosen by name
-- and checked to load, not yet listened to by a person. An empty `asset` is still silent. A `subtitle` is shown as a
-- caption whenever the sound plays (with or without an asset), for the sounds the story needs players to notice.
-- Subtitles approved by Catlyn 2026-11-02. `loop` repeats it; `seconds` stops it after that long.

export type Sound = { asset: string, volume: number?, subtitle: string?, draft: boolean?, loop: boolean?, seconds: number?, pitch: number? }

local function id(n: number): string
	return "rbxassetid://" .. n
end

local Sounds: { [string]: Sound } = {
	-- ambience (client loops: the night village, the lake; under the water when taken)
	amb_night = { asset = id(9112764546), volume = 0.35, loop = true }, -- Crickets Night 1
	amb_water = { asset = id(9116203162), volume = 0.3, loop = true }, -- Lake Lap Water Movement 2
	amb_underwater = { asset = id(9112889917), volume = 0.5, loop = true }, -- Underwater Ambience 1

	-- §4 beat 4 / §5.5 step 1: a child crying from the water
	child_crying_water = { asset = id(9113996806), volume = 0.5, pitch = 1.08, subtitle = "[a child crying, out on the water]", draft = false }, -- Cries Whimpers 14
	-- §4 beat 3: inside a house when its window lights. Faint, no caption (the brief says no UI comment)
	child_inside = { asset = id(9113784466), volume = 0.2 }, -- Child Giggle 1
	-- §4 beat 3: a lantern set on the water
	lantern_on_water = { asset = id(9119293555), volume = 0.35 }, -- Small Splash Shallow Water Fountain Pool 1
	-- §4 beat 6: the camera's REC light, if nobody has found it for a while (no sound yet)
	camera_beep = { asset = "", volume = 0.5, subtitle = "[a small red light blinking in the reeds by the shrine]", draft = false },
	-- §5.3: the end of a tape
	tape_static = { asset = id(9118027586), volume = 0.4, loop = true, seconds = 1.6 }, -- Radio Static 9
	-- §5.1 mementos: a short sound with each memory (the whistle and the drum have no fitting sound yet)
	memento_minh = { asset = id(9117233304), volume = 0.4 }, -- paper rustle
	memento_hanh = { asset = id(9120918417), volume = 0.4 }, -- wood knock (the puppet)
	memento_ti = { asset = "", volume = 0.4 },
	memento_khoa = { asset = "", volume = 0.4 },
	-- §6 carp steps / §5.5 step 2: carp splashing at the edge
	carp_splash = { asset = id(9119481268), volume = 0.4 }, -- Splashes Small Wet Sloshes Drips 13
	-- §5.5 step 3: wet footsteps behind the player
	wet_footsteps = { asset = id(9120589946), volume = 0.45, seconds = 5, subtitle = "[small wet footsteps, close behind you]", draft = false },
	-- §5.6: being taken / incense
	taken = { asset = id(9126147241), volume = 0.7, seconds = 6 }, -- Underwater Movement Gurgly Mysterious
	incense = { asset = id(9120930385), volume = 0.4, seconds = 3 }, -- Wood Matches 4
	-- §7 endings
	festival_static = { asset = id(9118027586), volume = 0.35, loop = true, seconds = 12, subtitle = "[static, and very faint, festival music]", draft = false },
	radio_off = { asset = id(9117158538), volume = 0.5 }, -- Old Radio Click On Off Tuning Buzz 1
	finale_home = { asset = "", volume = 0.5 }, -- music: for the sound-designer / Catlyn (no licensed piece chosen)
}

return Sounds
