--!strict
-- First person, with a body (docs/ISSUES.md I-12).
--   * In a run the camera is locked in first person, a little forward of the head: look down and you see your own
--     arms, hands, the camcorder and your legs (only your head and hat/hair are hidden).
--   * Every character's head and waist follow where that player looks (player attribute "LookPitch"); when their
--     camcorder is up ("CameraUp") both arms come up to hold it at the eye. Everyone sees everyone's pose.
--   * A light head bob while walking, breathing when still, a small lean when strafing.
--   * The mouse is freed while a panel that needs clicking is open (clue, journal, dialogue, clips, Light a lantern).
-- Leaves the camera alone when another controller has it (menu, tape playback, cut scenes: CameraType Scriptable).
-- R15 only for poses (R6 characters still get first person).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local BodyController = {}

local lp = Players.LocalPlayer

type Rig = { motors: { [string]: Motor6D }, base: { [string]: CFrame }, pitch: number, raise: number }
local rigs: { [Model]: Rig } = {}

local JOINTS: { [string]: string } = {
	Neck = "Head",
	Waist = "UpperTorso",
	RightShoulder = "RightUpperArm",
	LeftShoulder = "LeftUpperArm",
	RightElbow = "RightLowerArm",
	LeftElbow = "LeftLowerArm",
}

local function rigOf(char: Model): Rig?
	local r = rigs[char]
	if r then
		return r
	end
	local motors: { [string]: Motor6D } = {}
	local base: { [string]: CFrame } = {}
	for joint, partName in JOINTS do
		local p = char:FindFirstChild(partName)
		local m = p and p:FindFirstChild(joint)
		if m and m:IsA("Motor6D") then
			motors[joint] = m
			base[joint] = m.C0
		end
	end
	if not motors.Neck or not motors.RightShoulder then
		return nil -- R6, or not loaded yet
	end
	r = { motors = motors, base = base, pitch = 0, raise = 0 }
	rigs[char] = r
	char.AncestryChanged:Connect(function()
		if not char.Parent then
			rigs[char] = nil
		end
	end)
	return r
end

local function set(r: Rig, joint: string, cf: CFrame)
	local m = r.motors[joint]
	if m then
		m.C0 = r.base[joint] * cf
	end
end

-- head and waist follow the look; arms come up to the eye with the camcorder (angles: + is up)
local function pose(r: Rig, pitch: number, raise: number)
	local p = math.rad(pitch)
	set(r, "Neck", CFrame.Angles(p * 0.55, 0, 0))
	set(r, "Waist", CFrame.Angles(p * 0.3, 0, 0))
	local lift = raise * (math.rad(80) + p * 0.6)
	set(r, "RightShoulder", CFrame.Angles(0, raise * math.rad(28), 0) * CFrame.Angles(lift, 0, 0))
	set(r, "LeftShoulder", CFrame.Angles(0, -raise * math.rad(36), 0) * CFrame.Angles(lift, 0, 0))
	set(r, "RightElbow", CFrame.Angles(raise * math.rad(25), 0, 0))
	set(r, "LeftElbow", CFrame.Angles(raise * math.rad(40), 0, 0))
end

local function inRun(): boolean
	return lp:GetAttribute("InRun") == true and lp.Character ~= nil
end

local function cameraPitch(): number
	return math.deg(math.asin(math.clamp(Workspace.CurrentCamera.CFrame.LookVector.Y, -1, 1)))
end

local function attachedToHead(part: BasePart, head: BasePart?): boolean
	if part == head then
		return true
	end
	local acc = part.Parent
	if acc and acc:IsA("Accessory") then
		-- anything worn on the head, however it is fastened (newer avatars hold hair with a RigidConstraint, not a weld:
		-- long hair then filled the first-person view; playthrough bot 2026-11-04)
		local kind = (acc :: Accessory).AccessoryType
		if kind == Enum.AccessoryType.Hat or kind == Enum.AccessoryType.Hair or kind == Enum.AccessoryType.Face
			or kind == Enum.AccessoryType.Neck then
			return true
		end
		local w = part:FindFirstChildWhichIsA("JointInstance") :: any
		if w ~= nil and (w.Part0 == head or w.Part1 == head) then
			return true
		end
		local rc = part:FindFirstChildWhichIsA("RigidConstraint")
		local other = rc and (if rc.Attachment0 and rc.Attachment0.Parent ~= part then rc.Attachment0 else rc.Attachment1)
		if other and other.Parent == head then
			return true
		end
		-- and anything sitting right round the head (an unknown type)
		return head ~= nil and (part.Position - head.Position).Magnitude < 1.6
	end
	return false
end

-- your own body: visible in first person (but the head), hidden while you look through the viewfinder;
-- untouched while the camcorder hides it for a tape (local attribute "HideSelf")
local function ownBody(char: Model)
	if lp:GetAttribute("HideSelf") then
		return
	end
	local cam = Workspace.CurrentCamera
	local head = char:FindFirstChild("Head") :: BasePart?
	local scripted = cam.CameraType == Enum.CameraType.Scriptable
	local hum = char:FindFirstChildOfClass("Humanoid")
	local swimming = hum ~= nil and hum:GetState() == Enum.HumanoidStateType.Swimming -- (lying flat in the water, the body filled the view)
	local viewfinder = (lp:GetAttribute("CameraUp") == true and not scripted) or swimming
	for _, d in char:GetDescendants() do
		if d:IsA("BasePart") or d:IsA("Decal") then
			local hide = 0
			if viewfinder then
				hide = 1
			elseif not scripted then
				local part = if d:IsA("Decal") then d.Parent else d
				if part and part:IsA("BasePart") and attachedToHead(part, head) then
					hide = 1
				end
			end
			(d :: any).LocalTransparencyModifier = hide
		end
	end
end

local bobT, rollNow = 0, 0
local function bob(dt: number)
	local cam = Workspace.CurrentCamera
	local char = lp.Character
	local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if cam.CameraType ~= Enum.CameraType.Custom or not root then
		return
	end
	local v = root.AssemblyLinearVelocity
	local flat = Vector3.new(v.X, 0, v.Z)
	local speed = math.min(flat.Magnitude / Config.WalkSpeed, 1.5)
	bobT += dt * Config.BobSpeed * math.max(speed, 0.15)
	local amp = Config.BobAmount * speed + Config.BreathAmount * (1 - math.min(speed, 1))
	if lp:GetAttribute("CameraUp") then
		amp *= 0.4 -- handheld: a little shake, not a bounce
	end
	local x = math.sin(bobT) * amp * 0.6
	local y = math.sin(bobT * 2) * amp
	local strafe = cam.CFrame.RightVector:Dot(flat) / Config.WalkSpeed
	rollNow += (-strafe * Config.SwayRoll - rollNow) * math.min(1, dt * 6)
	cam.CFrame = cam.CFrame * CFrame.new(x, y, 0) * CFrame.Angles(0, 0, math.rad(rollNow))
end

-- panels that need the mouse while it's locked to the centre
local NEED_MOUSE = { "CluePanel", "Journal", "Dialogue", "Clips", "Taken", "Stay" }
local modal: TextButton
local function needsMouse(): boolean
	if ReplicatedStorage:GetAttribute("Phase") == "Ending" then
		return true
	end
	local ui = lp.PlayerGui:FindFirstChild("LangVongUI") :: ScreenGui?
	if not (ui and ui.Enabled) then
		return false
	end
	for _, name in NEED_MOUSE do
		local f = ui:FindFirstChild(name, true) :: GuiObject?
		if f and f.Visible then
			return true
		end
	end
	return false
end

local sentPitch, sentAt = 999, 0
local function step(dt: number)
	local k = math.min(1, dt * Config.PoseLerp)
	for _, p in Players:GetPlayers() do
		local char = p.Character
		local r = char and rigOf(char)
		if r then
			local target = if p == lp then cameraPitch() else (p:GetAttribute("LookPitch") :: number?) or 0
			local raise = if p:GetAttribute("CameraUp") then 1 else 0
			r.pitch += (math.clamp(target, -Config.LookPitchMax, Config.LookPitchMax) - r.pitch) * k
			r.raise += (raise - r.raise) * k
			pose(r, r.pitch, r.raise)
		end
	end
	if not inRun() then
		modal.Visible = false
		return
	end
	local char = lp.Character :: Model
	if lp.CameraMode ~= Enum.CameraMode.LockFirstPerson then
		lp.CameraMode = Enum.CameraMode.LockFirstPerson
	end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if hum and hum.CameraOffset ~= Config.FirstPersonCameraOffset then
		hum.CameraOffset = Config.FirstPersonCameraOffset
	end
	ownBody(char)
	bob(dt)
	modal.Visible = needsMouse()
	local now = os.clock()
	local pitch = cameraPitch()
	if now - sentAt >= 1 / Config.LookPitchSendHz and math.abs(pitch - sentPitch) >= 2 then
		sentAt, sentPitch = now, pitch
		Remotes.event(Remotes.Names.LookPitch):FireServer(pitch)
	end
end

function BodyController.Init()
	local gui = Instance.new("ScreenGui")
	gui.Name = "LangVongBody"
	gui.ResetOnSpawn = false
	gui.Parent = lp:WaitForChild("PlayerGui")
	modal = Instance.new("TextButton")
	modal.Name = "FreeMouse"
	modal.Modal = true -- a visible modal button frees the mouse in first person
	modal.Size = UDim2.fromOffset(0, 0)
	modal.BackgroundTransparency = 1
	modal.Text = ""
	modal.Visible = false
	modal.Parent = gui
end

function BodyController.Start()
	RunService:BindToRenderStep("LangVongBody", Enum.RenderPriority.Camera.Value + 2, step)
end

return BodyController
