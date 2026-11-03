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
-- Bin's tapes (§5.3, Content/Tapes) play through the same code once the group has his camera (attribute BinTapes):
-- an authored path, handheld shake, ghost figures that exist only on the tape (they can move and fade), bursts of
-- static, a murky underwater picture, and static at the end.

local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Analytics = require(Shared:WaitForChild("Analytics"))
local Figures = require(Shared:WaitForChild("Figures"))
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Tags = require(Shared:WaitForChild("Tags"))
local Tapes = require(Shared:WaitForChild("Content"):WaitForChild("Tapes"))
local Text = require(Shared:WaitForChild("Content"):WaitForChild("Text"))

type Sample = { t: number, cf: CFrame }
type Clip = { samples: { Sample }, events: { { id: string, t: number } }, length: number,
	ghosts: { Tapes.Ghost }?, staticFrom: number?, handheld: boolean?, name: string?, stamp: string?,
	glitches: { Tapes.Glitch }?, underwaterFrom: number? }

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
local ghostFolder: Folder? = nil
local murk: ColorCorrectionEffect? = nil -- the underwater picture on a tape
local playT = 0 -- seconds into the clip that's playing
local staticOn = false
local playingName = ""
local playingStamp: string? = nil -- on playback the HUD shows the time the clip was recorded
local playGen = 0 -- bumped by each playback, so an older playback's cleanup can't stop a newer one

-- the player's own body: hidden while watching a tape (the camera that recorded it never filmed its holder)
local function hideSelf(hidden: boolean)
	player:SetAttribute("HideSelf", hidden) -- local only: BodyController leaves the body alone while this is set
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
		if p:GetAttribute("Hidden") then
			continue -- (a graybox stand-in under a model: never shown again; Bà Thu's block came back after a tape)
		end
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
	UI.vfTime.Text = if playing and playingStamp then playingStamp else clockText()
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
		Remotes.event(Remotes.Names.Track):FireServer("camera_record", { seconds = math.floor(clip.length) })
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
	local look = Workspace.CurrentCamera:FindFirstChild("CamcorderLook")
	if look then
		look:Destroy()
	end
	local jb = UI.Gui():FindFirstChild("JournalButton")
	if jb then
		(jb :: GuiObject).Visible = true
	end
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
	-- the camcorder's own look: a cool, low-saturation night picture with a little lift (the live view was an orange wash
	-- under the lanterns, and black in the dark); the Journal button steps out of the viewfinder's corner
	local look = Workspace.CurrentCamera:FindFirstChild("CamcorderLook") or Instance.new("ColorCorrectionEffect")
	look.Name = "CamcorderLook"
	look.TintColor, look.Saturation, look.Contrast, look.Brightness = Color3.fromRGB(196, 226, 206), -0.55, 0.12, 0.08
	look.Parent = Workspace.CurrentCamera
	local jb = UI.Gui():FindFirstChild("JournalButton")
	if jb then
		(jb :: GuiObject).Visible = false
	end
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
		current = { samples = {}, events = {}, length = 0, stamp = clockText() }
	end
end

-- an authored tape as a clip: its key positions sampled at the recording rate
local function tapeClip(tape: Tapes.Tape): Clip
	local samples: { Sample } = {}
	local keys = tape.keys
	local step = 1 / Config.CameraSampleHz
	local t = 0
	local k = 1
	while t <= tape.length + 1e-6 do
		while k < #keys - 1 and keys[k + 1].t <= t do
			k += 1
		end
		local a, b = keys[k], keys[math.min(k + 1, #keys)]
		local f = if b.t > a.t then math.clamp((t - a.t) / (b.t - a.t), 0, 1) else 0
		local s = f * f * (3 - 2 * f) -- ease in and out between keys
		table.insert(samples, { t = t, cf = CFrame.lookAt(a.pos:Lerp(b.pos, s), a.look:Lerp(b.look, s)) })
		t += step
	end
	return { samples = samples, events = {}, length = tape.length, ghosts = tape.ghosts, staticFrom = tape.staticFrom,
		handheld = tape.handheld, name = tape.id, stamp = tape.stamp, glitches = tape.glitches, underwaterFrom = tape.underwaterFrom }
end

-- figures that exist only on a tape, built locally (never on the server, never seen by eyes)
local function ghost(template: string, cf: CFrame): Model?
	local m: Model
	if template == "GirlInWater" then
		-- a small girl standing in the water up to her waist, looking up; her hair hides her face (characters.md)
		m = Figures.Sen(cf, nil, 18)
	elseif template == "GirlClose" then
		m = Figures.Sen(cf, nil, 45) -- right below the camera, head tipped far back; still only hair
	elseif template == "SenHand" then
		m = Figures.Hand(cf, nil)
	elseif template == "GirlSinking" then
		m = Figures.Sen(cf, nil, 0)
	elseif template == "BinSinking" then
		-- Bin under the water: a dark shape, his orange jacket just readable
		m = Figures.Child(cf, "Bin", 4.6, nil)
		local body = m:FindFirstChild("Body") :: BasePart?
		if body then
			body.Color = Color3.fromRGB(110, 62, 30)
		end
	else
		warn(`[LangVong] unknown tape ghost {template}`)
		return nil
	end
	m.Name = "Ghost_" .. template
	m.Parent = ghostFolder
	return m
end

-- a ghost on the tape this frame: where it is along its move, how faded; gone after untilT
type Live = { g: Tapes.Ghost, m: Model, base: { [BasePart]: number } }
local function stepGhost(l: Live, t: number): boolean
	local g = l.g
	if g.untilT and t >= g.untilT then
		l.m:Destroy()
		return false
	end
	if g.to and g.dur then
		l.m:PivotTo(g.cf:Lerp(g.to, math.clamp((t - g.t) / g.dur, 0, 1)))
	end
	if g.fadeAt then
		local f = math.clamp((t - g.fadeAt) / (g.fadeSeconds or 1), 0, 1)
		for p, b in l.base do
			p.Transparency = b + (1 - b) * f
		end
	end
	return true
end

local function stopPlayback()
	if not playing then
		return
	end
	playing = false
	playingName = ""
	playingStamp = nil
	if ghostFolder then
		ghostFolder:Destroy()
		ghostFolder = nil
	end
	if murk then
		murk:Destroy()
		murk = nil
	end
	staticOn = false
	UI.Static(false)
	local cam = Workspace.CurrentCamera
	cam.CameraType = Enum.CameraType.Custom
	cam.FieldOfView = savedFov
	local char = player.Character
	local head = char and char:FindFirstChild("Head") :: BasePart?
	local body = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if head and body then -- straight ahead from your eyes, not the tape's last angle
		cam.CFrame = CFrame.lookAt(head.Position, head.Position + body.CFrame.LookVector)
	end
	setVisible(Tags.HiddenOnCamera, true)
	setVisible(Tags.CameraOnly, false)
	hideSelf(false)
	UI.viewfinder.Visible = false
	local look = Workspace.CurrentCamera:FindFirstChild("CamcorderLook")
	if look then
		look:Destroy()
	end
	local jb = UI.Gui():FindFirstChild("JournalButton")
	if jb then
		(jb :: GuiObject).Visible = true
	end
	local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if hum and savedWalk then
		hum.WalkSpeed = savedWalk
	end
	savedWalk = nil
end

local function playClip(clip: Clip)
	if playing or battery() <= 0 then
		return
	end
	Camcorder.Lower()
	UI.clipChooser.Visible = false
	playing = true
	playGen += 1
	local my = playGen
	playingName = clip.name or "clip"
	playingStamp = clip.stamp
	local folder = Instance.new("Folder")
	folder.Name = "TapeGhosts"
	folder.Parent = Workspace
	ghostFolder = folder
	local pending = table.clone(clip.ghosts or {})
	local live: { Live } = {}
	local cam = Workspace.CurrentCamera
	savedFov = cam.FieldOfView
	cam.CameraType = Enum.CameraType.Scriptable
	cam.FieldOfView = Config.CameraViewfinderFov
	UI.viewfinder.Visible = true
	local jbp = UI.Gui():FindFirstChild("JournalButton")
	if jbp then
		(jbp :: GuiObject).Visible = false -- (out of the tape's corner too)
	end
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
	while playing and playGen == my do
		local t = os.clock() - t0
		playT = t
		while i < #samples and samples[i + 1].t <= t do
			i += 1
		end
		if i >= #samples then
			cam.CFrame = samples[#samples].cf
			break
		end
		local a, b = samples[i], samples[i + 1]
		local cf = a.cf:Lerp(b.cf, math.clamp((t - a.t) / math.max(b.t - a.t, 1e-3), 0, 1))
		if clip.handheld then -- a person holding it: a slow sway and a little breathing
			cf = cf * CFrame.new(0, math.sin(t * 2.3) * 0.04, 0)
				* CFrame.Angles(math.sin(t * 1.7) * 0.012, math.sin(t * 1.3) * 0.016, math.sin(t * 2.1) * 0.006)
		end
		cam.CFrame = cf
		for k = #pending, 1, -1 do
			if pending[k].t <= t then
				local g = pending[k]
				local m = ghost(g.template, g.cf)
				if m then
					local base: { [BasePart]: number } = {}
					for _, d in m:GetDescendants() do
						if d:IsA("BasePart") then
							base[d] = d.Transparency
						end
					end
					table.insert(live, { g = g, m = m, base = base })
				end
				table.remove(pending, k)
			end
		end
		for k = #live, 1, -1 do
			if not stepGhost(live[k], t) then
				table.remove(live, k)
			end
		end
		if clip.underwaterFrom and t >= clip.underwaterFrom and not murk then
			local c = Instance.new("ColorCorrectionEffect")
			c.Name = "TapeMurk"
			c.TintColor = Color3.fromRGB(90, 130, 115)
			c.Brightness = -0.22
			c.Contrast = 0.25
			c.Saturation = -0.45
			c.Parent = Lighting
			murk = c
		end
		local glitch = false
		for _, gl in clip.glitches or {} do
			if t >= gl.from and t < gl.to then
				glitch = true
			end
		end
		if (clip.staticFrom and t >= clip.staticFrom) or glitch then
			staticOn = true
			UI.Static(true) -- re-rolled every frame, so it flickers
		elseif staticOn then
			staticOn = false
			UI.Static(false)
		end
		RunService.RenderStepped:Wait()
	end
	task.wait(0.3)
	if playGen == my then
		stopPlayback()
	end
end

function Camcorder.Play(index: number)
	local clip = clips[index]
	if clip then
		Analytics.track("camera_playback", { clip = index })
		Remotes.event(Remotes.Names.Track):FireServer("camera_playback", { clip = index })
		playClip(clip)
	end
end

function Camcorder.HasTapes(): boolean
	return ReplicatedStorage:GetAttribute("BinTapes") == true
end

function Camcorder.PlayTape(n: number)
	local tape = Tapes[n]
	if tape and Camcorder.HasTapes() then
		Analytics.track("bin_tape_played", { tape = tape.id })
		Remotes.event(Remotes.Names.Track):FireServer("bin_tape_played", { tape = tape.id })
		playClip(tapeClip(tape))
	end
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
	if #clips == 0 and not Camcorder.HasTapes() then
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
	if Camcorder.HasTapes() then
		for n, tape in Tapes do
			local b = Instance.new("TextButton")
			b.Name = "Tape" .. n
			b.LayoutOrder = 100 + n
			b.Size = UDim2.new(1, -16, 0, 44)
			b.BackgroundColor3 = Color3.fromRGB(70, 36, 30)
			b.TextColor3 = Color3.fromRGB(240, 225, 200)
			b.Font = Enum.Font.Code
			b.TextSize = 20
			b.Text = string.format("▶ %s %s  %02ds", Text.UI.binTape, tape.title, tape.length)
			b.ZIndex = 6
			b.Parent = chooser
			b.Activated:Connect(function()
				task.spawn(Camcorder.PlayTape, n)
			end)
		end
	end
	local rows = 0
	for _, c in chooser:GetChildren() do
		if c:IsA("TextButton") or c:IsA("TextLabel") then
			rows += 1
		end
	end
	chooser.Size = UDim2.fromOffset(260, 14 + 50 * math.max(1, rows))
	chooser.Visible = true
end

function Camcorder.State(): { [string]: any }
	local foot = partsOf(Tags.CameraOnly)[1]
	local thu = nil -- (the first part of her that shows: not a Hidden stand-in under her model)
	for _, p in partsOf(Tags.HiddenOnCamera) do
		if not p:GetAttribute("Hidden") then
			thu = p
			break
		end
	end
	return { raised = raised, recording = recording, playing = playing, clips = #clips,
		cameraOnlyT = foot and foot.Transparency or -1, hiddenOnCameraT = thu and thu.Transparency or -1,
		fov = Workspace.CurrentCamera.FieldOfView, battery = battery(),
		lastClipEvents = clips[#clips] and #clips[#clips].events or 0,
		tapes = Camcorder.HasTapes(), playingName = playingName, static = staticOn,
		ghosts = ghostFolder and #ghostFolder:GetChildren() or 0, playT = if playing then playT else -1,
		murky = murk ~= nil }
end

function Camcorder.Init()
	UI = require(script.Parent:WaitForChild("UIController"))
end

function Camcorder.Start()
	-- eyes can't see CameraOnly things; hide them now and whenever one is added
	setVisible(Tags.CameraOnly, false)
	CollectionService:GetInstanceAddedSignal(Tags.CameraOnly):Connect(function(inst)
		setVisible(Tags.CameraOnly, raised or playing)
		-- (a tagged model can arrive before its parts do: hide those too as they come in)
		inst.DescendantAdded:Connect(function(d)
			if d:IsA("BasePart") and not (raised or playing) then
				d.Transparency = 1
			end
		end)
	end)
	task.delay(3, function() -- and once more after the world has settled
		if not (raised or playing) then
			setVisible(Tags.CameraOnly, false)
		end
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
			elseif cmd == "tape" then
				task.spawn(Camcorder.PlayTape, tonumber(arg) or 1)
			elseif cmd == "chooser" then
				showChooser()
				local names = {}
				for _, c in UI.clipChooser:GetChildren() do
					if c:IsA("TextButton") then
						table.insert(names, c.Name)
					end
				end
				UI.clipChooser.Visible = false
				return names
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
