-- First/third-person toggle. V switches on keyboard; a HUD button covers touch.
-- Touch devices default to third person, everything else to the Config default.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage.Shared.Config)

local player = Players.LocalPlayer

local firstPerson = Config.Camera.DefaultFirstPerson and not UserInputService.TouchEnabled

local function apply()
	player.CameraMode = if firstPerson then Enum.CameraMode.LockFirstPerson else Enum.CameraMode.Classic
	if not firstPerson then
		player.CameraMaxZoomDistance = Config.Camera.MaxZoom
	end
end

local function toggle()
	firstPerson = not firstPerson
	apply()
end

UserInputService.InputBegan:Connect(function(input, processed)
	if not processed and input.KeyCode == Config.Camera.ToggleKey then
		toggle()
	end
end)

if UserInputService.TouchEnabled then
	local gui = Instance.new("ScreenGui")
	gui.Name = "CameraToggle"
	gui.ResetOnSpawn = false

	local button = Instance.new("TextButton")
	button.AnchorPoint = Vector2.new(1, 0)
	button.Position = UDim2.new(1, -16, 0, 16)
	button.Size = UDim2.fromOffset(44, 44)
	button.Text = "👁"
	button.TextSize = 24
	button.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	button.BackgroundTransparency = 0.5
	button.TextColor3 = Color3.new(1, 1, 1)
	button.Parent = gui
	button.Activated:Connect(toggle)

	gui.Parent = player:WaitForChild("PlayerGui")
end

player.CharacterAdded:Connect(apply)
apply()
