--!strict
-- Clue texts (PROTOTYPE_BRIEF §6). Written from docs/design/story.md only — never invent facts.
-- Mark agent-written text with `draft = true` until Catlyn reviews it.

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
	-- M2: the two test clues the brief asks for. The rest of §6 comes in M4.
	-- DRAFT: needs Catlyn review (wording adapted from story.md "the red paper" passages)
	shrine_redpaper = {
		id = "shrine_redpaper",
		location = "Shrine",
		title = "The red paper",
		text = "A sheet of red paper pinned by the altar: the names of every child the lake took, copied out in the village head's hand. Minh. Hạnh. Tí. Khoa.\n\nThe list ends there.",
		pointsTo = { "TeacherHouse", "PuppetHouse", "FishHouse", "HeadHouse" },
		draft = true,
	},
	-- DRAFT: needs Catlyn review (story.md: the teacher's class photo)
	teacher_classphoto = {
		id = "teacher_classphoto",
		location = "TeacherHouse",
		title = "A class photo",
		text = "The village school, one row of children. At the end of the row, a skinny girl with her hair in her eyes, not smiling. Under her, in the teacher's handwriting: Sen.",
		pointsTo = { "SenHouse" },
		draft = true,
	},
}

return Clues
