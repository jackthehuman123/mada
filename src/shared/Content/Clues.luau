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
	-- TODO(M4): fill in every ClueId from PROTOTYPE_BRIEF §6.
}

return Clues
