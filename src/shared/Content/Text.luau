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
		findBin = "Find Bin.", -- brief §4 beat 7
		causewayFlooded = "The causeway is under water.", -- brief §4 beat 5
		forestEdge = "Wandering in the forest won't save you.", -- trying to leave by land; Catlyn's line, 2026-11-02
		binCamera = "Bin's camera. Still recording.", -- story.md §13 "still recording". Approved by Catlyn 2026-11-02
		binTapesHint = "Press T to watch Bin's tapes.",
		letterFound = "A letter, folded very small, under the altar.", -- approved 2026-11-02
		incenseUsed = "The incense smoke drifts out over the water.", -- approved 2026-11-02
		taken = "The water closes over you.", -- the taken player's own screen. Approved 2026-11-02
		rescued = "Incense smoke, and the shrine's lanterns. You're back.", -- approved 2026-11-02
		humming = "♪ hm, hm, %s, hm ♪", -- §5.5 step 4: a children's tune with the player's name in it. Approved 2026-11-02
		holdOrLet = "Sen is reaching for your hand.", -- the Stay ending's choice (cut, unused)
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
		busyStudio = "A team is already playing in this Studio session.", -- Studio only
	},
}

return Text
