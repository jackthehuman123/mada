--!strict
-- Plays the server's sounds (Content/Sounds). A sound with an asset plays at its position (or everywhere); a sound
-- with no asset yet shows its subtitle instead, if it has one, so scripted moments still read before the audio pass.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Remotes"))
local Sounds = require(Shared:WaitForChild("Content"):WaitForChild("Sounds"))

local SoundController = {}

function SoundController.Play(id: string, pos: Vector3?)
	local UI = require(script.Parent:WaitForChild("UIController")) :: any
	local def = Sounds[id]
	if not def then
		warn(`[LangVong] unknown sound {id}`)
		return
	end
	if def.asset == "" then
		if def.subtitle then
			UI.Message(def.subtitle)
		end
		return
	end
	local s = Instance.new("Sound")
	s.SoundId = def.asset
	s.Volume = def.volume or 0.5
	if pos then
		local a = Instance.new("Attachment")
		a.WorldPosition = pos
		a.Parent = Workspace.Terrain
		s.Parent = a
		s.Ended:Connect(function()
			a:Destroy()
		end)
		s:Play()
	else
		SoundService:PlayLocalSound(s)
	end
end

function SoundController.Start()
	Remotes.event(Remotes.Names.Sfx).OnClientEvent:Connect(function(id: string, pos: Vector3?)
		SoundController.Play(id, pos)
	end)
end

return SoundController
