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

function SoundController.Start()
	Remotes.event(Remotes.Names.Sfx).OnClientEvent:Connect(function(id: string, pos: Vector3?)
		SoundController.Play(id, pos)
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
