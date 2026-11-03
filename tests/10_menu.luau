-- I-09: the menu holds players until a team begins; "Play alone" (debug "begin", run by test.py at startup) makes a
-- team of one and starts the run in this server (Studio can't teleport); characters only load for players in a run
--@ Server
local s = dbg("teams")
eq(s.kind, "Studio", "server kind")
eq(game:GetService("Players").CharacterAutoLoads, false, "CharacterAutoLoads")
local p = game.Players:GetPlayers()[1]
eq(p:GetAttribute("InRun"), true, "the player is in the run")
local mine = nil
for _, t in s.teams do
	for _, m in t.members do
		if m.userId == p.UserId then mine = t end
	end
end
check(mine, "the player has no team")
eq(#mine.members, 1, "team size")
eq(mine.starting, true, "the team has begun")
dbg("begin") -- a second Begin does nothing
check(dbg("get").phase ~= "Lobby", "the run never started")
return "Studio menu: team of 1 begun, phase " .. dbg("get").phase
--@ Client
local menu = lp.PlayerGui:WaitForChild("LangVongMenu", 5)
check(menu, "no LangVongMenu")
eq(menu.Panel.Visible, false, "menu panel hidden once in the run")
eq(gui.Enabled, true, "game UI shown once in the run")
return "menu hidden, game UI back"
