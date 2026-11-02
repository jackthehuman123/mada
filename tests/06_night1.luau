-- M3 ★ Night 1 (brief §4, §5.3, §5.4, §11 M3): beats 1-7 run unaided and log "[Night1] beat N": Bin walks with the
-- players; Bà Thu's scene at the shrine; four lanterns drift and light four windows (Sen's stays dark); Bin wanders
-- off and vanishes; the causeway floods; Bin's camera gives the group both tapes; the run ends in Open.
-- Night 1 runs 25 times faster here (DebugService "speed"); the tapes play in real time.
--@ Server
dbg("speed", 25)
dbg("phase", "Arrival")
task.wait(0.5)
local s = dbg("night1")
eq(s.beat, 1, "beat at Arrival")
check(s.bin, "Bin is not there at Arrival")
eq(s.binMode, "follow", "Bin's mode at Arrival")
dbg("goto", "Shrine")
local t0 = os.clock()
while dbg("night1").beat < 2 and os.clock() - t0 < 4 do task.wait(0.1) end
eq(dbg("get").phase, "Night1", "phase after reaching the shrine")
while dbg("night1").beat < 3 and os.clock() - t0 < 14 do task.wait(0.1) end
eq(dbg("night1").beat, 3, "beat after Bà Thu's scene")
return string.format("beat 1 with Bin following; shrine -> beat 2 (Bà Thu's scene) -> beat 3 in %.1f s", os.clock() - t0)
--@ Server
local t0 = os.clock()
while dbg("night1").beat < 4 and os.clock() - t0 < 12 do task.wait(0.1) end
local s = dbg("night1")
check(s.beat >= 4, "lanterns never all arrived (beat " .. tostring(s.beat) .. ")")
local lit = {}
for house, on in s.windows do if on then table.insert(lit, house) end end
table.sort(lit)
eq(#lit, 4, "windows lit (" .. table.concat(lit, ", ") .. ")")
for _, h in { "HeadHouse", "FishHouse", "PuppetHouse", "TeacherHouse" } do check(s.windows[h], h .. " window not lit") end
check(not s.windows.SenHouse, "Sen's window is lit")
return "four lanterns arrived; lit: " .. table.concat(lit, ", ") .. "; Sen's house dark"
--@ Shot lit-windows -60,16,-80 -> -115,5,22
--@ Server
local t0 = os.clock()
while dbg("night1").beat < 6 and os.clock() - t0 < 12 do task.wait(0.1) end
local s = dbg("night1")
eq(s.beat, 6, "beat after Bin wanders off")
check(not s.bin, "Bin is still there")
check(s.flooded, "the causeway is not flooded")
check(s.camera, "Bin's camera is not in the reeds")
-- walking out along the flooded causeway brings you back to the shore
local root = game.Players:GetPlayers()[1].Character.HumanoidRootPart
local zone = workspace:FindFirstChild("FloodBoundary", true)
root.CFrame = CFrame.new(zone.Position + Vector3.new(0, 3, 0))
local back = game:GetService("CollectionService"):GetTagged("ShoreReturn")[1]
local t1 = os.clock()
while os.clock() - t1 < 6 and (root.Position - back.Position).Magnitude > 12 do task.wait(0.2) end
check((root.Position - back.Position).Magnitude <= 12, "not returned from the flooded causeway: " .. tostring(root.Position))
return string.format("Bin gone, causeway flooded (back to the shore in %.1f s), camera in the reeds", os.clock() - t1)
--@ Shot flooded-causeway -300,22,20 -> -360,0,110
--@ Shot bin-camera -280,7,-40 -> -286,-1,-55
--@ Server
dbg("pickup")
local t0 = os.clock()
while dbg("get").phase ~= "Open" and os.clock() - t0 < 4 do task.wait(0.1) end
local s = dbg("night1")
eq(dbg("get").phase, "Open", "phase after picking up Bin's camera")
eq(s.beat, 7, "beat")
check(s.tapes, "the group has no tapes")
near(dbg("get").clock, Config.OpenPhaseStartHour, 0.01, "clock at Open")
local logs = {}
for _, m in game:GetService("LogService"):GetLogHistory() do table.insert(logs, m.message) end
local all = table.concat(logs, "\n")
for n = 1, 7 do check(all:find("[Night1] beat " .. n, 1, true), "no '[Night1] beat " .. n .. "' line") end
return "picked up Bin's camera -> Open at 21:00 with the tapes; console has [Night1] beat 1..7"
--@ Client
task.wait(0.5)
local names = cam("chooser")
local have = table.concat(names, ",")
check(have:find("Tape1", 1, true) and have:find("Tape2", 1, true), "Bin's tapes not in the chooser: " .. have)

local s = cam("tape", 1)
task.wait(1.5)
s = cam("state")
check(s.playing, "tape 1 is not playing")
eq(s.playingName, "bin_tape1", "tape")
eq(gui.Viewfinder.Time.Text, "19:04", "the time burned into tape 1")
eq(s.hiddenOnCameraT, 1, "Bà Thu on Bin's tape 1")
return "chooser: " .. have .. "; tape 1 plays and Bà Thu isn't on it"
--@ Shot tape1
--@ Client
cam("stopplay")
task.wait(0.3)
cam("tape", 2)
task.wait(7.2)
local s = cam("state")
eq(s.playingName, "bin_tape2", "tape")
eq(s.ghosts, 1, "the girl in the water on tape 2")
check(not workspace:FindFirstChild("Ghost_GirlInWater", true) or workspace.TapeGhosts, "ghost outside the tape folder")
return "tape 2: down the steps; the girl stands in the water"
--@ Shot tape2
--@ Client
local t0 = os.clock()
while not cam("state").static and os.clock() - t0 < 5 do task.wait(0.1) end
check(cam("state").static, "tape 2 did not end in static")
while cam("state").playing and os.clock() - t0 < 8 do task.wait(0.2) end
local s = cam("state")
check(not s.playing, "tape 2 never ended")
eq(s.ghosts, 0, "ghosts left after the tape")
check(not workspace:FindFirstChild("TapeGhosts"), "the tape's ghost folder is still there")
eq(s.hiddenOnCameraT, 0, "Bà Thu back after the tape")
return "tape 2 ends in static; the girl is gone with it; Bà Thu back"
--@ Server
dbg("goto", "Shrine")
dbg("talk")
task.wait(0.3)
return "talking to Bà Thu again (Open phase)"
--@ Client
local d = gui.Dialogue
check(d.Visible, "no dialogue box")
eq(d.Speaker.Text, "Bà Thu", "speaker")
return "dialogue: " .. d.Speaker.Text .. ": " .. d.Line.Text:sub(1, 60)
--@ Shot dialogue
--@ Server
dbg("time", 23)
local t0 = os.clock()
local all = ""
while os.clock() - t0 < 4 do
	local logs = {}
	for _, m in game:GetService("LogService"):GetLogHistory() do table.insert(logs, m.message) end
	all = table.concat(logs, "\n")
	if all:find("[Lanterns] second drift", 1, true) then break end
	task.wait(0.2)
end
check(all:find("[Lanterns] second drift", 1, true), "no second lantern drift at 23:00")
local n = #workspace.World:WaitForChild("NightLanterns"):GetChildren()
eq(n, 4, "lanterns on the water in the second drift")
dbg("speed", 1)
dbg("reset")
task.wait(1)
local s = dbg("night1")
eq(s.beat, 0, "beat after reset")
check(not s.flooded and not s.tapes and not s.camera, "Night 1 left things behind after a reset")
local lit = 0
for _, on in s.windows do if on then lit += 1 end end
eq(lit, 0, "lit windows after reset")
return "23:00: the lanterns go out again; reset clears flood, camera, tapes and windows"
