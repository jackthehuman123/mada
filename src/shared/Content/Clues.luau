--!strict
-- Clue texts (PROTOTYPE_BRIEF §6). Written from docs/design/story.md only — never invent facts.
-- Mark agent-written text with `draft = true` until Catlyn reviews it. Every clue below approved by Catlyn 2026-11-02.
-- Clues are objects and documents, never explanations (story-keeper rules). Under ~80 words each.

export type Clue = {
	id: string,
	location: string, -- Location name, e.g. "TeacherHouse"
	title: string,
	text: string,
	image: string?, -- rbxassetid://...
	pointsTo: { string }?, -- Location names this clue leads to (for hint logic)
	draft: boolean,
}

local Clues: { [string]: Clue } = {
	-- The shrine (story.md §11, §14)
	shrine_redpaper = {
		id = "shrine_redpaper",
		location = "Shrine",
		title = "The red paper",
		text = "A sheet of red paper pinned by the altar: the names of every child the lake took, copied out in the village head's hand. Minh. Hạnh. Tí. Khoa.\n\nThe list ends there.",
		pointsTo = { "TeacherHouse", "PuppetHouse", "FishHouse", "HeadHouse" },
		draft = false,
	},
	shrine_photos = {
		id = "shrine_photos",
		location = "Shrine",
		title = "Photographs by the altar",
		text = "Small photographs propped against the incense bowl, one for each name on the red paper. A serious boy in glasses. A girl holding a puppet. A small boy with a clay whistle. An older boy with a fishing rod.\n\nThere are no others.",
		pointsTo = { "TeacherHouse", "PuppetHouse", "FishHouse", "HeadHouse" },
		draft = false,
	},
	-- The teacher's house: Minh (story.md §14; gameplay.md "The four houses")
	teacher_classphoto = {
		id = "teacher_classphoto",
		location = "TeacherHouse",
		title = "A class photo",
		text = "The village school, one row of children. At the end of the row, a skinny girl with her hair in her eyes, not smiling. Under her, in the teacher's handwriting: Sen.",
		pointsTo = { "SenHouse" },
		draft = false,
	},
	teacher_report = {
		id = "teacher_report",
		location = "TeacherHouse",
		title = "A report, never sent",
		text = "A report on one of his pupils, in the teacher's careful hand. Something is wrong in that house. The father keeps his wife and daughter away from the festival, from weddings, from everyone.\n\nIt was never sent. It stayed in his drawer.",
		pointsTo = { "SenHouse" },
		draft = false,
	},
	minh_notebook = {
		id = "minh_notebook",
		location = "TeacherHouse",
		title = "Minh's exercise book",
		text = "A schoolboy's exercise book: sums, some marked wrong in red.\n\nOn the last page, in pencil: \"Hạnh, after school. Under the stage.\"",
		pointsTo = { "PuppetHouse" },
		draft = false,
	},
	-- The puppet master's house: Hạnh (story.md §7, §14)
	puppet_diary = {
		id = "puppet_diary",
		location = "PuppetHouse",
		title = "The puppet master's diary",
		text = "Festival night. From the stage I saw one lantern come drifting out from behind the last house on the lane, where no lantern had any business coming from. I watched it join the others in the middle of the lake.\n\nThat's strange, I thought.\n\nI said nothing.",
		pointsTo = { "SenHouse", "CarpSteps" },
		draft = false,
	},
	-- The fish seller's house: Tí (story.md §9, §14)
	fish_notes = {
		id = "fish_notes",
		location = "FishHouse",
		title = "The fish seller's notes",
		text = "Notes between the prices in a market ledger.\n\nA letter came on the boat for him, from his sister in the city. I handed it to him over my baskets. He read it right there at the stall, and his face went the color of ash.\n\nAll he said was: \"Don't mention this to Thu.\"",
		pointsTo = { "SenHouse" },
		draft = false,
	},
	-- The village head's house: Khoa (story.md §11, §14)
	head_minutes = {
		id = "head_minutes",
		location = "HeadHouse",
		title = "Minutes of the last meeting",
		text = "Minutes of the meeting at the communal house. The vote: stop the festival, and leave Làng Vọng for good.\n\nA question from the floor: \"What about Thu's girl? Has anyone ever had a letter from Thu's girl?\"\n\nUnder it, one line: Told to sit down.",
		pointsTo = { "Shrine", "TeacherHouse" },
		draft = false,
	},
	head_redpaper_draft = {
		id = "head_redpaper_draft",
		location = "HeadHouse",
		title = "A spoiled sheet of red paper",
		text = "Red paper, the names written out once and set aside for a neater copy: Minh. Hạnh. Tí. Khoa.\n\nThe same four names that hang at the shrine.",
		pointsTo = { "Shrine" },
		draft = false,
	},
	-- The house at the end of the lane: Sen's (story.md §4, §14)
	sen_doorframe = {
		id = "sen_doorframe",
		location = "SenHouse",
		title = "The doorframe",
		text = "The doorframe where a family marks how tall its children are getting.\n\nThis one has no marks at all.",
		draft = false,
	},
	sen_bowl = {
		id = "sen_bowl",
		location = "SenHouse",
		title = "A small bowl",
		text = "One small bowl and a pair of chopsticks, set at one place at the table.\n\nFreshly washed.",
		draft = false,
	},
	sen_chair = {
		id = "sen_chair",
		location = "SenHouse",
		title = "An old woman's chair",
		text = "An old woman's chair in the back room, turned to face the door. Beside it, teacups gray with years of dust.\n\nThey are the same cups as the ones at the shrine.",
		pointsTo = { "Shrine" },
		draft = false,
	},
	sen_fishlantern = {
		id = "sen_fishlantern",
		location = "SenHouse",
		title = "A paper fish",
		text = "On the shelf, a paper lantern folded in the shape of a carp. Half finished.\n\nNo name is written on it.",
		draft = false,
	},
	sen_letter = {
		id = "sen_letter",
		location = "SenHouse",
		title = "The letter",
		text = "A letter from the city, folded up very small and hidden under the altar, under the ancestors' photographs. One line:\n\nSen never came here. Where is she?",
		pointsTo = { "Shrine" },
		draft = false,
	},
	-- The carp steps (story.md §14)
	steps_sandals = {
		id = "steps_sandals",
		location = "CarpSteps",
		title = "Little sandals",
		text = "Little sandals lined up on the stone steps, one pair for every lost child.",
		draft = false,
	},
}

return Clues
