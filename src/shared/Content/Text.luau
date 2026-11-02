--!strict
-- Player-facing text that isn't a clue or a dialogue line: text cards, one-line messages, UI labels.
-- Lines marked DRAFT were written by the agent and need Catlyn's review.

local Text = {
	Cards = {
		-- brief §3: the rumor video the channel watched. DRAFT: needs Catlyn review
		intro = "From a video the channel watched last week:\n\n\"In Làng Vọng, the lanterns light themselves.\"",
		-- the endings (brief §7), the teller's voice, adapted from story.md §15 and §16. DRAFT: needs Catlyn review
		ending_home = "That was all Sen ever wanted, I think. Someone to say her name and hold on to her.\n\nIn the morning the causeway was dry, and Bin woke up on the bank with his camera in his arms.\n\n(Về nhà)",
		ending_stay = "Some say Sen came up at the steps alone and reached for the nearest hand. The ones who held on went down with her. The ones who let go made it home, and they missed their friends every day of their lives.\n\n(Ở lại)",
		ending_silence = "Some say every lantern on the lake went out at once, and the quiet came down over the whole village. Weeks later somebody found a camera on some old steps, with nothing on it but static and, very faint, festival music.\n\n(Im lặng)",
	},
	Messages = {
		findBin = "Find Bin.", -- brief §4 beat 7
		causewayFlooded = "The causeway is under water.", -- brief §4 beat 5
		binCamera = "Bin's camera. Still recording.", -- story.md §13 "still recording". DRAFT: needs Catlyn review
		binTapesHint = "Press T to watch Bin's tapes.",
		letterFound = "A letter, folded very small, under the altar.", -- DRAFT
		incenseUsed = "The incense smoke drifts out over the water.", -- DRAFT
		taken = "The water closes over you.", -- DRAFT: the taken player's own screen
		rescued = "Incense smoke, and the shrine's lanterns. You're back.", -- DRAFT
		humming = "♪ hm, hm, %s, hm ♪", -- §5.5 step 4: a children's tune with the player's name in it. DRAFT
		holdOrLet = "Sen is reaching for your hand.", -- the Stay ending's choice. DRAFT
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
		lookUnder = "Look under the altar",
		lightIncense = "Light incense",
		lightLantern = "Light a lantern",
		incense = "Incense",
		letter = "The letter",
		holdOn = "Hold on",
		letGo = "Let go",
	},
	Speakers = {
		BaThu = "Bà Thu",
		Bin = "Bin",
	},
	Objects = {
		binCamera = "Bin's camera",
		altar = "The family altar",
		shrineAltar = "The shrine altar",
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
