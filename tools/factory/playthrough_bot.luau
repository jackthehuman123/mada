-- The playthrough bot's helpers (tools/factory/playthrough.py puts this in front of every step). Runs in the play-mode
-- CLIENT and plays like a player: walks with pathfinding, holds the real ProximityPrompts, presses the dialogue's
-- buttons (fires what they fire). State for the director lives on PlayerGui.LVBot (attributes); the events it sees are
-- appended to PlayerGui.LVBotEvents (JSON lines).
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local CS = game:GetService("CollectionService")
local PFS = game:GetService("PathfindingService")
local HS = game:GetService("HttpService")
local lp = Players.LocalPlayer
local gui = lp:WaitForChild("PlayerGui"):WaitForChild("LangVongUI", 10)
local Remotes = RS:WaitForChild("Remotes")
local C = lp:WaitForChild("PlayerScripts"):WaitForChild("LVClientDebug", 10)
local function cam(...) return C:Invoke(...) end
local state = lp.PlayerGui:FindFirstChild("LVBot")
if not state then
	state = Instance.new("Folder")
	state.Name = "LVBot"
	state.Parent = lp.PlayerGui
end
local events = lp.PlayerGui:FindFirstChild("LVBotEvents")
if not events then
	events = Instance.new("StringValue")
	events.Name = "LVBotEvents"
	events.Value = ""
	events.Parent = lp.PlayerGui
end
local T0 = state:GetAttribute("T0") or os.clock()
state:SetAttribute("T0", T0)
local function now() return math.floor((os.clock() - T0) * 10) / 10 end
local function event(kind, text)
	events.Value ..= HS:JSONEncode({ t = now(), kind = kind, text = tostring(text) }) .. "\n"
end
local ticks = {}
local function tick(label, ok, detail)
	table.insert(ticks, { label = label, ok = ok and true or false, detail = detail and tostring(detail) or "", t = now() })
	state:SetAttribute("Ticks", HS:JSONEncode(ticks))
end
local function shot(name)
	state:SetAttribute("Want", name)
	local t0 = os.clock()
	while state:GetAttribute("Got") ~= name and os.clock() - t0 < 8 do task.wait(0.1) end
end
local function root() return lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") end
local function hum() return lp.Character and lp.Character:FindFirstChildOfClass("Humanoid") end
local function phase() return RS:GetAttribute("Phase") end
local function waitFor(fn, timeout)
	local t0 = os.clock()
	while os.clock() - t0 < timeout do
		local ok, v = pcall(fn)
		if ok and v then return true end
		task.wait(0.2)
	end
	return false
end
local function goal()
	local g = gui:FindFirstChild("Goal")
	return (g and g.Visible and g:FindFirstChild("Text")) and g.Text.Text or ""
end
local function flat(a, b) return Vector3.new(a.X - b.X, 0, a.Z - b.Z).Magnitude end
-- walk there like a player (pathfinding, jumping where the path says), up to a few tries
local function walkTo(target, within)
	within = within or 4
	for _ = 1, 4 do
		local r, h = root(), hum()
		if not (r and h) then return false end
		if flat(r.Position, target) <= within then return true end
		local path = PFS:CreatePath({ AgentRadius = 2, AgentHeight = 5, AgentCanJump = true, WaypointSpacing = 6 })
		local ok = pcall(function() path:ComputeAsync(r.Position, target) end)
		if ok and path.Status == Enum.PathStatus.Success then
			for _, w in path:GetWaypoints() do
				r = root()
				if not r then return false end
				if w.Action == Enum.PathWaypointAction.Jump then h.Jump = true end
				h:MoveTo(w.Position)
				local t0 = os.clock()
				while flat(r.Position, w.Position) > 2.5 and os.clock() - t0 < 4 and r.Parent do task.wait(0.05) end
				if flat(r.Position, target) <= within then return true end
			end
		else
			h:MoveTo(target)
			local t0 = os.clock()
			while flat(r.Position, target) > within and os.clock() - t0 < 8 do task.wait(0.1) end
		end
	end
	local r = root()
	return r ~= nil and flat(r.Position, target) <= within + 2
end
local function posOf(inst)
	if inst:IsA("BasePart") then return inst.Position end
	if inst:IsA("Model") then return inst:GetPivot().Position end
	if inst:IsA("Attachment") then return inst.WorldPosition end
	return nil
end
local function findPrompt(action, near, radius)
	local best, bd, bp = nil, math.huge, nil
	for _, p in workspace:GetDescendants() do
		if p:IsA("ProximityPrompt") and p.Enabled and p.ActionText == action then
			local pos = posOf(p.Parent)
			if pos then
				local d = (pos - near).Magnitude
				if d <= (radius or math.huge) and d < bd then best, bd, bp = p, d, pos end
			end
		end
	end
	return best, bp
end
-- walk up to a prompt and hold it for its whole HoldDuration, like a player holding E: stand still first (a hold is
-- cancelled if you drift out of range, e.g. floating in water), and check it fired; up to 3 tries. Returns true if it did
local PPS = game:GetService("ProximityPromptService")
local function hold(p, pos)
	local fired = false
	local con = PPS.PromptTriggered:Connect(function(t) if t == p then fired = true end end)
	local shown = false
	local con2 = PPS.PromptShown:Connect(function(t) if t == p then shown = true end end)
	for _ = 1, 3 do
		walkTo(pos, math.max(2, p.MaxActivationDistance - 3))
		local h, r = hum(), root()
		if h and r then h:MoveTo(r.Position) end
		-- look at it, as a player does: Roblox only shows a prompt that is on screen (looking straight ahead, things on
		-- the floor or in the water below you never showed)
		local cam = workspace.CurrentCamera
		cam.CFrame = CFrame.lookAt(cam.CFrame.Position, pos)
		task.wait(0.8)
		p:InputHoldBegin()
		task.wait(p.HoldDuration + 0.5)
		p:InputHoldEnd()
		task.wait(0.5)
		if fired or not p.Parent or not p.Enabled then break end
	end
	con:Disconnect()
	con2:Disconnect()
	tick("prompt showed on screen: " .. p.ActionText, shown)
	return fired or not p.Parent or not p.Enabled
end
-- only what happened since this step began
local function since(needle)
	return events.Value:find(needle, (state:GetAttribute("EvFrom") or 0) + 1, true) ~= nil
end
local function location(name)
	for _, m in CS:GetTagged("Location") do
		if m:GetAttribute("Location") == name then return m end
	end
	return nil
end
-- the event listener (once a run)
if not state:GetAttribute("Listening") then
	state:SetAttribute("Listening", true)
	Remotes:WaitForChild("Message").OnClientEvent:Connect(function(text) event("message", text) end)
	Remotes:WaitForChild("SenWarning").OnClientEvent:Connect(function(step) event("sen_warning_" .. tostring(step), step) end)
	Remotes:WaitForChild("PlayerTaken").OnClientEvent:Connect(function(id) event("taken", id) end)
	Remotes:WaitForChild("ShowTextCard").OnClientEvent:Connect(function(id) event("card", id) end)
	Remotes:WaitForChild("DialogueShow").OnClientEvent:Connect(function(sp, text) event("dialogue", sp .. ": " .. text) end)
	Remotes:WaitForChild("Sfx").OnClientEvent:Connect(function(id) event("sfx", id) end)
	for _, a in { "Phase", "Goal", "Night1Beat" } do
		RS:GetAttributeChangedSignal(a):Connect(function() event(a, RS:GetAttribute(a)) end)
	end
	lp:GetAttributeChangedSignal("Taken"):Connect(function() event("me_taken", lp:GetAttribute("Taken")) end)
	workspace.DescendantAdded:Connect(function(d)
		if d.Name == "SenOnLand" then event("sen_on_land", "she came out of the water") end
	end)
end
