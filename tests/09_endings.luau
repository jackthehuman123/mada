-- M6 ★ Endings (brief §5.7, §7, §10, §11 M6; gameplay.md): giving Bà Thu the letter -> "Write: Sen" -> she walks to
-- the carp steps -> Về nhà; anything else at midnight -> Im lặng: the lanterns go out and Sen takes the players one by
-- one (Ở lại is cut). Each ends on the teller's card and the playtest summary line, and the server resets after.
--@ Server
dbg("speed", 25)
dbg("sen", "off")
dbg("phase", "Open")
dbg("goto", "Shrine")
dbg("letter")
task.wait(0.3)
dbg("talk")
local t0 = os.clock()
local logs, all = {}, ""
while os.clock() - t0 < 6 do
	logs = {}
	for _, m in game:GetService("LogService"):GetLogHistory() do table.insert(logs, m.message) end
	all = table.concat(logs, "\n")
	if all:find("[Dialogue] bathu_letter 4/5", 1, true) then break end
	task.wait(0.1)
end
check(all:find("[Ending] the letter was given to Bà Thu", 1, true), "talking to her with the letter didn't give it")
check(all:find("[Dialogue] bathu_letter 4/5", 1, true), "the letter scene never reached the name")
return "the letter given; she asks for the name"
--@ Client
task.wait(0.3)
check(gui.Dialogue.Visible and gui.Dialogue.Choice.Visible, "no 'Write: Sen' button")
eq(gui.Dialogue.Choice.Text, "Write: Sen", "choice")
return "dialogue: " .. gui.Dialogue.Line.Text .. " [" .. gui.Dialogue.Choice.Text .. "]"
--@ Shot write-sen
--@ Server
dbg("write")
local t0 = os.clock()
while not dbg("ending").walking and os.clock() - t0 < 5 do task.wait(0.1) end
check(dbg("ending").nameWritten, "the name was not written")
check(dbg("ending").walking, "Bà Thu did not start walking")
local thu = game:GetService("CollectionService"):GetTagged("NpcBaThu")[1]
local start = thu:GetPivot().Position
task.wait(1)
check((thu:GetPivot().Position - start).Magnitude > 5, "Bà Thu isn't moving")
while dbg("get").phase == "Open" and os.clock() - t0 < 20 do task.wait(0.1) end
check(dbg("ending").thuAtSteps, "Bà Thu never reached the bottom step")
eq(dbg("get").phase, "Finale", "phase when she reached the steps")
dbg("speed", 3) -- slow the finale down for the screenshots
local t1 = os.clock()
while os.clock() - t1 < 12 do
	local logs = {}
	for _, m in game:GetService("LogService"):GetLogHistory() do table.insert(logs, m.message) end
	if table.concat(logs, "\n"):find("Sen comes up", 1, true) then break end
	task.wait(0.1)
end
task.wait(1.2)
return "Write: Sen -> she walked to the bottom step (" .. math.floor(os.clock() - t0) .. " s at 25x) -> Về nhà finale"
--@ Shot finale-home
--@ Server
dbg("speed", 25)
local t0 = os.clock()
while dbg("get").phase ~= "Ending" and os.clock() - t0 < 15 do task.wait(0.1) end
eq(dbg("get").phase, "Ending", "phase after the finale")
eq(dbg("ending").ending, "home", "ending")
local logs = {}
for _, m in game:GetService("LogService"):GetLogHistory() do table.insert(logs, m.message) end
local all = table.concat(logs, "\n")
for _, line in { "[Ending] Bà Thu reached the bottom step", "Sen comes up, holding hands", "Bà Thu takes her daughter's hand", "[Bin] asleep on the bank",
	"[Analytics] summary ending=home" } do
	check(all:find(line, 1, true), "missing: " .. line)
end
return "Về nhà: Sen and the children rise, Bà Thu takes her hand, dawn, Bin asleep on the bank; summary printed"
--@ Client
task.wait(0.5)
check(gui.Card.Visible and gui.Card.Text.Text:find("Về nhà", 1, true), "no Về nhà card")
return "card: " .. gui.Card.Text.Text:gsub("\n", " "):sub(1, 80)
--@ Shot ending-home
--@ Server
-- Ở lại is cut: at the steps at midnight, the letter never given, it's Im lặng, and Sen takes the player
dbg("reset")
task.wait(1.5)
dbg("speed", 25)
dbg("sen", "off")
dbg("phase", "Open")
local root = game.Players:GetPlayers()[1].Character.HumanoidRootPart
root.CFrame = CFrame.new(350, 3, 6)
task.wait(0.3)
dbg("time", 23.999)
local t0 = os.clock()
while dbg("get").phase ~= "Ending" and os.clock() - t0 < 8 do task.wait(0.1) end
eq(dbg("ending").ending, "silence", "ending at the steps")
eq(game.Players:GetPlayers()[1]:GetAttribute("Taken"), true, "Sen didn't take the player in Im lặng")
return "midnight at the carp steps -> Im lặng; the player was taken"
--@ Client
check(not gui.Stay.Visible, "the hold on / let go choice showed")
check(not gui.Taken.Visible, "'Light a lantern' showed after the night ended")
return "no Ở lại choice, no lantern button"
--@ Server
-- Im lặng: midnight anywhere else
dbg("reset")
task.wait(1.5)
dbg("speed", 25)
dbg("sen", "off")
dbg("phase", "Open")
dbg("goto", "CommunalHouse")
task.wait(0.3)
dbg("time", 23.999)
local t0 = os.clock()
while dbg("get").phase ~= "Ending" and os.clock() - t0 < 8 do task.wait(0.1) end
eq(dbg("ending").ending, "silence", "ending")
local lit = 0
for _, d in workspace.World:GetDescendants() do
	if d:IsA("BasePart") and d.Name == "PaperLantern" and d.Material == Enum.Material.Neon then lit += 1 end
end
eq(lit, 0, "lanterns still lit in Im lặng")
return "Im lặng: every lantern went out"
--@ Client
task.wait(0.3)
check(gui.ScreenStatic.Visible, "no static")
check(not game:GetService("SoundService"):FindFirstChild("Ambience_amb_night"), "the night still sounds in Im lặng")
check(gui.Card.Text.Text:find("Im lặng", 1, true), "no Im lặng card")
return "static and the Im lặng card"
--@ Shot ending-silence
--@ Server
dbg("speed", 1)
dbg("reset")
task.wait(1.5)
local lit = 0
for _, d in workspace.World:GetDescendants() do
	if d:IsA("BasePart") and d.Name == "PaperLantern" and d.Material == Enum.Material.Neon then lit += 1 end
end
check(lit >= 10, "the lanterns didn't come back after the reset (" .. lit .. ")")
local thu = game:GetService("CollectionService"):GetTagged("NpcBaThu")[1]
check((thu:GetPivot().Position - Vector3.new(-334, 2.4, -64)).Magnitude < 1, "Bà Thu isn't back on her mat")
eq(dbg("ending").ending, nil, "ending after reset")
return "reset: lanterns lit again, Bà Thu back on her mat, no ending"
--@ Client
task.wait(0.5)
check(workspace.CurrentCamera.CameraType == Enum.CameraType.Custom, "the camera is still in the finale")
check(not gui.ScreenStatic.Visible, "static still up")
return "camera and screen back to normal"
