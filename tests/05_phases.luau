-- The run's skeleton (brief §3): reaching the shrine starts Night 1; the Open phase runs the clock to midnight;
-- midnight -> Finale -> Ending; a reset clears the group's clues and batteries and starts a new run
--@ Server
dbg("phase", "Arrival")
dbg("goto", "Shrine")
task.wait(1)
eq(dbg("get").phase, "Night1", "phase after reaching the shrine")
dbg("phase", "Open")
near(dbg("get").clock, Config.OpenPhaseStartHour, 0.01, "clock at Open")
dbg("time", 23.999)
task.wait(1)
local p = dbg("get").phase
check(p == "Finale" or p == "Ending", "midnight did not end the night: " .. p)
return "shrine -> Night1; Open at 21:00; midnight -> " .. p
--@ Client
task.wait(0.5)
local msg = gui.Message
return "message line: " .. msg.Text
--@ Server
dbg("phase", "Ending")
task.wait(0.5)
dbg("battery", 10)
dbg("reset")
task.wait(1)
local s = dbg("get")
eq(s.phase, "Intro", "phase after reset")
eq(#s.clues, 0, "clues after reset")
eq(s.batteries[game.Players:GetPlayers()[1].Name], 100, "battery after reset")
return "reset: Intro, no clues, full battery"
--@ Client
task.wait(0.5)
check(gui.Card.Visible, "intro card not shown")
return "intro card: " .. gui.Card.Text.Text:sub(1, 60)
--@ Shot intro-card
