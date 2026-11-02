--!strict
-- Listens to the replicated Phase attribute. Other controllers can react to phase changes here.
-- TODO(M2+): drive HUD visibility, text cards and music by phase.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PhaseController = {}

function PhaseController.Start()
	ReplicatedStorage:GetAttributeChangedSignal("Phase"):Connect(function()
		print(`[LangVong] client sees phase {ReplicatedStorage:GetAttribute("Phase")}`)
	end)
end

return PhaseController
