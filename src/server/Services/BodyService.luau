--!strict
-- Bodies everyone can read (docs/ISSUES.md I-12). Each player's camcorder is a small prop in their right hand, seen by
-- all; its REC light glows while the viewfinder is up. Where a player looks up or down comes from their client
-- (LookPitch, a few times a second) and is shared as the player attribute "LookPitch"; "CameraUp" (CamcorderService)
-- says the camera is at their eye. BodyController on every client turns those into head, waist and arm poses.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local BodyService = {}

local rgb = Color3.fromRGB
local lastPitch: { [Player]: number } = {}

local function part(m: Model, name: string, size: Vector3, color: Color3, material: Enum.Material?): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.CanCollide, p.CanQuery, p.CanTouch, p.Massless, p.CastShadow = false, false, false, true, false
	p.Parent = m
	return p
end

local function weld(a: BasePart, b: BasePart, c0: CFrame)
	local w = Instance.new("Weld")
	w.Part0, w.Part1, w.C0 = a, b, c0
	w.Parent = b
end

-- a 1990s handheld camcorder: body, lens, strap side, REC light (graybox; swap for a model in the art pass)
local function camcorder(char: Model)
	local hand = char:FindFirstChild("RightHand") or char:FindFirstChild("Right Arm")
	if not (hand and hand:IsA("BasePart")) or char:FindFirstChild("Camcorder") then
		return
	end
	local m = Instance.new("Model")
	m.Name = "Camcorder"
	local body = part(m, "Body", Vector3.new(0.45, 0.55, 1.1), rgb(38, 38, 42))
	local lens = part(m, "Lens", Vector3.new(0.38, 0.38, 0.3), rgb(18, 18, 20), Enum.Material.Glass)
	lens.Shape = Enum.PartType.Cylinder
	local rec = part(m, "Rec", Vector3.new(0.08, 0.08, 0.08), rgb(90, 20, 20), Enum.Material.Neon)
	m.PrimaryPart = body
	-- held in the palm, lens forward (R15 hand: down is -Y; R6 arm: the hand end is at -Y 1)
	local grip = if hand.Name == "RightHand" then CFrame.new(0, -0.25, -0.2) else CFrame.new(0, -1.2, -0.2)
	weld(hand, body, grip)
	weld(body, lens, CFrame.new(0, 0.05, -0.65) * CFrame.Angles(0, math.rad(90), 0))
	weld(body, rec, CFrame.new(0.12, 0.3, -0.4))
	m.Parent = char
end

local function setRec(p: Player)
	local char = p.Character
	local rec = char and char:FindFirstChild("Camcorder") and (char :: any).Camcorder:FindFirstChild("Rec") :: BasePart?
	if rec then
		rec.Color = if p:GetAttribute("CameraUp") then rgb(255, 40, 40) else rgb(90, 20, 20)
	end
end

local function onPlayer(p: Player)
	p:SetAttribute("LookPitch", 0)
	p.CharacterAdded:Connect(function(char)
		char:WaitForChild("Humanoid", 10)
		camcorder(char)
		setRec(p)
	end)
	p:GetAttributeChangedSignal("CameraUp"):Connect(function()
		setRec(p)
	end)
	if p.Character then
		camcorder(p.Character)
	end
end

function BodyService.Init()
	Remotes.event(Remotes.Names.LookPitch).OnServerEvent:Connect(function(p: Player, deg: any)
		if typeof(deg) ~= "number" or deg ~= deg then
			return
		end
		local now = os.clock()
		if now - (lastPitch[p] or 0) < 0.5 / Config.LookPitchSendHz then
			return
		end
		lastPitch[p] = now
		p:SetAttribute("LookPitch", math.round(math.clamp(deg, -Config.LookPitchMax, Config.LookPitchMax)))
	end)
end

function BodyService.Start()
	Players.PlayerAdded:Connect(onPlayer)
	for _, p in Players:GetPlayers() do
		task.spawn(onPlayer, p)
	end
	Players.PlayerRemoving:Connect(function(p)
		lastPitch[p] = nil
	end)
end

return BodyService
