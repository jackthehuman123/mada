--!strict
-- The story's client side (PROTOTYPE_BRIEF §5.1, §5.5, §5.6, §7):
--   mementos: the memory plays (fade, lines, a sound, fade back)
--   Sen's warning: the screen hears and sees what the server says (the humming line comes as a message)
--   taken: the "Light a lantern" button and its 60 s cooldown
--   the finale: the camera follows the server's shots (FinaleCamPos / FinaleCamLook), the fade and the static,
--     and the Stay ending's choice (hold on / let go)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Mementos = require(Shared:WaitForChild("Content"):WaitForChild("Mementos"))
local Pace = require(Shared:WaitForChild("Pace"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local StoryController = {}

local player = Players.LocalPlayer
local UI: any, Sound: any
local lastLantern = -math.huge
local cinematic = false

local function phase(): string
	return (ReplicatedStorage:GetAttribute("Phase") :: string?) or ""
end

local function updateCamera()
	local cam = Workspace.CurrentCamera
	local pos = ReplicatedStorage:GetAttribute("FinaleCamPos")
	local look = ReplicatedStorage:GetAttribute("FinaleCamLook")
	local want = (phase() == "Finale" or phase() == "Ending") and typeof(pos) == "Vector3" and typeof(look) == "Vector3"
	if want then
		if not cinematic then
			UI.HideClue() -- a scene starts: nothing left open in front of it
			UI.ToggleJournal(false)
			UI.HideDialogue()
		end
		cinematic = true
		cam.CameraType = Enum.CameraType.Scriptable
		cam.CFrame = CFrame.lookAt(pos :: Vector3, look :: Vector3)
	elseif cinematic then
		cinematic = false
		cam.CameraType = Enum.CameraType.Custom
		UI.ScreenStatic(false)
	end
end

function StoryController.State(): { [string]: any }
	return { cinematic = cinematic, taken = player:GetAttribute("Taken") == true, memory = UI.MemoryShowing(),
		stayOpen = UI.Gui():FindFirstChild("Stay") and (UI.Gui() :: any).Stay.Visible or false }
end

function StoryController.Start()
	UI = require(script.Parent:WaitForChild("UIController"))
	Sound = require(script.Parent:WaitForChild("SoundController"))
	-- mementos
	Remotes.event(Remotes.Names.Memento).OnClientEvent:Connect(function(id: string)
		local m = Mementos[id]
		if not m or UI.MemoryShowing() then
			return
		end
		Sound.Play(m.sound, nil)
		UI.Memory(m.lines, Config.MementoLineSeconds)
	end)
	-- taken: the lantern button
	UI.onLightLantern = function()
		if os.clock() - lastLantern >= Pace.seconds(Config.TakenLanternCooldown) then
			lastLantern = os.clock()
			Remotes.event(Remotes.Names.LightLantern):FireServer()
		end
	end
	local function onTaken()
		if player:GetAttribute("Taken") == true then
			UI.HideClue()
			UI.ToggleJournal(false)
		end
		-- no "Light a lantern" once the night is over (Im lặng takes everyone in the finale)
		local over = ReplicatedStorage:GetAttribute("Phase") == "Finale" or ReplicatedStorage:GetAttribute("Phase") == "Ending"
		-- (not while the pull into the water is still playing: SenController)
		UI.SetTaken(player:GetAttribute("Taken") == true and player:GetAttribute("Stayed") ~= true and not over
			and player:GetAttribute("SenCinematic") ~= true)
	end
	player:GetAttributeChangedSignal("Taken"):Connect(onTaken)
	player:GetAttributeChangedSignal("SenCinematic"):Connect(onTaken)
	player:GetAttributeChangedSignal("Stayed"):Connect(onTaken)
	ReplicatedStorage:GetAttributeChangedSignal("Phase"):Connect(onTaken)
	onTaken()
	RunService.Heartbeat:Connect(function()
		if player:GetAttribute("Taken") == true then
			UI.SetLanternCooldown(Pace.seconds(Config.TakenLanternCooldown) - (os.clock() - lastLantern))
		end
	end)
	-- the Stay ending's choice
	UI.onStay = function(hold: boolean)
		Remotes.event(Remotes.Names.StayChoice):FireServer(hold)
	end
	Remotes.event(Remotes.Names.StayChoice).OnClientEvent:Connect(function(open: boolean, seconds: number?)
		UI.ShowStay(open, seconds)
	end)
	-- the finale's camera, fade and static
	for _, a in { "FinaleCamPos", "FinaleCamLook", "Phase" } do
		ReplicatedStorage:GetAttributeChangedSignal(a):Connect(updateCamera)
	end
	ReplicatedStorage:GetAttributeChangedSignal("FinaleFade"):Connect(function()
		if ReplicatedStorage:GetAttribute("FinaleFade") == true then
			task.spawn(UI.Fade, 3)
		end
	end)
	RunService.RenderStepped:Connect(function()
		if ReplicatedStorage:GetAttribute("FinaleStatic") == true and (phase() == "Finale" or phase() == "Ending") then
			UI.ScreenStatic(true)
		end
	end)
	ReplicatedStorage:GetAttributeChangedSignal("FinaleStatic"):Connect(function()
		if ReplicatedStorage:GetAttribute("FinaleStatic") ~= true then
			UI.ScreenStatic(false)
		end
	end)
	-- Studio-only hook for the factory tests
	if RunService:IsStudio() then
		local hook = Instance.new("BindableFunction")
		hook.Name = "LVStoryDebug"
		hook.OnInvoke = function(cmd: string, arg: any): any
			if cmd == "lantern" then
				UI.onLightLantern()
			elseif cmd == "stay" then
				UI.onStay(arg == "hold")
			end
			return StoryController.State()
		end
		hook.Parent = player:WaitForChild("PlayerScripts")
	end
end

return StoryController
