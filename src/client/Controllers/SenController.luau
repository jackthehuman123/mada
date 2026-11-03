--!strict
-- Being taken, seen from your own eyes (docs/ISSUES.md I-16). The server (SenService.Take) slides your body into the
-- water where everyone can see it; this plays what you see, about 6.5 s:
--   1 the grab: she's suddenly right in front of you, small, her face hidden by her wet hair; a sting, a flicker
--     (skipped when quiet: the Im lặng ending, where all sound dies)
--   2 a small cold hand closes on yours and the view lurches down to the water's edge
--   3 under: murky green, blurred, muffled, bubbles
--   4 sinking slowly, looking up at the lanterns on the surface; a small dark shape beside you, her back turned,
--     holding your hand
--   5 black; you wake in the drowned festival
-- Nothing violent, no struggle, her face never shown. Rescued during it: it stops at once.
-- Timings go through Pace, so the factory tests (25x) see it finish in a fraction of a second.

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

local function hideBody(hidden: boolean)
	player:SetAttribute("HideSelf", hidden) -- BodyController leaves the body alone
	for _, d in (player.Character and player.Character:GetDescendants() or {}) do
		if d:IsA("BasePart") or d:IsA("Decal") then
			(d :: any).LocalTransparencyModifier = if hidden then 1 else 0
		end
	end
end

local function play(water: Vector3, quiet: boolean)
	running += 1
	local my = running
	local cam = Workspace.CurrentCamera
	local fov, reverb = cam.FieldOfView, SoundService.AmbientReverb
	local start = cam.CFrame
	player:SetAttribute("SenCinematic", true)
	hideBody(true)
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
	blur.Size = 10
	blur.Parent = cam

	local eye = start.Position
	local flatDir = (water - eye) * Vector3.new(1, 0, 1)
	local dir = if flatDir.Magnitude > 0.1 then flatDir.Unit else start.LookVector
	local ok = true

	-- 1 the grab
	if not quiet then
		local at = eye + dir * 1.9 - Vector3.new(0, 1.6, 0)
		local her = Figures.Sen(CFrame.lookAt(at, Vector3.new(eye.X, at.Y, eye.Z)), folder, 12)
		for _, d in her:GetDescendants() do
			if d:IsA("BasePart") then
				d.Reflectance = 0.15 -- wet
			end
		end
		Sound.Play("sen_sting", nil)
		UI.ScreenStatic(true)
		task.delay(Pace.seconds(0.12), function()
			UI.ScreenStatic(false)
		end)
		local face = at + Vector3.new(0, 1.3, 0)
		ok = over(my, 0.7, function(a)
			local shake = (1 - a) * 0.12
			cam.FieldOfView = fov - 18 * math.min(1, a * 4)
			cam.CFrame = CFrame.lookAt(eye, face) * CFrame.new((math.random() - 0.5) * shake, (math.random() - 0.5) * shake, 0)
		end)
		her:Destroy()
		cam.FieldOfView = fov
	end

	-- 2 the hand, and the pull to the water's edge
	local edge = Vector3.new(water.X, Config.WaterY + 0.6, water.Z)
	local hand = Figures.Hand(CFrame.new(eye), folder)
	if ok then
		ok = over(my, 1.4, function(a)
			local e = ease(a)
			local pos = eye:Lerp(edge, e)
			local lookAt = pos + dir * 3 - Vector3.new(0, 2 + e * 2, 0)
			cam.CFrame = CFrame.lookAt(pos, lookAt) * CFrame.Angles(0, 0, math.rad(8 * e))
			-- her hand at the bottom of the view, holding on, reaching back toward the water
			hand:PivotTo(cam.CFrame * CFrame.new(0.35, -0.9, -1.4) * CFrame.Angles(math.rad(-70), 0, 0))
		end)
	end

	-- 3 under
	local under = Vector3.new(water.X, Config.WaterY - 1.5, water.Z)
	local deep = Vector3.new(water.X, Config.WaterY - 11, water.Z) + dir * 6 -- the lake bed is at about -14
	local beside: Model? = nil
	if ok then
		cc.Enabled, blur.Enabled = true, true
		SoundService.AmbientReverb = Enum.ReverbType.UnderWater
		Sound.Play("sen_bubbles", nil)
		-- 4 sinking under the lanterns, a small dark shape beside you holding your hand
		local b = Figures.Sen(CFrame.new(under), folder, -10)
		for _, d in b:GetDescendants() do
			if d:IsA("BasePart") then
				d.Color = rgb(18, 24, 28)
				d.Transparency = 0.25
			end
		end
		beside = b
		ok = over(my, 3.8, function(a)
			local e = ease(a)
			local pos = under:Lerp(deep, e)
			local up = pos + dir * 4 + Vector3.new(0, 10, 0)
			cam.CFrame = CFrame.lookAt(pos, up) * CFrame.Angles(0, 0, math.rad(math.sin(a * 3) * 4))
			local side = cam.CFrame.RightVector * 2.2 - Vector3.new(0, 0.8, 0)
			-- her back to you, a little ahead: facing away from the camera
			b:PivotTo(CFrame.lookAt(pos + side, pos + side + cam.CFrame.LookVector * Vector3.new(1, 0, 1) + Vector3.new(0, 0.01, 0)))
			hand:PivotTo(cam.CFrame * CFrame.new(0.9, -1.0, -1.6) * CFrame.Angles(0, 0, math.rad(-80)))
			blur.Size = 10 + e * 8
		end)
	end

	-- 5 black, then the festival (the server moves you there)
	if ok then
		black.BackgroundTransparency = 1
		black.Visible = true
		over(my, 0.6, function(a)
			black.BackgroundTransparency = 1 - a
		end)
	end
	folder:Destroy()
	cc:Destroy()
	blur:Destroy()
	SoundService.AmbientReverb = reverb
	cam.FieldOfView = fov
	cam.CameraType = Enum.CameraType.Custom
	hideBody(false)
	player:SetAttribute("SenCinematic", false)
	if black.Visible then
		local t0, len = os.clock(), Pace.seconds(0.8)
		while os.clock() - t0 < len do
			black.BackgroundTransparency = (os.clock() - t0) / len
			RunService.RenderStepped:Wait()
		end
		black.Visible = false
	end
	if beside then
		beside:Destroy()
	end
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
