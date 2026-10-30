-- Weapon definitions and fire-rate rules. Pure data and math so Lune tests can load it.
-- The server enforces these numbers; the client only uses them for feel (local cooldown, crosshair).

export type Weapon = {
	name: string,
	damage: number,
	fireRate: number, -- shots per second
	range: number, -- studs
	automatic: boolean,
	melee: boolean?, -- short range swing; the raycast is still the hit test
	splash: number?, -- studs of area damage around the impact point
	burn: number?, -- seconds a hit creature keeps burning (BurnUntil attribute)
}

local Weapons = {}

Weapons.Definitions = {
	AssaultRifle = {
		name = "AssaultRifle",
		damage = 10,
		fireRate = 8,
		range = 250,
		automatic = true,
	},
	Shotgun = {
		name = "Shotgun",
		damage = 40,
		fireRate = 1.5,
		range = 60,
		automatic = false,
	},
	DualPistols = {
		name = "DualPistols",
		damage = 12,
		fireRate = 6,
		range = 150,
		automatic = false,
	},
	-- Class weapons (Classes.luau `weapon` field). Melee swings have a short range.
	Carbine = { name = "Carbine", damage = 14, fireRate = 5, range = 200, automatic = true },
	SMG = { name = "SMG", damage = 6, fireRate = 12, range = 120, automatic = true },
	Flamethrower = { name = "Flamethrower", damage = 4, fireRate = 15, range = 25, automatic = true, burn = 2 },
	BoltRifle = { name = "BoltRifle", damage = 60, fireRate = 0.8, range = 400, automatic = false },
	GrenadeLauncher = {
		name = "GrenadeLauncher",
		damage = 50,
		fireRate = 1,
		range = 150,
		automatic = false,
		splash = 8,
	},
	Flail = { name = "Flail", damage = 25, fireRate = 1.5, range = 10, automatic = true, melee = true },
	GreatAxe = { name = "GreatAxe", damage = 45, fireRate = 1.2, range = 10, automatic = true, melee = true },
	Staff = { name = "Staff", damage = 20, fireRate = 2, range = 150, automatic = false },
	Wand = { name = "Wand", damage = 10, fireRate = 4, range = 120, automatic = true },
}

-- How much earlier than the nominal interval a shot may arrive before the server rejects it.
-- Covers network jitter without letting a modified client double its fire rate.
Weapons.RateTolerance = 0.8

function Weapons.get(name: string): Weapon
	local def = Weapons.Definitions[name]
	assert(def, `Unknown weapon {name}`)
	return def
end

function Weapons.interval(def: Weapon): number
	return 1 / def.fireRate
end

-- Server-side check: may a weapon that last fired at `lastFiredAt` fire again at `now`?
-- `rateMult` > 1 (skill buffs) shortens the interval.
function Weapons.canFire(def: Weapon, lastFiredAt: number?, now: number, rateMult: number?): boolean
	if lastFiredAt == nil then
		return true
	end
	return now - lastFiredAt >= Weapons.interval(def) / (rateMult or 1) * Weapons.RateTolerance
end

return Weapons
