--!strict
-- The camcorder (PROTOTYPE_BRIEF §5.2), all client-side except the battery (a player attribute the server owns).
--   F / hold right mouse: raise or lower the viewfinder (VHS overlay, FOV 55, clock + battery shown)
--   R (viewfinder up): start / stop recording a clip (max 20 s, 3 clips, the oldest is overwritten)
--   T: choose a clip and play it back full screen; T again stops. The player can't move while watching.
-- What the camera sees differs from the eye, locally only:
--   CameraOnly (Sen's wet footprints...): invisible to eyes, visible in the live viewfinder and on playback
--   HiddenOnCamera (Bà Thu...): visible to eyes and the live viewfinder, gone on playback
-- A recording is the camera's path sampled at 10 Hz plus the CameraOnly things that were in view (brief §5.2);
-- playback flies a scriptable camera along that path through the world as it is now (see DECISIONS).

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Analytics = require(Shared:WaitForChild("Analytics"))
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Tags = require(Shared:WaitForChild("Tags"))
local Text = require(Shared:WaitForChild("Content"):WaitForChild("Text"))

type Sample = { t: number, cf: CFrame }
type Clip = { samples: { Sample }, events: { { id: string, t: number } }, length: number }

local Camcorder = {}

local player = Players.LocalPlayer
local UI: any
local raised, recording, playing = false, false, false
local clips: { Clip } = {}
local current: Clip? = nil
local recStart = 0
local savedFov = 70
local savedWalk: number? = nil
local baseTransparency: { [BasePart]: number } = {}
local savedMode: Enum.CameraMode? = nil

-- the player's own body: hidden while watching a tape (the camera that recorded it never filmed its holder)
local function hideSelf(hidden: boolean)
	for _, d in (player.Character and player.Character:GetDescendants() or {}) do
		if d:IsA("BasePart") or d:IsA("Decal") then
			(d :: any).LocalTransparencyModifier = hidden and 1 or 0
		end
	end
end

local function partsOf(tagName: string): { BasePart }
	local out = {}
	for _, inst in CollectionService:GetTagged(tagName) do
		if inst:IsA("BasePart") then
			table.insert(out, inst)
		end
		for _, d in inst:GetDescendants() do
			if d:IsA("BasePart") then
				table.insert(out, d)
			end
		end
	end
	return out
end

local function setVisible(tagName: string, visible: boolean)
	for _, p in partsOf(tagName) do
		if baseTransparency[p] == nil then
			baseTransparency[p] = if p.Transparency >= 1 then 0 else p.Transparency
		end
		p.Transparency = if visible then baseTransparency[p] else 1
	end
end

local function battery(): number
	return (player:GetAttribute("Battery") :: number?) or 100
end

local function clockText(): string
	local h = (ReplicatedStorage:GetAttribute("ClockHour") :: number?) or 0
	local hh = math.floor(h) % 24
	local mm = math.floor((h % 1) * 60)
	return string.format("%02d:%02d", hh, mm)
end

local function updateHud()
	if not UI or not UI.viewfinder then
		return
	end
	UI.vfTime.Text = clockText()
	local b = battery()
	UI.vfBattery.Text = if b <= 0 then Text.UI.noBattery else string.format("%s %d%%", Text.UI.battery, math.floor(b + 0.5))
	if playing then
		UI.vfRec.Text = ""
		UI.vfMode.Text = "▶ " .. Text.UI.play
	elseif recording then
		UI.vfRec.Text = (os.clock() % 1 < 0.6 and "● " or "  ") .. Text.UI.rec .. string.format(" %02d", math.floor(os.clock() - recStart))
		UI.vfMode.Text = ""
	else
		UI.vfRec.Text = ""
		UI.vfMode.Text = ""
	end
end

local function stopRecording()
	if not recording or not current then
		return
	end
	recording = false
	local clip = current :: Clip
	clip.length = os.clock() - recStart
	current = nil
	if #clip.samples > 1 then
		table.insert(clips, clip)
		while #clips > Config.CameraMaxClips do
			table.remove(clips, 1)
		end
		Analytics.track("camera_record", { seconds = math.floor(clip.length * 10) / 10, events = #clip.events })
	end
end

function Camcorder.Lower()
	stopRecording()
	if not raised then
		return
	end
	raised = false
	Workspace.CurrentCamera.FieldOfView = savedFov
	player.CameraMode = savedMode or Enum.CameraMode.Classic
	savedMode = nil
	if not playing then
		UI.viewfinder.Visible = false
		setVisible(Tags.CameraOnly, false)
	end
	Remotes.event(Remotes.Names.CameraRaised):FireServer(false)
end

function Camcorder.Raise()
	if raised or playing or battery() <= 0 then
		return
	end
	raised = true
	savedFov = Workspace.CurrentCamera.FieldOfView
	savedMode = player.CameraMode
	player.CameraMode = Enum.CameraMode.LockFirstPerson -- you look through the viewfinder, not over your shoulder
	Workspace.CurrentCamera.FieldOfView = Config.CameraViewfinderFov
	UI.viewfinder.Visible = true
	setVisible(Tags.CameraOnly, true)
	Remotes.event(Remotes.Names.CameraRaised):FireServer(true)
	updateHud()
end

function Camcorder.ToggleRecord()
	if not raised then
		return
	end
	if recording then
		stopRecording()
	else
		recording = true
		recStart = os.clock()
		current = { samples = {}, events = {}, length = 0 }
	end
end

local function stopPlayback()
	if not playing then
		return
	end
	playing = false
	local cam = Workspace.CurrentCamera
	cam.CameraType = Enum.CameraType.Custom
	cam.FieldOfView = savedFov
	setVisible(Tags.HiddenOnCamera, true)
	setVisible(Tags.CameraOnly, false)
	hideSelf(false)
	UI.viewfinder.Visible = false
	local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if hum and savedWalk then
		hum.WalkSpeed = savedWalk
	end
	savedWalk = nil
end

function Camcorder.Play(index: number)
	local clip = clips[index]
	if not clip or playing or battery() <= 0 then
		return
	end
	Camcorder.Lower()
	UI.clipChooser.Visible = false
	playing = true
	Analytics.track("camera_playback", { clip = index })
	local cam = Workspace.CurrentCamera
	savedFov = cam.FieldOfView
	cam.CameraType = Enum.CameraType.Scriptable
	cam.FieldOfView = Config.CameraViewfinderFov
	UI.viewfinder.Visible = true
	setVisible(Tags.HiddenOnCamera, false) -- the camera never saw her
	setVisible(Tags.CameraOnly, true)
	hideSelf(true)
	local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if hum then
		savedWalk = hum.WalkSpeed
		hum.WalkSpeed = 0
	end
	local t0 = os.clock()
	local samples = clip.samples
	local i = 1
	while playing do
		local t = os.clock() - t0
		while i < #samples and samples[i + 1].t <= t do
			i += 1
		end
		if i >= #samples then
			cam.CFrame = samples[#samples].cf
			break
		end
		local a, b = samples[i], samples[i + 1]
		cam.CFrame = a.cf:Lerp(b.cf, math.clamp((t - a.t) / math.max(b.t - a.t, 1e-3), 0, 1))
		RunService.RenderStepped:Wait()
	end
	task.wait(0.3)
	stopPlayback()
end

function Camcorder.StopPlayback()
	stopPlayback()
end

local function showChooser()
	local chooser = UI.clipChooser
	for _, c in chooser:GetChildren() do
		if c:IsA("TextButton") or c:IsA("TextLabel") then
			c:Destroy()
		end
	end
	if #clips == 0 then
		local l = Instance.new("TextLabel")
		l.Size = UDim2.new(1, -16, 0, 40)
		l.BackgroundTransparency = 1
		l.Text = Text.UI.noClips
		l.TextColor3 = Color3.fromRGB(220, 220, 220)
		l.Font = Enum.Font.Code
		l.TextSize = 20
		l.Parent = chooser
	end
	for i, clip in clips do
		local b = Instance.new("TextButton")
		b.Name = "Clip" .. i
		b.LayoutOrder = i
		b.Size = UDim2.new(1, -16, 0, 44)
		b.BackgroundColor3 = Color3.fromRGB(40, 44, 52)
		b.TextColor3 = Color3.fromRGB(235, 235, 235)
		b.Font = Enum.Font.Code
		b.TextSize = 20
		b.Text = string.format("▶ %s %d  %02ds", Text.UI.clips, i, math.floor(clip.length + 0.5))
		b.ZIndex = 6
		b.Parent = chooser
		b.Activated:Connect(function()
			task.spawn(Camcorder.Play, i)
		end)
	end
	chooser.Visible = true
end

function Camcorder.State(): { [string]: any }
	local foot = partsOf(Tags.CameraOnly)[1]
	local thu = partsOf(Tags.HiddenOnCamera)[1]
	return { raised = raised, recording = recording, playing = playing, clips = #clips,
		cameraOnlyT = foot and foot.Transparency or -1, hiddenOnCameraT = thu and thu.Transparency or -1,
		fov = Workspace.CurrentCamera.FieldOfView, battery = battery(),
		lastClipEvents = clips[#clips] and #clips[#clips].events or 0 }
end

function Camcorder.Init()
	UI = require(script.Parent:WaitForChild("UIController"))
end

function Camcorder.Start()
	-- eyes can't see CameraOnly things; hide them now and whenever one is added
	setVisible(Tags.CameraOnly, false)
	CollectionService:GetInstanceAddedSignal(Tags.CameraOnly):Connect(function()
		setVisible(Tags.CameraOnly, raised or playing)
	end)
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end
		if input.KeyCode == Enum.KeyCode.F then
			if raised then Camcorder.Lower() else Camcorder.Raise() end
		elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
			Camcorder.Raise()
		elseif input.KeyCode == Enum.KeyCode.R then
			Camcorder.ToggleRecord()
		elseif input.KeyCode == Enum.KeyCode.T then
			if playing then
				stopPlayback()
			elseif UI.clipChooser.Visible then
				UI.clipChooser.Visible = false
			else
				showChooser()
			end
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton2 then
			Camcorder.Lower()
		end
	end)
	player:GetAttributeChangedSignal("Battery"):Connect(function()
		if battery() <= 0 then
			Camcorder.Lower()
			stopPlayback()
		end
	end)
	-- record at Config.CameraSampleHz; note CameraOnly things in view so playback can show them
	local acc = 0
	RunService.RenderStepped:Connect(function(dt)
		if raised or playing then
			updateHud()
		end
		if not recording or not current then
			return
		end
		local clip = current :: Clip
		acc += dt
		if acc < 1 / Config.CameraSampleHz then
			return
		end
		acc = 0
		local t = os.clock() - recStart
		local cam = Workspace.CurrentCamera
		table.insert(clip.samples, { t = t, cf = cam.CFrame })
		for _, inst in CollectionService:GetTagged(Tags.CameraOnly) do
			local pos = if inst:IsA("Model") then inst:GetPivot().Position elseif inst:IsA("BasePart") then inst.Position else nil
			if pos then
				local _, onScreen = cam:WorldToViewportPoint(pos)
				if onScreen and (pos - cam.CFrame.Position).Magnitude < 150 then
					table.insert(clip.events, { id = inst:GetFullName(), t = t })
				end
			end
		end
		if t >= Config.CameraClipMaxSeconds then
			stopRecording()
		end
	end)
	-- Studio-only hook so the factory tests can drive the camcorder (BindableFunction, client side)
	if RunService:IsStudio() then
		local hook = Instance.new("BindableFunction")
		hook.Name = "LVClientDebug"
		hook.OnInvoke = function(cmd: string, arg: any): any
			if cmd == "raise" then
				Camcorder.Raise()
			elseif cmd == "lower" then
				Camcorder.Lower()
			elseif cmd == "record" then
				Camcorder.ToggleRecord()
			elseif cmd == "play" then
				task.spawn(Camcorder.Play, tonumber(arg) or #clips)
			elseif cmd == "stopplay" then
				stopPlayback()
			elseif cmd == "look" then -- point the camera at a world position (tests)
				local cam = Workspace.CurrentCamera
				cam.CFrame = CFrame.lookAt(cam.CFrame.Position, arg)
			end
			return Camcorder.State()
		end
		hook.Parent = player:WaitForChild("PlayerScripts")
	end
end

return Camcorder
