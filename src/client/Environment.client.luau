-- Per-zone sky and lighting. Lighting is per client, so each player sees the mood of where they are: the lobby's
-- bright day, or inside a run the dungeon's look (Environments.luau). Driven by the InRun and DungeonId attributes
-- Run.luau sets on the player; changes tween over Environments.TweenSeconds. Nothing is sent to the server.

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Environments = require(ReplicatedStorage.Shared.Environments)

local player = Players.LocalPlayer

local function rgb(c: { number }): Color3
	return Color3.fromRGB(c[1], c[2], c[3])
end

local function findOrMake<T>(parent: Instance, className: string, name: string): T
	local found = parent:FindFirstChildOfClass(className :: any)
	if found then
		return found :: any
	end
	local made = Instance.new(className :: any)
	made.Name = name
	made.Parent = parent
	return made :: any
end

-- Atmosphere/SunRays come from default.project.json and Clouds from Environment.server; give them a moment to
-- replicate, then fall back to local copies so the client always has something to drive.
Lighting:WaitForChild("Atmosphere", 5)
local terrain = workspace:WaitForChild("Terrain") :: Terrain
terrain:WaitForChild("Clouds", 5)

local atmosphere: Atmosphere = findOrMake(Lighting, "Atmosphere", "Atmosphere")
local sunRays: SunRaysEffect = findOrMake(Lighting, "SunRaysEffect", "SunRays")
local clouds: Clouds = findOrMake(terrain, "Clouds", "Clouds")
local grade = Instance.new("ColorCorrectionEffect") -- local only; the server never sees it
grade.Name = "EnvironmentGrade"
grade.Parent = Lighting

local tweens: { Tween } = {}

local function set(instance: Instance, goal: { [string]: any }, info: TweenInfo?)
	if info then
		local tween = TweenService:Create(instance, info, goal)
		table.insert(tweens, tween)
		tween:Play()
	else
		for key, value in goal do
			(instance :: any)[key] = value
		end
	end
end

local function apply(env: Environments.Environment, instant: boolean)
	for _, tween in tweens do
		tween:Cancel()
	end
	table.clear(tweens)
	local info = if instant
		then nil
		else TweenInfo.new(Environments.TweenSeconds, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)

	set(Lighting, {
		ClockTime = env.clockTime,
		Brightness = env.brightness,
		Ambient = rgb(env.ambient),
		OutdoorAmbient = rgb(env.outdoorAmbient),
		EnvironmentDiffuseScale = Environments.SkyLightDiffuse,
		EnvironmentSpecularScale = Environments.SkyLightSpecular,
	}, info)
	local a = env.atmosphere
	set(atmosphere, {
		Density = a.density,
		Offset = a.offset,
		Color = rgb(a.color),
		Decay = rgb(a.decay),
		Glare = a.glare,
		Haze = a.haze,
	}, info)
	set(clouds, {
		Cover = env.clouds.cover,
		Density = env.clouds.density,
		Color = rgb(env.clouds.color),
	}, info)
	set(sunRays, { Intensity = env.sunRays }, info)
	local g = env.grade
	set(grade, {
		Brightness = g.brightness,
		Contrast = g.contrast,
		Saturation = g.saturation,
		TintColor = rgb(g.tint),
	}, info)
end

local current: Environments.Environment? = nil
local pending = false

local function refresh()
	pending = false
	local env = Environments.forZone(player:GetAttribute("InRun"), player:GetAttribute("DungeonId"))
	if env ~= current then
		apply(env, current == nil)
		current = env
	end
end

local function schedule()
	-- InRun and DungeonId change together; settle on one refresh per frame
	if not pending then
		pending = true
		task.defer(refresh)
	end
end

player:GetAttributeChangedSignal("InRun"):Connect(schedule)
player:GetAttributeChangedSignal("DungeonId"):Connect(schedule)
refresh()
