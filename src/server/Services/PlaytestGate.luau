--!strict
-- Closed playtest: a live server lets in only members of Config.PlaytestGroupId; everyone else is kicked on join.
-- Studio (tests, local servers) is never gated. If Roblox's group check fails, the player is let in rather than kicked.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Text = require(Shared:WaitForChild("Content"):WaitForChild("Text"))

local PlaytestGate = {}

local function check(player: Player)
	local ok, member = pcall(player.IsInGroup, player, Config.PlaytestGroupId)
	if ok and not member then
		print(`[Playtest] {player.UserId} is not in group {Config.PlaytestGroupId}: kicked`)
		player:Kick(Text.Messages.membersOnly)
	elseif not ok then
		warn(`[Playtest] group check failed for {player.UserId}; let in: {member}`)
	end
end

function PlaytestGate.Start()
	if RunService:IsStudio() or Config.PlaytestGroupId == 0 then
		return
	end
	Players.PlayerAdded:Connect(check)
	for _, p in Players:GetPlayers() do
		task.spawn(check, p)
	end
end

return PlaytestGate
