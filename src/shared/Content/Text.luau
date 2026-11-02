--!strict
-- Player-facing text that isn't a clue or a dialogue line: text cards, one-line messages, UI labels.
-- Lines marked DRAFT were written by the agent and need Catlyn's review.

local Text = {
	Cards = {
		-- brief §3: the rumor video the channel watched. DRAFT: needs Catlyn review
		intro = "From a video the channel watched last week:\n\n\"In Làng Vọng, the lanterns light themselves.\"",
		-- placeholder until the endings are built (M6). DRAFT: stage direction from brief §7, not story text
		ending_silence = "Every lantern on the lake goes out at once.\n\n(Im lặng)",
	},
	Messages = {
		findBin = "Find Bin.", -- brief §4 beat 7
		causewayFlooded = "The causeway is under water.", -- brief §4 beat 5
		binCamera = "Bin's camera. Still recording.", -- story.md §13 "still recording". DRAFT: needs Catlyn review
		binTapesHint = "Press T to watch Bin's tapes.",
	},
	UI = {
		look = "Look",
		journal = "Journal",
		journalEmpty = "Nothing written down yet.",
		close = "Close",
		rec = "REC",
		play = "PLAY",
		battery = "BATT",
		noBattery = "NO BATTERY",
		clips = "Clips",
		noClips = "No clips recorded.",
		binTape = "Bin's tape",
		talk = "Talk",
		pickUp = "Pick up",
		next = "Click or press Enter",
	},
	Speakers = {
		BaThu = "Bà Thu",
		Bin = "Bin",
	},
	Objects = {
		binCamera = "Bin's camera",
	},
	Places = { -- journal group headings, by Location
		Shrine = "The shrine",
		TeacherHouse = "The teacher's house",
		PuppetHouse = "The puppet master's house",
		FishHouse = "The fish seller's house",
		HeadHouse = "The village head's house",
		SenHouse = "The house at the end of the lane",
		CarpSteps = "The stone steps",
	},
}

return Text
