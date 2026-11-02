-- M2: clue prompt -> panel -> journal with the 2 test clues; what one player finds, the group has (brief §5.1, §11 M2)
--@ Server
local CS = game:GetService("CollectionService")
for _, c in CS:GetTagged("Clue") do
	local part = c:IsA("BasePart") and c or c:FindFirstChildWhichIsA("BasePart", true)
	check(part:FindFirstChildOfClass("ProximityPrompt"), "no Look prompt on " .. c:GetFullName())
end
dbg("goto", "Shrine")
dbg("clue", "shrine_redpaper")
local s = dbg("get")
eq(s.clues[1], "shrine_redpaper", "first clue found")
return #CS:GetTagged("Clue") .. " clues have a Look prompt; red paper found"
--@ Client
task.wait(0.5)
check(gui.CluePanel.Visible, "clue panel not open")
check(gui.CluePanel.Body.Text:find("Minh", 1, true), "clue text missing")
check(gui.Journal.List:FindFirstChild("Entry_shrine_redpaper"), "not in the journal")
check(gui.Journal.List:FindFirstChild("Place_Shrine"), "journal not grouped by place")
return "panel shows the red paper; journal lists it under the shrine"
--@ Shot clue-panel
--@ Server
dbg("goto", "TeacherHouse")
dbg("clue", "teacher_classphoto")
local s = dbg("get")
eq(#s.clues, 2, "clues found")
return "class photo found: " .. table.concat(s.clues, ", ")
--@ Client
task.wait(0.5)
check(gui.Journal.List:FindFirstChild("Entry_teacher_classphoto"), "photo not in the journal")
gui.CluePanel.Visible = false
gui.Journal.Visible = true
task.wait(0.3)
--@ Shot journal
--@ Client
gui.Journal.Visible = false
return "journal shows both, grouped by place"
