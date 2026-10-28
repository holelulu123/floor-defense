-- Server-owned creatures: a blocky anchored Part moved along a precomputed path each Heartbeat.
-- No Humanoid, so a hundred of them cost almost nothing and nothing about them is client-driven.
-- Health lives in an attribute; Creatures.damage is the only way to lower it.

local PathfindingService = game:GetService("PathfindingService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Enemies = require(ReplicatedStorage.Shared.Enemies)

local Creatures = {}

export type Creature = {
	part: Part,
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
local routeCache: { [Part]: { Vector3 } } = {}
local heartbeat: RBXScriptConnection? = nil

-- Straight-line fallback keeps the game playable if pathfinding fails (e.g. no navmesh yet).
local function routeFrom(gate: Part, goal: Vector3): { Vector3 }
	local cached = routeCache[gate]
	if cached then
		return cached
	end

	local waypoints = { goal }
	local path = PathfindingService:CreatePath({ AgentRadius = 2, AgentHeight = 5, AgentCanJump = false })
	local ok = pcall(path.ComputeAsync, path, gate.Position, goal)
	if ok and path.Status == Enum.PathStatus.Success then
		waypoints = {}
		for _, wp in path:GetWaypoints() do
			table.insert(waypoints, wp.Position)
		end
	else
		warn(`Pathfinding from {gate.Name} failed; using a straight line`)
	end

	routeCache[gate] = waypoints
	return waypoints
end

local function step(dt: number)
	for part, c in active do
		local target = c.waypoints[c.nextWaypoint]
		if not target then
			c.onArrive(c)
			Creatures.remove(c)
			continue
		end

		local pos = part.Position
		local flatTarget = Vector3.new(target.X, pos.Y, target.Z)
		local delta = flatTarget - pos
		local stepLen = c.speed * dt
		if delta.Magnitude <= stepLen then
			part.Position = flatTarget
			c.nextWaypoint += 1
		else
			part.CFrame = CFrame.lookAt(pos + delta.Unit * stepLen, flatTarget)
		end
	end
end

function Creatures.spawn(
	archetype: string,
	health: number,
	coins: number,
	gate: Part,
	goal: Vector3,
	arriveDistance: number,
	onDeath: (Creature, number?) -> (),
	onArrive: (Creature) -> ()
): Creature
	local def = Enemies.get(archetype)
	local size = Vector3.new(def.size[1], def.size[2], def.size[3])

	local part = Instance.new("Part")
	part.Name = archetype
	part.Size = size
	part.Anchored = true
	part.CanCollide = false
	part.Color = Color3.fromRGB(def.color[1], def.color[2], def.color[3])
	part.Position = gate.Position + Vector3.new(0, size.Y / 2 - gate.Size.Y / 2, 0)
	part:SetAttribute("Health", health)
	part:SetAttribute("MaxHealth", health)
	part:SetAttribute("Archetype", archetype)
	part.Parent = gate.Parent

	-- Stop short of the Town Hall's surface rather than its centre.
	local waypoints = table.clone(routeFrom(gate, goal))
	local last = waypoints[#waypoints]
	local toGoal = Vector3.new(goal.X - last.X, 0, goal.Z - last.Z)
	if toGoal.Magnitude > arriveDistance then
		waypoints[#waypoints] = goal - toGoal.Unit * arriveDistance
	end

	local creature: Creature = {
		part = part,
		archetype = archetype,
		health = health,
		speed = def.speed,
		damage = def.damage,
		coins = coins,
		waypoints = waypoints,
		nextWaypoint = 1,
		lastHitBy = nil,
		onDeath = onDeath,
		onArrive = onArrive,
	}
	active[part] = creature

	-- Studio-only stand-in for a gun until Combat lands: click a creature to hit it for 10.
	if RunService:IsStudio() then
		local click = Instance.new("ClickDetector")
		click.MaxActivationDistance = 60
		click.MouseClick:Connect(function(player)
			Creatures.damage(creature, 10, player.UserId)
		end)
		click.Parent = part
	end

	if not heartbeat then
		heartbeat = RunService.Heartbeat:Connect(step)
	end
	return creature
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
	end
end

function Creatures.remove(creature: Creature)
	active[creature.part] = nil
	creature.part:Destroy()
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
	table.clear(routeCache)
	if heartbeat then
		heartbeat:Disconnect()
		heartbeat = nil
	end
end

return Creatures
