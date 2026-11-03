-- First person: nothing worn on your own head shows (the playthrough bot found long hair filling the screen: newer
-- avatars hold hair with a RigidConstraint, and only welded hats were hidden).
--@ Server
dbg("phase", "Open")
task.wait(1)
return "Open phase"
--@ Client
task.wait(1.5)
local char = lp.Character
local head = char:FindFirstChild("Head")
local worn, shown = 0, {}
for _, a in char:GetChildren() do
	if a:IsA("Accessory") then
		local h = a:FindFirstChild("Handle")
		local onHead = a.AccessoryType == Enum.AccessoryType.Hat or a.AccessoryType == Enum.AccessoryType.Hair
			or (h and head and (h.Position - head.Position).Magnitude < 1.6)
		if h and onHead then
			worn += 1
			if h.LocalTransparencyModifier < 1 then table.insert(shown, a.Name) end
		end
	end
end
check(#shown == 0, "still showing in first person: " .. table.concat(shown, ", "))
return worn .. " head accessories, all hidden in first person"
--@ Shot first-person
