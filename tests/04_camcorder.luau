-- M2: the camcorder (brief §5.2, §11 M2): a HiddenOnCamera dummy (Bà Thu) is visible live but absent in playback;
-- a CameraOnly object (the wet footprints) is invisible to eyes, visible in the viewfinder and in playback;
-- the battery drains with the viewfinder up and recharges in the ShrineZone
--@ Server
dbg("goto", "Shrine")
dbg("battery", 100)
-- stand facing Bà Thu, a few steps away
local thu = game:GetService("CollectionService"):GetTagged("NpcBaThu")[1]:GetPivot().Position
local root = game.Players:GetPlayers()[1].Character.HumanoidRootPart
root.CFrame = CFrame.lookAt(thu + Vector3.new(4, 1, 9), thu + Vector3.new(0, 1, 0))
task.wait(0.5)
return "at the shrine, facing Bà Thu"
--@ Client
local s = cam("state")
eq(s.cameraOnlyT, 1, "footprints to the eye")
eq(s.hiddenOnCameraT, 0, "Bà Thu to the eye")
s = cam("raise")
local thu = game:GetService("CollectionService"):GetTagged("NpcBaThu")[1]
task.wait(0.3)
cam("look", thu:GetPivot().Position)
check(s.raised, "viewfinder did not come up")
near(s.fov, Config.CameraViewfinderFov, 0.5, "viewfinder FOV")
eq(s.cameraOnlyT, 0, "footprints in the live viewfinder")
eq(s.hiddenOnCameraT, 0, "Bà Thu in the live viewfinder")
check(gui.Viewfinder.Visible, "no VHS overlay")
-- record two seconds looking at Bà Thu
cam("look", thu:GetPivot().Position)
cam("record")
task.wait(2.2)
s = cam("record")
eq(s.clips, 1, "clips after one recording")
return "eyes: no footprints, Bà Thu there; viewfinder: both; recorded a 2 s clip"
--@ Shot viewfinder-live
--@ Client
local s = cam("lower")
eq(s.cameraOnlyT, 1, "footprints hidden again when lowered")
s = cam("play", 1)
task.wait(0.6)
s = cam("state")
check(s.playing, "playback did not start")
eq(s.hiddenOnCameraT, 1, "Bà Thu on playback")
eq(s.cameraOnlyT, 0, "footprints on playback")
return "playback: Bà Thu gone, footprints shown"
--@ Shot playback
--@ Client
local t0 = os.clock()
while cam("state").playing and os.clock() - t0 < 6 do task.wait(0.2) end
local s = cam("state")
check(not s.playing, "playback never ended")
eq(s.hiddenOnCameraT, 0, "Bà Thu back after playback")
eq(s.cameraOnlyT, 1, "footprints hidden after playback")
for _ = 1, 3 do cam("raise") cam("record") task.wait(0.4) cam("record") cam("lower") end
eq(cam("state").clips, Config.CameraMaxClips, "clip cap")
return "playback ended and restored the world; clips capped at " .. Config.CameraMaxClips
--@ Server
dbg("goto", "Dock")
dbg("battery", 50)
return "at the dock, battery 50"
--@ Client
cam("raise")
task.wait(3)
cam("lower")
return "viewfinder up 3 s"
--@ Server
local b = dbg("get").batteries[game.Players:GetPlayers()[1].Name]
check(b < 50 - 0.5 and b > 50 - 3 * Config.CameraDrainPerSecond - 1, "battery after 3 s up: " .. tostring(b))
dbg("goto", "Shrine")
task.wait(2)
local b2 = dbg("get").batteries[game.Players:GetPlayers()[1].Name]
check(b2 > b + 5, "no recharge at the shrine: " .. tostring(b) .. " -> " .. tostring(b2))
return string.format("battery 50 -> %.1f with the viewfinder up; %.1f after 2 s at the shrine", b, b2)
