-- Server-owned creatures: a blocky anchored Part moved along the dungeon lane each Heartbeat.
-- No Humanoid and no pathfinding, so a hundred of them cost almost nothing and nothing about them is
-- client-driven. Health lives in an attribute; Creatures.damage is the only way to lower it.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Enemies = require(ReplicatedStorage.Shared.Enemies)
local Roster = require(ReplicatedStorage.Shared.Roster)
local Waves = require(ReplicatedStorage.Shared.Waves)

local Creatures = {}

local FLYING_HEIGHT = 8
local FLYING_STRIDE = 5 -- flyers keep every Nth lane point, cutting the corners between them

export type Creature = {
	part: Part,
	id: string, -- roster creature id, e.g. "Zombie"
	archetype: string,
	health: number,
	speed: number,
	damage: number,
	coins: number,
	waypoints: { Vector3 },
	nextWaypoint: number,
	lastHitBy: number?, -- UserId
	onDeath: (Creature, killer: number?) -> (),
	onArrive: (Creature) -> (),
}

local active: { [Part]: Creature } = {}
local heartbeat: RBXScriptConnection? = nil

local function step(dt: number)
	for part, c in active do
		local target = c.waypoints[c.nextWaypoint]
		if not target then
			c.onArrive(c)
			Creatures.remove(c)
			continue
		end

		-- Status effects written by Skills as attributes: Frozen stops movement, SlowUntil/SlowFactor
		-- scale speed until a clock time (os.clock, the same clock Combat uses).
		if part:GetAttribute("Frozen") == true then
			continue
		end
		local speed = c.speed
		local slowUntil = part:GetAttribute("SlowUntil")
		if type(slowUntil) == "number" and os.clock() < slowUntil then
			local factor = part:GetAttribute("SlowFactor")
			speed *= if type(factor) == "number" then factor else 0.5
		end

		local pos = part.Position
		local delta = target - pos
		local stepLen = speed * dt
		if delta.Magnitude <= stepLen then
			part.Position = target
			c.nextWaypoint += 1
		else
			part.CFrame = CFrame.lookAt(pos + delta.Unit * stepLen, target)
		end
	end
end

-- The route a creature walks: the lane lifted to its body height; flyers take a sparse copy at height.
local function routeFor(lane: { Vector3 }, flying: boolean, halfHeight: number): { Vector3 }
	local lift = Vector3.new(0, halfHeight + (if flying then FLYING_HEIGHT else 0), 0)
	local route = {}
	if flying then
		for i = 1, #lane, FLYING_STRIDE do
			table.insert(route, lane[i] + lift)
		end
		if (#lane - 1) % FLYING_STRIDE ~= 0 then
			table.insert(route, lane[#lane] + lift)
		end
	else
		for _, p in lane do
			table.insert(route, p + lift)
		end
	end
	return route
end

function Creatures.spawn(
	creature: Roster.Creature,
	stats: Waves.Stats,
	lane: { Vector3 },
	parent: Instance,
	onDeath: (Creature, number?) -> (),
	onArrive: (Creature) -> ()
): Creature
	assert(#lane >= 2, "a lane needs at least two points")
	local def = Enemies.get(creature.archetype)
	local size = Vector3.new(def.size[1], def.size[2], def.size[3]) * creature.scale
	local route = routeFor(lane, creature.flying, size.Y / 2)

	local part = Instance.new("Part")
	part.Name = creature.id
	part.Size = size
	part.Anchored = true
	part.CanCollide = false
	part.Color = Color3.fromRGB(def.color[1], def.color[2], def.color[3])
	part.CFrame = CFrame.lookAt(route[1], route[2])
	part:SetAttribute("Health", stats.health)
	part:SetAttribute("MaxHealth", stats.health)
	part:SetAttribute("CreatureId", creature.id)
	part:SetAttribute("Archetype", creature.archetype)
	part.Parent = parent

	local c: Creature = {
		part = part,
		id = creature.id,
		archetype = creature.archetype,
		health = stats.health,
		speed = stats.speed,
		damage = stats.damage,
		coins = stats.coins,
		waypoints = route,
		nextWaypoint = 2,
		lastHitBy = nil,
		onDeath = onDeath,
		onArrive = onArrive,
	}
	active[part] = c

	if not heartbeat then
		heartbeat = RunService.Heartbeat:Connect(step)
	end
	return c
end

function Creatures.get(part: Instance): Creature?
	return active[part :: any]
end

function Creatures.damage(creature: Creature, amount: number, byUserId: number?)
	if creature.health <= 0 then
		return
	end
	creature.health = math.max(0, creature.health - amount)
	creature.part:SetAttribute("Health", creature.health)
	creature.lastHitBy = byUserId or creature.lastHitBy
	if creature.health == 0 then
		creature.onDeath(creature, creature.lastHitBy)
		Creatures.remove(creature)
		return
	end

	-- Hit flash so damage reads at a glance before proper effects exist.
	local part = creature.part
	local baseColor = Color3.fromRGB(table.unpack(Enemies.get(creature.archetype).color))
	part.Color = Color3.new(1, 1, 1)
	task.delay(0.08, function()
		if part.Parent then
			part.Color = baseColor
		end
	end)
end

function Creatures.remove(creature: Creature)
	active[creature.part] = nil
	creature.part:Destroy()
end

-- Every live creature, in no particular order.
function Creatures.all(): { Creature }
	local list = {}
	for _, c in active do
		table.insert(list, c)
	end
	return list
end

function Creatures.count(): number
	local n = 0
	for _ in active do
		n += 1
	end
	return n
end

function Creatures.clear()
	for _, c in active do
		c.part:Destroy()
	end
	table.clear(active)
	if heartbeat then
		heartbeat:Disconnect()
		heartbeat = nil
	end
end

return Creatures
