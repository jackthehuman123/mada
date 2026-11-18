--!strict
-- Shows the server's dialogue lines in the dialogue box and tells the server when this player moves it on
-- (click the box or press Enter). The server decides when the conversation ends.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Remotes"))

local DialogueController = {}

function DialogueController.Start()
	local UI = require(script.Parent:WaitForChild("UIController")) :: any
	local advance = Remotes.event(Remotes.Names.DialogueAdvance)
	local open = false
	local function next()
		if open then
			advance:FireServer()
		end
	end
	UI.onDialogueClick = next
	UI.onDialogueChoice = function()
		Remotes.event(Remotes.Names.DialogueChoice):FireServer()
	end
	UI.onDialogueSkip = function()
		if open then
			Remotes.event(Remotes.Names.DialogueSkip):FireServer()
		end
	end
	Remotes.event(Remotes.Names.DialogueShow).OnClientEvent
		:Connect(function(speaker: string, text: string, _i: number, _n: number, choice: string?)
			open = true
			UI.ShowDialogue(speaker, text, choice)
		end)
	Remotes.event(Remotes.Names.DialogueEnd).OnClientEvent:Connect(function()
		open = false
		UI.HideDialogue()
	end)
	UserInputService.InputBegan:Connect(function(input, processed)
		if not processed and (input.KeyCode == Enum.KeyCode.Return or input.KeyCode == Enum.KeyCode.KeypadEnter) then
			next()
		end
	end)
end

return DialogueController
