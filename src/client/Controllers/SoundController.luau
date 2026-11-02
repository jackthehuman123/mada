--!strict
-- Plays the server's sounds (Content/Sounds). A sound with an asset plays at its position (or everywhere); a sound
-- with a subtitle also shows it as a caption. The night ambience loops from Arrival to midnight; a taken player hears
-- the water instead; in the Im lặng finale every sound dies (brief §7).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Remotes"))
local Sounds = require(Shared:WaitForChild("Content"):WaitForChild("Sounds"))

local SoundController = {}

local ambience: { [string]: Sound } = {}

local function make(def: Sounds.Sound): Sound
	local s = Instance.new("Sound")
	s.SoundId = def.asset
	s.Volume = def.volume or 0.5
	s.Looped = def.loop == true
	s.PlaybackSpeed = def.pitch or 1
	return s
end

-- music plays only through the finale and its ending card; a reset stops it
local music: { [Sound]: boolean } = {}

function SoundController.Play(id: string, pos: Vector3?)
	local UI = require(script.Parent:WaitForChild("UIController")) :: any
	local def = Sounds[id]
	if not def then
		warn(`[LangVong] unknown sound {id}`)
		return
	end
	if def.subtitle then
		UI.Message(def.subtitle)
	end
	if def.asset == "" then
		return
	end
	local s = make(def)
	local holder: Instance
	if pos then
		local a = Instance.new("Attachment")
		a.WorldPosition = pos
		a.Parent = Workspace.Terrain
		holder = a
	else
		holder = SoundService
	end
	s.Parent = holder
	s:Play()
	if def.music then
		music[s] = true
		s.Destroying:Connect(function()
			music[s] = nil
		end)
	end
	local life = def.seconds or (if def.loop then 10 else nil)
	if life then
		task.delay(life, function()
			s:Destroy()
			if holder:IsA("Attachment") then
				holder:Destroy()
			end
		end)
	else
		s.Ended:Connect(function()
			s:Destroy()
			if holder:IsA("Attachment") then
				holder:Destroy()
			end
		end)
	end
end

-- which ambience should be playing now
local function wanted(): { [string]: boolean }
	local phase = ReplicatedStorage:GetAttribute("Phase")
	local player = Players.LocalPlayer
	if ReplicatedStorage:GetAttribute("FinaleStatic") == true then
		return {} -- Im lặng: all sound dies
	end
	if player:GetAttribute("Taken") == true and player:GetAttribute("Stayed") ~= true then
		return { amb_underwater = true }
	end
	if phase == "Arrival" or phase == "Night1" or phase == "Open" or phase == "Finale" then
		return { amb_night = true, amb_water = true }
	end
	return {}
end

local function updateAmbience()
	local want = wanted()
	for id, s in ambience do
		if not want[id] then
			s:Destroy()
			ambience[id] = nil
		end
	end
	for id in want do
		if not ambience[id] and Sounds[id] and Sounds[id].asset ~= "" then
			local s = make(Sounds[id])
			s.Name = "Ambience_" .. id
			s.Parent = SoundService
			s:Play()
			ambience[id] = s
		end
	end
end

function SoundController.Ambience(): { string }
	local out = {}
	for id in ambience do
		table.insert(out, id)
	end
	table.sort(out)
	return out
end

-- the music layer (I-13): one track at a time, crossfaded. Tension/chase come from Sen's warnings to this player
local Config = require(Shared:WaitForChild("Config"))
local TweenService = game:GetService("TweenService")
local layer: { [string]: Sound } = {}
local tensionUntil, chaseUntil = 0, 0

local function wantedMusic(): string?
	local phase = ReplicatedStorage:GetAttribute("Phase")
	local player = Players.LocalPlayer
	if ReplicatedStorage:GetAttribute("FinaleStatic") == true or phase == "Finale" or phase == "Ending" then
		return nil -- the finale has its own music, and Im lặng is silence
	end
	if not player:GetAttribute("InRun") then
		return if ReplicatedStorage:GetAttribute("ServerKind") == "Run" then nil else "music_menu"
	end
	if player:GetAttribute("Taken") == true then
		return nil
	end
	local now = os.clock()
	if now < chaseUntil then
		return "music_chase"
	elseif now < tensionUntil then
		return "music_tension"
	elseif phase == "Open" then
		return "music_bed"
	end
	return nil
end

local function updateMusic()
	local want = wantedMusic()
	local fade = TweenInfo.new(Config.MusicFadeSeconds)
	for id, s in layer do
		if id ~= want then
			layer[id] = nil
			local t = TweenService:Create(s, fade, { Volume = 0 })
			t.Completed:Connect(function()
				s:Destroy()
			end)
			t:Play()
		end
	end
	if want and not layer[want] and Sounds[want] and Sounds[want].asset ~= "" then
		local s = make(Sounds[want])
		s.Name = "Music_" .. want
		s.Volume = 0
		s.Parent = SoundService
		s:Play()
		layer[want] = s
		TweenService:Create(s, fade, { Volume = Sounds[want].volume or 0.5 }):Play()
	end
end

function SoundController.Music(): string?
	for id in layer do
		return id
	end
	return nil
end

function SoundController.Start()
	Remotes.event(Remotes.Names.SenWarning).OnClientEvent:Connect(function(step: number)
		local now = os.clock()
		if step >= Config.MusicChaseStep then
			chaseUntil = now + Config.MusicHoldSeconds
		elseif step >= Config.MusicTensionStep then
			tensionUntil = now + Config.MusicHoldSeconds
		end
		updateMusic()
	end)
	task.spawn(function()
		while true do
			updateMusic()
			task.wait(0.5)
		end
	end)
	Remotes.event(Remotes.Names.Sfx).OnClientEvent:Connect(function(id: string, pos: Vector3?)
		SoundController.Play(id, pos)
	end)
	ReplicatedStorage:GetAttributeChangedSignal("Phase"):Connect(function()
		local phase = ReplicatedStorage:GetAttribute("Phase")
		if phase ~= "Finale" and phase ~= "Ending" then
			for s in music do
				s:Destroy()
			end
		end
	end)
	for _, a in { "Phase", "FinaleStatic" } do
		ReplicatedStorage:GetAttributeChangedSignal(a):Connect(updateAmbience)
	end
	local player = Players.LocalPlayer
	player:GetAttributeChangedSignal("Taken"):Connect(updateAmbience)
	player:GetAttributeChangedSignal("Stayed"):Connect(updateAmbience)
	updateAmbience()
end

return SoundController
