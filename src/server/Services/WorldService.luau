--!strict
-- Builds the graybox world from code (World/Build) when the place doesn't have it yet, so a fresh place, a live
-- server and a test run all get the same village from git. Runs in Init: other services find the world by tags in Start.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))

local WorldService = {}

function WorldService.Init()
	if Workspace:GetAttribute("WorldBuilt") ~= "LangVong" then
		local build = require(script.Parent.Parent:WaitForChild("World"):WaitForChild("Build")) :: any
		local t0 = os.clock()
		build()
		print(`[LangVong] world built in {math.floor((os.clock() - t0) * 1000)} ms`)
	end
	StarterPlayer.CharacterWalkSpeed = Config.WalkSpeed
	local base = Workspace:FindFirstChild("Baseplate")
	if base then
		base:Destroy() -- a new Studio place comes with one; the village has its own land
	end
end

return WorldService
