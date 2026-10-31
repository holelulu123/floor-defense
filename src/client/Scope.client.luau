-- Sniper scope: hold the right mouse button with a scoped primary (Weapons `scope`, the Sniper's BoltRifle) to aim
-- down the scope. The camera goes to first person with its field of view divided by the zoom, the mouse turns that
-- much slower for fine aim, and a black scope ring with crosshairs covers the screen. Release, a weapon switch or
-- death puts everything back. Purely local view; shots still go through Weapon.client and the server.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Weapons = require(ReplicatedStorage.Shared.Weapons)

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

local ZOOM_SECONDS = 0.12

-- Overlay: a clear circle in a black screen (a huge stroke around a round frame), thin crosshair lines and a dot.
local gui = Instance.new("ScreenGui")
gui.Name = "Scope"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 5
gui.Enabled = false

local lens = Instance.new("Frame")
lens.AnchorPoint = Vector2.new(0.5, 0.5)
lens.Position = UDim2.fromScale(0.5, 0.5)
lens.Size = UDim2.fromScale(0.8, 0.8)
lens.BackgroundTransparency = 1
lens.Parent = gui
do
	local aspect = Instance.new("UIAspectRatioConstraint")
	aspect.AspectRatio = 1
	aspect.DominantAxis = Enum.DominantAxis.Height
	aspect.Parent = lens
	local round = Instance.new("UICorner")
	round.CornerRadius = UDim.new(0.5, 0)
	round.Parent = lens
	local shade = Instance.new("UIStroke")
	shade.Color = Color3.new(0, 0, 0)
	shade.Thickness = 2000 -- reaches past every screen edge
	shade.Parent = lens
	local rim = Instance.new("Frame") -- dark inner rim
	rim.Size = UDim2.fromScale(1, 1)
	rim.BackgroundTransparency = 1
	rim.Parent = lens
	local rimRound = Instance.new("UICorner")
	rimRound.CornerRadius = UDim.new(0.5, 0)
	rimRound.Parent = rim
	local rimStroke = Instance.new("UIStroke")
	rimStroke.Color = Color3.fromRGB(20, 20, 20)
	rimStroke.Thickness = 10
	rimStroke.Transparency = 0.3
	rimStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	rimStroke.Parent = rim
end

local function line(size: UDim2)
	local l = Instance.new("Frame")
	l.AnchorPoint = Vector2.new(0.5, 0.5)
	l.Position = UDim2.fromScale(0.5, 0.5)
	l.Size = size
	l.BackgroundColor3 = Color3.new(0, 0, 0)
	l.BackgroundTransparency = 0.15
	l.BorderSizePixel = 0
	l.Parent = lens
end
line(UDim2.new(1, 0, 0, 2))
line(UDim2.new(0, 2, 1, 0))
do
	local dot = Instance.new("Frame")
	dot.AnchorPoint = Vector2.new(0.5, 0.5)
	dot.Position = UDim2.fromScale(0.5, 0.5)
	dot.Size = UDim2.fromOffset(6, 6)
	dot.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
	dot.BorderSizePixel = 0
	dot.Parent = lens
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(1, 0)
	c.Parent = dot
end
gui.Parent = player:WaitForChild("PlayerGui")

-- State ------------------------------------------------------------------------------------------

local scoped = false
-- The unscoped view, taken once: re-reading FieldOfView mid-tween (a fast re-press) would save a zoomed value.
local BASE_FOV = camera.FieldOfView
local saved: { mode: Enum.CameraMode, sensitivity: number }? = nil
local zoomTween: Tween? = nil

local function tweenFov(fov: number)
	if zoomTween then
		zoomTween:Cancel()
	end
	local t = TweenService:Create(camera, TweenInfo.new(ZOOM_SECONDS), { FieldOfView = fov })
	zoomTween = t
	t:Play()
end

local function scopeOf(): number?
	if player:GetAttribute("WeaponSlot") ~= 1 then
		return nil
	end
	local def = Weapons.find(player:GetAttribute("Weapon"))
	return def and def.scope
end

local function setScoped(on: boolean)
	if on == scoped then
		return
	end
	local zoom = scopeOf()
	if on and not zoom then
		return
	end
	scoped = on
	if on and zoom then
		local before = { mode = player.CameraMode, sensitivity = UserInputService.MouseDeltaSensitivity }
		saved = before
		player.CameraMode = Enum.CameraMode.LockFirstPerson
		tweenFov(BASE_FOV / zoom)
		UserInputService.MouseDeltaSensitivity = before.sensitivity / zoom
		gui.Enabled = true
	elseif saved then
		tweenFov(BASE_FOV)
		player.CameraMode = saved.mode
		UserInputService.MouseDeltaSensitivity = saved.sensitivity
		gui.Enabled = false
		saved = nil
	end
end

UserInputService.InputBegan:Connect(function(input, processed)
	if not processed and input.UserInputType == Enum.UserInputType.MouseButton2 then
		setScoped(true)
	end
end)
UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		setScoped(false)
	end
end)
-- Leave the scope when the scoped weapon is put away, on death and on respawn.
for _, attribute in { "Weapon", "WeaponSlot" } do
	player:GetAttributeChangedSignal(attribute):Connect(function()
		if scoped and not scopeOf() then
			setScoped(false)
		end
	end)
end
player.CharacterAdded:Connect(function()
	setScoped(false)
end)
RunService.RenderStepped:Connect(function()
	if scoped then
		local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if not humanoid or humanoid.Health <= 0 then
			setScoped(false)
		end
	end
end)
