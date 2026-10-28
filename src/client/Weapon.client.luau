-- Client side of shooting: input, aiming, a local cooldown for feel, tracers and a crosshair.
-- The server decides hits; this script only tells it where we aimed.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Weapons = require(ReplicatedStorage.Shared.Weapons)

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local fireRemote = remotes:WaitForChild("Fire") :: RemoteEvent
local hitFx = remotes:WaitForChild("HitFx") :: RemoteEvent

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

local TRACER_SECONDS = 0.06
local AIM_RANGE = 1000

-- Crosshair -------------------------------------------------------------------------------------

local gui = Instance.new("ScreenGui")
gui.Name = "Crosshair"
gui.ResetOnSpawn = false
gui.Enabled = false

local dot = Instance.new("Frame")
dot.AnchorPoint = Vector2.new(0.5, 0.5)
dot.Position = UDim2.fromScale(0.5, 0.5)
dot.Size = UDim2.fromOffset(6, 6)
dot.BackgroundColor3 = Color3.new(1, 1, 1)
dot.BorderSizePixel = 0
dot.Parent = gui
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(1, 0)
corner.Parent = dot

gui.Parent = player:WaitForChild("PlayerGui")

local function flashHit()
	dot.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
	dot.Size = UDim2.fromOffset(10, 10)
	task.delay(0.1, function()
		dot.BackgroundColor3 = Color3.new(1, 1, 1)
		dot.Size = UDim2.fromOffset(6, 6)
	end)
end

-- Tracers ---------------------------------------------------------------------------------------

local function drawTracer(from: Vector3, to: Vector3)
	local length = (to - from).Magnitude
	if length < 0.5 then
		return
	end
	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Material = Enum.Material.Neon
	part.Color = Color3.fromRGB(255, 230, 120)
	part.Size = Vector3.new(0.1, 0.1, length)
	part.CFrame = CFrame.lookAt(from, to) * CFrame.new(0, 0, -length / 2)
	part.Parent = camera
	task.delay(TRACER_SECONDS, part.Destroy, part)
end

-- Aiming ----------------------------------------------------------------------------------------

local function currentWeapon(): Weapons.Weapon?
	local name = player:GetAttribute("Weapon")
	return if type(name) == "string" then Weapons.get(name) else nil
end

-- Returns the muzzle origin and the direction toward whatever is under the crosshair / cursor.
local function aim(): (Vector3?, Vector3?)
	local character = player.Character
	local head = character and character:FindFirstChild("Head") :: BasePart?
	if not head then
		return nil, nil
	end

	local ray
	if UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter then
		ray = camera:ViewportPointToRay(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
	else
		-- GetMouseLocation is already in viewport space (inset included), so pair it with ViewportPointToRay.
		local mouse = UserInputService:GetMouseLocation()
		ray = camera:ViewportPointToRay(mouse.X, mouse.Y)
	end

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character :: Instance }
	local hit = Workspace:Raycast(ray.Origin, ray.Direction * AIM_RANGE, params)
	local target = if hit then hit.Position else ray.Origin + ray.Direction * AIM_RANGE

	local origin = head.Position
	return origin, (target - origin).Unit
end

-- Firing ----------------------------------------------------------------------------------------

local holding = false
local lastShot = 0

local function tryFire()
	local def = currentWeapon()
	if not def then
		return
	end
	local now = os.clock()
	if now - lastShot < Weapons.interval(def) then
		return
	end
	local origin, direction = aim()
	if not origin or not direction then
		return
	end
	lastShot = now
	fireRemote:FireServer(origin, direction)
	drawTracer(origin, origin + direction * def.range)
end

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		holding = true
		tryFire()
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		holding = false
	end
end)

RunService.RenderStepped:Connect(function()
	local def = currentWeapon()
	gui.Enabled = def ~= nil
	if holding and def and def.automatic then
		tryFire()
	end
end)

hitFx.OnClientEvent:Connect(function(shooterUserId: number, origin: Vector3, endpoint: Vector3, hit: boolean)
	if shooterUserId == player.UserId then
		if hit then
			flashHit()
		end
		return
	end
	drawTracer(origin, endpoint)
end)
