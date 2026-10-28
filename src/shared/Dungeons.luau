-- Dungeon (map) list. Pure data so Lune can test unlock rules. Order is unlock order.
-- Creature family ids match showcase/catalog.js; props kits are the asset folders for the map.

export type Dungeon = {
	id: string,
	name: string,
	unlockLevel: number,
	family: string,
	lanes: number,
	gimmick: string,
}

local Dungeons = {}

local list: { Dungeon } = {
	{
		id = "Graveyard",
		name = "Graveyard",
		unlockLevel = 1,
		family = "skeletons",
		lanes = 3,
		gimmick = "Fog rolls in on boss waves, cutting sight lines",
	},
	{
		id = "Farm",
		name = "Haunted Farm",
		unlockLevel = 3,
		family = "farm",
		lanes = 2,
		gimmick = "Hay bales can be pushed into lanes as cover; animals trample them",
	},
	{
		id = "Swamp",
		name = "Swamp",
		unlockLevel = 5,
		family = "swamp",
		lanes = 2,
		gimmick = "Shallow water slows everyone; ice spells freeze it solid",
	},
	{
		id = "Sewer",
		name = "Sewer",
		unlockLevel = 10,
		family = "slimes",
		lanes = 3,
		gimmick = "Slimes split in two when killed above half health",
	},
	{
		id = "Village",
		name = "Bandit Village",
		unlockLevel = 15,
		family = "bandits",
		lanes = 4,
		gimmick = "Bandits loot dropped coins before you can",
	},
	{
		id = "Frozen",
		name = "Frozen Cavern",
		unlockLevel = 20,
		family = "frozen",
		lanes = 2,
		gimmick = "Everything is slippery; freeze spells last twice as long",
	},
	{
		id = "Jungle",
		name = "Jungle Temple",
		unlockLevel = 25,
		family = "jungle",
		lanes = 3,
		gimmick = "Vines block sight lines until burned away",
	},
	{
		id = "Pirate",
		name = "Pirate Cove",
		unlockLevel = 30,
		family = "pirates",
		lanes = 3,
		gimmick = "Cannons on the cliffs can be captured and fired at the lanes",
	},
	{
		id = "Factory",
		name = "Factory",
		unlockLevel = 35,
		family = "invaders",
		lanes = 4,
		gimmick = "Conveyor belts move anything on them, including grenades",
	},
	{
		id = "Station",
		name = "Space Station",
		unlockLevel = 40,
		family = "aliens",
		lanes = 4,
		gimmick = "Airlocks vent a lane for 5 s when opened",
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
