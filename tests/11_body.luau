-- I-12: first person with a body: everyone holds a camcorder others can see (its REC light glows when raised), the
-- camera is locked in first person with your arms visible and your head hidden. I-13: the music layer follows the phase.
--@ Server
dbg("reset")
task.wait(3)
local p = game.Players:GetPlayers()[1]
local cam = p.Character and p.Character:FindFirstChild("Camcorder")
check(cam and cam:FindFirstChild("Rec"), "no camcorder in the hand")
p:SetAttribute("CameraUp", true)
task.wait(0.2)
check(cam.Rec.Color.R > 0.9, "REC light not on with the camera up")
p:SetAttribute("CameraUp", false)
check(typeof(p:GetAttribute("LookPitch")) == "number", "no LookPitch")
dbg("phase", "Open")
return "camcorder in hand, REC light follows CameraUp; phase Open"
--@ Client
task.wait(Config.MusicFadeSeconds + 1)
eq(lp.CameraMode, Enum.CameraMode.LockFirstPerson, "camera mode")
local char = lp.Character
local hum = char:FindFirstChildOfClass("Humanoid")
eq(hum.CameraOffset, Config.FirstPersonCameraOffset, "camera offset")
local hand = char:FindFirstChild("RightHand")
if hand and workspace.CurrentCamera.CameraType == Enum.CameraType.Custom then
	eq(hand.LocalTransparencyModifier, 0, "own hand visible")
	eq(char.Head.LocalTransparencyModifier, 1, "own head hidden")
end
check(game:GetService("SoundService"):FindFirstChild("Music_music_bed"), "no music bed in the Open phase")
return "first person, hand visible, head hidden, music bed playing"
