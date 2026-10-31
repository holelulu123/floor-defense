-- Skill use: validates the request, owns the cooldown clock, applies the effect in the world and tells
-- clients what to draw. Effect numbers come from shared Skills.Effects; this file is the Roblox side.
--
-- Attribute contract (all times are os.clock() seconds):
--   creature part: Frozen (bool), SlowUntil + SlowFactor, BurnUntil + BurnBy, MarkedUntil
--   Town Hall part: ShieldUntil (TownHall.takeDamage ignores damage while now < ShieldUntil)
--   player: <Stat> + <Stat>Until buffs (DamageMult, FireRateMult, SpeedMult, CritShots), Turrets

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Classes = require(ReplicatedStorage.Shared.Classes)
local SharedSkills = require(ReplicatedStorage.Shared.Skills)
local Combat = require(script.Parent.Combat)
local Damage = require(script.Parent.Damage)
local TownHall = require(script.Parent.TownHall)
local Turrets = require(script.Parent.Turrets)

local useSkill = ReplicatedStorage.Remotes.UseSkill :: RemoteEvent
local skillFx = ReplicatedStorage.Remotes.SkillFx :: RemoteEvent

local Skills = {}

local AIM_SLACK = 6
local BASE_WALK_SPEED = 16
local BASE_MAX_HEALTH = 100

type Zone = { cframe: CFrame, size: Vector3, untilTime: number, tickDamage: number, burn: number, owner: number }
type Hold = { player: Player, radius: number, untilTime: number, slowFactor: number }

local used: { [Player]: { [string]: number } } = {}
local appliedClass: { [Player]: string } = {}
local inRun: { [Player]: boolean } = {}
local townHall: TownHall.TownHall? = nil
local zones: { Zone } = {}
local holds: { Hold } = {}
local ticking = false

-- Helpers -----------------------------------------------------------------------------------------

local function character(player: Player): (Model?, Humanoid?, BasePart?)
	local char = player.Character
	local humanoid = char and char:FindFirstChildOfClass("Humanoid")
	local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not char or not humanoid or humanoid.Health <= 0 or not root then
		return nil, nil, nil
	end
	return char, humanoid, root
end

local function classOf(player: Player): string?
	local id = player:GetAttribute("Class")
	return if Classes.find(id) then id :: string else nil
end

-- Player buffs use Workspace:GetServerTimeNow() (not os.clock) so the client can read the same
-- `<Stat>Until` attribute for its local fire-rate feel.
local function setBuff(player: Player, stat: string, value: number, seconds: number)
	player:SetAttribute(stat, value)
	player:SetAttribute(stat .. "Until", Workspace:GetServerTimeNow() + seconds)
end

local function buff(player: Player, stat: string, default: number): number
	return SharedSkills.buffValue(
		player:GetAttribute(stat) :: number?,
		player:GetAttribute(stat .. "Until") :: number?,
		Workspace:GetServerTimeNow(),
		default
	)
end

-- The skill being applied right now (set around the handler call): every broadcast is tagged with its id and caster
-- so clients pick the visuals (shared SkillVisuals) and the caster plays the move; the first one also carries
-- `cast = true`. Payloads are visual only; clients never send them back.
local casting: { skill: string, caster: Player, cast: boolean }? = nil

local function broadcastFx(payload: { [string]: any })
	if casting then
		payload.skill = casting.skill
		payload.caster = casting.caster
		if casting.cast then
			payload.cast = true
			casting.cast = false
		end
	end
	skillFx:FireAllClients(payload)
end

-- Where the player is aiming: a validated client ray, or straight ahead when the client sent junk.
local function aimRay(player: Player, root: BasePart, origin: any, direction: any): (Vector3, Vector3)
	local char = player.Character
	local head = char and char:FindFirstChild("Head") :: BasePart?
	local anchor = if head then head.Position else root.Position
	if
		typeof(origin) == "Vector3"
		and typeof(direction) == "Vector3"
		and origin == origin
		and direction == direction
		and (origin - anchor).Magnitude <= AIM_SLACK
		and direction.Magnitude > 0.5
	then
		return origin, direction.Unit
	end
	return anchor, root.CFrame.LookVector
end

local function aimPoint(player: Player, origin: Vector3, direction: Vector3, range: number): Vector3
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local char = player.Character
	params.FilterDescendantsInstances = if char then { char } else {}
	local hit = Workspace:Raycast(origin, direction * range, params)
	return if hit then hit.Position else origin + direction * range
end

local function groundAt(point: Vector3, ignore: Instance?): Vector3
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = if ignore then { ignore } else {}
	local hit = Workspace:Raycast(point + Vector3.new(0, 4, 0), Vector3.new(0, -20, 0), params)
	return if hit then hit.Position else point
end

-- Passives ----------------------------------------------------------------------------------------

-- Walk speed from the class passive times any active speed buff; refreshed every tick so buffs expire.
local function refreshSpeed(player: Player)
	local _, humanoid = character(player)
	if not humanoid then
		return
	end
	local classId = classOf(player)
	local passive = classId and SharedSkills.Passives[classId]
	local speed = BASE_WALK_SPEED * ((passive and passive.walkSpeed) or 1) * buff(player, "SpeedMult", 1)
	if math.abs(humanoid.WalkSpeed - speed) > 0.01 then
		humanoid.WalkSpeed = speed
	end
end

-- Applies the class to the player's current character: max health (Classes `maxHealth`) and speed.
-- Safe to call again after a respawn or a class switch during prep.
function Skills.applyClass(player: Player)
	local _, humanoid = character(player)
	local classId = classOf(player)
	if not humanoid or not classId then
		return
	end
	local maxHealth = Classes.get(classId).maxHealth
	if humanoid.MaxHealth ~= maxHealth then
		-- Keep the same fraction of health, so a fresh character starts full and a prep switch is fair.
		local ratio = humanoid.Health / math.max(1, humanoid.MaxHealth)
		humanoid.MaxHealth = maxHealth
		humanoid.Health = math.max(humanoid.Health, maxHealth * ratio)
	end
	refreshSpeed(player)
	if classId ~= "Engineer" then
		Turrets.removeFor(player)
	end
	if appliedClass[player] ~= classId then
		appliedClass[player] = classId
		used[player] = {} -- a fresh class starts with everything ready; a respawn does not
		skillFx:FireClient(player, { kind = "reset" })
	end
end

-- Berserker passive: kills heal. Called by Run from the wave manager's kill hook.
function Skills.onKill(killer: Player)
	if classOf(killer) ~= "Berserker" then
		return
	end
	local _, humanoid = character(killer)
	if humanoid then
		humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + SharedSkills.Passives.Berserker.killHeal)
	end
end

-- Tick: burns, zones, holds, speed buffs ----------------------------------------------------------

local function tick()
	local now = os.clock()
	local creatures = Damage.creatures()
	local positions = Damage.positions(creatures)

	for i = #zones, 1, -1 do
		local z = zones[i]
		if now >= z.untilTime then
			table.remove(zones, i)
			continue
		end
		for _, c in creatures do
			local local_ = z.cframe:PointToObjectSpace(c.part.Position)
			if math.abs(local_.X) <= z.size.X / 2 and math.abs(local_.Z) <= z.size.Z / 2 then
				Damage.burn(c, z.burn, z.owner)
				Damage.hit(c, z.tickDamage, z.owner)
			end
		end
	end

	for i = #holds, 1, -1 do
		local h = holds[i]
		local _, _, root = character(h.player)
		if now >= h.untilTime or not root then
			table.remove(holds, i)
			continue
		end
		for _, idx in SharedSkills.inRadius(root.Position, positions, h.radius) do
			local part = creatures[idx].part
			part:SetAttribute("SlowUntil", now + SharedSkills.TickSeconds * 1.2)
			part:SetAttribute("SlowFactor", h.slowFactor)
		end
	end

	for _, c in creatures do
		local burnUntil = c.part:GetAttribute("BurnUntil")
		if type(burnUntil) == "number" and now < burnUntil and c.health > 0 then
			local by = c.part:GetAttribute("BurnBy")
			Damage.hit(
				c,
				SharedSkills.BurnDamagePerSecond * SharedSkills.TickSeconds,
				if type(by) == "number" then by else nil
			)
		end
	end

	for player in inRun do
		refreshSpeed(player)
	end
end

local function startTicking()
	if ticking then
		return
	end
	ticking = true
	task.spawn(function()
		while ticking do
			tick()
			task.wait(SharedSkills.TickSeconds)
		end
	end)
end

-- Effects -----------------------------------------------------------------------------------------

type Ctx = {
	player: Player,
	classId: string,
	skillId: string,
	root: BasePart,
	humanoid: Humanoid,
	origin: Vector3,
	direction: Vector3,
	effect: any,
	now: number,
}

local handlers: { [string]: (Ctx) -> boolean } = {}

handlers.buff = function(ctx)
	setBuff(ctx.player, ctx.effect.stat, ctx.effect.multiplier, ctx.effect.duration)
	if ctx.effect.speed then
		setBuff(ctx.player, "SpeedMult", ctx.effect.speed, ctx.effect.duration)
		refreshSpeed(ctx.player)
	end
	broadcastFx({
		kind = ctx.effect.fx,
		position = ctx.root.Position,
		direction = ctx.direction,
		radius = 4,
		duration = ctx.effect.duration,
	})
	return true
end

handlers.teamBuff = function(ctx)
	for player in inRun do
		setBuff(player, ctx.effect.stat, ctx.effect.multiplier, ctx.effect.duration)
		if ctx.effect.refill then
			Combat.refill(player) -- Ammo Crate: the whole team reloads instantly
		end
	end
	local flat = Vector3.new(ctx.direction.X, 0, ctx.direction.Z)
	local ahead = ctx.root.Position + (if flat.Magnitude > 0.1 then flat.Unit else ctx.root.CFrame.LookVector) * 3
	broadcastFx({
		kind = ctx.effect.fx,
		position = groundAt(ahead, ctx.player.Character),
		radius = 3,
		duration = ctx.effect.duration,
	})
	return true
end

handlers.radius = function(ctx)
	local creatures = Damage.creatures()
	local center = ctx.root.Position
	for _, i in SharedSkills.inRadius(center, Damage.positions(creatures), ctx.effect.radius) do
		local c = creatures[i]
		Damage.hit(c, ctx.effect.damage, ctx.player.UserId)
		if ctx.effect.knockback and c.health > 0 then
			local away = c.part.Position - center
			away = Vector3.new(away.X, 0, away.Z)
			if away.Magnitude > 0.01 then
				c.part.Position += away.Unit * ctx.effect.knockback
			end
		end
	end
	broadcastFx({ kind = ctx.effect.fx, position = center, radius = ctx.effect.radius })
	return true
end

handlers.hold = function(ctx)
	table.insert(holds, {
		player = ctx.player,
		radius = ctx.effect.radius,
		untilTime = ctx.now + ctx.effect.duration,
		slowFactor = ctx.effect.slowFactor,
	})
	broadcastFx({
		kind = ctx.effect.fx,
		position = ctx.root.Position,
		radius = ctx.effect.radius,
		duration = ctx.effect.duration,
	})
	return true
end

handlers.dash = function(ctx)
	local flat = Vector3.new(ctx.direction.X, 0, ctx.direction.Z)
	if flat.Magnitude < 0.1 then
		flat = ctx.root.CFrame.LookVector
	end
	local speed = ctx.effect.range / ctx.effect.duration
	ctx.root.AssemblyLinearVelocity = flat.Unit * speed + Vector3.new(0, 2, 0)
	broadcastFx({ kind = ctx.effect.fx, position = ctx.root.Position, direction = flat.Unit, range = ctx.effect.range })
	return true
end

handlers.mark = function(ctx)
	local creatures = Damage.creatures()
	local hits = SharedSkills.lineHits(ctx.origin, ctx.direction, Damage.positions(creatures), ctx.effect.range, 3, 1)
	local target = if hits[1] then creatures[hits[1]] else Damage.nearest(ctx.root.Position, 40)
	if not target then
		return false
	end
	target.part:SetAttribute("MarkedUntil", ctx.now + ctx.effect.duration)
	broadcastFx({
		kind = ctx.effect.fx,
		position = target.part.Position,
		radius = 2,
		duration = ctx.effect.duration,
		target = target.part,
	})
	return true
end

handlers.repair = function(ctx)
	if not townHall or not townHall:isAlive() then
		return false
	end
	townHall:repair(ctx.effect.heal)
	broadcastFx({
		kind = ctx.effect.fx,
		position = townHall.part.Position,
		radius = townHall.part.Size.X,
		amount = ctx.effect.heal,
	})
	return true
end

handlers.shield = function(ctx)
	if not townHall or not townHall:isAlive() then
		return false
	end
	townHall.part:SetAttribute("ShieldUntil", ctx.now + ctx.effect.duration)
	broadcastFx({
		kind = ctx.effect.fx,
		position = townHall.part.Position,
		radius = townHall.part.Size.X,
		duration = ctx.effect.duration,
	})
	return true
end

handlers.turret = function(ctx)
	local flat = Vector3.new(ctx.direction.X, 0, ctx.direction.Z)
	if flat.Magnitude < 0.1 then
		flat = ctx.root.CFrame.LookVector
	end
	local ahead = ctx.root.Position + flat.Unit * math.min(ctx.effect.range, 6)
	local ground = groundAt(ahead, ctx.player.Character)
	if (ground - ctx.root.Position).Magnitude > ctx.effect.range + 4 then
		return false
	end
	local turret = Turrets.place(ctx.player, ground, ground + flat.Unit * 10)
	broadcastFx({ kind = ctx.effect.fx, position = ground, radius = 2, target = turret.model })
	return true
end

handlers.overclock = function(ctx)
	if Turrets.count(ctx.player) == 0 then
		return false
	end
	Turrets.overclock(ctx.player, ctx.effect.duration)
	broadcastFx({
		kind = ctx.effect.fx,
		position = ctx.root.Position,
		radius = 3,
		duration = ctx.effect.duration,
		turrets = Turrets.models(ctx.player),
	})
	return true
end

handlers.cone = function(ctx)
	local creatures = Damage.creatures()
	local hits = SharedSkills.inCone(
		ctx.root.Position,
		ctx.direction,
		Damage.positions(creatures),
		ctx.effect.range,
		ctx.effect.halfAngle
	)
	local damage = ctx.effect.damage
	if ctx.classId == "Berserker" then
		damage *= SharedSkills.Passives.Berserker.meleeMult
	end
	for _, i in hits do
		local c = creatures[i]
		Damage.hit(c, damage, ctx.player.UserId)
		if ctx.effect.burn and c.health > 0 then
			Damage.burn(c, ctx.effect.burn, ctx.player.UserId)
		end
	end
	broadcastFx({
		kind = ctx.effect.fx,
		position = ctx.root.Position,
		direction = ctx.direction,
		range = ctx.effect.range,
		halfAngle = ctx.effect.halfAngle,
	})
	return true
end

handlers.bolt = function(ctx)
	local creatures = Damage.creatures()
	local hits =
		SharedSkills.inCone(ctx.root.Position, ctx.direction, Damage.positions(creatures), ctx.effect.range, 45)
	local target = if hits[1] then creatures[hits[1]] else Damage.nearest(ctx.root.Position, ctx.effect.range)
	if not target then
		return false
	end
	broadcastFx({ kind = ctx.effect.fx, position = ctx.origin, target = target.part, duration = ctx.effect.delay })
	local userId = ctx.player.UserId
	local splash = ctx.effect.splash
	task.delay(ctx.effect.delay, function()
		if target.health > 0 and target.part.Parent then
			if splash then
				Damage.area(target.part.Position, splash, ctx.effect.damage, userId) -- the target and its neighbours
			else
				Damage.hit(target, ctx.effect.damage, userId)
			end
		end
	end)
	return true
end

handlers.freeze = function(ctx)
	local creatures = Damage.creatures()
	local center = ctx.root.Position
	local seconds = SharedSkills.freezeDuration(ctx.classId, ctx.effect.duration)
	local frozen = {}
	for _, i in SharedSkills.inRadius(center, Damage.positions(creatures), ctx.effect.radius) do
		local part = creatures[i].part
		part:SetAttribute("Frozen", true)
		part:SetAttribute("SlowUntil", ctx.now + seconds) -- belt and braces for movers that only read SlowUntil
		part:SetAttribute("SlowFactor", 0)
		table.insert(frozen, part)
	end
	task.delay(seconds, function()
		for _, part in frozen do
			if part.Parent then
				part:SetAttribute("Frozen", nil)
			end
		end
	end)
	broadcastFx({ kind = ctx.effect.fx, position = center, radius = ctx.effect.radius, duration = seconds })
	return true
end

handlers.zone = function(ctx)
	local flat = Vector3.new(ctx.direction.X, 0, ctx.direction.Z)
	if flat.Magnitude < 0.1 then
		flat = ctx.root.CFrame.LookVector
	end
	local center = groundAt(ctx.root.Position + flat.Unit * 10, ctx.player.Character)
	local cframe = CFrame.lookAt(center, center + flat.Unit) -- wall's Z is along the lane, X across it
	local size = Vector3.new(ctx.effect.width, 6, ctx.effect.depth)
	table.insert(zones, {
		cframe = cframe,
		size = size,
		untilTime = ctx.now + ctx.effect.duration,
		tickDamage = ctx.effect.tickDamage,
		burn = ctx.effect.burn,
		owner = ctx.player.UserId,
	})
	broadcastFx({ kind = ctx.effect.fx, cframe = cframe, size = size, duration = ctx.effect.duration })
	return true
end

handlers.line = function(ctx)
	local creatures = Damage.creatures()
	local hits = SharedSkills.lineHits(
		ctx.origin,
		ctx.direction,
		Damage.positions(creatures),
		ctx.effect.range,
		ctx.effect.radius,
		ctx.effect.maxTargets
	)
	local hitAt = {}
	local struck: { [any]: boolean } = {}
	local splash = ctx.effect.splash
	local positions = Damage.positions(creatures)
	for _, i in hits do
		table.insert(hitAt, creatures[i].part.Position)
		-- the pierced creature, plus anything within `splash` of it; each creature takes the shot once
		local around = if splash then SharedSkills.inRadius(positions[i], positions, splash) else { i }
		for _, j in around do
			if not struck[j] then
				struck[j] = true
				Damage.hit(creatures[j], ctx.effect.damage, ctx.player.UserId)
			end
		end
	end
	broadcastFx({
		kind = ctx.effect.fx,
		position = ctx.origin,
		direction = ctx.direction,
		range = ctx.effect.range,
		hits = hitAt,
	})
	return true
end

handlers.crit = function(ctx)
	setBuff(ctx.player, "CritShots", ctx.effect.count, ctx.effect.duration)
	broadcastFx({
		kind = ctx.effect.fx,
		position = ctx.root.Position,
		direction = ctx.direction,
		radius = 3,
		duration = ctx.effect.duration,
	})
	return true
end

-- Runs after a task.delay, outside the handler, so it tags its broadcast itself.
local function explode(center: Vector3, radius: number, damage: number, player: Player, fx: string, skillId: string)
	Damage.area(center, radius, damage, player.UserId)
	skillFx:FireAllClients({ kind = fx, position = center, radius = radius, skill = skillId, caster = player })
end

handlers.grenade = function(ctx)
	local target = aimPoint(ctx.player, ctx.origin, ctx.direction, ctx.effect.range)
	local radius = SharedSkills.splashRadius(ctx.classId, ctx.effect.radius)
	broadcastFx({ kind = "throw", position = ctx.origin, target = target, duration = ctx.effect.delay })
	task.delay(ctx.effect.delay, explode, target, radius, ctx.effect.damage, ctx.player, ctx.effect.fx, ctx.skillId)
	return true
end

handlers.cluster = function(ctx)
	local points = SharedSkills.clusterPoints(
		ctx.root.Position,
		ctx.direction,
		ctx.effect.count,
		ctx.effect.spacing,
		ctx.effect.startDistance
	)
	local radius = SharedSkills.splashRadius(ctx.classId, ctx.effect.radius)
	local centers = {}
	for n, p in points do
		local center = groundAt(Vector3.new(p.X, p.Y, p.Z), ctx.player.Character)
		centers[n] = center
		task.delay(
			ctx.effect.delay + (n - 1) * 0.15,
			explode,
			center,
			radius,
			ctx.effect.damage,
			ctx.player,
			ctx.effect.fx,
			ctx.skillId
		)
	end
	broadcastFx({
		kind = "throw",
		position = ctx.origin,
		target = centers[1],
		points = centers,
		duration = ctx.effect.delay,
	})
	return true
end

-- Remote -------------------------------------------------------------------------------------------

local function onUseSkill(player: Player, index: any, origin: any, direction: any)
	if not inRun[player] or (index ~= 1 and index ~= 2) then
		return
	end
	local classId = classOf(player)
	if not classId then
		return
	end
	local _, humanoid, root = character(player)
	if not humanoid or not root then
		return
	end

	local now = os.clock()
	local cooldowns = used[player] or {}
	used[player] = cooldowns
	local ok, left = Classes.canUse(classId, index, cooldowns, now)
	if not ok then
		skillFx:FireClient(player, { kind = "cooldown", index = index, cooldown = left })
		return
	end

	local skill = Classes.get(classId).skills[index]
	local effect = SharedSkills.effectFor(classId, index)
	local handler = handlers[effect.kind]
	if not handler then
		warn(`No handler for skill kind {effect.kind}`)
		return
	end

	local aimOrigin, aimDir = aimRay(player, root, origin, direction)
	casting = { skill = skill.id, caster = player, cast = true }
	local ran, applied = pcall(handler, {
		player = player,
		classId = classId,
		skillId = skill.id,
		root = root,
		humanoid = humanoid,
		origin = aimOrigin,
		direction = aimDir,
		effect = effect,
		now = now,
	})
	casting = nil
	if not ran then
		warn(`Skill {skill.id} failed: {applied}`)
		applied = false
	end
	if not applied then
		skillFx:FireClient(player, { kind = "failed", index = index })
		return
	end
	cooldowns[skill.id] = now
	skillFx:FireClient(player, { kind = "cooldown", index = index, cooldown = skill.cooldown })
end

-- Run lifecycle -------------------------------------------------------------------------------------

function Skills.beginRun(players: { Player }, hall: TownHall.TownHall)
	townHall = hall
	for _, player in players do
		inRun[player] = true
	end
	startTicking()
end

local function clearBuffs(player: Player)
	for _, stat in { "DamageMult", "FireRateMult", "SpeedMult", "CritShots" } do
		player:SetAttribute(stat, nil)
		player:SetAttribute(stat .. "Until", nil)
	end
end

function Skills.endRun()
	ticking = false
	townHall = nil
	table.clear(zones)
	table.clear(holds)
	for player in inRun do
		if player.Parent then
			clearBuffs(player)
			local _, humanoid = character(player)
			if humanoid then
				humanoid.WalkSpeed = BASE_WALK_SPEED
				humanoid.MaxHealth = BASE_MAX_HEALTH
			end
		end
	end
	table.clear(inRun)
	table.clear(used)
	table.clear(appliedClass)
	Turrets.clear()
end

function Skills.init()
	useSkill.OnServerEvent:Connect(onUseSkill)
	Players.PlayerRemoving:Connect(function(player)
		inRun[player] = nil
		used[player] = nil
		appliedClass[player] = nil
	end)
end

return Skills
