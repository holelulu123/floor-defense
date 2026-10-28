-- Weapon definitions and fire-rate rules. Pure data and math so Lune tests can load it.
-- The server enforces these numbers; the client only uses them for feel (local cooldown, crosshair).

export type Weapon = {
	name: string,
	damage: number,
	fireRate: number, -- shots per second
	range: number, -- studs
	automatic: boolean,
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
function Weapons.canFire(def: Weapon, lastFiredAt: number?, now: number): boolean
	if lastFiredAt == nil then
		return true
	end
	return now - lastFiredAt >= Weapons.interval(def) * Weapons.RateTolerance
end

return Weapons
