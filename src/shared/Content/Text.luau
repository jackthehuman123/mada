--!strict
-- Player-facing text that isn't a clue or a dialogue line: text cards, one-line messages, UI labels.
-- Lines marked DRAFT were written by the agent and need Catlyn's review.

local Text = {
	Cards = {
		-- brief §3: the rumor video the channel watched. Approved by Catlyn 2026-11-02
		intro = "From a video the channel watched last week:\n\n\"In Làng Vọng, the lanterns light themselves.\"",
		-- the endings (brief §7), the teller's voice, adapted from story.md §15 and §16. Approved by Catlyn 2026-11-02
		-- (ending_stay: Ở lại is cut, Config.StayEnding)
		ending_home = "That was all Sen ever wanted, I think. Someone to say her name and hold on to her.\n\nIn the morning the causeway was dry, and Bin woke up on the bank with his camera in his arms.\n\n(Về nhà)",
		ending_stay = "Some say Sen came up at the steps alone and reached for the nearest hand. The ones who held on went down with her. The ones who let go made it home, and they missed their friends every day of their lives.\n\n(Ở lại)",
		ending_silence = "Some say every lantern on the lake went out at once, and the quiet came down over the whole village, and Sen came for them one by one until morning. Bin was never found. Weeks later somebody found a camera on some old steps, with nothing on it but static and, very faint, festival music.\n\n(Im lặng)",
	},
	Messages = {
		membersOnly = "Làng Vọng is in closed playtesting: only members of the dev group can join for now.", -- DRAFT (kick message, PlaytestGate)
		membersCheckFailed = "Roblox couldn't check your group just now. Please rejoin in a moment.", -- DRAFT (PlaytestGate)
		findBin = "Find Bin.", -- brief §4 beat 7
		causewayFlooded = "The causeway is under water.", -- brief §4 beat 5
		forestEdge = "Wandering in the forest won't save you.", -- trying to leave by land; Catlyn's line, 2026-11-02
		binCamera = "Bin's camera. Still recording.", -- story.md §13 "still recording". Approved by Catlyn 2026-11-02
		binTapesHint = "Bin's camera: F to look through it, R to record, T to watch the tapes.",
		letterFound = "A letter, folded very small, under the altar.", -- approved 2026-11-02
		incenseUsed = "The incense smoke drifts out over the water.", -- approved 2026-11-02
		taken = "The water closes over you.", -- the taken player's own screen. Approved 2026-11-02
		rescued = "Incense smoke, and the shrine's lanterns. You're back.", -- approved 2026-11-02
		humming = "♪ hm, hm, %s, hm ♪", -- §5.5 step 4: a children's tune with the player's name in it. Approved 2026-11-02
		holdOrLet = "Sen is reaching for your hand.", -- the Stay ending's choice (cut, unused)
		takenSolo = "Nobody is coming for you. The lantern on the stage knows the way up.", -- DRAFT (alone, first taking)
		wayBack = "Cold grass, and the wind. The shrine's lanterns are west of you. Run.", -- DRAFT (alone, back on the shore)
	},
	-- the goal line, top right (release council 11-03 B1). DRAFT: needs Catlyn's review (all of Goals)
	Goals = {
		arrival = "Walk with Bin to the shrine at the west end of the lane.",
		listen = "Listen to Bà Thu.",
		lanterns = "Watch where the lanterns go.",
		binGone = "Where is Bin going?",
		camera = "Something is beeping in the reeds by the shrine.",
		search = "Find Bin. Search the houses the lanterns lit.",
		senHouse = "Who was the girl on Bin's tape? Try the house at the end of the lane.",
		letter = "Bring the letter to Bà Thu at the shrine.",
		walkThu = "Bà Thu is walking to the stone steps. Keep her safe until midnight.",
		midnight = "Stay with Bà Thu at the steps until midnight.",
		finale = "",
		takenTeam = "Taken. Light a lantern down here to show your friends the way; incense at the shrine brings you back.",
		takenSolo = "Taken, and alone. Find the lantern on the stage and follow it home.",
		takenFinal = "Taken for good. Watch over your friends.",
		counts = "Clues %d/%d · Mementos %d/%d · Incense %d",
	},
	-- the rules, each taught once a run when it first matters (B2). DRAFT: needs Catlyn's review (all of Rules)
	Rules = {
		water = "Bà Thu's rule: she takes the ones who are alone by the water. Stay together, or stay away from the shore.",
		incense = "You carry two sticks of incense (pick one from your hotbar and click): she backs off for a minute.",
		warning = "A child crying out on the water means she has picked you. Get away from the shore, or get close to a friend.",
		shrine = "The shrine is safe. She can't come here.",
		rescue = "%s was taken. Light incense at the shrine altar to bring them back.",
	},
	-- after an ending (B5). DRAFT: needs Catlyn's review (all of Recap)
	Recap = {
		title = "The night in Làng Vọng",
		clues = "Clues found: %d of %d",
		mementos = "Mementos: %d of %d",
		letter = "The letter reached Bà Thu's hands.",
		noLetter = "The letter was never read.",
		taken = "Taken: %s",
		nobody = "Nobody was taken.",
		minutes = "%d minutes in the village.",
		backSoon = "Back to the menu in a moment.",
		again = "The night starts again in a moment.",
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
		skip = "Skip", -- DRAFT
		skipWaiting = "Skip (waiting for the others)", -- DRAFT
		followLantern = "Follow the lantern home", -- DRAFT
	},
	Speakers = {
		BaThu = "Bà Thu",
		Bin = "Bin",
	},
	Objects = {
		binCamera = "Bin's camera",
		altar = "The family altar",
		shrineAltar = "The shrine altar",
		festivalLantern = "A lantern", -- DRAFT
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
	-- The menu (docs/ISSUES.md I-09). DRAFT: needs Catlyn review (all of Menu). "%s"/"%d" are filled in by the code.
	Menu = {
		title = "Làng Vọng",
		tagline = "A story-horror game for 1 to 4 players. Best with headphones.",
		playAlone = "Play alone",
		createTeam = "Create a team",
		joinTeam = "Join a team",
		back = "Back",
		teamOf = "%s's team", -- the team's name, from its leader's display name
		leader = "Leader",
		emptySlot = "Empty",
		open = "Open: anyone can join",
		private = "Private: friends and invites only",
		makeOpen = "Make open",
		makePrivate = "Make private",
		invite = "Invite friends",
		leave = "Leave team",
		begin = "Begin",
		waitingLeader = "Waiting for %s to begin.",
		join = "Join",
		full = "Full",
		noTeams = "No teams to join right now. Create one, or invite a friend.",
		starting = "Starting...",
		waitingTeam = "Waiting for your team (%d of %d)...", -- in the run server before it starts
		backToMenu = "Back to menu",
		cantJoin = "That team is full or private.",
		teleportFailed = "Couldn't start the game. Try again.",
		cantFollow = "Your friend's team has already started. Start your own, or wait for their next run.",
		busyStudio = "A team is already playing in this Studio session.", -- Studio only
	},
}

return Text
