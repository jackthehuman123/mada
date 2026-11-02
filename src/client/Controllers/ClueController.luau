--!strict
-- Shows a clue when the server says this player looked at one, keeps the journal in step with the group's clues,
-- and opens the journal on J.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Remotes"))

local ClueController = {}

function ClueController.Start()
	local UI = require(script.Parent:WaitForChild("UIController")) :: any
	Remotes.event(Remotes.Names.InspectClue).OnClientEvent:Connect(function(id: string)
		UI.ShowClue(id)
	end)
	Remotes.event(Remotes.Names.JournalSync).OnClientEvent:Connect(function(ids: { string })
		UI.SetJournal(ids)
	end)
	UserInputService.InputBegan:Connect(function(input, processed)
		if not processed and input.KeyCode == Enum.KeyCode.J then
			UI.ToggleJournal()
		end
	end)
end

return ClueController
