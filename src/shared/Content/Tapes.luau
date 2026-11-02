--!strict
-- Bin's two tapes (PROTOTYPE_BRIEF §5.3), played through the camcorder's playback code. A tape is a camera path
-- (keys: time, camera position, the point it looks at) plus ghost events: local-only figures that exist only on
-- the tape. Playback also hides everything tagged HiddenOnCamera, like any recording.
-- Positions follow src/server/World/Build.luau: the shrine is centred at (-330, 0, -64), Bà Thu's mat at
-- (-334, 1, -64); the carp steps go down from (350, 1, 8) into the cove's water (surface y = -1).

export type Key = { t: number, pos: Vector3, look: Vector3 }
export type Ghost = { t: number, template: string, cf: CFrame }
export type Tape = { id: string, title: string, length: number, keys: { Key }, ghosts: { Ghost }, staticFrom: number?, handheld: boolean,
	stamp: string } -- stamp: the VHS clock burned into the tape (when Bin filmed it on Night 1)

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
		-- Tape 2, the steps: handheld, down a set of stone steps into dark water; at the bottom a small girl stands in
		-- the water, looking up. Ends in static. (The carp steps behind Sen's house, but nothing says so.)
		id = "bin_tape2", title = "2", length = 12, handheld = true, staticFrom = 10.2, stamp = "20:07",
		keys = {
			{ t = 0, pos = v(350, 6.2, 17), look = v(350, 0, -8) },
			{ t = 3, pos = v(350, 5.4, 8.5), look = v(350, -1, -14) },
			{ t = 6, pos = v(350, 4.0, 4), look = v(350, -1.2, -16) },
			{ t = 8, pos = v(350, 3.7, 2.5), look = v(350, 0.2, -13) },
			{ t = 12, pos = v(350, 3.6, 2.2), look = v(350, 0.4, -13) },
		},
		ghosts = {
			{ t = 6.5, template = "GirlInWater", cf = CFrame.lookAt(v(350, -1.1, -13), v(350, -1.1, 2.2)) },
		},
	},
}

return Tapes
