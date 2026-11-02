--!strict
-- Bin's two tapes (PROTOTYPE_BRIEF §5.3), played through the camcorder's playback code. A tape is a camera path
-- (keys: time, camera position, the point it looks at) plus ghost events: local-only figures that exist only on
-- the tape. Playback also hides everything tagged HiddenOnCamera, like any recording.
-- Positions follow src/server/World/Build.luau: the shrine is centred at (-330, 0, -64), Bà Thu's mat at
-- (-334, 1, -64); the carp steps go down from (350, 1, 8) into the cove's water (surface y = -1).

export type Key = { t: number, pos: Vector3, look: Vector3 }
-- a ghost appears at t; optionally moves from cf to `to` over `dur` s, fades out from fadeAt over fadeSeconds, and is
-- gone at untilT
export type Ghost = { t: number, template: string, cf: CFrame, to: CFrame?, dur: number?, fadeAt: number?, fadeSeconds: number?,
	untilT: number? }
export type Glitch = { from: number, to: number } -- a burst of static
export type Tape = { id: string, title: string, length: number, keys: { Key }, ghosts: { Ghost }, staticFrom: number?, handheld: boolean,
	stamp: string, -- stamp: the VHS clock burned into the tape (when Bin filmed it on Night 1)
	glitches: { Glitch }?, underwaterFrom: number? } -- underwaterFrom: the picture goes murky (the camera is in the lake)

local v = Vector3.new

local Tapes: { Tape } = {
	{
		-- Tape 1, the shrine: Bin's angle on Night 1, from the lane side. Bà Thu is not in it.
		id = "bin_tape1", title = "1", length = 13, handheld = true, ghosts = {}, stamp = "19:04",
		keys = {
			{ t = 0, pos = v(-322, 5.2, -50), look = v(-334, 2.6, -64) },
			{ t = 4, pos = v(-323, 5.0, -51), look = v(-333.5, 2.8, -64) },
			{ t = 7, pos = v(-324, 5.1, -51.5), look = v(-330, 4.4, -72.5) }, -- up to the altar and the photos
			{ t = 10, pos = v(-324, 5.0, -52), look = v(-335, 2.6, -63) }, -- back to the mat
			{ t = 13, pos = v(-324, 5.0, -52), look = v(-334, 2.4, -64) },
		},
	},
	{
		-- Tape 2, the steps (story.md §13; Catlyn 2026-11-02): handheld, down a set of stone steps into dark water; at the
		-- bottom a small girl stands in the water, looking up. Between bursts of static she is closer each time, then
		-- her small hand takes Bin's, the picture lurches into the lake, and under the murky water two shapes, the girl
		-- and a boy in an orange jacket, sink slowly and fade. No scream, nothing seen clearly. Ends in static.
		-- (The carp steps behind Sen's house, but nothing says so.) DRAFT: needs Catlyn review (staging)
		id = "bin_tape2", title = "2", length = 21, handheld = true, staticFrom = 19.6, stamp = "20:07",
		keys = {
			{ t = 0, pos = v(350, 6.2, 17), look = v(350, 0, -8) },
			{ t = 3, pos = v(350, 5.4, 8.5), look = v(350, -1, -14) },
			{ t = 6, pos = v(350, 4.0, 4), look = v(350, -1.2, -16) },
			{ t = 8, pos = v(350, 3.7, 2.5), look = v(350, 0.2, -13) },
			{ t = 11.4, pos = v(350, 3.6, 2.2), look = v(350, 0.2, -10) },
			{ t = 13.4, pos = v(350, 3.5, 2.1), look = v(350, 0.4, -2) }, -- down at her, right below
			{ t = 14.3, pos = v(350, -0.6, -0.4), look = v(350, -5, -6) }, -- the lurch into the water
			{ t = 21, pos = v(350, -2.4, -1.4), look = v(350, -8.5, -7.5) }, -- drifting down
		},
		ghosts = {
			{ t = 6.5, template = "GirlInWater", cf = CFrame.lookAt(v(350, -1.1, -13), v(350, -1.1, 2.2)), untilT = 9.75 },
			{ t = 9.75, template = "GirlInWater", cf = CFrame.lookAt(v(350, -1.1, -7), v(350, -1.1, 2.2)), untilT = 11.6 },
			{ t = 11.6, template = "GirlClose", cf = CFrame.lookAt(v(350, -1.1, -1.6), v(350, -1.1, 2.2)), untilT = 14.3 },
			-- her hand rises into the frame and takes his
			{ t = 12.5, template = "SenHand", cf = CFrame.lookAt(v(350.3, 1.2, 0.2), v(350.3, 4, 1.4)),
				to = CFrame.lookAt(v(350.3, 2.7, 0.9), v(350.3, 5, 1.9)), dur = 0.9, untilT = 14.3 },
			-- under the water: the girl and the boy sink and fade into the dark
			{ t = 14.3, template = "GirlSinking", cf = CFrame.new(349.4, -4, -5.5), to = CFrame.new(349.4, -9.5, -8.5), dur = 6,
				fadeAt = 16.5, fadeSeconds = 3 },
			{ t = 14.3, template = "BinSinking", cf = CFrame.new(351.2, -4.3, -5), to = CFrame.new(351.2, -9.8, -8), dur = 6,
				fadeAt = 16.5, fadeSeconds = 3 },
		},
		glitches = {
			{ from = 9.5, to = 9.75 }, { from = 11.35, to = 11.6 }, { from = 13.3, to = 14.6 },
			{ from = 15.6, to = 15.8 }, { from = 17.0, to = 17.35 }, { from = 18.4, to = 18.6 },
		},
		underwaterFrom = 14.3,
	},
}

return Tapes
