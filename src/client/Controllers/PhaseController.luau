--!strict
-- Listens to the replicated Phase attribute and the server's text cards, messages and fades, and shows them.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Remotes"))
local Text = require(Shared:WaitForChild("Content"):WaitForChild("Text"))

local PhaseController = {}

function PhaseController.Start()
	local UI = require(script.Parent:WaitForChild("UIController")) :: any
	ReplicatedStorage:GetAttributeChangedSignal("Phase"):Connect(function()
		print(`[LangVong] client sees phase {ReplicatedStorage:GetAttribute("Phase")}`)
	end)
	Remotes.event(Remotes.Names.ShowTextCard).OnClientEvent:Connect(function(id: string)
		local text = (Text.Cards :: any)[id]
		if text then
			UI.Card(text)
		end
	end)
	Remotes.event(Remotes.Names.Message).OnClientEvent:Connect(function(text: string)
		UI.Message(text)
	end)
	Remotes.event(Remotes.Names.Fade).OnClientEvent:Connect(function(seconds: number)
		UI.Fade(seconds)
	end)
end

return PhaseController
