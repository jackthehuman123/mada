--!strict
-- Dialogue lines for Bà Thu and Bin (PROTOTYPE_BRIEF §4, §5.4, §5.7). Story facts only from story.md.
-- Bà Thu repeats her stories with one small new detail per repeat.

export type Line = { speaker: string, text: string, draft: boolean }
export type Conversation = { id: string, lines: { Line } }

local Dialogue: { [string]: Conversation } = {
	-- TODO(M2/M3): "bathu_night1", "bathu_repeat_1..n", "bathu_letter", "bin_arrival", "bin_wanders"
}

return Dialogue
