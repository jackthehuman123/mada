--!strict
-- CollectionService tag names. Code finds world objects by these tags, never by Workspace paths.
-- Add new tags here first, then use Tags.X everywhere.

local Tags = {
	-- Places (also set attribute Location = "<name>" on the place's root model/part)
	Location = "Location", -- Shrine, TeacherHouse, PuppetHouse, FishHouse, HeadHouse, SenHouse, TellerHouse, CarpSteps, Dock, Causeway, CommunalHouse, DrownedFestival

	-- Zones (invisible, CanCollide = false parts)
	ShrineZone = "ShrineZone", -- safe zone + camera recharge
	WaterEdge = "WaterEdge", -- shoreline parts used for Sen's distance checks
	BoundaryTeleport = "BoundaryTeleport", -- walking into it returns players to the lake shore
	ShoreReturn = "ShoreReturn", -- where a boundary sends players back to (a part on the lane by the shrine)

	-- Interaction
	Clue = "Clue", -- attribute ClueId
	Memento = "Memento", -- attribute ChildName (Minh, Hạnh, Tí, Khoa)
	ShrineAltar = "ShrineAltar", -- incense rescue prompt
	SenAltar = "SenAltar", -- the letter is hidden here
	HideSpot = "HideSpot", -- optional M8 (Quiet Man)

	-- Lanterns
	LanternPath = "LanternPath", -- attribute House = Location name; ordered waypoint parts (attribute Index)
	LanternStop = "LanternStop", -- attribute House
	HouseWindow = "HouseWindow", -- attribute House; lit when that house's lantern arrives

	-- Camcorder visibility (client-side only)
	CameraOnly = "CameraOnly", -- invisible to eyes; visible in viewfinder and playback
	HiddenOnCamera = "HiddenOnCamera", -- visible to eyes and live viewfinder; hidden in playback (Bà Thu)

	-- NPCs
	NpcBaThu = "NpcBaThu",
	NpcBin = "NpcBin",
	BinCamera = "BinCamera", -- §4 beat 6: floating in the reeds by the shrine; picking it up gives the group Bin's tapes
	Flood = "Flood", -- §4 beat 5: the water over the causeway
}

return Tags
