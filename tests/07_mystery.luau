-- M4 Mystery content (brief §5.1, §5.4, §6, §11 M4): every clue and memento of §6 is placed and readable; the letter
-- can be picked up from under Sen's altar; the stuck hint fires after 240 s without a new clue; the carp rise at the
-- steps. (Night 1 is skipped: these run in the Open phase, 25 times faster.)
--@ Server
dbg("speed", 25)
dbg("sen", "off")
dbg("phase", "Open")
local CS = game:GetService("CollectionService")
local Clues = require(game.ReplicatedStorage.Shared.Content.Clues)
local placed, missing = {}, {}
for _, inst in CS:GetTagged("Clue") do
	local part = inst:IsA("BasePart") and inst or inst:FindFirstChildWhichIsA("BasePart", true)
	check(part and part:FindFirstChildOfClass("ProximityPrompt"), "no Look prompt on " .. inst:GetFullName())
	placed[inst:GetAttribute("ClueId")] = true
end
for id in Clues do
	if id ~= "sen_letter" and not placed[id] then table.insert(missing, id) end
end
check(#missing == 0, "clues not placed in the world: " .. table.concat(missing, ", "))
local mementos = {}
for _, m in CS:GetTagged("Memento") do
	local part = m:FindFirstChildWhichIsA("BasePart", true)
	check(part and part:FindFirstChildOfClass("ProximityPrompt"), "no prompt on memento " .. m:GetFullName())
	table.insert(mementos, m:GetAttribute("MementoId"))
end
table.sort(mementos)
eq(#mementos, 4, "mementos (" .. table.concat(mementos, ",") .. ")")
local altar = CS:GetTagged("SenAltar")[1]
check(altar:FindFirstChild("LookUnder"), "no 'Look under the altar' prompt")
dbg("goto", "TeacherHouse")
dbg("memento", "minh")
local n = 0
for _ in placed do n += 1 end
return n .. " clues placed, each with a Look prompt; 4 mementos; the altar prompt"
--@ Client
task.wait(1.5)
check(game:GetService("SoundService"):FindFirstChild("Ambience_amb_night"), "no night ambience in the Open phase")
check(gui.Memory.Visible, "the memory did not play")
check(gui.Memory.Text.Text:find("Minh", 1, true) or gui.Memory.Text.Text ~= "", "no memory text")
return "memory: " .. gui.Memory.Text.Text
--@ Shot memento
--@ Client
local t0 = os.clock()
while gui.Memory.Visible and os.clock() - t0 < 14 do task.wait(0.2) end
check(not gui.Memory.Visible, "the memory never ended")
return "the memory faded back"
--@ Server
dbg("clue", "all")
task.wait(0.3)
local found = dbg("get").clues
local Clues = require(game.ReplicatedStorage.Shared.Content.Clues)
local total = 0
for _ in Clues do total += 1 end
eq(#found, total, "clues in the journal")
dbg("reset")
task.wait(1.5)
dbg("speed", 25)
dbg("phase", "Open")
dbg("goto", "SenHouse")
dbg("letter")
task.wait(0.3)
local s = dbg("mystery")
check(s.letterFound, "the letter was not found")
eq(s.letterHolder, game.Players:GetPlayers()[1].Name, "who holds the letter")
check(game.Players:GetPlayers()[1].Backpack:FindFirstChild("Letter"), "no Letter in the backpack")
return "every clue readable into the journal (" .. total .. "); the letter taken from under the altar"
--@ Client
task.wait(0.3)
gui.Card.Visible = false -- (the intro card from the reset)
check(gui.CluePanel.Visible and gui.CluePanel.Title.Text == "The letter", "the letter's text did not show")
return "letter: " .. gui.CluePanel.Body.Text:gsub("\n", " "):sub(1, 90)
--@ Shot sen-house 248,7,23 -> 240,2,36
--@ Client
gui.CluePanel.Visible = false
return "panel closed"
--@ Server
-- nobody finds anything for 240 s (game time): the nearest house with clues left flickers
local t0 = os.clock()
local all = ""
while os.clock() - t0 < 14 do
	local logs = {}
	for _, m in game:GetService("LogService"):GetLogHistory() do table.insert(logs, m.message) end
	all = table.concat(logs, "\n")
	if all:find("(stuck)", 1, true) then break end
	task.wait(0.25)
end
local line = all:match("%[Hint%] ([%w]+) %(stuck%)")
check(line, "no stuck hint after 240 s without a clue")
return "stuck hint fired at " .. line
--@ Server
-- climbing down the carp steps brings the carp up
local root = game.Players:GetPlayers()[1].Character.HumanoidRootPart
root.CFrame = CFrame.new(350, 2.5, 2)
local t0 = os.clock()
while not workspace.World:FindFirstChild("Carp") and os.clock() - t0 < 3 do task.wait(0.1) end
check(workspace.World:FindFirstChild("Carp"), "no carp at the steps")
return "carp rise when someone climbs down the steps"
--@ Shot carp-steps 350,6,14 -> 350,-2,-14
--@ Shot teacher-house -24,7,23 -> -30,2,36
--@ Server
dbg("speed", 1)
dbg("reset")
task.wait(1)
check(not dbg("mystery").letterFound, "the letter is still found after a reset")
return "reset clears the letter"
