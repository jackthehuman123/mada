--!strict
--!nolint DeprecatedApi
-- (DeprecatedApi off: LoadCharacter/IsInGroup kept on purpose until a playtest, see docs/ISSUES.md)
-- Closed playtest: a live server lets in only members of Config.PlaytestGroupId; everyone else is kicked on join.
-- Studio (tests, local servers) is never gated. If Roblox's group check keeps failing, the player is asked to rejoin
-- (it used to let them in: a closed playtest open to anyone whenever the group service hiccupped).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Text = require(Shared:WaitForChild("Content"):WaitForChild("Text"))

local PlaytestGate = {}

local function check(player: Player)
	local ok, member = false, nil
	for try = 1, 3 do
		-- selene: allow(deprecated)
		ok, member = pcall(player.IsInGroup, player, Config.PlaytestGroupId)
		if ok or not player.Parent then
			break
		end
		task.wait(2 * try)
	end
	if not player.Parent then
		return
	end
	if ok and not member then
		print(`[Playtest] {player.UserId} is not in group {Config.PlaytestGroupId}: kicked`)
		player:Kick(Text.Messages.membersOnly)
	elseif not ok then
		warn(`[Playtest] group check failed 3 times for {player.UserId}: asked to rejoin ({member})`)
		player:Kick(Text.Messages.membersCheckFailed)
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
