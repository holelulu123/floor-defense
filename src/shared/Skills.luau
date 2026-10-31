-- Skill effects as data plus the geometry and buff math the server needs to apply them.
-- Pure: positions are anything with X/Y/Z fields (Vector3 in Roblox, plain tables in Lune tests),
-- times are plain seconds. The server (src/server/Skills.luau) turns these into world changes.

local Classes = require(script and script.Parent.Classes or "./Classes")

-- Vector3 in Roblox, a plain table in Lune tests.
export type Position = Vector3 | { X: number, Y: number, Z: number }

export type Effect = {
	kind: string, -- see server Skills.luau for one handler per kind
	damage: number?,
	radius: number?, -- studs around a point
	range: number?, -- studs in front of the caster
	halfAngle: number?, -- degrees, for cones
	maxTargets: number?,
	duration: number?, -- seconds the effect lingers (buffs, freezes, zones)
	multiplier: number?, -- for buffs
	knockback: number?,
	heal: number?,
	count: number?, -- bomblets
	spacing: number?,
	delay: number?, -- seconds before a thrown thing goes off
	refill: boolean?, -- teamBuff: also refill every run player's magazine
	fx: string, -- client effect name sent through SkillFx
}

local Skills = {}

Skills.Effects = {
	-- Trooper
	BurstFire = { kind = "buff", stat = "DamageMult", multiplier = 2, duration = 1, fx = "buff" },
	-- Every run player's magazine refills instantly, then +20% fire rate for 10 s.
	AmmoCrate = {
		kind = "teamBuff",
		stat = "FireRateMult",
		multiplier = 1.2,
		duration = 10,
		refill = true,
		fx = "crate",
	},
	-- Tank
	FlailSweep = { kind = "radius", damage = 30, radius = 6, knockback = 6, fx = "sweep" },
	IronWall = { kind = "hold", radius = 8, duration = 8, slowFactor = 0.2, fx = "wall" },
	-- Scout
	Dash = { kind = "dash", range = 20, duration = 0.4, fx = "dash" },
	MarkTarget = { kind = "mark", range = 150, duration = 8, multiplier = 1.3, fx = "mark" },
	-- Medic
	RepairPulse = { kind = "repair", heal = 150, fx = "pulse" },
	Overcharge = { kind = "shield", duration = 6, fx = "shield" },
	-- Engineer
	PlaceTurret = { kind = "turret", range = 12, fx = "build" },
	Overclock = { kind = "overclock", duration = 10, fx = "buff" },
	-- Berserker
	Cleave = { kind = "cone", damage = 60, range = 8, halfAngle = 70, fx = "sweep" },
	Rage = { kind = "buff", stat = "FireRateMult", multiplier = 1.4, speed = 1.4, duration = 10, fx = "buff" },
	-- Mage
	ArcaneBolt = { kind = "bolt", damage = 35, range = 60, delay = 0.3, splash = 9, fx = "bolt" },
	FrostNova = { kind = "freeze", radius = 15, duration = 3, fx = "nova" },
	-- Pyro
	FlameSweep = { kind = "cone", damage = 20, range = 20, halfAngle = 30, burn = 4, fx = "flame" },
	FireWall = { kind = "zone", width = 16, depth = 3, duration = 8, tickDamage = 10, burn = 1, fx = "firewall" },
	-- Sniper
	-- splash: creatures within this many studs of each pierced target are hit as well (once each).
	PiercingShot = { kind = "line", damage = 80, range = 120, radius = 2.5, maxTargets = 5, splash = 8, fx = "pierce" },
	Overwatch = { kind = "crit", count = 5, duration = 10, multiplier = 2, fx = "buff" },
	-- Demolisher
	FragToss = { kind = "grenade", damage = 120, radius = 8, range = 60, delay = 0.8, fx = "blast" },
	ClusterBomb = {
		kind = "cluster",
		damage = 50,
		radius = 5,
		count = 6,
		spacing = 6,
		startDistance = 10,
		delay = 1,
		fx = "blast",
	},
}

-- Passive tuning applied by the server. Kept here so tests can pin the numbers. Class max health lives in
-- Classes.luau `maxHealth`.
Skills.Passives = {
	Trooper = { reloadSpeed = 1.1 }, -- reload time is divided by this (Weapons.reloadTime)
	Scout = { walkSpeed = 1.2 },
	Berserker = { killHeal = 5, meleeMult = 1.25 },
	Mage = { freezeMult = 1.25 },
	Pyro = { burnTakenMult = 1.15 },
	Sniper = { critMult = 1.5 },
	Demolisher = { splashMult = 1.2 },
	Medic = { repairMult = 2 },
}

-- Damage over time applied by the server tick (BurnUntil attribute).
Skills.BurnDamagePerSecond = 5
Skills.TickSeconds = 0.5

function Skills.effectFor(classId: string, skillIndex: number): Effect
	local skill = Classes.get(classId).skills[skillIndex]
	local effect = Skills.Effects[skill.id]
	assert(effect, `No effect for skill {skill.id}`)
	return effect
end

-- Geometry ---------------------------------------------------------------------------------------

local function sub(a: Position, b: Position): Position
	return { X = a.X - b.X, Y = a.Y - b.Y, Z = a.Z - b.Z }
end

local function dot(a: Position, b: Position): number
	return a.X * b.X + a.Y * b.Y + a.Z * b.Z
end

local function length(a: Position): number
	return math.sqrt(dot(a, a))
end

function Skills.distance(a: Position, b: Position): number
	return length(sub(a, b))
end

local function unit(a: Position): Position
	local l = length(a)
	if l < 1e-6 then
		return { X = 0, Y = 0, Z = 1 }
	end
	return { X = a.X / l, Y = a.Y / l, Z = a.Z / l }
end

-- Indices of `positions` within `radius` of `center`, nearest first.
function Skills.inRadius(center: Position, positions: { Position }, radius: number): { number }
	local found = {}
	for i, p in positions do
		local d = Skills.distance(center, p)
		if d <= radius then
			table.insert(found, { i = i, d = d })
		end
	end
	table.sort(found, function(a, b)
		return a.d < b.d
	end)
	local out = {}
	for _, f in found do
		table.insert(out, f.i)
	end
	return out
end

-- Indices of `positions` inside a cone from `origin` along `direction` (range studs, halfAngle degrees).
-- Height is ignored so a cone on flat ground does not miss tall or short creatures.
function Skills.inCone(
	origin: Position,
	direction: Position,
	positions: { Position },
	range: number,
	halfAngle: number
): { number }
	local dir = unit({ X = direction.X, Y = 0, Z = direction.Z })
	local cosLimit = math.cos(math.rad(halfAngle))
	local out = {}
	for i, p in positions do
		local to = { X = p.X - origin.X, Y = 0, Z = p.Z - origin.Z }
		local d = length(to)
		if d <= range and (d < 1e-6 or dot(unit(to), dir) >= cosLimit - 1e-9) then
			table.insert(out, i)
		end
	end
	return out
end

-- Indices of up to `maxTargets` positions within `radius` of the ray (origin, direction), nearest first.
function Skills.lineHits(
	origin: Position,
	direction: Position,
	positions: { Position },
	range: number,
	radius: number,
	maxTargets: number
): { number }
	local dir = unit(direction)
	local found = {}
	for i, p in positions do
		local to = sub(p, origin)
		local along = dot(to, dir)
		if along >= 0 and along <= range then
			local closest = { X = origin.X + dir.X * along, Y = origin.Y + dir.Y * along, Z = origin.Z + dir.Z * along }
			if Skills.distance(closest, p) <= radius then
				table.insert(found, { i = i, d = along })
			end
		end
	end
	table.sort(found, function(a, b)
		return a.d < b.d
	end)
	local out = {}
	for n, f in found do
		if n > maxTargets then
			break
		end
		table.insert(out, f.i)
	end
	return out
end

-- Points along `direction` from `origin`: the Cluster Bomb's bomblet impact spots.
function Skills.clusterPoints(
	origin: Position,
	direction: Position,
	count: number,
	spacing: number,
	startDistance: number
): { Position }
	local dir = unit({ X = direction.X, Y = 0, Z = direction.Z })
	local points = {}
	for n = 0, count - 1 do
		local d = startDistance + n * spacing
		table.insert(points, { X = origin.X + dir.X * d, Y = origin.Y, Z = origin.Z + dir.Z * d })
	end
	return points
end

-- Buffs and status ------------------------------------------------------------------------------

-- Attribute pairs `<stat>` / `<stat>Until`; value applies only while now < until.
function Skills.buffValue(value: number?, untilTime: number?, now: number, default: number): number
	if value ~= nil and untilTime ~= nil and now < untilTime then
		return value
	end
	return default
end

-- Damage multiplier a creature takes from its status attributes.
function Skills.damageTakenMultiplier(attrs: { MarkedUntil: number?, BurnUntil: number? }, now: number): number
	local mult = 1
	if attrs.MarkedUntil and now < attrs.MarkedUntil then
		mult *= Skills.Effects.MarkTarget.multiplier
	end
	if attrs.BurnUntil and now < attrs.BurnUntil then
		mult *= Skills.Passives.Pyro.burnTakenMult
	end
	return mult
end

-- Freeze duration after class passives (the Mage's freeze lasts 25% longer).
function Skills.freezeDuration(classId: string, base: number): number
	local passive = Skills.Passives[classId]
	return base * ((passive and passive.freezeMult) or 1)
end

-- Explosion radius after class passives (the Demolisher's blasts are 20% wider).
function Skills.splashRadius(classId: string, base: number): number
	local passive = Skills.Passives[classId]
	return base * ((passive and passive.splashMult) or 1)
end

-- Engineer turrets --------------------------------------------------------------------------------

Skills.Turret = {
	MaxPlaced = Classes.Turrets.MaxPlaced,
	RepairPerHit = Classes.Turrets.RepairPerHit,
	OverclockRate = Classes.Turrets.OverclockRate,
	Health = 300,
	Damage = 8,
	Interval = 0.6, -- seconds between shots
	Range = 40,
	Splash = 8, -- studs around the target that each shot also hits
	BumpDamagePerSecond = 15, -- creatures within BumpRadius chew on the turret
	BumpRadius = 4,
	RepairReach = 8, -- studs the Engineer may be from a turret to repair it with a swing
}

-- Which slot a new turret takes given the placement times of the existing ones: a free slot while
-- under the cap, otherwise the oldest turret's slot (and `replaced` is true).
function Skills.Turret.placeIndex(placedAt: { number }): (number, boolean)
	if #placedAt < Skills.Turret.MaxPlaced then
		return #placedAt + 1, false
	end
	local oldest = 1
	for i, t in placedAt do
		if t < placedAt[oldest] then
			oldest = i
		end
	end
	return oldest, true
end

-- Health after one repair swing: +25% of max, capped.
function Skills.Turret.repair(health: number, maxHealth: number): number
	return math.min(maxHealth, health + maxHealth * Skills.Turret.RepairPerHit)
end

-- Seconds between shots right now; halves while overclocked.
function Skills.Turret.interval(overclockUntil: number?, now: number): number
	if overclockUntil and now < overclockUntil then
		return Skills.Turret.Interval / Skills.Turret.OverclockRate
	end
	return Skills.Turret.Interval
end

function Skills.Turret.canFire(lastFired: number?, overclockUntil: number?, now: number): boolean
	return lastFired == nil or now - lastFired >= Skills.Turret.interval(overclockUntil, now)
end

return Skills
