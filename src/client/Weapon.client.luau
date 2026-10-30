-- Client side of shooting: input, aiming, a local cooldown for feel, tracers and a crosshair.
-- The server decides hits; this script only tells it where we aimed. Skill keys (Q/E) send the
-- skill index plus the same aim ray; SkillFx events from the server are drawn here as placeholders.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Classes = require(ReplicatedStorage.Shared.Classes)
local Weapons = require(ReplicatedStorage.Shared.Weapons)

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local fireRemote = remotes:WaitForChild("Fire") :: RemoteEvent
local hitFx = remotes:WaitForChild("HitFx") :: RemoteEvent
local useSkill = remotes:WaitForChild("UseSkill") :: RemoteEvent
local skillFx = remotes:WaitForChild("SkillFx") :: RemoteEvent

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

-- Skills ----------------------------------------------------------------------------------------

local SKILL_KEYS = { [Enum.KeyCode.Q] = 1, [Enum.KeyCode.E] = 2 }

local function useSkillIndex(index: number)
	if not currentWeapon() then
		return -- not in a run
	end
	local origin, direction = aim()
	useSkill:FireServer(index, origin, direction)
end

-- Hud.client.luau fires this bindable when a skill button is tapped (touch / mouse).
local skillButtonPressed = Instance.new("BindableEvent")
skillButtonPressed.Name = "SkillButtonPressed"
skillButtonPressed.Parent = player:WaitForChild("PlayerScripts")
skillButtonPressed.Event:Connect(useSkillIndex)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		holding = true
		tryFire()
	elseif input.UserInputType == Enum.UserInputType.Keyboard then
		local index = SKILL_KEYS[input.KeyCode]
		if index then
			useSkillIndex(index)
		end
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

-- Skill effects: short-lived neon placeholders so every skill reads on screen before real VFX exist.

local function fxPart(cframe: CFrame, size: Vector3, color: Color3, seconds: number, shape: Enum.PartType?): Part
	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Material = Enum.Material.Neon
	part.Transparency = 0.4
	part.Color = color
	part.Shape = shape or Enum.PartType.Block
	part.Size = size
	part.CFrame = cframe
	part.Parent = camera
	task.delay(seconds, part.Destroy, part)
	return part
end

local FX_COLORS = {
	sweep = Color3.fromRGB(230, 230, 240),
	nova = Color3.fromRGB(120, 200, 255),
	flame = Color3.fromRGB(255, 120, 30),
	firewall = Color3.fromRGB(255, 90, 20),
	blast = Color3.fromRGB(255, 170, 40),
	buff = Color3.fromRGB(255, 240, 120),
	crate = Color3.fromRGB(120, 200, 90),
	wall = Color3.fromRGB(160, 170, 200),
	pulse = Color3.fromRGB(90, 255, 140),
	shield = Color3.fromRGB(90, 200, 255),
	build = Color3.fromRGB(240, 160, 60),
	mark = Color3.fromRGB(255, 60, 60),
	pounce = Color3.fromRGB(190, 90, 255),
	dash = Color3.fromRGB(200, 240, 255),
}

skillFx.OnClientEvent:Connect(function(fx)
	if type(fx) ~= "table" or type(fx.kind) ~= "string" then
		return
	end
	local color = FX_COLORS[fx.kind] or Color3.new(1, 1, 1)
	if fx.kind == "turretShot" and fx.from and fx.to then
		drawTracer(fx.from, fx.to)
	elseif (fx.kind == "pierce" or fx.kind == "flame") and fx.position and fx.direction then
		local length = fx.range or 20
		local width = if fx.kind == "flame" then 3 else 0.3
		fxPart(
			CFrame.lookAt(fx.position, fx.position + fx.direction) * CFrame.new(0, 0, -length / 2),
			Vector3.new(width, width, length),
			if fx.kind == "flame" then FX_COLORS.flame else Color3.fromRGB(255, 255, 200),
			0.25
		)
	elseif fx.kind == "firewall" and fx.cframe and fx.size then
		fxPart(fx.cframe, fx.size, color, fx.duration or 8)
	elseif (fx.kind == "bolt" or fx.kind == "throw") and fx.position then
		local target = if typeof(fx.target) == "Instance" then (fx.target :: BasePart).Position else fx.target
		if typeof(target) == "Vector3" then
			local projectile = fxPart(
				CFrame.new(fx.position),
				Vector3.new(0.6, 0.6, 0.6),
				color,
				fx.duration or 0.5,
				Enum.PartType.Ball
			)
			local start = os.clock()
			local seconds = fx.duration or 0.5
			local from = fx.position
			local conn
			conn = RunService.RenderStepped:Connect(function()
				local t = math.clamp((os.clock() - start) / seconds, 0, 1)
				if projectile.Parent then
					projectile.Position = from:Lerp(target, t) + Vector3.new(0, math.sin(t * math.pi) * 3, 0)
				end
				if t >= 1 then
					conn:Disconnect()
				end
			end)
		end
	elseif fx.kind == "dash" and fx.position and fx.direction then
		fxPart(
			CFrame.lookAt(fx.position, fx.position + fx.direction) * CFrame.new(0, 0, -(fx.range or 10) / 2),
			Vector3.new(1, 0.2, fx.range or 10),
			color,
			0.3
		)
	elseif fx.position then
		local radius = fx.radius or 3
		local seconds = math.clamp(fx.duration or 0.4, 0.3, 1.5)
		fxPart(
			CFrame.new(fx.position),
			Vector3.new(radius * 2, radius * 2, radius * 2),
			color,
			seconds,
			Enum.PartType.Ball
		)
	end
end)

-- Skill cooldown feedback lands in the HUD; the class in play drives which weapon fires.
player:GetAttributeChangedSignal("Class"):Connect(function()
	local id = player:GetAttribute("Class")
	if type(id) == "string" and Classes.find(id) then
		lastShot = 0
	end
end)
