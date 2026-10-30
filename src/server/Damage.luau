-- The one place every weapon, skill, turret and pet goes through to hurt a creature. Applies the
-- status multipliers (MarkedUntil, BurnUntil attributes) and then calls Creatures.damage, which
-- stays the only function that lowers creature health.

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Skills = require(ReplicatedStorage.Shared.Skills)
local Creatures = require(script.Parent.Creatures)

local Damage = {}

function Damage.hit(creature: Creatures.Creature, amount: number, byUserId: number?)
	local part = creature.part
	local mult = Skills.damageTakenMultiplier({
		MarkedUntil = part:GetAttribute("MarkedUntil") :: number?,
		BurnUntil = part:GetAttribute("BurnUntil") :: number?,
	}, os.clock())
	Creatures.damage(creature, amount * mult, byUserId)
end

-- Sets a creature on fire: it takes Skills.BurnDamagePerSecond from the server tick and extra damage
-- from everyone (Pyro passive). `byUserId` gets the kill credit for burn ticks.
function Damage.burn(creature: Creatures.Creature, seconds: number, byUserId: number?)
	local part = creature.part
	local now = os.clock()
	part:SetAttribute("BurnUntil", math.max(part:GetAttribute("BurnUntil") :: number? or 0, now + seconds))
	if byUserId then
		part:SetAttribute("BurnBy", byUserId)
	end
end

-- Every live creature. Prefers Creatures.all when the creature module exposes it; otherwise scans
-- the workspace for parts the creature registry knows. Cached for the current frame because skills
-- and turrets often ask several times in one step.
local cachedAt = -1
local cached: { Creatures.Creature } = {}

function Damage.creatures(): { Creatures.Creature }
	local now = os.clock()
	if now == cachedAt then
		return cached
	end
	cachedAt = now
	local list = {}
	local all = (Creatures :: any).all
	if type(all) == "function" then
		for _, c in all() do
			table.insert(list, c)
		end
	else
		for _, inst in Workspace:GetDescendants() do
			if inst:IsA("BasePart") then
				local c = Creatures.get(inst)
				if c then
					table.insert(list, c)
				end
			end
		end
	end
	cached = list
	return list
end

function Damage.positions(list: { Creatures.Creature }): { Skills.Position }
	local out: { Skills.Position } = table.create(#list)
	for i, c in list do
		out[i] = c.part.Position
	end
	return out
end

-- Damage to everything within `radius` of `center`. Returns the number of creatures hit.
function Damage.area(center: Vector3, radius: number, amount: number, byUserId: number?): number
	local list = Damage.creatures()
	local hits = Skills.inRadius(center, Damage.positions(list), radius)
	for _, i in hits do
		Damage.hit(list[i], amount, byUserId)
	end
	return #hits
end

-- Nearest creature to `point` within `range`, if any.
function Damage.nearest(point: Vector3, range: number): Creatures.Creature?
	local best, bestDist = nil, range
	for _, c in Damage.creatures() do
		local d = (c.part.Position - point).Magnitude
		if d <= bestDist then
			best, bestDist = c, d
		end
	end
	return best
end

return Damage
