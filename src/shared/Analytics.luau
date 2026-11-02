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
	print(`[Analytics] {name}`, data or "")
end

function Analytics.all(): { Event }
	return events
end

function Analytics.reset()
	table.clear(events)
	startTime = os.clock()
end

return Analytics
