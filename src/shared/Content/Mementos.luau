--!strict
-- Mementos (PROTOTYPE_BRIEF §5.1, §6): one in each lost child's house. Picking one up plays a short memory of that
-- child's last day: the screen fades, 2-4 lines of text, a sound, fade back. Every memory approved by Catlyn
-- 2026-11-02, from story.md §10 ("The lake keeps them") and characters.md ("The lost children") only.

export type Memento = { id: string, child: string, house: string, object: string, lines: { string }, sound: string, draft: boolean }

local Mementos: { [string]: Memento } = {
	minh = {
		id = "minh", child = "Minh", house = "TeacherHouse", object = "A report card with one red mark",
		lines = {
			"Minh, eleven. The teacher's son. Glasses, and afraid of disappointing his father.",
			"A scolding over his marks.",
			"He ran down to the water by himself.",
		},
		sound = "memento_minh", draft = false,
	},
	hanh = {
		id = "hanh", child = "Hạnh", house = "PuppetHouse", object = "A broken water puppet",
		lines = {
			"Hạnh, nine. The puppet master's girl.",
			"She liked to play by herself under the stage, playing pretend with the puppets.",
			"Nobody was watching.",
		},
		sound = "memento_hanh", draft = false,
	},
	ti = {
		id = "ti", child = "Tí", house = "FishHouse", object = "A clay whistle",
		lines = {
			"Tí, six. The fish seller's little one, blowing his clay whistle all day long.",
			"One afternoon the whistle stopped.",
			"It never started again.",
		},
		sound = "memento_ti", draft = false,
	},
	khoa = {
		id = "khoa", child = "Khoa", house = "HeadHouse", object = "A festival drumstick",
		lines = {
			"Khoa, twelve. The village head's son. Quiet, patient.",
			"He liked to fish alone.",
			"He went fishing by himself at dusk.",
		},
		sound = "memento_khoa", draft = false,
	},
}

return Mementos
