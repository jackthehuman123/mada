--!strict
-- Game time for scripted sequences. In Studio the tests speed Night 1 up with the ReplicatedStorage attribute
-- "DebugTimeScale" (DebugService "speed"); live servers always run at 1.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Pace = {}

function Pace.scale(): number
	if not RunService:IsStudio() then
		return 1
	end
	local s = ReplicatedStorage:GetAttribute("DebugTimeScale")
	return if typeof(s) == "number" and s > 0 then s else 1
end

-- seconds of game time -> real seconds
function Pace.seconds(s: number): number
	return s / Pace.scale()
end

function Pace.wait(s: number)
	task.wait(Pace.seconds(s))
end

return Pace
