-- Class list: weapon, passive and two skills each. Pure data so Lune can test the unlock rules.
-- Mirrors showcase/catalog.js CLASSES (which also carries the preview rig and animation names).

export type Skill = {
	id: string,
	name: string,
	cooldown: number, -- seconds
	duration: number, -- seconds the effect lasts; 0 for instant
}

export type Class = {
	id: string,
	free: boolean,
	cost: number, -- gems; 0 when free
	role: string,
	weapon: string,
	passive: string,
	skills: { Skill },
}

local Classes = {}

local function skill(id: string, name: string, cooldown: number, duration: number?): Skill
	return { id = id, name = name, cooldown = cooldown, duration = duration or 0 }
end

local list: { Class } = {
	{
		id = "Trooper",
		free = true,
		cost = 0,
		role = "All-rounder",
		weapon = "AssaultRifle",
		passive = "+10% reload speed",
		skills = { skill("BurstFire", "Burst Fire", 6, 1), skill("AmmoCrate", "Ammo Crate", 45, 10) },
	},
	{
		id = "Tank",
		free = true,
		cost = 0,
		role = "Blocker",
		weapon = "Flail",
		passive = "Creatures cannot push past you; +50% max health",
		skills = { skill("FlailSweep", "Flail Sweep", 5, 1), skill("IronWall", "Iron Wall", 30, 8) },
	},
	{
		id = "Scout",
		free = true,
		cost = 0,
		role = "Mobility",
		weapon = "DualPistols",
		passive = "+20% move speed",
		skills = { skill("Dash", "Dash", 4), skill("MarkTarget", "Mark Target", 25, 8) },
	},
	{
		id = "Medic",
		free = true,
		cost = 0,
		role = "Support",
		weapon = "SMG",
		passive = "Repairs the Town Hall 2x faster",
		skills = { skill("RepairPulse", "Repair Pulse", 8), skill("Overcharge", "Overcharge", 40, 6) },
	},
	{
		id = "Engineer",
		free = true,
		cost = 0,
		role = "Area control",
		weapon = "Carbine",
		passive = "Melee on a turret repairs it",
		skills = { skill("PlaceTurret", "Place Turret", 10), skill("Overclock", "Overclock", 30, 10) },
	},
	{
		id = "Berserker",
		free = false,
		cost = 1200,
		role = "Melee damage",
		weapon = "GreatAxe",
		passive = "Kills heal 5 HP; melee +25%",
		skills = { skill("Cleave", "Cleave", 4, 1), skill("Rage", "Rage", 30, 10) },
	},
	{
		id = "Mage",
		free = false,
		cost = 1200,
		role = "Crowd control",
		weapon = "Staff",
		passive = "Spells cost 25% less; freeze lasts 25% longer",
		skills = { skill("ArcaneBolt", "Arcane Bolt", 2), skill("FrostNova", "Frost Nova", 25, 3) },
	},
	{
		id = "Pyro",
		free = false,
		cost = 1500,
		role = "Area damage",
		weapon = "Flamethrower",
		passive = "Burning creatures take +15% damage",
		skills = { skill("FlameSweep", "Flame Sweep", 7, 2), skill("FireWall", "Fire Wall", 40, 8) },
	},
	{
		id = "Sniper",
		free = false,
		cost = 1500,
		role = "Boss killer",
		weapon = "BoltRifle",
		passive = "+50% headshot damage",
		skills = { skill("PiercingShot", "Piercing Shot", 8), skill("Overwatch", "Overwatch", 35, 10) },
	},
	{
		id = "Demolisher",
		free = false,
		cost = 2000,
		role = "Burst",
		weapon = "GrenadeLauncher",
		passive = "+2 grenades; explosions 20% wider",
		skills = { skill("FragToss", "Frag Toss", 6), skill("ClusterBomb", "Cluster Bomb", 45, 1) },
	},
	{
		id = "Summoner",
		free = false,
		cost = 2500,
		role = "Pet",
		weapon = "Wand",
		passive = "Starts with a pet that attacks the nearest creature",
		skills = { skill("PetPounce", "Pet Pounce", 5, 1), skill("Enrage", "Enrage", 45, 8) },
	},
}
Classes.List = list

-- Engineer turret rules shared by server and UI.
Classes.Turrets = { MaxPlaced = 3, RepairPerHit = 0.25, OverclockRate = 2 }

function Classes.get(id: string): Class
	for _, c in Classes.List do
		if c.id == id then
			return c
		end
	end
	error(`Unknown class {id}`)
end

-- A class is playable when it is free or the player owns it.
function Classes.isOwned(id: string, owned: { string }): boolean
	if Classes.get(id).free then
		return true
	end
	return table.find(owned, id) ~= nil
end

-- Returns the gems left after buying, or nil (and a reason) when the purchase is not possible.
function Classes.tryBuy(id: string, gems: number, owned: { string }): (number?, string?)
	local class = Classes.get(id)
	if Classes.isOwned(id, owned) then
		return nil, "already owned"
	end
	if gems < class.cost then
		return nil, "not enough gems"
	end
	return gems - class.cost, nil
end

-- Skill cooldown bookkeeping: `used` maps skill id -> time it was last used.
function Classes.canUse(classId: string, skillIndex: number, used: { [string]: number }, now: number): (boolean, number)
	local s = Classes.get(classId).skills[skillIndex]
	local last = used[s.id]
	if last == nil then
		return true, 0
	end
	local left = s.cooldown - (now - last)
	return left <= 0, math.max(0, left)
end

return Classes
