-- M1: every place of brief §8 exists and is tagged with its Location; each is reachable on foot from the spawn;
-- night lighting; boundaries bring players back to the shore (brief §11 M1)
--@ Server
local want = { "Shrine", "Dock", "CommunalHouse", "HeadHouse", "FishHouse", "PuppetHouse", "TeacherHouse", "TellerHouse",
	"SenHouse", "Causeway", "CarpSteps", "DrownedFestival" }
local have = {}
for _, l in dbg("locations") do have[l] = true end
for _, l in want do check(have[l], "missing Location " .. l) end
local CS = game:GetService("CollectionService")
eq(#CS:GetTagged("ShrineZone"), 1, "ShrineZone")
eq(#CS:GetTagged("LanternStop"), 4, "LanternStops (one per lost child's house)")
check(#CS:GetTagged("HouseWindow") >= 5, "HouseWindows")
check(#CS:GetTagged("WaterEdge") >= 20, "WaterEdges")
check(#CS:GetTagged("BoundaryTeleport") >= 6, "boundaries")
eq(#CS:GetTagged("SenAltar"), 1, "SenAltar")
check(game.Lighting.ClockTime >= 18 or game.Lighting.ClockTime < 6, "not night: " .. game.Lighting.ClockTime)
return #want .. " places tagged; lanterns stops, windows, water edges, boundaries ok"
--@ Server
-- on foot from the spawn to every place (the drowned festival is below the lake: players only get there taken)
local PFS = game:GetService("PathfindingService")
local spawn = workspace.World:FindFirstChild("Spawn", true)
local from = spawn.Position + Vector3.new(0, 3, 0)
local reached, failed = {}, {}
for _, m in game:GetService("CollectionService"):GetTagged("Location") do
	local name = m:GetAttribute("Location")
	if name ~= "DrownedFestival" then
		local path = PFS:CreatePath({ AgentRadius = 2, AgentHeight = 5, AgentCanJump = true, WaypointSpacing = 8 })
		path:ComputeAsync(from, m:GetPivot().Position)
		if path.Status == Enum.PathStatus.Success then
			local w = path:GetWaypoints()
			table.insert(reached, string.format("%s %d", name, math.floor((w[#w].Position - from).Magnitude)))
		else
			table.insert(failed, name .. " (" .. path.Status.Name .. ")")
		end
	end
end
check(#failed == 0, "no walking path to: " .. table.concat(failed, ", "))
table.sort(reached)
return "walkable from the spawn: " .. table.concat(reached, ", ")
--@ Server
-- walk into the lake's boundary: back on the shore within a few seconds
local p = game.Players:GetPlayers()[1]
local root = p.Character.HumanoidRootPart
root.CFrame = CFrame.new(0, 3, -140) -- inside the lake's boundary wall
local back = game:GetService("CollectionService"):GetTagged("ShoreReturn")[1]
local t0 = os.clock()
while os.clock() - t0 < 6 and (root.Position - back.Position).Magnitude > 12 do task.wait(0.2) end
check((root.Position - back.Position).Magnitude <= 12, "not returned to the shore: " .. tostring(root.Position))
return string.format("returned to the shore in %.1f s", os.clock() - t0)
--@ Client
gui.Card.Visible = false -- (the intro card may still be up)
return "card cleared"
--@ Shot top-down -20,170,150 -> -20,0,-40
--@ Shot lane -120,7,-26 -> 120,4,-14
--@ Shot shrine -296,10,-30 -> -330,3,-62
--@ Shot sen-house 245,8,-34 -> 245,5,30
--@ Shot carp-steps 352,14,40 -> 350,-4,-30
