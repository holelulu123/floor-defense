-- Dungeon (map) list. Pure data so Lune can test unlock rules. Order is unlock order.
-- Creature family ids match showcase/catalog.js; props kits are the asset folders for the map.
-- One dungeon unlocks per level (1..10): the XP curve grows x3 per level, so wider gaps would mean an
-- absurd grind in the previous dungeon.

export type Dungeon = {
	id: string,
	name: string,
	unlockLevel: number,
	family: string,
	lanes: number,
	gimmick: string,
	-- Creature health and Town Hall damage multiplier (Graveyard 1.0, x1.35 per dungeon after it).
	difficulty: number,
	-- End-of-run reward multipliers (Progression.xpForRun / diamondsForRun). XP grows about x3 per dungeon
	-- to keep up with the level curve; Diamonds grow gently so classes keep their price.
	xpMultiplier: number,
	diamondMultiplier: number,
}

local Dungeons = {}

local list: { Dungeon } = {
	{
		id = "Graveyard",
		name = "Graveyard",
		unlockLevel = 1,
		family = "graveyard",
		lanes = 1,
		gimmick = "Fog rolls in on boss waves, cutting sight lines",
		difficulty = 1.0,
		xpMultiplier = 1,
		diamondMultiplier = 1,
	},
	{
		id = "Farm",
		name = "Haunted Farm",
		unlockLevel = 2,
		family = "farm",
		lanes = 1,
		gimmick = "Hay bales can be pushed into lanes as cover; animals trample them",
		difficulty = 1.35,
		xpMultiplier = 1.5,
		diamondMultiplier = 1.25,
	},
	{
		id = "Swamp",
		name = "Swamp",
		unlockLevel = 3,
		family = "swamp",
		lanes = 1,
		gimmick = "Shallow water slows everyone; ice spells freeze it solid",
		difficulty = 1.82,
		xpMultiplier = 3.5,
		diamondMultiplier = 1.5,
	},
	{
		id = "Sewer",
		name = "Sewer",
		unlockLevel = 4,
		family = "sewer",
		lanes = 1,
		gimmick = "Slimes split in two when killed above half health",
		difficulty = 2.46,
		xpMultiplier = 10,
		diamondMultiplier = 1.75,
	},
	{
		id = "Village",
		name = "Bandit Village",
		unlockLevel = 5,
		family = "village",
		lanes = 1,
		gimmick = "Bandits loot dropped coins before you can",
		difficulty = 3.32,
		xpMultiplier = 30,
		diamondMultiplier = 2,
	},
	{
		id = "Frozen",
		name = "Frozen Cavern",
		unlockLevel = 6,
		family = "frozen",
		lanes = 1,
		gimmick = "Everything is slippery; freeze spells last twice as long",
		difficulty = 4.48,
		xpMultiplier = 90,
		diamondMultiplier = 2.5,
	},
	{
		id = "Jungle",
		name = "Jungle Temple",
		unlockLevel = 7,
		family = "jungle",
		lanes = 1,
		gimmick = "Vines block sight lines until burned away",
		difficulty = 6.05,
		xpMultiplier = 270,
		diamondMultiplier = 3,
	},
	{
		id = "Pirate",
		name = "Pirate Cove",
		unlockLevel = 8,
		family = "pirate",
		lanes = 1,
		gimmick = "Cannons on the cliffs can be captured and fired at the lanes",
		difficulty = 8.17,
		xpMultiplier = 810,
		diamondMultiplier = 3.5,
	},
	{
		id = "Factory",
		name = "Factory",
		unlockLevel = 9,
		family = "factory",
		lanes = 1,
		gimmick = "Conveyor belts move anything on them, including grenades",
		difficulty = 11.03,
		xpMultiplier = 2430,
		diamondMultiplier = 4,
	},
	{
		id = "Station",
		name = "Space Station",
		unlockLevel = 10,
		family = "station",
		lanes = 1,
		gimmick = "Airlocks vent a lane for 5 s when opened",
		difficulty = 14.89,
		xpMultiplier = 7290,
		diamondMultiplier = 5,
	},
}
Dungeons.List = list

function Dungeons.get(id: string): Dungeon
	for _, d in Dungeons.List do
		if d.id == id then
			return d
		end
	end
	error(`Unknown dungeon {id}`)
end

-- Ratio between one dungeon's difficulty and the previous one's (the table above is this, rounded).
Dungeons.DifficultyStep = 1.35

-- Position in unlock order (1 = Graveyard), or nil for an unknown id.
function Dungeons.indexOf(id: any): number?
	for i, d in Dungeons.List do
		if d.id == id then
			return i
		end
	end
	return nil
end

function Dungeons.isUnlocked(id: string, level: number): boolean
	return level >= Dungeons.get(id).unlockLevel
end

function Dungeons.unlockedFor(level: number): { Dungeon }
	local out = {}
	for _, d in Dungeons.List do
		if level >= d.unlockLevel then
			table.insert(out, d)
		end
	end
	return out
end

-- The next dungeon a player will unlock, or nil at the end of the list.
function Dungeons.nextUnlock(level: number): Dungeon?
	for _, d in Dungeons.List do
		if level < d.unlockLevel then
			return d
		end
	end
	return nil
end

return Dungeons
