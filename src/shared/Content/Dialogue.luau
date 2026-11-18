--!strict
-- Dialogue lines for Bà Thu and Bin (PROTOTYPE_BRIEF §4, §5.4, §5.7). Story facts only from story.md.
-- Bà Thu repeats her stories with one small new detail per repeat. Every line here approved by Catlyn 2026-11-02.
-- Sources: story.md §13 (the shrine scene: welcome, tea, the taken children, the old festival, the bedtime story
-- word for word, "My daughter's staying with relatives"), §2 (the festival, the market boat), §10 (the children),
-- §12 (her lanterns copied off the red paper); characters.md (voices: Thu warm, slow, repeats herself; Bin cheerful).

export type Line = { speaker: string, text: string, draft: boolean, choice: string? } -- choice: a button that must be pressed
-- (speaker "" = narration, shown without a name)
export type Conversation = { id: string, lines: { Line } }

local function thu(text: string): Line
	return { speaker = "BaThu", text = text, draft = false }
end

local function bin(text: string): Line
	return { speaker = "Bin", text = text, draft = false }
end

local function say(text: string): Line
	return { speaker = "", text = text, draft = false }
end

local Dialogue: { [string]: Conversation } = {
	-- §4 beat 2: players reach the shrine on Night 1. Bin films it (Tape 1)
	bathu_night1 = {
		id = "bathu_night1",
		lines = {
			thu("Oh. Visitors. Come in, come in out of the dark. Sit down."),
			thu("Have some tea. Nobody comes out here any more."),
			thu("Not since the lake took the children."),
			thu(
				"Minh, the teacher's boy. Hạnh, the puppet master's girl. Little Tí, with his clay whistle. And Khoa, the village head's son."
			),
			thu(
				"On Rằm tháng bảy we carried lanterns from this shrine all the way round to the puppet stage on the far shore."
			),
			thu("Hundreds of them, out in the middle of the lake. The drums, the puppets splashing."),
			thu(
				"On festival night, the lanterns carry the lost souls across the lake, to a happier place on the other side."
			),
			thu("And the carp swim beside them to show the way."),
			thu("My daughter's staying with relatives. She'll be home soon."),
		},
	},
	-- §5.4: talking to her again during the Open phase; each repeat adds one small detail, then she circles back
	bathu_repeat_1 = {
		id = "bathu_repeat_1",
		lines = {
			thu("You're back. Sit, sit. Have some tea."),
			thu("Did I tell you about the market boat? Once a week, rice and fish sauce and the mail."),
			thu("Everyone ran down to the dock when they heard its engine."),
			thu("My daughter's staying with relatives. She'll be home soon."),
		},
	},
	bathu_repeat_2 = {
		id = "bathu_repeat_2",
		lines = {
			thu("Little Tí blew that clay whistle all day long. Drove us all mad."),
			thu("One afternoon the whistle stopped. It never started again."),
			thu("She'll be home soon, my daughter."),
		},
	},
	bathu_repeat_3 = {
		id = "bathu_repeat_3",
		lines = {
			thu("Every night of ghost month I make a lantern for each of them."),
			thu("I copy their names off the red paper, stroke by stroke."),
			thu(
				"On festival night, the lanterns carry the lost souls across the lake, to a happier place on the other side."
			),
			thu("She'll be home soon."),
		},
	},
	-- §5.7: the letter given to her (story.md §15). The players read it out; she stops smiling and cries; she finishes
	-- the paper fish and asks them to write the name. "Write: Sen" is the button (brief §5.7)
	bathu_letter = {
		id = "bathu_letter",
		lines = {
			say(
				'You unfold the letter and read it out to her, because she can\'t read it herself: "Sen never came here. Where is she?"'
			),
			say("Bà Thu listens for a long time. Then she stops smiling, and she cries for her daughter."),
			say("She takes out a half-finished paper fish and finishes it, her hands going so fast."),
			-- the words she used to say to her husband (story.md §15)
			{ speaker = "BaThu", text = "Write to Sen for me.", draft = false, choice = "Write: Sen" },
			say("Sen. The first time that name has ever been written anywhere in Làng Vọng."),
		},
	},
	-- §4 beat 1 and 4: Bin's two lines (barks, shown without stopping anyone)
	bin_arrival = { id = "bin_arrival", lines = {
		bin("Look, lanterns at the shrine! Someone's here. Come on!"),
	} },
	bin_wanders = { id = "bin_wanders", lines = {
		bin("I'm getting a shot of the water. Back in a minute!"),
	} },
}

-- the order Bà Thu's repeats come in (§5.4); after the last one she starts again from the first
Dialogue.RepeatOrder = { "bathu_repeat_1", "bathu_repeat_2", "bathu_repeat_3" } :: any

return Dialogue
