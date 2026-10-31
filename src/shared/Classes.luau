-- Class list: health, primary weapon, optional melee secondary, passive and two skills each. Pure data so
-- Lune can test the unlock rules.
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
	cost: number, -- diamonds; 0 when free
	role: string,
	maxHealth: number, -- Humanoid MaxHealth while playing this class
	weapon: string, -- slot 1 (key 1), key into Weapons.Definitions
	secondary: string?, -- slot 2 (key 2), a melee weapon; nil when the class has none (Tank)
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
		maxHealth = 120,
		weapon = "AssaultRifle",
		secondary = "CombatKnife",
		passive = "+10% reload speed",
		skills = { skill("BurstFire", "Burst Fire", 6, 1), skill("AmmoCrate", "Ammo Crate", 45, 10) },
	},
	{
		id = "Tank",
		free = true,
		cost = 0,
		role = "Blocker",
		maxHealth = 220,
		weapon = "Flail",
		passive = "Creatures cannot push past you",
		skills = { skill("FlailSweep", "Flail Sweep", 5, 1), skill("IronWall", "Iron Wall", 30, 8) },
	},
	{
		id = "Scout",
		free = true,
		cost = 0,
		role = "Mobility",
		maxHealth = 90,
		weapon = "DualPistols",
		secondary = "Karambit",
		passive = "+20% move speed",
		skills = { skill("Dash", "Dash", 4), skill("MarkTarget", "Mark Target", 25, 8) },
	},
	{
		id = "Medic",
		free = true,
		cost = 0,
		role = "Support",
		maxHealth = 110,
		weapon = "SMG",
		secondary = "Scalpel",
		passive = "Repairs the Town Hall 2x faster",
		skills = { skill("RepairPulse", "Repair Pulse", 8), skill("Overcharge", "Overcharge", 40, 6) },
	},
	{
		id = "Engineer",
		free = true,
		cost = 0,
		role = "Area control",
		maxHealth = 120,
		weapon = "Shotgun",
		secondary = "Hammer",
		passive = "Melee hits on a turret repair it",
		skills = { skill("PlaceTurret", "Place Turret", 10), skill("Overclock", "Overclock", 30, 10) },
	},
	{
		id = "Berserker",
		free = false,
		cost = 1200,
		role = "Melee damage",
		maxHealth = 170,
		weapon = "GreatAxe",
		secondary = "Sword",
		passive = "Kills heal 5 HP; melee +25%",
		skills = { skill("Cleave", "Cleave", 4, 1), skill("Rage", "Rage", 30, 10) },
	},
	{
		id = "Mage",
		free = false,
		cost = 1200,
		role = "Crowd control",
		maxHealth = 90,
		weapon = "Staff",
		secondary = "Dagger",
		passive = "Spells cost 25% less; freeze lasts 25% longer",
		skills = { skill("ArcaneBolt", "Arcane Bolt", 2), skill("FrostNova", "Frost Nova", 25, 3) },
	},
	{
		id = "Pyro",
		free = false,
		cost = 1500,
		role = "Area damage",
		maxHealth = 130,
		weapon = "Flamethrower",
		secondary = "Machete",
		passive = "Burning creatures take +15% damage",
		skills = { skill("FlameSweep", "Flame Sweep", 7, 2), skill("FireWall", "Fire Wall", 40, 8) },
	},
	{
		id = "Sniper",
		free = false,
		cost = 1500,
		role = "Boss killer",
		maxHealth = 85,
		weapon = "BoltRifle",
		secondary = "CombatKnife",
		passive = "+50% headshot damage",
		skills = { skill("PiercingShot", "Piercing Shot", 8), skill("Overwatch", "Overwatch", 35, 10) },
	},
	{
		id = "Demolisher",
		free = false,
		cost = 2000,
		role = "Burst",
		maxHealth = 120,
		weapon = "GrenadeLauncher",
		secondary = "Hatchet",
		passive = "+2 grenades; explosions 20% wider",
		skills = { skill("FragToss", "Frag Toss", 6), skill("ClusterBomb", "Cluster Bomb", 45, 1) },
	},
}
Classes.List = list

-- Engineer turret rules shared by server and UI.
Classes.Turrets = { MaxPlaced = 3, RepairPerHit = 0.25, OverclockRate = 2 }

-- Keybinds shown in the HUD; the client sends the skill index, never the key.
Classes.SkillKeys = { "Q", "E" }
-- Weapon slots: 1 = primary, 2 = melee secondary. The client sends the slot number; R reloads.
Classes.WeaponKeys = { "1", "2" }
Classes.ReloadKey = "R"

-- Class by id, or nil for an unknown id (use for values that came from a client).
function Classes.find(id: any): Class?
	if type(id) ~= "string" then
		return nil
	end
	for _, c in Classes.List do
		if c.id == id then
			return c
		end
	end
	return nil
end

function Classes.get(id: string): Class
	return Classes.find(id) or error(`Unknown class {id}`)
end

-- A class is playable when it is free or the player owns it.
function Classes.isOwned(id: string, owned: { string }): boolean
	if Classes.get(id).free then
		return true
	end
	return table.find(owned, id) ~= nil
end

-- Returns the diamonds left after buying, or nil (and a reason) when the purchase is not possible.
function Classes.tryBuy(id: string, diamonds: number, owned: { string }): (number?, string?)
	local class = Classes.get(id)
	if Classes.isOwned(id, owned) then
		return nil, "already owned"
	end
	if diamonds < class.cost then
		return nil, "not enough diamonds"
	end
	return diamonds - class.cost, nil
end

-- Weapon definition name for a class (key into Weapons.Definitions).
function Classes.weaponFor(id: string): string
	return Classes.get(id).weapon
end

-- Weapon name in a slot (1 primary, 2 secondary), or nil when the class has nothing there or the
-- slot is not 1 or 2 (use for values that came from a client).
function Classes.weaponInSlot(id: string, slot: any): string?
	local class = Classes.get(id)
	if slot == 1 then
		return class.weapon
	elseif slot == 2 then
		return class.secondary
	end
	return nil
end

-- Ids of every class the player may pick (free ones plus purchases).
function Classes.playable(owned: { string }): { string }
	local ids = {}
	for _, c in Classes.List do
		if Classes.isOwned(c.id, owned) then
			table.insert(ids, c.id)
		end
	end
	return ids
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
