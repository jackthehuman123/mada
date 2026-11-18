-- Every ProximityPrompt can be reached: none sits under the ground (2026-11-04: the basin terrain buried Bin's camera in
-- the reeds and Night 1 could not go on). Checked with Night 1 at the camera beat, so the camera prompt exists too.
--@ Server
dbg("speed", 25)
dbg("sen", "off")
dbg("phase", "Night1")
local t0 = os.clock()
while (game.ReplicatedStorage:GetAttribute("Night1Beat") or 0) < 6 and os.clock() - t0 < 30 do
	task.wait(0.2)
end
local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Include
params.FilterDescendantsInstances = { workspace.Terrain }
params.IgnoreWater = true
local n, buried = 0, {}
for _, pp in workspace:GetDescendants() do
	if pp:IsA("ProximityPrompt") then
		local part = pp.Parent
		local pos = part:IsA("BasePart") and part.Position or (part:IsA("Attachment") and part.WorldPosition)
		if pos and pos.Y > -100 then -- (the drowned festival is far below the land)
			n += 1
			local hit = workspace:Raycast(Vector3.new(pos.X, pos.Y + 60, pos.Z), Vector3.new(0, -60, 0), params)
			local top = part:IsA("BasePart") and pos.Y + part.Size.Y / 2 or pos.Y
			if hit and hit.Position.Y > top + 0.3 then
				table.insert(
					buried,
					string.format(
						"%s on %s (top %.1f, ground %.1f)",
						pp.ActionText,
						part:GetFullName(),
						top,
						hit.Position.Y
					)
				)
			end
		end
	end
end
check(#buried == 0, "under the ground: " .. table.concat(buried, "; "))
check(n >= 10, "only " .. n .. " prompts found")
return n .. " prompts, none under the ground"
