--!strict
-- Builds the model templates (Shared/Art) in the background at server start.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Art = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Art"))

local ArtService = {}

function ArtService.Init()
	task.spawn(function()
		local ok, err = pcall(Art.build)
		if not ok then
			warn(`[Art] building the templates failed: {err}`)
		end
	end)
end

return ArtService
