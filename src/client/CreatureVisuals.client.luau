-- Client-side looks for server creatures. The server moves an invisible hitbox Part (tag "Creature", attributes
-- ModelKey, Gait, Health); this script clones the matching template from ReplicatedStorage.CreatureModels, keeps
-- it on the hitbox with a little smoothing and poses it every frame with CreatureMotion: step bob and sway,
-- hop arcs, hover bob and bank, heavy stomps. A health drop flashes it white and swells it briefly; when the
-- hitbox goes away the clone tips over, sinks and fades (or just fades if it reached the Town Hall alive).
-- Nothing here is sent back to the server: position and health stay authoritative there.

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local CreatureMotion = require(ReplicatedStorage.Shared.CreatureMotion)

local TAG = "Creature"
local FOLLOW_RATE = 18 -- 1/s, exponential smoothing of the replicated hitbox position
local TURN_RATE = 10 -- 1/s, yaw smoothing
local SNAP_DISTANCE = 30 -- studs; further than this and the clone jumps (spawn, teleport)
local FLASH_SECONDS = 0.09
local MAX_FLASHES = 20 -- Highlights are capped per client; keep well under the limit

type Visual = {
	hitbox: BasePart,
	model: Model,
	parts: { BasePart },
	transparency: { number },
	gait: CreatureMotion.Gait,
	height: number,
	baseScale: number,
	scale: number,
	pos: Vector3,
	yaw: number,
	turn: number,
	speed: number,
	phase: number,
	seed: number,
	health: number,
	hitAt: number,
	highlight: Highlight?,
	flashUntil: number,
	diedAt: number?,
	killed: boolean,
	conn: RBXScriptConnection?,
}

local visuals: { [Instance]: Visual } = {}
local dying: { Visual } = {}
local flashing = 0

local folder = Instance.new("Folder")
folder.Name = "CreatureVisuals"
folder.Parent = Workspace

local function yawOf(cf: CFrame): number
	local look = cf.LookVector
	return math.atan2(-look.X, -look.Z)
end

local function wrapAngle(a: number): number
	return (a + math.pi) % (2 * math.pi) - math.pi
end

local function templateFor(key: string): Model?
	local templates = ReplicatedStorage:FindFirstChild("CreatureModels")
		or ReplicatedStorage:WaitForChild("CreatureModels", 5)
	if not templates then
		return nil
	end
	local template = templates:FindFirstChild(key) or templates:WaitForChild(key, 5)
	return if template and template:IsA("Model") then template else nil
end

local function stopFlash(v: Visual)
	if v.highlight and v.highlight.Enabled then
		v.highlight.Enabled = false
		flashing -= 1
	end
end

local function flash(v: Visual, now: number)
	v.hitAt = now
	if not v.highlight then
		local h = Instance.new("Highlight")
		h.FillColor = Color3.new(1, 1, 1)
		h.FillTransparency = 0.35
		h.OutlineTransparency = 1
		h.DepthMode = Enum.HighlightDepthMode.Occluded
		h.Enabled = false
		h.Adornee = v.model
		h.Parent = v.model
		v.highlight = h
	end
	local h = v.highlight :: Highlight
	if not h.Enabled and flashing < MAX_FLASHES then
		h.Enabled = true
		flashing += 1
	end
	v.flashUntil = now + FLASH_SECONDS
end

local function release(hitbox: Instance)
	local v = visuals[hitbox]
	if not v then
		return
	end
	visuals[hitbox] = nil
	if v.conn then
		v.conn:Disconnect()
	end
	stopFlash(v)
	v.diedAt = os.clock()
	table.insert(dying, v)
end

local function attach(hitbox: Instance)
	if visuals[hitbox] or not hitbox:IsA("BasePart") then
		return
	end
	local key = hitbox:GetAttribute("ModelKey")
	if type(key) ~= "string" then
		return -- placeholder block: the server draws it
	end
	local template = templateFor(key)
	if not hitbox:IsDescendantOf(Workspace) or visuals[hitbox] then
		return
	end
	if not template then
		hitbox.Transparency = 0 -- template never arrived: show the hitbox block locally rather than nothing
		return
	end

	local model = template:Clone()
	local parts, transparency = {}, {}
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = false
			d.CanQuery = false
			d.CanTouch = false
			table.insert(parts, d)
			table.insert(transparency, d.Transparency)
		end
	end
	local gait = hitbox:GetAttribute("Gait")
	local health = hitbox:GetAttribute("Health")
	local v: Visual = {
		hitbox = hitbox,
		model = model,
		parts = parts,
		transparency = transparency,
		gait = if type(gait) == "string" then gait :: any else "walk",
		height = hitbox.Size.Y,
		baseScale = model:GetScale(),
		scale = 1,
		pos = hitbox.Position,
		yaw = yawOf(hitbox.CFrame),
		turn = 0,
		speed = 0,
		phase = math.random(),
		seed = math.random() * 10,
		health = if type(health) == "number" then health else 1,
		hitAt = -1,
		highlight = nil,
		flashUntil = 0,
		diedAt = nil,
		killed = false,
		conn = nil,
	}
	v.conn = hitbox:GetAttributeChangedSignal("Health"):Connect(function()
		local h = hitbox:GetAttribute("Health")
		if type(h) ~= "number" then
			return
		end
		if h < v.health then
			flash(v, os.clock())
		end
		v.health = h
		v.killed = h <= 0
	end)
	model:PivotTo(hitbox.CFrame)
	model.Parent = folder
	visuals[hitbox] = v
end

-- Pose about the feet so sway and tipping pivot on the ground, not mid-body.
local function placeAt(v: Visual, pos: Vector3, pitch: number, roll: number)
	local half = v.height / 2
	v.model:PivotTo(
		CFrame.new(pos)
			* CFrame.Angles(0, v.yaw, 0)
			* CFrame.new(0, -half, 0)
			* CFrame.Angles(pitch, 0, roll)
			* CFrame.new(0, half, 0)
	)
end

local function setScale(v: Visual, s: number)
	if math.abs(s - v.scale) > 0.004 then
		v.scale = s
		v.model:ScaleTo(v.baseScale * s)
	end
end

local function update(v: Visual, now: number, dt: number)
	local target = v.hitbox.Position
	local prev = v.pos
	if (target - prev).Magnitude > SNAP_DISTANCE then
		v.pos = target
	else
		v.pos = prev:Lerp(target, 1 - math.exp(-FOLLOW_RATE * dt))
	end
	local moved = v.pos - prev
	local instSpeed = Vector3.new(moved.X, 0, moved.Z).Magnitude / dt
	v.speed += (instSpeed - v.speed) * math.min(1, dt * 8)

	local dyaw = wrapAngle(yawOf(v.hitbox.CFrame) - v.yaw) * math.min(1, dt * TURN_RATE)
	v.yaw = wrapAngle(v.yaw + dyaw)
	v.turn += (dyaw / dt - v.turn) * math.min(1, dt * 6)

	v.phase += CreatureMotion.cadence(v.gait, v.speed, v.height) * dt
	local moving = math.clamp(v.speed / 4, 0, 1)
	local pose = CreatureMotion.pose(v.gait, v.phase, now + v.seed, v.height, moving, v.turn)

	if v.flashUntil > 0 and now >= v.flashUntil then
		v.flashUntil = 0
		stopFlash(v)
	end
	setScale(v, CreatureMotion.hitPulse(now - v.hitAt))
	placeAt(v, v.pos + Vector3.new(0, pose.lift, 0), pose.pitch, pose.roll)
end

-- Returns true when the death animation is over and the clone is gone.
local function updateDying(v: Visual, now: number): boolean
	local duration = if v.killed then CreatureMotion.DeathSeconds else CreatureMotion.ArriveSeconds
	local alpha = (now - (v.diedAt :: number)) / duration
	if alpha >= 1 then
		v.model:Destroy()
		return true
	end
	setScale(v, 1)
	local fade, sink, tip
	if v.killed then
		local d = CreatureMotion.death(alpha, v.height)
		fade, sink, tip = d.fade, d.sink, d.tip
		if v.gait == "fly" then
			sink += alpha * alpha * (8 + v.height) -- flyers drop out of the air
		end
	else
		fade, sink, tip = alpha, 0, 0
	end
	for i, p in v.parts do
		local base = v.transparency[i]
		p.Transparency = base + (1 - base) * fade
	end
	placeAt(v, v.pos - Vector3.new(0, sink, 0), tip, 0)
	return false
end

RunService.RenderStepped:Connect(function(dt: number)
	if dt <= 0 then
		return
	end
	local now = os.clock()
	for hitbox, v in visuals do
		if hitbox.Parent then
			update(v, now, dt)
		else
			release(hitbox)
		end
	end
	for i = #dying, 1, -1 do
		if updateDying(dying[i], now) then
			table.remove(dying, i)
		end
	end
end)

CollectionService:GetInstanceAddedSignal(TAG):Connect(function(inst)
	task.spawn(attach, inst)
end)
CollectionService:GetInstanceRemovedSignal(TAG):Connect(release)
for _, inst in CollectionService:GetTagged(TAG) do
	task.spawn(attach, inst)
end
