-- Release council 11-03 B7 (owner's yes 11-04): Làng Vọng's own Blender models load and replace the graybox: the
-- shrine and its altar, paper lanterns, reeds, the causeway, the village props, and Sen and the lost children (the
-- shots are the Scene Review's).
--@ Server
local RS = game:GetService("ReplicatedStorage")
local t0 = os.clock()
while not RS:FindFirstChild("ArtTemplates") and os.clock() - t0 < 60 do task.wait(0.5) end
check(RS:FindFirstChild("ArtTemplates"), "the models never loaded")
eq(#RS.ArtTemplates:GetChildren(), 19, "models")
task.wait(2) -- (the world's dressing places them right after)
local W = workspace.World
local shrine = W:FindFirstChild("Shrine", true)
check(shrine and shrine:FindFirstChild("Shrine") and shrine:FindFirstChild("Altar"), "the shrine or its altar is still the graybox")
check(W:FindFirstChild("CausewayStones", true), "no causeway stones")
local papers, reeds = 0, 0
for _, d in W:GetDescendants() do
	if d.Name == "LanternPaper" then papers += 1 end
	if d.Name == "Reed" and d:IsA("Model") then reeds += 1 end
end
check(papers >= 10, "paper lanterns: " .. papers)
check(reeds >= 5, "reed clumps: " .. reeds)
for _, item in { "Boat", "Fence", "FishRack", "Well" } do
	check(W:FindFirstChild(item, true), "no " .. item)
end
-- Sen and a child on the shore for the shots
local Figures = require(RS.Shared.Figures)
local f = Instance.new("Folder")
f.Name = "ArtShot"
f.Parent = W
Figures.Sen(CFrame.lookAt(Vector3.new(-312, 2.6, -40), Vector3.new(-300, 2.6, -30)), f, 4)
Figures.Child(CFrame.lookAt(Vector3.new(-306, 2.4, -42), Vector3.new(-300, 2.4, -30)), "Minh", 3.8, f)
local light = Instance.new("Part")
light.Anchored, light.CanCollide, light.Transparency, light.Size = true, false, 1, Vector3.one
light.Position = Vector3.new(-302, 6, -32)
local pl = Instance.new("PointLight")
pl.Range, pl.Brightness = 20, 1.2
pl.Parent = light
light.Parent = f
return string.format("13 models; shrine, altar, causeway, %d lanterns, %d reed clumps, the props", papers, reeds)
--@ Client
gui.Card.Visible = false
return "card cleared"
--@ Shot shrine-model -296,10,-30 -> -330,3,-62
--@ Shot sen-child -301,4.5,-33 -> -310,2.5,-41
--@ Shot ba-thu -334,5,-55 -> -334,3.4,-64
--@ Shot causeway -300,9,26 -> -340,0,80
--@ Shot props -150,9,-20 -> -140,1,8
--@ Shot boat -128,6,-40 -> -133,-1,-64
--@ Server
workspace.World.ArtShot:Destroy()
return "cleanup"
