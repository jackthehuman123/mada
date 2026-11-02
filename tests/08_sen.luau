-- M5 Sen + taken (brief §5.5, §5.6, §11 M5): a player alone by the water gets the five warnings in order, then is
-- taken to the drowned festival (dropping the letter); a taken player can light a lantern; incense at the shrine brings
-- them back; incense makes Sen withdraw; leaving the water cancels her; the shrine is safe; a second taking is for
-- good, and when everyone is taken the run goes to Im lặng. 25 times faster; one test player, so "DebugKeepRun"
-- stops the first taking from ending the run.
--@ Server
dbg("speed", 25)
dbg("sen", "off")
dbg("keeprun", "on")
dbg("phase", "Open")
dbg("goto", "Dock")
local root = game.Players:GetPlayers()[1].Character.HumanoidRootPart
root.CFrame = CFrame.new(-140, 3, -70) -- out on the dock, alone, over the water
task.wait(0.3)
check(dbg("mystery").exposed, "a lone player on the dock is not exposed to Sen")
dbg("letter")
root.CFrame = CFrame.new(-140, 3, -70)
dbg("sen", "now")
local t0 = os.clock()
while not dbg("mystery").taken and os.clock() - t0 < 4 do task.wait(0.1) end
check(dbg("mystery").taken, "not taken after the warnings")
task.wait(1)
local logs = {}
for _, m in game:GetService("LogService"):GetLogHistory() do table.insert(logs, m.message) end
local all = table.concat(logs, "\n")
local last = 0
for n = 1, 5 do
	local at = all:find("[Sen] warning " .. n, last + 1, true)
	check(at, "warning " .. n .. " missing or out of order")
	last = at
end
check(root.Position.Y < -300, "not in the drowned festival: " .. tostring(root.Position))
local s = dbg("mystery")
check(s.letterFound and s.letterHolder == nil, "the letter did not drop when its holder was taken")
check(workspace.World:FindFirstChild("Letter"), "the dropped letter isn't in the world")
eq(dbg("get").phase, "Open", "phase (DebugKeepRun)")
-- resetting your character doesn't get you out
local plr = game.Players:GetPlayers()[1]
local char = plr.Character
char.Humanoid.Health = 0
local t1 = os.clock()
while (plr.Character == char or not (plr.Character and plr.Character:FindFirstChild("HumanoidRootPart"))) and os.clock() - t1 < 12 do task.wait(0.2) end
task.wait(0.6)
check(plr.Character ~= char, "no respawn")
check(plr.Character.HumanoidRootPart.Position.Y < -300, "a taken player who reset woke on the surface: " .. tostring(plr.Character.HumanoidRootPart.Position))
return "warnings 1-5 in order, then taken to the drowned festival; the letter dropped where they stood"
--@ Client
task.wait(0.5)
gui.Card.Visible = false -- (the intro card from the previous file's reset)
check(gui.Taken.Visible, "no 'Light a lantern' button for the taken player")
check(game:GetService("SoundService"):FindFirstChild("Ambience_amb_underwater"), "no underwater sound for the taken player")
local story = lp.PlayerScripts:WaitForChild("LVStoryDebug")
story:Invoke("lantern")
return "taken: the lantern button is up; lit a lantern"
--@ Shot drowned-festival
--@ Server
local t0 = os.clock()
local all = ""
while os.clock() - t0 < 3 do
	local logs = {}
	for _, m in game:GetService("LogService"):GetLogHistory() do table.insert(logs, m.message) end
	all = table.concat(logs, "\n")
	if all:find("(taken)", 1, true) then break end
	task.wait(0.1)
end
check(all:find("(taken)", 1, true), "the taken player's lantern did not flicker anywhere")
eq(dbg("rescue"), game.Players:GetPlayers()[1].Name, "rescued")
task.wait(1.5)
local p = game.Players:GetPlayers()[1]
check(not dbg("mystery").taken, "still taken after the incense at the shrine")
eq(p:GetAttribute("Rescues"), 1, "rescues")
check(dbg("inshrine"), "not back at the shrine")
check(not dbg("mystery").exposed, "Sen can reach a player in the shrine")
return "the lantern flickered near a clue; incense at the shrine brought them back; the shrine is safe"
--@ Client
task.wait(0.3)
check(not gui.Taken.Visible, "the lantern button is still up")
return "back: the lantern button is gone"
--@ Server
-- incense makes her withdraw
local root = game.Players:GetPlayers()[1].Character.HumanoidRootPart
root.CFrame = CFrame.new(-140, 3, -70)
task.wait(0.2)
dbg("sen", "now")
task.wait(0.3)
check(dbg("incense"), "incense could not be used")
task.wait(0.6)
local s = dbg("mystery")
check(not s.taken, "taken despite the incense")
eq(s.incense, 1, "incense left")
check(not s.exposed, "Sen didn't withdraw")
-- after the incense wears off, walking away from the water cancels her
task.wait(Config.IncenseWithdrawSeconds / 25 + 0.3)
root.CFrame = CFrame.new(-140, 3, -70)
task.wait(0.2)
check(dbg("mystery").exposed, "exposed again after the incense wore off")
dbg("sen", "now")
task.wait(0.1)
dbg("goto", "CommunalHouse")
task.wait(0.6)
check(not dbg("mystery").taken, "taken after walking away from the water")
local logs = {}
for _, m in game:GetService("LogService"):GetLogHistory() do table.insert(logs, m.message) end
local all = table.concat(logs, "\n")
check(all:find("[Sen] withdraws (incense)", 1, true), "no withdraw line")
check(all:find("[Sen] warning cancelled", 1, true), "no cancelled line")
return "incense: she withdraws (1 left); walking away from the water cancels her"
--@ Server
-- the second taking is for good, and with everyone taken the run goes to Im lặng
dbg("keeprun", "off")
local root = game.Players:GetPlayers()[1].Character.HumanoidRootPart
root.CFrame = CFrame.new(-140, 3, -70)
task.wait(0.2)
dbg("sen", "now")
local t0 = os.clock()
while dbg("get").phase ~= "Ending" and os.clock() - t0 < 10 do task.wait(0.2) end
eq(dbg("get").phase, "Ending", "phase after everyone was taken")
eq(dbg("ending").ending, "silence", "ending")
eq(game.Players:GetPlayers()[1]:GetAttribute("TakenFinal"), true, "the second taking is for good")
local logs = {}
for _, m in game:GetService("LogService"):GetLogHistory() do table.insert(logs, m.message) end
check(table.concat(logs, "\n"):find("[Analytics] summary ending=silence", 1, true), "no summary line")
dbg("speed", 1)
dbg("reset")
task.wait(1.5)
check(not dbg("mystery").taken, "still taken after a reset")
return "second taking for good -> everyone taken -> Im lặng; summary printed; reset brings everyone back"
