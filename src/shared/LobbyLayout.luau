-- Lobby hub layout in studs. Pure and deterministic (no Roblox APIs) so Lune can test it and the
-- server builds exactly the hub the showcase draws (`showLobby` in showcase/index.html).
--
-- Scale: the showcase lobby is a 420 m grass disc with the dungeon ring at 165 m. The game uses the
-- same 1.4 studs per metre as Lane.luau, so the field is 588 studs across its radius, the dungeon
-- ring sits at 231 studs and the pad ring at 189: a 12 second walk from the spawn plaza to a pad at
-- the default walk speed, which keeps the hub big enough for the arc of ten dioramas without feeling
-- empty. Pads are wider apart than in the showcase (14 studs instead of 11) so a Squad pad has room
-- for four characters.
--
-- Axes: +x is east, -z is "far" (the direction a freshly spawned character faces). The dungeon arc
-- runs from the west (-170 degrees) round the far side to the east (-10 degrees) in unlock order;
-- the Scoreboard, Shop and reserved plots sit on the near (+z) side.

local Dungeons = require(script and script.Parent.Dungeons or "./Dungeons")

local LobbyLayout = {}

export type Mode = { mode: string, capacity: number, countdown: number }
export type PadDef = {
	dungeonId: string,
	mode: string,
	capacity: number,
	countdown: number,
	position: { number }, -- { x, y, z } with y the ground top
}
export type Plot = {
	dungeonId: string,
	index: number,
	angle: number, -- radians
	x: number,
	z: number,
	ux: number, -- radial unit vector (plaza -> plot)
	uz: number,
	tx: number, -- tangential unit vector (anticlockwise along the arc)
	tz: number,
}
export type Zone =
	{ id: string, title: string, subtitle: string, x: number, z: number, radius: number, square: boolean }

LobbyLayout.StudsPerMetre = 1.4

local M = LobbyLayout.StudsPerMetre

LobbyLayout.FieldRadius = 420 * M -- 588
LobbyLayout.RingRadius = 165 * M -- 231, diorama centres
LobbyLayout.PadRingRadius = 135 * M -- 189, every dungeon's pad trio
LobbyLayout.PlazaRadius = 30 * M -- 42
LobbyLayout.SpokeStart = 28 * M -- dungeon paths begin at the plaza edge
LobbyLayout.SpokeEnd = (165 - 18) * M -- and stop at the diorama's near edge
LobbyLayout.ArcStart = math.rad(-170)
LobbyLayout.ArcEnd = math.rad(-10)
LobbyLayout.Diorama = { width = 44 * M, depth = 34 * M } -- 61.6 x 47.6, tangential x radial
LobbyLayout.PadSpacing = 14
LobbyLayout.PadRadius = 5
LobbyLayout.PathWidth = 5 * M
LobbyLayout.ZonePathWidth = 6 * M
LobbyLayout.RingRoadWidth = 7 * M

-- Pad kinds in front of every dungeon. Mode names must match Waves.Modes.
LobbyLayout.Modes = {
	{ mode = "Solo", capacity = 1, countdown = 5 },
	{ mode = "Duo", capacity = 2, countdown = 10 },
	{ mode = "Squad", capacity = 4, countdown = 15 },
} :: { Mode }

LobbyLayout.Zones = {
	{
		id = "Scoreboard",
		title = "SCOREBOARD",
		subtitle = "Hall of Fame",
		x = -100 * M,
		z = 55 * M,
		radius = 24 * M,
		square = false,
	},
	{
		id = "Shop",
		title = "SHOP & CLASSES",
		subtitle = "gear, skins, class select",
		x = 100 * M,
		z = 55 * M,
		radius = 24 * M,
		square = false,
	},
	{
		id = "Reserved1",
		title = "RESERVED",
		subtitle = "future feature",
		x = -115 * M,
		z = 120 * M,
		radius = 13 * M,
		square = true,
	},
	{
		id = "Reserved2",
		title = "RESERVED",
		subtitle = "future feature",
		x = 115 * M,
		z = 120 * M,
		radius = 13 * M,
		square = true,
	},
	{
		id = "Reserved3",
		title = "RESERVED",
		subtitle = "future feature",
		x = 0,
		z = 135 * M,
		radius = 13 * M,
		square = true,
	},
} :: { Zone }

-- Each dungeon's accent colour (RGB 0-255): its light pillar and sign in the lobby. All distinct and bright enough
-- to read against the sky from the spawn plaza.
LobbyLayout.Accents = {
	Graveyard = { 150, 110, 255 },
	Farm = { 255, 220, 80 },
	Swamp = { 110, 205, 90 },
	Sewer = { 190, 255, 60 },
	Village = { 255, 145, 60 },
	Frozen = { 170, 240, 255 },
	Jungle = { 40, 230, 170 },
	Pirate = { 40, 160, 255 },
	Factory = { 255, 70, 50 },
	Station = { 235, 90, 255 },
} :: { [string]: { number } }

function LobbyLayout.accent(dungeonId: string): { number }
	return LobbyLayout.Accents[dungeonId] or { 255, 180, 84 }
end

function LobbyLayout.mode(name: string): Mode
	for _, m in LobbyLayout.Modes do
		if m.mode == name then
			return m
		end
	end
	error(`Unknown mode {name}`)
end

-- Where dungeon `index` of `count` sits on the arc.
function LobbyLayout.plot(index: number, count: number?): Plot
	local n = count or #Dungeons.List
	local t = if n > 1 then (index - 1) / (n - 1) else 0.5
	local a = LobbyLayout.ArcStart + (LobbyLayout.ArcEnd - LobbyLayout.ArcStart) * t
	local ux, uz = math.cos(a), math.sin(a)
	return {
		dungeonId = Dungeons.List[index].id,
		index = index,
		angle = a,
		x = ux * LobbyLayout.RingRadius,
		z = uz * LobbyLayout.RingRadius,
		ux = ux,
		uz = uz,
		tx = -uz,
		tz = ux,
	}
end

function LobbyLayout.plots(): { Plot }
	local out = {}
	for i in Dungeons.List do
		out[i] = LobbyLayout.plot(i)
	end
	return out
end

-- Pad position for a dungeon plot and a mode index (1..#Modes), centred on the pad ring.
function LobbyLayout.padPosition(plot: Plot, modeIndex: number): (number, number)
	local offset = (modeIndex - (#LobbyLayout.Modes + 1) / 2) * LobbyLayout.PadSpacing
	local x = plot.ux * LobbyLayout.PadRingRadius + plot.tx * offset
	local z = plot.uz * LobbyLayout.PadRingRadius + plot.tz * offset
	return x, z
end

-- Every pad in the lobby: one per dungeon per mode, in dungeon unlock order then mode order.
function LobbyLayout.pads(): { PadDef }
	local out: { PadDef } = {}
	for _, plot in LobbyLayout.plots() do
		for j, m in LobbyLayout.Modes do
			local x, z = LobbyLayout.padPosition(plot, j)
			table.insert(out, {
				dungeonId = plot.dungeonId,
				mode = m.mode,
				capacity = m.capacity,
				countdown = m.countdown,
				position = { x, 0, z },
			})
		end
	end
	return out
end

function LobbyLayout.inField(x: number, z: number): boolean
	return x * x + z * z <= LobbyLayout.FieldRadius * LobbyLayout.FieldRadius
end

return LobbyLayout
