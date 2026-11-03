-- Release council 11-03 phase 3 (owner's yes 11-04): the goal line follows the run (search -> Sen's house -> the
-- letter); a lone player taken the first time has a way back (the festival lantern) and the run goes on; Sen walks out
-- of the water after a lone player on the shore; Bà Thu's lines can be skipped. 25 times faster, one test player.
--@ Server
dbg("speed", 25)
dbg("sen", "off")
dbg("keeprun", "off")
dbg("reset")
task.wait(1)
dbg("phase", "Open")
task.wait(1)
eq(dbg("goal"), "search", "goal at the start of the Open phase")
eq(game.ReplicatedStorage:GetAttribute("CluesTotal"), 14, "clues total (the letter is its own step)")
for _, id in { "shrine_redpaper", "shrine_photos", "teacher_classphoto", "teacher_report" } do
	dbg("clue", id)
end
task.wait(1)
eq(dbg("goal"), "senHouse", "goal after four clues")
dbg("letter")
task.wait(1)
eq(dbg("goal"), "letter", "goal with the letter found")
return "goal: search -> Sen's house -> bring the letter"
--@ Client
task.wait(0.5)
check(gui.Goal.Visible, "no goal box")
check(gui.Goal.Text.Text:find("letter", 1, true), "goal box says: " .. gui.Goal.Text.Text)
check(gui.Goal.Counts.Text:find("4/14", 1, true), "counts say: " .. gui.Goal.Counts.Text)
return "the goal box shows the letter goal and 4/14 clues"
--@ Shot goal-line
--@ Server
-- alone, the first taking: the run goes on, and the festival lantern leads home
local p = game.Players:GetPlayers()[1]
p:SetAttribute("Rescues", 0)
dbg("take")
task.wait(1.5)
check(p:GetAttribute("Taken"), "not taken")
eq(dbg("get").phase, "Open", "phase after a lone player's first taking")
local prompt = nil
for _, d in workspace.World:GetDescendants() do
	if d.Name == "WayBack" and d:IsA("ProximityPrompt") then prompt = d end
end
check(prompt and prompt.Enabled, "no way-back prompt on the festival stage")
check(dbg("wayback"), "the way back didn't work")
task.wait(1.2)
check(not p:GetAttribute("Taken"), "still taken after following the lantern")
eq(p:GetAttribute("Rescues"), 1, "rescues")
local root = p.Character.HumanoidRootPart
check(root.Position.Y > -50 and (root.Position - Config.SoloWakeSpot).Magnitude < 12, "not on the shore by the shrine: " .. tostring(root.Position))
return "alone: taken, the run goes on, the lantern on the stage leads back to the shore"
--@ Server
-- Sen on land: she comes out of the water after a lone player on the shore
local p = game.Players:GetPlayers()[1]
local root = p.Character.HumanoidRootPart
root.CFrame = CFrame.new(-40, 3, -44) -- the shore in front of the teacher's house, alone
task.wait(0.3)
check(dbg("mystery").exposed, "a lone player on the shore is not exposed")
p:SetAttribute("Incense", 0)
dbg("sen", "now")
local t0 = os.clock()
local seen = false
while os.clock() - t0 < 4 and not dbg("mystery").taken do
	if workspace.World:FindFirstChild("SenOnLand") then seen = true end
	task.wait(0.05)
end
check(seen, "Sen never came out of the water")
check(dbg("mystery").taken, "she didn't take the lone player")
local t1 = os.clock()
while dbg("get").phase ~= "Ending" and os.clock() - t1 < 8 do task.wait(0.2) end
eq(dbg("get").phase, "Ending", "the second taking (alone) is for good: Im lặng")
return "Sen walked out of the water and took them; the second taking ended the run"
--@ Server
-- Bà Thu's lines can be skipped
dbg("reset")
task.wait(1)
dbg("phase", "Night1")
local t0 = os.clock()
while dbg("get").beat ~= 2 and os.clock() - t0 < 5 do task.wait(0.1) end
task.wait(0.5)
return "Night 1: Bà Thu talking"
--@ Client
task.wait(0.3)
check(gui.Dialogue.Visible, "no dialogue box")
check(gui.Dialogue.Skip.Visible, "no skip button")
game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("DialogueSkip"):FireServer()
task.wait(0.6)
check(not gui.Dialogue.Visible, "the dialogue didn't skip")
return "skip ends Bà Thu's scene"
--@ Server
local t0 = os.clock()
while (dbg("get").beat or 0) < 3 and os.clock() - t0 < 4 do task.wait(0.1) end
check((dbg("get").beat or 0) >= 3, "Night 1 didn't move on after the skip")
dbg("reset")
return "after the skip Night 1 goes on to the lanterns"
