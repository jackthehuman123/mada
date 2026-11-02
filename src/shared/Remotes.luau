--!strict
-- Single place to create/get RemoteEvents. The server creates them; clients wait for them.
-- Usage: local ev = Remotes.event(Remotes.Names.ClueFound)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local FOLDER_NAME = "Remotes"

local Remotes = {}

-- Add every remote name here before using it.
Remotes.Names = {
	ClueFound = "ClueFound", -- server -> clients: (clueId)
	InspectRequest = "InspectRequest", -- client -> server: (clueId)
	DialogueAdvance = "DialogueAdvance", -- client -> server
	DialogueShow = "DialogueShow", -- server -> client: (speaker, line, index, total)
	DialogueEnd = "DialogueEnd", -- server -> client: the conversation is over
	DialogueChoice = "DialogueChoice", -- client -> server: the player pressed the line's choice button
	Memento = "Memento", -- server -> client: (mementoId) play that child's memory
	LightLantern = "LightLantern", -- client -> server: a taken player lights a lantern on the surface
	StayChoice = "StayChoice", -- server -> client: (open) / client -> server: (hold: boolean) the Stay ending
	Track = "Track", -- client -> server: (name, data) analytics events that happen on the client
	Sfx = "Sfx", -- server -> clients: (soundId, position?) a sound from Content/Sounds (subtitled until it has an asset)
	ShowTextCard = "ShowTextCard", -- server -> clients: (cardId) teller narration
	SenWarning = "SenWarning", -- server -> target client: (step)
	PlayerTaken = "PlayerTaken", -- server -> clients: (userId)
	InspectClue = "InspectClue", -- server -> client: (clueId) open the clue panel
	JournalSync = "JournalSync", -- server -> clients: ({ clueId }) the group's found clues
	CameraRaised = "CameraRaised", -- client -> server: (raised: boolean) the viewfinder is up (battery drain)
	Message = "Message", -- server -> clients: (text) one line at the bottom of the screen
	Fade = "Fade", -- server -> client: (seconds) fade to black and back (boundary return)
}

local function getFolder(): Folder
	local existing = ReplicatedStorage:FindFirstChild(FOLDER_NAME)
	if existing then
		return existing :: Folder
	end
	if RunService:IsServer() then
		local folder = Instance.new("Folder")
		folder.Name = FOLDER_NAME
		folder.Parent = ReplicatedStorage
		return folder
	end
	return ReplicatedStorage:WaitForChild(FOLDER_NAME) :: Folder
end

function Remotes.event(name: string): RemoteEvent
	local folder = getFolder()
	local existing = folder:FindFirstChild(name)
	if existing then
		return existing :: RemoteEvent
	end
	if RunService:IsServer() then
		local remote = Instance.new("RemoteEvent")
		remote.Name = name
		remote.Parent = folder
		return remote
	end
	return folder:WaitForChild(name) :: RemoteEvent
end

return Remotes
