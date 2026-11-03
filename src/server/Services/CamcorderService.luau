--!strict
-- The camcorder's battery is the server's (PROTOTYPE_BRIEF §5.2): a player attribute "Battery" (percent). It drains
-- while that player's viewfinder is up and recharges inside the ShrineZone. Recording and playback are client-side.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Analytics = require(Shared:WaitForChild("Analytics"))
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local CamcorderService = {}

local raised: { [Player]: boolean } = {}

local function full(p: Player)
	p:SetAttribute("Battery", 100)
end

function CamcorderService.Reset()
	for _, p in Players:GetPlayers() do
		full(p)
		raised[p] = nil
		p:SetAttribute("CameraUp", false)
	end
end

function CamcorderService.IsRaised(p: Player): boolean
	return raised[p] == true
end

function CamcorderService.Init()
	Remotes.event(Remotes.Names.CameraRaised).OnServerEvent:Connect(function(p: Player, up: any)
		if typeof(up) ~= "boolean" then
			return
		end
		if up and ((p:GetAttribute("Battery") :: number?) or 0) <= 0 then
			up = false
		end
		raised[p] = up or nil
		p:SetAttribute("CameraUp", up == true) -- everyone sees the arms come up (BodyController)
	end)
	Players.PlayerAdded:Connect(full)
	Players.PlayerRemoving:Connect(function(p)
		raised[p] = nil
	end)
	for _, p in Players:GetPlayers() do
		full(p)
	end
end

function CamcorderService.Start()
	local GameState = require(script.Parent:WaitForChild("GameStateService")) :: any
	GameState.OnReset(CamcorderService.Reset)
	local last = os.clock()
	while true do
		task.wait(0.25)
		local now = os.clock()
		local dt = now - last
		last = now
		for _, p in Players:GetPlayers() do
			local b = (p:GetAttribute("Battery") :: number?) or 100
			if GameState.InShrine(p) then
				b = math.min(100, b + Config.CameraRechargePerSecond * dt)
			elseif raised[p] then
				b = math.max(0, b - Config.CameraDrainPerSecond * dt)
				if b <= 0 then
					raised[p] = nil
					p:SetAttribute("CameraUp", false)
					Analytics.track("camera_battery_empty", { player = p.Name })
				end
			end
			p:SetAttribute("Battery", b)
		end
	end
end

return CamcorderService
