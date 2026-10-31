-- Skill effects: draws every class skill for every player who sees it, from the server's SkillFx broadcasts (tagged
-- with the skill id and caster; the look per skill is shared SkillVisuals `fx`, a rough Roblox take on the showcase's
-- skillFx). Visual only: the server already applied the skill. Everything here is anchored, non-colliding, unqueryable
-- and short-lived (one RenderStepped connection per animated piece, Debris as a backstop), parented to a local
-- Workspace folder.

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local ModelIds = require(ReplicatedStorage.Shared.ModelIds) :: { [string]: number }
local SharedSkills = require(ReplicatedStorage.Shared.Skills)
local SkillVisuals = require(ReplicatedStorage.Shared.SkillVisuals)

local skillFx = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("SkillFx") :: RemoteEvent

local folder = Instance.new("Folder")
folder.Name = "SkillEffects"
folder.Parent = Workspace

local rgb = Color3.fromRGB
local NEON = Enum.Material.Neon
local BALL = Enum.PartType.Ball

-- Building blocks -------------------------------------------------------------------------------------------------

local function part(size: Vector3, cframe: CFrame, color: Color3, transparency: number?, material: Enum.Material?): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Material = material or NEON
	p.Color = color
	p.Transparency = transparency or 0
	p.Size = size
	p.CFrame = cframe
	p.Parent = folder
	Debris:AddItem(p, 15) -- backstop; every effect destroys its own parts sooner
	return p
end

local function ball(
	size: number,
	position: Vector3,
	color: Color3,
	transparency: number?,
	material: Enum.Material?
): Part
	local p = part(Vector3.one * size, CFrame.new(position), color, transparency, material)
	p.Shape = BALL
	return p
end

-- Calls step(k, dt) every frame for `seconds` (k runs 0..1), then done(). An erroring step ends the effect.
local function animate(seconds: number, step: (number, number) -> (), done: (() -> ())?)
	local start = os.clock()
	local conn: RBXScriptConnection
	conn = RunService.RenderStepped:Connect(function(dt)
		local k = math.min(1, (os.clock() - start) / math.max(seconds, 1e-3))
		local ok = pcall(step, k, dt)
		if k >= 1 or not ok then
			conn:Disconnect()
			if done then
				done()
			end
		end
	end)
end

local function later(seconds: number, fn: () -> ())
	if seconds > 0 then
		task.delay(seconds, fn)
	else
		fn()
	end
end

local function destroyAll(list: { Instance })
	for _, inst in list do
		inst:Destroy()
	end
end

local function playSound(key: string, at: Instance?, volume: number)
	local id = ModelIds[key]
	if not id or not at then
		return
	end
	local sound = Instance.new("Sound")
	sound.SoundId = `rbxassetid://{id}`
	sound.Volume = volume
	sound.RollOffMaxDistance = 80
	sound.Parent = at
	sound:Play()
	Debris:AddItem(sound, 3)
end

local function rayParams(extra: Instance?): RaycastParams
	local ignore: { Instance } = { folder }
	for _, p in Players:GetPlayers() do
		if p.Character then
			table.insert(ignore, p.Character)
		end
	end
	if extra then
		table.insert(ignore, extra)
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = ignore
	return params
end

-- The floor under a point (players and effects ignored); rays start inside a part miss it, so a Town Hall centre works.
local function floorBelow(position: Vector3): Vector3
	local hit = Workspace:Raycast(position + Vector3.new(0, 1, 0), Vector3.new(0, -40, 0), rayParams())
	return if hit then hit.Position + Vector3.new(0, 0.08, 0) else position - Vector3.new(0, 3, 0)
end

-- Where a shot from `from` along `direction` stops (world only: players and effects ignored).
local function shotEnd(from: Vector3, direction: Vector3, range: number): Vector3
	local hit = Workspace:Raycast(from, direction.Unit * range, rayParams())
	return if hit then hit.Position else from + direction.Unit * range
end

-- Expanding ring of neon segments on the ground (or any horizontal plane through `center`).
local SEGMENTS = 20
local function ring(center: Vector3, color: Color3, radius: number, seconds: number, delay: number?)
	later(delay or 0, function()
		local segs = {}
		for i = 1, SEGMENTS do
			segs[i] = part(Vector3.new(0.35, 0.15, 1), CFrame.new(center), color, 0.15)
		end
		animate(seconds, function(k)
			local r = 0.6 + (radius - 0.6) * math.sqrt(k)
			local len = 2 * math.pi * r / SEGMENTS * 1.08
			for i, s in segs do
				s.Size = Vector3.new(0.35, 0.15, len)
				s.CFrame = CFrame.new(center) * CFrame.Angles(0, i / SEGMENTS * 2 * math.pi, 0) * CFrame.new(r, 0, 0)
				s.Transparency = 0.15 + 0.85 * k
			end
		end, function()
			destroyAll(segs)
		end)
	end)
end

type SparkOpts = { size: number?, rise: number?, lifetime: number?, delay: number? }
local function sparks(position: Vector3, color: Color3, count: number, speed: number, opts: SparkOpts?)
	local o: SparkOpts = opts or {}
	later(o.delay or 0, function()
		local holder = part(Vector3.one * 0.2, CFrame.new(position), color, 1)
		local e = Instance.new("ParticleEmitter")
		e.Rate = 0
		e.Color = ColorSequence.new(color)
		e.LightEmission = 1
		e.Size = NumberSequence.new(o.size or 0.3, 0)
		e.Lifetime = NumberRange.new((o.lifetime or 0.6) * 0.5, o.lifetime or 0.6)
		e.Speed = NumberRange.new(speed * 0.4, speed)
		e.SpreadAngle = Vector2.new(180, 180)
		e.Acceleration = Vector3.new(0, o.rise or -25, 0)
		e.Drag = 2
		e.Parent = holder
		e:Emit(count)
		Debris:AddItem(holder, (o.lifetime or 0.6) + 0.5)
	end)
end

-- Text that floats up and fades ("+150 HP").
local function floatText(position: Vector3, text: string, color: Color3, delay: number?)
	later(delay or 0, function()
		local anchor = part(Vector3.one * 0.2, CFrame.new(position), color, 1)
		local gui = Instance.new("BillboardGui")
		gui.Size = UDim2.fromOffset(220, 46)
		gui.AlwaysOnTop = true
		gui.LightInfluence = 0
		gui.MaxDistance = 200
		gui.Adornee = anchor
		local label = Instance.new("TextLabel")
		label.BackgroundTransparency = 1
		label.Size = UDim2.fromScale(1, 1)
		label.Font = Enum.Font.GothamBlack
		label.TextScaled = true
		label.Text = text
		label.TextColor3 = color
		label.TextStrokeColor3 = Color3.new(0, 0, 0)
		label.TextStrokeTransparency = 0.3
		label.Parent = gui
		gui.Parent = anchor
		animate(1.4, function(k)
			anchor.CFrame = CFrame.new(position + Vector3.new(0, k * 3, 0))
			label.TextTransparency = k * k
			label.TextStrokeTransparency = 0.3 + 0.7 * k * k
		end, function()
			anchor:Destroy()
		end)
	end)
end

local function flash(position: Vector3, color: Color3, size: number)
	local f = ball(size, position, color, 0.1)
	local light = Instance.new("PointLight")
	light.Color = color
	light.Brightness = 6
	light.Range = size * 8
	light.Parent = f
	task.delay(0.07, f.Destroy, f)
end

-- A glowing column of rising particles and a light around a character for `seconds`, with a brief bubble.
local function aura(root: BasePart?, color: Color3, seconds: number)
	if not root then
		return
	end
	local holder = part(Vector3.new(3, 5, 3), root.CFrame, color, 1)
	local e = Instance.new("ParticleEmitter")
	e.Rate = 35
	e.Color = ColorSequence.new(color)
	e.LightEmission = 1
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0) })
	e.Transparency = NumberSequence.new(0.2, 1)
	e.Lifetime = NumberRange.new(0.6, 1.1)
	e.Speed = NumberRange.new(2, 5)
	e.EmissionDirection = Enum.NormalId.Top
	e.Acceleration = Vector3.new(0, 4, 0)
	e.Parent = holder
	local light = Instance.new("PointLight")
	light.Color = color
	light.Brightness = 2
	light.Range = 10
	light.Parent = holder
	local bubble = ball(6, root.Position, color, 0.4, Enum.Material.ForceField)
	animate(seconds, function(k)
		holder.CFrame = root.CFrame
		local b = math.min(1, k * seconds / 0.8) -- the bubble lasts the first 0.8 s
		if bubble.Parent then
			bubble.CFrame = root.CFrame
			bubble.Size = Vector3.one * (6 + 2 * b)
			bubble.Transparency = 0.4 + 0.6 * b
			if b >= 1 then
				bubble:Destroy()
			end
		end
	end, function()
		bubble:Destroy()
		e.Enabled = false
		light:Destroy()
		Debris:AddItem(holder, 1.2)
	end)
end

-- A glowing ball with a trail flying from `from` to wherever getTo() says (homing), arcing up `arc` studs.
local function projectile(
	from: Vector3,
	getTo: () -> Vector3,
	seconds: number,
	color: Color3,
	size: number,
	arc: number,
	onHit: ((Vector3) -> ())?
)
	local p = ball(size, from, color, 0)
	local a0 = Instance.new("Attachment")
	a0.Position = Vector3.new(0, size * 0.35, 0)
	a0.Parent = p
	local a1 = Instance.new("Attachment")
	a1.Position = Vector3.new(0, -size * 0.35, 0)
	a1.Parent = p
	local trail = Instance.new("Trail")
	trail.Attachment0 = a0
	trail.Attachment1 = a1
	trail.Color = ColorSequence.new(color)
	trail.LightEmission = 1
	trail.Lifetime = 0.25
	trail.Transparency = NumberSequence.new(0.2, 1)
	trail.Parent = p
	animate(seconds, function(k)
		p.CFrame = CFrame.new(from:Lerp(getTo(), k) + Vector3.new(0, math.sin(k * math.pi) * arc, 0))
			* CFrame.Angles(k * 9, k * 5, 0)
	end, function()
		local at = p.Position
		p:Destroy()
		if onHit then
			onHit(at)
		end
	end)
end

-- A straight glowing bar that fades (and fattens by `grow`).
local function beam(from: Vector3, to: Vector3, color: Color3, width: number, seconds: number, grow: number?)
	local len = (to - from).Magnitude
	if len < 0.1 then
		return
	end
	local b = part(Vector3.new(width, width, len), CFrame.lookAt(from, to) * CFrame.new(0, 0, -len / 2), color, 0)
	animate(seconds, function(k)
		local w = width * (1 + k * (grow or 0))
		b.Size = Vector3.new(w, w, len)
		b.Transparency = k
	end, function()
		b:Destroy()
	end)
end

-- Explosion: a fireball that swells and fades, a light, sparks, smoke and a ground ring.
local function boom(position: Vector3, radius: number)
	local f = ball(1, position, rgb(255, 220, 120), 0.05)
	local light = Instance.new("PointLight")
	light.Color = rgb(255, 150, 60)
	light.Brightness = 6
	light.Range = radius * 3
	light.Parent = f
	animate(0.45, function(k)
		f.Size = Vector3.one * (1 + radius * 1.5 * math.sqrt(k))
		f.Transparency = 0.05 + 0.95 * k
		f.Color = rgb(255, 220, 120):Lerp(rgb(170, 40, 10), k)
	end, function()
		f:Destroy()
	end)
	sparks(position, rgb(255, 170, 60), 22, radius * 4, { size = 0.4 })
	local smoke = part(Vector3.one * 0.2, CFrame.new(position), Color3.new(), 1)
	local e = Instance.new("ParticleEmitter")
	e.Rate = 0
	e.Color = ColorSequence.new(rgb(70, 65, 60))
	e.Size = NumberSequence.new(radius * 0.4, radius * 0.9)
	e.Transparency = NumberSequence.new(0.3, 1)
	e.Lifetime = NumberRange.new(0.8, 1.4)
	e.Speed = NumberRange.new(2, 5)
	e.SpreadAngle = Vector2.new(180, 180)
	e.Acceleration = Vector3.new(0, 3, 0)
	e.Parent = smoke
	e:Emit(8)
	Debris:AddItem(smoke, 1.8)
	ring(floorBelow(position), rgb(255, 160, 60), radius, 0.45)
	playSound("Sound_MeleeHit", smoke, 0.6)
end

-- Caster helpers ------------------------------------------------------------------------------------------------

type Caster = { char: Model?, root: BasePart?, muzzle: Attachment? }

local function casterOf(fx: { [string]: any }): Caster
	local who = fx.caster
	local char = if typeof(who) == "Instance" and who:IsA("Player") then who.Character else nil
	local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local muzzle = nil
	local tool = char and char:FindFirstChildOfClass("Tool")
	if tool then
		local m = tool:FindFirstChild("Muzzle", true)
		muzzle = if m and m:IsA("Attachment") then m else nil
	end
	return { char = char, root = root, muzzle = muzzle }
end

local function hand(c: Caster, side: string): Vector3?
	local h = c.char and c.char:FindFirstChild(side .. "Hand")
	if h and h:IsA("BasePart") then
		return h.Position
	end
	return if c.root then c.root.Position else nil
end

local function muzzleAt(c: Caster, fallback: Vector3?): Vector3?
	if c.muzzle and c.muzzle.Parent then
		return c.muzzle.WorldPosition
	end
	return hand(c, "Right") or fallback
end

local function vec(v: any): Vector3?
	return if typeof(v) == "Vector3" and v == v then v else nil
end

local function num(v: any, default: number): number
	return if type(v) == "number" and v == v then v else default
end

local function partOf(v: any): BasePart?
	return if typeof(v) == "Instance" and v:IsA("BasePart") and v:IsDescendantOf(Workspace) then v else nil
end

-- The model a creature part belongs to (for a Highlight), or the part itself.
local function bodyOf(p: BasePart): Instance
	local parent = p.Parent
	return if parent and parent:IsA("Model") and parent ~= Workspace then parent else p
end

local function highlight(adornee: Instance, color: Color3, seconds: number, fill: number?)
	local h = Instance.new("Highlight")
	h.Adornee = adornee
	h.FillColor = color
	h.FillTransparency = fill or 0.7
	h.OutlineColor = color
	h.OutlineTransparency = 0
	h.DepthMode = Enum.HighlightDepthMode.Occluded
	h.Parent = folder
	Debris:AddItem(h, seconds)
end

-- Effects, one per SkillVisuals fx name ---------------------------------------------------------------------------

type Fx = { [string]: any }
local FX: { [string]: (Fx, Caster) -> () } = {}

local GOLD = rgb(255, 210, 63)

-- Trooper Burst Fire: three tracers from the muzzle in step with the three kicks.
FX.burst = function(fx, c)
	local dir = vec(fx.direction) or (c.root and c.root.CFrame.LookVector)
	if not dir then
		return
	end
	for n, t in { 0.08, 0.28, 0.48 } do
		task.delay(t, function()
			local from = muzzleAt(c, vec(fx.position))
			if not from then
				return
			end
			local spread = Vector3.new(math.random() - 0.5, math.random() - 0.5, math.random() - 0.5) * 0.03
			local to = shotEnd(from, dir + spread, 120)
			flash(from, rgb(255, 224, 138), 0.6)
			beam(from, to, rgb(255, 224, 138), 0.14, 0.08)
			sparks(to, rgb(255, 210, 122), 6 + n, 20, { size = 0.2, lifetime = 0.3 })
		end)
	end
end

-- Trooper Ammo Crate: a crate lobbed from the off hand lands with a ring, sparks and "AMMO +20%".
FX.crate = function(fx, c)
	local to = vec(fx.position)
	local from = hand(c, "Left") or (to and to + Vector3.new(0, 4, 0))
	if not to or not from then
		return
	end
	local crate = part(Vector3.new(2.2, 1.6, 1.6), CFrame.new(from), rgb(91, 107, 58), 0, Enum.Material.WoodPlanks)
	local lid = part(Vector3.new(2.3, 0.3, 1.7), CFrame.new(from), GOLD, 0, Enum.Material.Metal)
	local rest = to + Vector3.new(0, 0.8, 0)
	local landed = false
	animate(4.5, function(k)
		local q = math.min(1, k * 4.5 / 0.55)
		local cf = CFrame.new(from:Lerp(rest, q) + Vector3.new(0, 5 * 4 * q * (1 - q), 0))
			* CFrame.Angles((1 - q) * 4, 0, 0)
		local s = if k > 0.85 then math.max(0.05, (1 - k) / 0.15) else 1
		crate.Size = Vector3.new(2.2, 1.6, 1.6) * s
		lid.Size = Vector3.new(2.3, 0.3, 1.7) * s
		crate.CFrame = cf
		lid.CFrame = cf * CFrame.new(0, 0.9 * s, 0)
		if q >= 1 and not landed then
			landed = true
			ring(to, rgb(255, 230, 102), math.max(6, num(fx.radius, 3) * 2), 0.7)
			sparks(rest, rgb(255, 230, 102), 12, 14, { size = 0.25 })
			floatText(to + Vector3.new(0, 4, 0), "AMMO +20%", rgb(255, 230, 102))
			playSound("Sound_MeleeHit", crate, 0.5)
		end
	end, function()
		crate:Destroy()
		lid:Destroy()
	end)
end

-- Tank Flail Sweep: a pale arc spins round the Tank at waist height, then a ground ring and dust.
FX.sweep = function(fx, c)
	local root = c.root
	if not root then
		return
	end
	local radius = num(fx.radius, 6)
	local n = 14
	local segs = {}
	for i = 1, n do
		segs[i] = part(Vector3.new(0.3, 0.3, 1), root.CFrame, rgb(216, 216, 255), 0.2)
	end
	animate(0.9, function(k)
		local r = radius * 0.7
		local len = 2 * math.pi * r * 0.7 / n * 1.1
		for i, s in segs do
			local a = -k * 14 + i / n * math.pi * 1.4
			s.Size = Vector3.new(0.3, 0.3, len)
			s.CFrame = CFrame.new(root.Position) * CFrame.Angles(0, a, 0) * CFrame.new(r, 0, 0)
			s.Transparency = 0.2 + 0.8 * k
		end
	end, function()
		destroyAll(segs)
	end)
	local floor = floorBelow(root.Position)
	ring(floor, rgb(207, 207, 255), radius, 0.7, 0.3)
	sparks(floor + Vector3.new(0, 0.5, 0), rgb(181, 154, 106), 20, 16, { size = 0.4, rise = -10, delay = 0.3 })
	playSound("Sound_Whoosh", root, 0.8)
end

-- Tank Iron Wall: a blue dome over the Tank for the whole duration, a ring and "TAUNT".
FX.shield = function(fx, c)
	local root = c.root
	if not root then
		return
	end
	local seconds = num(fx.duration, 8)
	local dome = ball(8, root.Position, rgb(90, 168, 255), 0.5, Enum.Material.ForceField)
	animate(seconds, function(k)
		dome.CFrame = root.CFrame
		local fade = math.min(1, k * seconds / 0.3, (1 - k) * seconds / 0.6)
		dome.Transparency = 1 - 0.55 * fade * (0.85 + 0.15 * math.sin(os.clock() * 8))
	end, function()
		dome:Destroy()
	end)
	ring(floorBelow(root.Position), rgb(90, 168, 255), num(fx.radius, 8), 0.6)
	floatText(root.Position + Vector3.new(0, 4, 0), "TAUNT", rgb(126, 192, 255))
end

-- Scout Dash: white speed streaks trailing the Scout.
FX.dash = function(fx, c)
	local root = c.root
	local dir = vec(fx.direction) or (root and root.CFrame.LookVector)
	if not root or not dir then
		return
	end
	local streaks = {}
	for i = 1, 6 do
		local offset = Vector3.new((math.random() - 0.5) * 3, (math.random() - 0.3) * 4, (math.random() - 0.5) * 3)
		streaks[i] = { p = part(Vector3.new(0.12, 0.12, 5), root.CFrame, Color3.new(1, 1, 1), 0.3), offset = offset }
	end
	animate(0.45, function(k)
		for i, s in streaks do
			local back = 2 + k * 4 + i * 0.3
			local at = root.Position + s.offset - dir * back
			s.p.CFrame = CFrame.lookAt(at, at + dir)
			s.p.Transparency = 0.3 + 0.7 * k
		end
	end, function()
		for _, s in streaks do
			s.p:Destroy()
		end
	end)
	playSound("Sound_Whoosh", root, 0.7)
end

-- Scout Mark Target: a red shot at the creature, then a spinning red marker over it and a red outline while marked.
FX.mark = function(fx, c)
	local target = partOf(fx.target)
	if not target then
		return
	end
	local seconds = num(fx.duration, 8)
	task.delay(0.2, function()
		local from = muzzleAt(c, vec(fx.position))
		if from and target.Parent then
			flash(from, rgb(255, 96, 96), 0.8)
			beam(from, target.Position, rgb(255, 80, 80), 0.15, 0.2)
			ring(floorBelow(target.Position), rgb(255, 68, 68), 3, 0.6)
			floatText(target.Position + Vector3.new(0, 3, 0), "+30%", rgb(255, 107, 107))
		end
	end)
	highlight(bodyOf(target), rgb(255, 60, 60), seconds, 0.8)
	local top = target.Size.Y / 2 + 2
	local marker = part(Vector3.one * 0.9, target.CFrame, rgb(255, 60, 60), 0.1)
	animate(seconds, function(k)
		if not target.Parent then
			marker.Transparency = 1
			return
		end
		marker.CFrame = CFrame.new(target.Position + Vector3.new(0, top + math.sin(os.clock() * 4) * 0.2, 0))
			* CFrame.Angles(0, os.clock() * 3, 0)
			* CFrame.Angles(math.rad(45), 0, math.rad(45))
		marker.Transparency = if k > 0.9 then (k - 0.9) * 10 else 0.1
	end, function()
		marker:Destroy()
	end)
end

-- Medic Repair Pulse: a green spark flies to the Town Hall, green rings spread round it and "+150 HP" rises.
FX.repair = function(fx, c)
	local hall = vec(fx.position)
	if not hall then
		return
	end
	local floor = floorBelow(hall)
	local radius = num(fx.radius, 8)
	local from = hand(c, "Right")
	if from then
		sparks(from, rgb(125, 255, 160), 14, 6, { size = 0.25, rise = 8 })
		projectile(from, function()
			return hall
		end, 0.35, rgb(92, 255, 138), 0.6, 2)
	end
	ring(floor, rgb(92, 255, 138), radius * 1.3, 1.0, 0.3)
	ring(floor, rgb(92, 255, 138), radius * 0.9, 1.0, 0.45)
	floatText(
		hall + Vector3.new(0, radius * 0.6 + 2, 0),
		`+{math.floor(num(fx.amount, 150))} HP`,
		rgb(92, 255, 138),
		0.4
	)
end

-- Medic Overcharge: a gold aura on the Medic and a gold shell over the Town Hall while it cannot be hurt.
FX.overcharge = function(fx, c)
	local seconds = num(fx.duration, 6)
	aura(c.root, GOLD, math.min(seconds, 3))
	local hall = vec(fx.position)
	if not hall then
		return
	end
	local size = num(fx.radius, 8) * 1.6
	local shell = ball(size, hall, GOLD, 1, Enum.Material.ForceField)
	animate(seconds, function(k)
		local fade = math.min(1, k * seconds / 0.4, (1 - k) * seconds / 0.6)
		shell.Transparency = 1 - 0.6 * fade * (0.8 + 0.2 * math.sin(os.clock() * 6))
	end, function()
		shell:Destroy()
	end)
	ring(floorBelow(hall), GOLD, size * 0.7, 0.8)
	floatText(hall + Vector3.new(0, size * 0.5 + 1, 0), "INVULNERABLE", GOLD)
end

-- Engineer Place Turret: the turret pops in with a flash box, a ring and grey sparks.
FX.turret = function(fx, _c)
	local at = vec(fx.position)
	if not at then
		return
	end
	local box = part(Vector3.one * 0.2, CFrame.new(at + Vector3.new(0, 1.3, 0)), rgb(159, 211, 255), 0.2)
	animate(0.4, function(k)
		local s = 3 * math.sin(k * math.pi * 0.5) * (1 + 0.15 * math.sin(k * 12))
		box.Size = Vector3.one * math.max(0.2, s)
		box.Transparency = 0.2 + 0.8 * k
	end, function()
		box:Destroy()
	end)
	ring(at, rgb(159, 211, 255), 4, 0.6, 0.2)
	sparks(at + Vector3.new(0, 0.5, 0), rgb(191, 191, 191), 14, 14, { size = 0.25, delay = 0.2 })
	local model = fx.target
	if typeof(model) == "Instance" and model:IsA("Model") then
		highlight(model, Color3.new(1, 1, 1), 0.4, 0.3)
	end
end

-- Engineer Overclock: a cyan aura on the Engineer and a cyan glow on every turret while it fires twice as fast.
FX.overclock = function(fx, c)
	local seconds = num(fx.duration, 10)
	aura(c.root, rgb(111, 211, 255), 1.6)
	if type(fx.turrets) ~= "table" then
		return
	end
	for _, model in fx.turrets do
		if typeof(model) == "Instance" and model:IsA("Model") and model.Parent then
			highlight(model, rgb(111, 211, 255), seconds, 0.6)
			local top = model:GetPivot().Position + Vector3.new(0, 3, 0)
			floatText(top, "x2 FIRE RATE", rgb(111, 211, 255))
			sparks(top, rgb(111, 211, 255), 10, 8, { size = 0.2 })
		end
	end
end

-- Berserker Cleave: a white arc cuts left to right in front of the Berserker, with red sparks where it lands.
FX.cleave = function(fx, c)
	local root = c.root
	if not root then
		return
	end
	local dir = vec(fx.direction) or root.CFrame.LookVector
	local flat = Vector3.new(dir.X, 0, dir.Z)
	flat = if flat.Magnitude > 0.1 then flat.Unit else root.CFrame.LookVector
	local center = CFrame.lookAt(root.Position, root.Position + flat) * CFrame.new(0, 0.5, 0)
	local radius = num(fx.range, 8) * 0.65
	local n = 14
	local spanDeg = math.min(170, num(fx.halfAngle, 70) * 2)
	local segs = {}
	for i = 1, n do
		segs[i] = part(Vector3.new(0.35, 0.12, 1), center, Color3.new(1, 1, 1), 1)
	end
	animate(0.4, function(k)
		local len = 2 * math.pi * radius * (spanDeg / 360) / n * 1.15
		for i, s in segs do
			local f = i / n -- 0 = the left end (the wind-up side), 1 = the right end
			local a = math.rad(spanDeg / 2 - spanDeg * f)
			local shown = k * 1.6 - f
			s.Size = Vector3.new(0.35, 0.12 + 0.2 * (1 - f), len)
			s.CFrame = center * CFrame.Angles(0, a, 0) * CFrame.new(0, 0, -radius) * CFrame.Angles(0, math.pi / 2, 0)
			s.Transparency = if shown < 0 then 1 else math.clamp(0.1 + shown * 1.2, 0.1, 1)
		end
	end, function()
		destroyAll(segs)
	end)
	for i = -1, 1 do
		local at = (center * CFrame.new(i * radius * 0.5, 0, -radius)).Position
		sparks(at, rgb(255, 90, 90), 6, 14, { size = 0.3, delay = 0.2 })
	end
	playSound("Sound_Whoosh", root, 0.9)
end

-- Berserker Rage: a red aura, a spray of red sparks and "RAGE".
FX.rage = function(fx, c)
	local root = c.root
	if not root then
		return
	end
	aura(root, rgb(255, 59, 48), math.min(num(fx.duration, 10), 4))
	sparks(root.Position + Vector3.new(0, 2, 0), rgb(255, 107, 74), 24, 18, { size = 0.35, delay = 0.2 })
	floatText(root.Position + Vector3.new(0, 4, 0), "RAGE", rgb(255, 75, 58))
end

-- Mage Arcane Bolt: a violet homing orb from the staff to the creature, a violet burst and the damage number.
FX.arcane = function(fx, c)
	local target = partOf(fx.target)
	local from = muzzleAt(c, vec(fx.position))
	if not target or not from then
		return
	end
	flash(from, rgb(176, 107, 255), 1)
	local last = target.Position
	projectile(
		from,
		function()
			if target.Parent then
				last = target.Position
			end
			return last
		end,
		math.max(0.3, num(fx.duration, 0.3)),
		rgb(176, 107, 255),
		0.9,
		2,
		function(at)
			sparks(at, rgb(201, 139, 255), 16, 16, { size = 0.3 })
			floatText(at + Vector3.new(0, 2, 0), tostring(SharedSkills.Effects.ArcaneBolt.damage), rgb(214, 168, 255))
		end
	)
end

-- Mage Frost Nova: icy rings race out across the freeze radius and a circle of ice shards pushes up.
FX.nova = function(fx, c)
	local center = vec(fx.position) or (c.root and c.root.Position)
	if not center then
		return
	end
	local floor = floorBelow(center)
	local radius = num(fx.radius, 15)
	ring(floor, rgb(158, 232, 255), radius, 0.8)
	ring(floor, Color3.new(1, 1, 1), radius * 0.7, 0.7, 0.1)
	local seconds = math.min(num(fx.duration, 3), 3)
	local shards = {}
	for i = 1, 12 do
		local a = i / 12 * math.pi * 2
		local at = floor + Vector3.new(math.cos(a), 0, math.sin(a)) * radius * 0.4
		local tilt = CFrame.Angles(0, -a, 0) * CFrame.Angles(0, 0, math.rad(-20)) * CFrame.Angles(0, math.rad(45), 0)
		shards[i] = {
			p = part(Vector3.new(0.7, 2.6, 0.7), CFrame.new(at), rgb(191, 239, 255), 0.25, Enum.Material.Glass),
			at = at,
			tilt = tilt,
		}
	end
	animate(seconds, function(k)
		local up = math.min(1, k * seconds / 0.25)
		for _, s in shards do
			s.p.CFrame = CFrame.new(s.at + Vector3.new(0, -1.3 + 1.3 * up, 0)) * s.tilt
			s.p.Transparency = if k > 0.75 then 0.25 + 0.75 * (k - 0.75) * 4 else 0.25
		end
	end, function()
		for _, s in shards do
			s.p:Destroy()
		end
	end)
	sparks(floor + Vector3.new(0, 0.5, 0), rgb(223, 247, 255), 24, radius, { size = 0.3, rise = -5 })
end

-- Pyro Flame Sweep: a stream of fire from the nozzle that follows the sweep for 1.4 s.
FX.flames = function(fx, c)
	local root = c.root
	local dir = vec(fx.direction) or (root and root.CFrame.LookVector)
	if not root or not dir then
		return
	end
	local nozzle = part(Vector3.one * 0.3, root.CFrame, rgb(255, 120, 30), 1)
	local e = Instance.new("ParticleEmitter")
	e.Rate = 90
	e.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, rgb(255, 230, 120)),
		ColorSequenceKeypoint.new(0.4, rgb(255, 106, 0)),
		ColorSequenceKeypoint.new(1, rgb(120, 25, 0)),
	})
	e.LightEmission = 0.9
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 3.2) })
	e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 1) })
	e.Lifetime = NumberRange.new(0.45, 0.6)
	e.Speed = NumberRange.new(num(fx.range, 20) * 1.6, num(fx.range, 20) * 2)
	e.Drag = 2.5
	e.SpreadAngle = Vector2.new(10, 10)
	e.EmissionDirection = Enum.NormalId.Front
	e.Acceleration = Vector3.new(0, 4, 0)
	e.Parent = nozzle
	local light = Instance.new("PointLight")
	light.Color = rgb(255, 140, 40)
	light.Brightness = 3
	light.Range = 14
	light.Parent = nozzle
	animate(1.4, function()
		if c.muzzle and c.muzzle.Parent then
			nozzle.CFrame = c.muzzle.WorldCFrame
		else
			nozzle.CFrame = CFrame.lookAt(root.Position, root.Position + root.CFrame.LookVector)
		end
	end, function()
		e.Enabled = false
		light:Destroy()
		Debris:AddItem(nozzle, 0.8)
	end)
end

-- Pyro Fire Wall: a row of flames along the server's wall box for its whole duration.
FX.firewall = function(fx, _c)
	local cframe = fx.cframe
	local size = vec(fx.size)
	if typeof(cframe) ~= "CFrame" or not size then
		return
	end
	local seconds = num(fx.duration, 8)
	local glow = part(Vector3.new(size.X, 0.15, size.Z), cframe * CFrame.new(0, 0.1, 0), rgb(255, 90, 0), 0.55)
	local body = part(Vector3.new(size.X, 1, size.Z), cframe * CFrame.new(0, 0.6, 0), rgb(255, 90, 0), 1)
	local flames = Instance.new("ParticleEmitter")
	flames.Rate = 110
	flames.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, rgb(255, 194, 58)),
		ColorSequenceKeypoint.new(0.5, rgb(255, 90, 0)),
		ColorSequenceKeypoint.new(1, rgb(110, 20, 0)),
	})
	flames.LightEmission = 0.8
	flames.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.6), NumberSequenceKeypoint.new(1, 0.3) })
	flames.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.15), NumberSequenceKeypoint.new(1, 1) })
	flames.Lifetime = NumberRange.new(0.5, 0.9)
	flames.Speed = NumberRange.new(4, 8)
	flames.SpreadAngle = Vector2.new(8, 8)
	flames.EmissionDirection = Enum.NormalId.Top
	flames.Acceleration = Vector3.new(0, 5, 0)
	flames.Parent = body
	local embers = flames:Clone()
	embers.Rate = 14
	embers.Size = NumberSequence.new(0.15, 0)
	embers.Lifetime = NumberRange.new(1, 1.6)
	embers.Speed = NumberRange.new(6, 10)
	embers.SpreadAngle = Vector2.new(30, 30)
	embers.Parent = body
	for _, x in { -0.3, 0.3 } do
		local a = Instance.new("Attachment")
		a.Position = Vector3.new(size.X * x, 1.5, 0)
		a.Parent = body
		local light = Instance.new("PointLight")
		light.Color = rgb(255, 120, 30)
		light.Brightness = 2
		light.Range = 14
		light.Parent = a
	end
	animate(seconds, function(k)
		glow.Transparency = 0.55 + 0.1 * math.sin(os.clock() * 10) + (if k > 0.9 then (k - 0.9) * 4.5 else 0)
	end, function()
		glow:Destroy()
		flames.Enabled = false
		embers.Enabled = false
		Debris:AddItem(body, 1.6)
	end)
end

-- Sniper Piercing Shot: a heavy flash and a bright beam down the line, sparks on each creature it went through.
FX.pierce = function(fx, c)
	local dir = vec(fx.direction)
	local from = muzzleAt(c, vec(fx.position))
	if not dir or not from then
		return
	end
	flash(from, rgb(255, 242, 176), 1.4)
	beam(from, from + dir.Unit * num(fx.range, 120), rgb(255, 242, 176), 0.25, 0.35, 3)
	if type(fx.hits) == "table" then
		for i, at in fx.hits do
			if typeof(at) == "Vector3" then
				sparks(at, rgb(255, 210, 122), 8, 16, { size = 0.3, delay = 0.04 + i * 0.03 })
			end
		end
	end
	if c.root then
		playSound("Sound_MeleeHit", c.root, 0.7)
	end
end

-- Sniper Overwatch: a red laser sight from the muzzle to whatever it points at, with a dot, while crits are up.
FX.laser = function(fx, c)
	local seconds = math.min(num(fx.duration, 10), 10)
	if c.root then
		floatText(c.root.Position + Vector3.new(0, 4, 0), "CRIT x5", rgb(255, 80, 80))
	end
	local muzzle = c.muzzle
	if not muzzle then
		return
	end
	local endAtt = Instance.new("Attachment")
	endAtt.Parent = Workspace.Terrain
	local laser = Instance.new("Beam")
	laser.Attachment0 = muzzle
	laser.Attachment1 = endAtt
	laser.Color = ColorSequence.new(rgb(255, 32, 32))
	laser.LightEmission = 1
	laser.Width0 = 0.08
	laser.Width1 = 0.08
	laser.FaceCamera = true
	laser.Transparency = NumberSequence.new(0.1, 0.4)
	laser.Parent = endAtt
	local dot = ball(0.35, muzzle.WorldPosition, rgb(255, 32, 32), 0)
	animate(seconds, function()
		if not muzzle.Parent then
			laser.Enabled = false
			dot.Transparency = 1
			return
		end
		local from = muzzle.WorldPosition
		local to = shotEnd(from, muzzle.WorldCFrame.LookVector, 200)
		endAtt.WorldPosition = to
		dot.CFrame = CFrame.new(to)
	end, function()
		endAtt:Destroy()
		dot:Destroy()
	end)
end

-- Demolisher Frag Toss: a grenade arcs from the off hand to the aim point ("throw"), then explodes ("blast").
FX.grenade = function(fx, c)
	if fx.kind == "blast" then
		local at = vec(fx.position)
		if at then
			boom(at, num(fx.radius, 8))
		end
		return
	end
	local to = vec(fx.target)
	local from = hand(c, "Left") or vec(fx.position)
	if not to or not from then
		return
	end
	projectile(from, function()
		return to
	end, num(fx.duration, 0.8), rgb(107, 142, 58), 0.8, 3 + (to - from).Magnitude * 0.15)
end

-- Demolisher Cluster Bomb: a shell bursts overhead into bomblets that rain on the impact points, each a small blast.
FX.cluster = function(fx, c)
	if fx.kind == "blast" then
		local at = vec(fx.position)
		if at then
			boom(at, num(fx.radius, 5))
		end
		return
	end
	local from = muzzleAt(c, vec(fx.position))
	if not from or type(fx.points) ~= "table" or #fx.points == 0 then
		return
	end
	local points = {}
	local sum = Vector3.zero
	for _, p in fx.points do
		if typeof(p) == "Vector3" then
			table.insert(points, p)
			sum += p
		end
	end
	if #points == 0 then
		return
	end
	local mid = from:Lerp(sum / #points, 0.4) + Vector3.new(0, 8, 0)
	local orange = rgb(255, 176, 96)
	local shellTime = 0.4
	local total = num(fx.duration, 1)
	flash(from, orange, 1.2)
	projectile(
		from,
		function()
			return mid
		end,
		shellTime,
		orange,
		0.9,
		2,
		function(at)
			flash(at, orange, 2)
			for n, p in points do
				local arrive = math.max(0.15, total + (n - 1) * 0.15 - shellTime)
				projectile(at, function()
					return p
				end, arrive, orange, 0.45, 2)
			end
		end
	)
end

-- Dispatch -------------------------------------------------------------------------------------------------------

-- Fail loudly in Studio if a SkillVisuals effect has no drawer here.
for _, name in SkillVisuals.Effects do
	if not FX[name] then
		warn(`SkillEffects: no effect for {name}`)
	end
end

skillFx.OnClientEvent:Connect(function(fx)
	if type(fx) ~= "table" then
		return
	end
	local visual = SkillVisuals.forSkill(fx.skill)
	local draw = visual and FX[visual.fx]
	if not visual or not draw then
		return
	end
	local delay = if fx.cast == true then SkillVisuals.fxDelay(visual.fx) else 0
	later(delay, function()
		local ok, err = pcall(draw, fx, casterOf(fx))
		if not ok then
			warn(`SkillEffects {visual.fx}: {err}`)
		end
	end)
end)
