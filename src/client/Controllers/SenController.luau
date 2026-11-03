--!strict
-- Being taken, seen from your own eyes (docs/ISSUES.md I-16, Catlyn's storyboard 2026-11-02). The server
-- (SenService.Take) holds the body and pulls it, feet first, into the water where everyone can see it; this plays what
-- you see, in Config.SenTakeSeconds (3 s):
--   1 the grab: something takes your leg. Your view turns round and down: a small wet hand holding your ankle
--   2 the pull: she pulls harder; you fall and slide backward across the ground into the water, still looking at it
--   3 under: murky, muffled, bubbles. Her face, for a moment, close: the wet hair drifts apart (a sting)
--   4 drowning: the lanterns above blur and darken as you sink
--   5 black; you wake in the drowned festival (you're taken, not dead)
-- Quiet (the Im lặng ending, where all sound dies): no sting and no face. Rescued mid-way: it stops at once.
-- Nothing violent, no struggle, nothing hurt. Timings go through Pace (the factory tests run it at 25x).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Figures = require(Shared:WaitForChild("Figures"))
local Pace = require(Shared:WaitForChild("Pace"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local SenController = {}

local player = Players.LocalPlayer
local UI: any, Sound: any
local rgb = Color3.fromRGB
local black: Frame
local running = 0

local function stillTaken(my: number): boolean
	return running == my and player:GetAttribute("Taken") == true
end

-- run fn(alpha) every frame for `seconds` (game time); false if it was cut short
local function over(my: number, seconds: number, fn: (number) -> ()): boolean
	local t0, len = os.clock(), math.max(Pace.seconds(seconds), 1e-3)
	while true do
		if not stillTaken(my) then
			return false
		end
		local a = math.min(1, (os.clock() - t0) / len)
		fn(a)
		if a >= 1 then
			return true
		end
		RunService.RenderStepped:Wait()
	end
end

local function ease(a: number): number
	return a * a * (3 - 2 * a)
end

local function part(char: Model?, names: { string }): BasePart?
	for _, n in names do
		local p = char and char:FindFirstChild(n)
		if p and p:IsA("BasePart") then
			return p
		end
	end
	return nil
end

-- your body stays visible (you see your own leg), only the head hidden; BodyController leaves it alone meanwhile
local function bodyView(on: boolean)
	player:SetAttribute("HideSelf", on)
	local char = player.Character
	for _, d in (char and char:GetDescendants() or {}) do
		if d:IsA("BasePart") or d:IsA("Decal") then
			-- only your legs stay: looking down at her hand, your own torso and arms filled the whole view (Studio pass,
			-- 2026-11-03: the grab showed nothing but the shirt)
			local part = if d:IsA("Decal") then d.Parent else d
			local name = part and part.Name or ""
			local leg = (name:find("Leg") or name:find("Foot")) and not (part and part.Parent and part.Parent:IsA("Accessory"))
			;(d :: any).LocalTransparencyModifier = if on and not leg then 1 else 0
		end
	end
end

-- her hand around the ankle, reaching from the water side
local function holdAnkle(hand: Model, foot: BasePart, water: Vector3)
	local from = (foot.Position - Vector3.new(water.X, foot.Position.Y, water.Z))
	local up = if from.Magnitude > 0.1 then from.Unit else Vector3.new(0, 0, 1)
	up = (up + Vector3.new(0, 0.35, 0)).Unit
	local right = up:Cross(Vector3.yAxis)
	right = if right.Magnitude > 0.1 then right.Unit else Vector3.xAxis
	local back = right:Cross(up)
	hand:PivotTo(CFrame.fromMatrix(foot.Position - up * 0.25 + Vector3.new(0, 0.05, 0), right, up, back))
end

local hidden: { ScreenGui } = {} -- the HUD the scene hid (given back even if the scene fails)
local function playInner(water: Vector3, quiet: boolean)
	running += 1
	local my = running
	local cam = Workspace.CurrentCamera
	local fov, reverb = cam.FieldOfView, SoundService.AmbientReverb
	local start = cam.CFrame
	local char = player.Character
	local head = part(char, { "Head" })
	local foot = part(char, { "RightFoot", "RightLowerLeg", "Right Leg", "HumanoidRootPart" })
	player:SetAttribute("SenCinematic", true)
	bodyView(true)
	-- nothing on screen but the scene: the HUD (journal button, objective) goes while it plays
	hidden = {}
	for _, g in player.PlayerGui:GetChildren() do
		if g:IsA("ScreenGui") and g.Enabled and g.Name ~= "LangVongSen" then
			g.Enabled = false
			table.insert(hidden, g)
		end
	end
	cam.CameraType = Enum.CameraType.Scriptable
	local folder = Instance.new("Folder")
	folder.Name = "SenCinematic"
	folder.Parent = Workspace
	local cc = Instance.new("ColorCorrectionEffect")
	cc.Enabled = false
	cc.TintColor, cc.Brightness, cc.Contrast, cc.Saturation = rgb(90, 150, 150), -0.15, 0.1, -0.5
	cc.Parent = cam
	local blur = Instance.new("BlurEffect")
	blur.Enabled = false
	blur.Size = 4
	blur.Parent = cam
	local hand = Figures.Hand(CFrame.new(), folder)
	for _, d in hand:GetDescendants() do
		if d:IsA("BasePart") then
			d.Reflectance = 0.15 -- wet
		end
	end
	-- a cold glint on her hand: at night the grab was too dark to see
	local handLight = Instance.new("PointLight")
	handLight.Color, handLight.Brightness, handLight.Range, handLight.Shadows = rgb(170, 210, 220), 2.2, 7, false
	handLight.Parent = hand.PrimaryPart
	local function eye(): Vector3
		return if head then head.Position + Vector3.new(0, 0.3, 0) else start.Position
	end
	local function ankle(): Vector3
		return if foot then foot.Position else eye() - Vector3.new(0, 4, 0)
	end
	local under = false
	local function checkUnder(pos: Vector3)
		if not under and pos.Y < Config.WaterY then
			under = true
			cc.Enabled, blur.Enabled = true, true
			SoundService.AmbientReverb = Enum.ReverbType.UnderWater
			Sound.Play("sen_bubbles", nil)
		end
	end

	-- 1 the grab: something takes your leg; you turn and look down at it
	if not quiet then
		Sound.Play("sen_grab", ankle())
	end
	local startLook = start.Position + start.LookVector * 10
	local ok = over(my, Config.SenGrabSeconds, function(a)
		if foot then
			holdAnkle(hand, foot, water)
		end
		local e = ease(math.min(1, a * 1.4))
		local jolt = if a < 0.15 then (0.15 - a) * 0.6 else 0
		local look = startLook:Lerp(ankle(), e)
		cam.CFrame = CFrame.lookAt(eye(), look) * CFrame.new((math.random() - 0.5) * jolt, (math.random() - 0.5) * jolt, 0)
	end)

	-- 2 the pull: backward across the ground and into the water, still looking at her hand
	if ok then
		ok = over(my, Config.SenDragSeconds, function(a)
			if foot then
				holdAnkle(hand, foot, water)
			end
			local shake = 0.08 + a * 0.1
			local pos = eye()
			checkUnder(pos)
			cam.CFrame = CFrame.lookAt(pos, ankle())
				* CFrame.new((math.random() - 0.5) * shake, (math.random() - 0.5) * shake, 0)
				* CFrame.Angles(0, 0, math.rad(math.sin(a * 9) * 6))
		end)
	end
	hand:Destroy()

	-- 3 under: her face, for a moment, close; the wet hair drifts apart
	local sink = if under then eye() else Vector3.new(water.X, Config.WaterY - 3, water.Z)
	checkUnder(sink - Vector3.new(0, 10, 0))
	local dir = (Vector3.new(water.X, 0, water.Z) - Vector3.new(start.Position.X, 0, start.Position.Z))
	dir = if dir.Magnitude > 0.1 then dir.Unit else Vector3.new(0, 0, -1)
	if ok and not quiet and Config.SenJumpscare then
		local facePos = sink + dir * 1.7
		local face, left, right = Figures.SenFace(CFrame.lookAt(facePos, sink), folder)
		-- lit from your side, pale and cold (underwater at night the face was a black frame: the scare was sound only)
		local lamp = Instance.new("Part")
		lamp.Anchored, lamp.CanCollide, lamp.CanQuery, lamp.CanTouch, lamp.Transparency = true, false, false, false, 1
		lamp.Size = Vector3.new(0.2, 0.2, 0.2)
		lamp.CFrame = CFrame.new(facePos - dir * 1.1 + Vector3.new(0, 0.3, 0))
		lamp.Parent = face
		local faceLight = Instance.new("PointLight")
		faceLight.Color, faceLight.Brightness, faceLight.Range, faceLight.Shadows = rgb(200, 232, 236), 5, 6, false
		faceLight.Parent = lamp
		local l0, r0 = left.CFrame, right.CFrame
		Sound.Play("sen_sting", nil)
		UI.ScreenStatic(true)
		task.delay(Pace.seconds(0.1), function()
			UI.ScreenStatic(false)
		end)
		ok = over(my, Config.SenFaceSeconds, function(a)
			-- the hair parts quickly, holds, then closes as she drifts back into the murk
			local open = if a < 0.25 then a / 0.25 elseif a < 0.7 then 1 else 1 - (a - 0.7) / 0.3
			left.CFrame = l0 * CFrame.new(-0.28 * open, 0, 0) * CFrame.Angles(0, 0, math.rad(8 * open))
			right.CFrame = r0 * CFrame.new(0.28 * open, 0, 0) * CFrame.Angles(0, 0, math.rad(-8 * open))
			local back = math.max(0, a - 0.6) * 4
			face:PivotTo(CFrame.lookAt(facePos + dir * back, sink))
			cam.FieldOfView = fov - 14 * math.min(1, a * 3)
			cam.CFrame = CFrame.lookAt(sink, facePos)
		end)
		face:Destroy()
		cam.FieldOfView = fov
	end

	-- 4 drowning: sinking, looking up at the lanterns as everything blurs and darkens
	if ok then
		local deep = sink - Vector3.new(0, 7, 0) + dir * 3
		ok = over(my, Config.SenDrownSeconds, function(a)
			local e = ease(a)
			local pos = sink:Lerp(deep, e)
			cam.CFrame = CFrame.lookAt(pos, pos + dir * 3 + Vector3.new(0, 10, 0)) * CFrame.Angles(0, 0, math.rad(math.sin(a * 2.5) * 5))
			blur.Size = 6 + e * 22
			cc.Brightness = -0.15 - e * 0.5
		end)
	end

	-- 5 black, then the drowned festival (the server moves you there)
	if ok then
		black.BackgroundTransparency = 1
		black.Visible = true
		local used = Config.SenGrabSeconds + Config.SenDragSeconds + Config.SenDrownSeconds
			+ (if quiet or not Config.SenJumpscare then 0 else Config.SenFaceSeconds)
		over(my, math.max(0.1, Config.SenTakeSeconds - used), function(a)
			black.BackgroundTransparency = 1 - a
		end)
	end
	folder:Destroy()
	cc:Destroy()
	blur:Destroy()
	SoundService.AmbientReverb = reverb
	cam.FieldOfView = fov
	cam.CameraType = Enum.CameraType.Custom
	bodyView(false)
	for _, g in hidden do
		g.Enabled = true
	end
	player:SetAttribute("SenCinematic", false)
	if black.Visible then
		local t0, len = os.clock(), Pace.seconds(0.4)
		while os.clock() - t0 < len do
			black.BackgroundTransparency = (os.clock() - t0) / len
			RunService.RenderStepped:Wait()
		end
		black.Visible = false
	end
end

-- the scene, guarded: if anything in it throws, the camera, the body, the HUD and the screen come back (a throw left the
-- player with a frozen camera and no HUD for the rest of the run)
local function play(water: Vector3, quiet: boolean)
	local ok, err = pcall(playInner, water, quiet)
	if ok then
		return
	end
	warn(`[LangVong] the taking scene failed: {err}`)
	local cam = Workspace.CurrentCamera
	cam.CameraType = Enum.CameraType.Custom
	cam.FieldOfView = 70
	for _, e in cam:GetChildren() do
		if e:IsA("BlurEffect") or e:IsA("ColorCorrectionEffect") then
			e:Destroy()
		end
	end
	local folder = Workspace:FindFirstChild("SenCinematic")
	if folder then
		folder:Destroy()
	end
	SoundService.AmbientReverb = Enum.ReverbType.NoReverb
	bodyView(false)
	for _, g in hidden do
		g.Enabled = true
	end
	hidden = {}
	if black then
		black.Visible = false
	end
	player:SetAttribute("SenCinematic", false)
end

function SenController.Init()
	local gui = Instance.new("ScreenGui")
	gui.Name = "LangVongSen"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 15
	gui.Parent = player:WaitForChild("PlayerGui")
	black = Instance.new("Frame")
	black.Name = "Black"
	black.Size = UDim2.fromScale(1, 1)
	black.BackgroundColor3 = Color3.new(0, 0, 0)
	black.BorderSizePixel = 0
	black.Visible = false
	black.Parent = gui
end

function SenController.Start()
	UI = require(script.Parent:WaitForChild("UIController"))
	Sound = require(script.Parent:WaitForChild("SoundController"))
	Remotes.event(Remotes.Names.SenGrab).OnClientEvent:Connect(function(water: Vector3, quiet: boolean)
		task.spawn(play, water, quiet == true)
	end)
	player:GetAttributeChangedSignal("Taken"):Connect(function()
		if player:GetAttribute("Taken") ~= true then
			running += 1 -- rescued: stop at once (play() cleans up)
		end
	end)
end

return SenController
