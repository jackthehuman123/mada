--!strict
-- Any way out of the village brings players back to the lake shore (PROTOTYPE_BRIEF §4 beat 5, §8): walking into a
-- BoundaryTeleport part fades that player's screen and puts them at the ShoreReturn point.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Tags = require(Shared:WaitForChild("Tags"))

local BoundaryService = {}

local busy: { [Player]: boolean } = {}

function BoundaryService.Return(player: Player)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local back = CollectionService:GetTagged(Tags.ShoreReturn)[1] :: BasePart?
	if not root or not back or busy[player] then
		return
	end
	busy[player] = true
	Remotes.event(Remotes.Names.Fade):FireClient(player, Config.BoundaryFadeSeconds)
	task.delay(Config.BoundaryFadeSeconds / 2, function()
		if root.Parent then
			root.AssemblyLinearVelocity = Vector3.zero
			root.CFrame = CFrame.new(back.Position + Vector3.new(0, 3, 0))
		end
		task.wait(Config.BoundaryCooldownSeconds)
		busy[player] = nil
	end)
end

local function watch(part: Instance)
	if not part:IsA("BasePart") then
		return
	end
	part.Touched:Connect(function(hit: BasePart)
		local character = hit:FindFirstAncestorOfClass("Model")
		local player = character and Players:GetPlayerFromCharacter(character)
		if player then
			BoundaryService.Return(player)
		end
	end)
end

function BoundaryService.Init()
	Remotes.event(Remotes.Names.Fade)
	Players.PlayerRemoving:Connect(function(p)
		busy[p] = nil
	end)
end

function BoundaryService.Start()
	for _, part in CollectionService:GetTagged(Tags.BoundaryTeleport) do
		watch(part)
	end
	CollectionService:GetInstanceAddedSignal(Tags.BoundaryTeleport):Connect(watch)
end

return BoundaryService
