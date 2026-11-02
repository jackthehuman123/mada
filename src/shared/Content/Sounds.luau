--!strict
-- Every sound the game plays, by id. `asset` is empty until the sound-designer finds or makes one (docs/ASSETS.md);
-- until then a sound with a `subtitle` shows that line instead, so the scene still reads. Subtitles are DRAFT.

export type Sound = { asset: string, volume: number?, subtitle: string?, draft: boolean? }

local Sounds: { [string]: Sound } = {
	-- §4 beat 4: when Bin vanishes. DRAFT subtitle
	child_crying_water = { asset = "", volume = 0.6, subtitle = "[a child crying, out on the water]", draft = true },
	-- §4 beat 3: inside a house when its window lights. Faint, no subtitle (the brief says no UI comment)
	child_inside = { asset = "", volume = 0.25 },
	-- §4 beat 3: a lantern set on the water
	lantern_on_water = { asset = "", volume = 0.4 },
	-- §4 beat 6: the camera's REC light, if nobody has found it for a while. DRAFT subtitle
	camera_beep = { asset = "", volume = 0.5, subtitle = "[a small red light blinking in the reeds by the shrine]", draft = true },
	-- §5.3: the end of a tape
	tape_static = { asset = "", volume = 0.5 },
}

return Sounds
