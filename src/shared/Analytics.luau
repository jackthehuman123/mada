--!strict
-- Analytics stub (PROTOTYPE_BRIEF §10). Prints and keeps events in memory.
-- Later: forward to Roblox AnalyticsService without changing call sites.

local Analytics = {}

export type Event = { name: string, t: number, data: { [string]: any }? }

local events: { Event } = {}
local startTime = os.clock()

function Analytics.track(name: string, data: { [string]: any }?)
	local event: Event = { name = name, t = os.clock() - startTime, data = data }
	table.insert(events, event)
	if name == "phase_change" and data and data.phase then -- (so the summary can say when each phase began)
		table.insert(events, { name = "phase_change_" .. tostring(data.phase), t = event.t })
	end
	print(`[Analytics] {name}`, data or "")
end

function Analytics.all(): { Event }
	return events
end

-- §10: at the ending, one line with the time to each key event, so playtest sessions can be compared
function Analytics.summary(ending: string): string
	local first: { [string]: number } = {}
	local count: { [string]: number } = {}
	for _, e in events do
		first[e.name] = first[e.name] or e.t
		count[e.name] = (count[e.name] or 0) + 1
	end
	local function at(name: string): string
		return if first[name] then string.format("%dm%02ds", math.floor(first[name] / 60), math.floor(first[name] % 60)) else "-"
	end
	local line = string.format(
		"[Analytics] summary ending=%s run=%s open=%s first_clue=%s clues=%d mementos=%d tapes=%d letter_found=%s letter_given=%s thu_at_steps=%s warnings=%d taken=%d rescued=%d hints=%d",
		ending, at("ending"), at("phase_change_Open"), at("clue_found"), count.clue_found or 0, count.memento_viewed or 0,
		count.bin_tape_played or 0, at("letter_found"), at("letter_given"), at("thu_at_steps"), count.sen_warning or 0,
		count.player_taken or 0, count.player_rescued or 0, count.hint_fired or 0)
	print(line)
	return line
end

function Analytics.reset()
	table.clear(events)
	startTime = os.clock()
end

return Analytics
