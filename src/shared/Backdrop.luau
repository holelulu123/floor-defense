-- Mountains, hills and low mounds around the lobby field and each dungeon arena, as a list of Terrain fill
-- operations. Pure and deterministic (no Roblox APIs) so Lune can test the clearances; src/server/Backdrop.luau
-- turns each shape into a Terrain:FillBall / FillBlock / FillWedge / ReplaceMaterial call.
--
-- Coordinates: the lobby plan is in world studs (field centre at the origin); arena plans are arena-local (the
-- arena floor centre at the origin, z from the gate edge toward the tower edge, like Lane.luau) and the server adds
-- Arena.Origin. The playable floors have their top at y = 0; the HorizonGround planes (Environment.server.luau)
-- have theirs at y = -4, so every range shape is sunk below -4 and nothing here has a flat top at 0 or -4.
--
-- Rules the spec checks:
-- * Range shapes never rise above y = 0 within FieldClearance of the lobby field or ArenaClearance of the arena
--   floor rectangle, so terrain never covers a playable surface or stands between the lane and the camera.
-- * Every arena shape stays inside ArenaBounds (arena-local), which is what the server clears with Air before the
--   next dungeon's backdrop; no lobby shape reaches into ArenaBounds (moved to Backdrop.ArenaOrigin), so clearing
--   an arena never eats a lobby mountain.
-- * Mounds on the arena floor keep MoundLaneClearance studs from every lane segment and clear of the tower.

local Lane = require(script and script.Parent.Lane or "./Lane")
local LobbyLayout = require(script and script.Parent.LobbyLayout or "./LobbyLayout")

local Backdrop = {}

export type Shape = {
	kind: string, -- "ball" | "block" | "wedge" | "snow"
	tag: string, -- "range" | "rim" | "skirt" | "water" | "mound"
	material: string, -- Enum.Material name ("Air" carves)
	x: number,
	y: number,
	z: number,
	radius: number?, -- ball; snow: half width of the square region
	size: { number }?, -- block / wedge: { sx, sy, sz } before rotation
	yaw: number?, -- radians about +Y, then
	tilt: number?, -- radians about the rotated +X
	top: number?, -- snow: region top (y is its bottom)
	from: { string }?, -- snow: materials replaced by `material`
}

export type Style = {
	near: string, -- feature kind of the near row: "hill" | "peak" | "crag" | "cliff" | "crater"
	far: string,
	base: { string }, -- one picked per feature
	accent: string, -- outcrops, spires, talus
	ground: string, -- floor skirt and mounds on the floor
	nearHeight: { number }, -- { min, max } studs above the floor top
	farHeight: { number },
	snow: string?, -- material above the snow line on features whose base is not already this
	snowLine: number?, -- fraction of the feature height
	water: boolean?, -- a shallow sea between the floor and the ranges
}

-- Lane.Point / Lane.Layout, restated: the dual-path require above hides Lane's exported types from the checker.
type Point = { x: number, z: number }
type LaneLayout = { points: { Point }, tower: Point }

export type Box = { minX: number, maxX: number, minY: number, maxY: number, minZ: number, maxZ: number }

Backdrop.Ground = -4 -- HorizonGround top
Backdrop.FieldClearance = 20 -- lobby ranges stay this far beyond the field rim above y = 0
Backdrop.ArenaClearance = 12 -- arena ranges stay this far beyond the floor edge above y = 0
Backdrop.MoundLaneClearance = 25
Backdrop.MoundTowerClearance = 55
Backdrop.LobbyMaxRadius = 1350 -- streaming: keep the lobby ranges within about StreamingTargetRadius
Backdrop.ArenaOrigin = { x = 0, z = 1500 } -- must match Arena.Origin (the server asserts it)
-- Everything an arena backdrop may touch, arena-local. Short on the gate (-z) side, which faces the lobby, so the
-- lobby ring keeps its southern mountains.
Backdrop.ArenaBounds = {
	minX = -Lane.Arena.width / 2 - 600,
	maxX = Lane.Arena.width / 2 + 600,
	minY = -300,
	maxY = 500,
	minZ = -Lane.Arena.depth / 2 - 260,
	maxZ = Lane.Arena.depth / 2 + 600,
} :: Box

Backdrop.TerrainMaterials = {
	"Air",
	"Asphalt",
	"Basalt",
	"Brick",
	"Cobblestone",
	"Concrete",
	"CrackedLava",
	"Glacier",
	"Grass",
	"Ground",
	"Ice",
	"LeafyGrass",
	"Limestone",
	"Mud",
	"Pavement",
	"Rock",
	"Salt",
	"Sand",
	"Sandstone",
	"Slate",
	"Snow",
	"Water",
	"WoodPlanks",
}

-- Lobby: a row of green hills just beyond the field and grey-white snowy mountains behind them.
Backdrop.LobbyHills = {
	near = "hill",
	far = "hill",
	base = { "Grass", "Grass", "LeafyGrass" },
	accent = "Rock",
	ground = "Grass",
	nearHeight = { 30, 90 },
	farHeight = { 30, 90 },
} :: Style
Backdrop.LobbyPeaks = {
	near = "peak",
	far = "peak",
	base = { "Rock", "Slate", "Rock" },
	accent = "Slate",
	ground = "Grass",
	nearHeight = { 120, 250 },
	farHeight = { 120, 250 },
	snow = "Snow",
	snowLine = 0.55,
} :: Style

-- Per dungeon (Roster.Themes / Dungeons ids).
Backdrop.Styles = {
	Graveyard = {
		near = "crag",
		far = "crag",
		base = { "Slate", "Basalt" },
		accent = "Basalt",
		ground = "Ground",
		nearHeight = { 50, 110 },
		farHeight = { 120, 220 },
	},
	Farm = {
		near = "hill",
		far = "hill",
		base = { "Grass", "Grass", "Ground" },
		accent = "Ground",
		ground = "Grass",
		nearHeight = { 25, 60 },
		farHeight = { 60, 130 },
	},
	Swamp = {
		near = "hill",
		far = "hill",
		base = { "Mud", "Grass", "LeafyGrass" },
		accent = "LeafyGrass",
		ground = "Mud",
		nearHeight = { 15, 40 },
		farHeight = { 40, 85 },
	},
	Sewer = {
		near = "cliff",
		far = "cliff",
		base = { "Concrete", "Slate" },
		accent = "Slate",
		ground = "Concrete",
		nearHeight = { 40, 90 },
		farHeight = { 90, 170 },
	},
	Village = {
		near = "hill",
		far = "peak",
		base = { "Grass", "Grass", "Rock" },
		accent = "Rock",
		ground = "Grass",
		nearHeight = { 30, 70 },
		farHeight = { 90, 170 },
		snow = "Snow",
		snowLine = 0.75,
	},
	Frozen = {
		near = "peak",
		far = "peak",
		base = { "Snow", "Glacier", "Rock" },
		accent = "Glacier",
		ground = "Snow",
		nearHeight = { 50, 120 },
		farHeight = { 140, 260 },
		snow = "Snow",
		snowLine = 0.35,
	},
	Jungle = {
		near = "hill",
		far = "peak",
		base = { "LeafyGrass", "LeafyGrass", "Grass" },
		accent = "Rock",
		ground = "LeafyGrass",
		nearHeight = { 40, 90 },
		farHeight = { 90, 190 },
	},
	Pirate = {
		near = "cliff",
		far = "crag",
		base = { "Rock", "Sandstone" },
		accent = "Sand",
		ground = "Sand",
		nearHeight = { 35, 80 },
		farHeight = { 80, 160 },
		water = true,
	},
	Factory = {
		near = "crag",
		far = "crag",
		base = { "Asphalt", "Basalt" },
		accent = "CrackedLava",
		ground = "Asphalt",
		nearHeight = { 40, 90 },
		farHeight = { 100, 190 },
	},
	Station = {
		near = "crater",
		far = "crag",
		base = { "Basalt", "Rock" },
		accent = "Basalt",
		ground = "Rock",
		nearHeight = { 25, 55 },
		farHeight = { 90, 180 },
	},
} :: { [string]: Style }

local TAU = math.pi * 2

local function lerp(range: { number }, t: number): number
	return range[1] + (range[2] - range[1]) * t
end

local function ball(tag: string, x: number, y: number, z: number, r: number, material: string): Shape
	return { kind = "ball", tag = tag, material = material, x = x, y = y, z = z, radius = r }
end

local function box(
	kind: string,
	tag: string,
	x: number,
	y: number,
	z: number,
	sx: number,
	sy: number,
	sz: number,
	yaw: number,
	tilt: number,
	material: string
): Shape
	return {
		kind = kind,
		tag = tag,
		material = material,
		x = x,
		y = y,
		z = z,
		size = { sx, sy, sz },
		yaw = yaw,
		tilt = tilt,
	}
end

-- Largest horizontal distance from the shape's centre to any of its points, and its vertical half extent.
local function extents(s: Shape): (number, number)
	if s.kind == "ball" then
		local r = s.radius :: number
		return r, r
	end
	local size = s.size :: { number }
	local t = s.tilt or 0
	local c, sn = math.abs(math.cos(t)), math.abs(math.sin(t))
	local hx, hy, hz = size[1] / 2, size[2] / 2, size[3] / 2
	return math.sqrt(hx * hx + (hy * sn + hz * c) ^ 2), hy * c + hz * sn
end
Backdrop.extents = extents

-- Half extents along x and z: exact for unrotated boxes (the sea), the bounding circle otherwise.
local function halfXZ(s: Shape): (number, number)
	if s.kind == "snow" then
		local r = s.radius :: number
		return r, r
	end
	if s.kind ~= "ball" and (s.yaw or 0) == 0 and (s.tilt or 0) == 0 then
		local size = s.size :: { number }
		return size[1] / 2, size[3] / 2
	end
	local h = extents(s)
	return h, h
end

-- Horizontal reach of the part of the shape at or above height `y` (a ball's cross-section; boxes are bounded by
-- their full extents), or -1 when the shape lies wholly below `y`.
function Backdrop.reachAbove(s: Shape, y: number): number
	if s.kind == "snow" or s.material == "Air" then
		return -1
	end
	if s.kind == "ball" then
		local r = s.radius :: number
		if s.y >= y then
			return r
		end
		local d = y - s.y
		if d >= r then
			return -1
		end
		return math.sqrt(r * r - d * d)
	end
	local h, v = extents(s)
	if s.y + v < y then
		return -1
	end
	return h
end

function Backdrop.topOf(s: Shape): number
	if s.kind == "snow" then
		return s.top :: number
	end
	local _, v = extents(s)
	return s.y + v
end

-- Distance from (x, z) to the arena floor rectangle (0 inside).
function Backdrop.rectDistance(x: number, z: number, hw: number, hd: number): number
	local dx = math.max(math.abs(x) - hw, 0)
	local dz = math.max(math.abs(z) - hd, 0)
	return math.sqrt(dx * dx + dz * dz)
end

-- Does the shape's full horizontal footprint and height span fit inside `b` (with the shape offset by ox, oz)?
function Backdrop.inside(s: Shape, b: Box, ox: number?, oz: number?): boolean
	local x, z = s.x + (ox or 0), s.z + (oz or 0)
	local hx, hz = halfXZ(s)
	if x - hx < b.minX or x + hx > b.maxX or z - hz < b.minZ or z + hz > b.maxZ then
		return false
	end
	if s.kind == "snow" then
		return s.y >= b.minY and (s.top :: number) <= b.maxY
	end
	local _, v = extents(s)
	return s.y - v >= b.minY and s.y + v <= b.maxY
end

-- Does the shape's full horizontal footprint stay out of `b` (offset by ox, oz)?
local function outside(s: Shape, b: Box, ox: number, oz: number): boolean
	local hx, hz = halfXZ(s)
	local x, z = s.x + ox, s.z + oz
	if s.kind == "snow" or (s.kind ~= "ball" and (s.yaw or 0) == 0 and (s.tilt or 0) == 0) then
		return x + hx < b.minX or x - hx > b.maxX or z + hz < b.minZ or z - hz > b.maxZ
	end
	local dx = math.max(b.minX - x, 0, x - b.maxX)
	local dz = math.max(b.minZ - z, 0, z - b.maxZ)
	return dx * dx + dz * dz > hx * hx
end
Backdrop.outside = function(s: Shape, b: Box, ox: number?, oz: number?): boolean
	return outside(s, b, ox or 0, oz or 0)
end

-- Features. Each builds its shapes around (0, 0) with the floor top at y = 0; `yawOut` turns cliffs to face the
-- playable area (their local +Z points away from it). Every main mass is sunk below the ground plane.

local function hill(rand: () -> number, H: number, base: string, accent: string): { Shape }
	local out = {}
	local r = H * (1.5 + rand() * 0.7)
	table.insert(out, ball("range", 0, H - r, 0, r, base))
	for _ = 1, 1 + math.floor(rand() * 2) do
		local h = H * (0.45 + rand() * 0.3)
		local rr = h * (1.4 + rand() * 0.5)
		local a, d = rand() * TAU, r * (0.4 + rand() * 0.3)
		table.insert(out, ball("range", math.cos(a) * d, h - rr, math.sin(a) * d, rr, base))
	end
	if rand() < 0.7 then
		-- A rock outcrop half sunk into the main hill's flank.
		local a, d = rand() * TAU, r * 0.3 * rand()
		local surface = (H - r) + math.sqrt(r * r - d * d)
		local rr = H * (0.08 + rand() * 0.06) + 3
		table.insert(out, ball("range", math.cos(a) * d, surface - rr * 0.4, math.sin(a) * d, rr, accent))
	end
	return out
end

local PEAK_LAYERS = { { 0.6, -0.2 }, { 0.4, 0.25 }, { 0.26, 0.58 }, { 0.15, 0.85 } } -- radius, centre (x H)

local function peak(rand: () -> number, H: number, base: string, accent: string): { Shape }
	local out = {}
	local lean, leanDir = H * (0.04 + rand() * 0.08), rand() * TAU
	for i, layer in PEAK_LAYERS do
		local t = (i - 1) / (#PEAK_LAYERS - 1)
		local jx = math.cos(leanDir) * lean * t + (rand() - 0.5) * H * 0.05
		local jz = math.sin(leanDir) * lean * t + (rand() - 0.5) * H * 0.05
		table.insert(out, ball("range", jx, layer[2] * H, jz, layer[1] * H, base))
	end
	for _ = 1, 2 + math.floor(rand() * 2) do
		local a, d = rand() * TAU, H * (0.35 + rand() * 0.15)
		local r = H * (0.3 + rand() * 0.12)
		table.insert(out, ball("range", math.cos(a) * d, -0.12 * H, math.sin(a) * d, r, base))
	end
	if rand() < 0.6 then
		local a, d = rand() * TAU, H * 0.3
		local w = H * 0.09
		table.insert(
			out,
			box("block", "range", math.cos(a) * d, H * 0.25, math.sin(a) * d, w, H * 0.35, w, rand() * TAU, 0.2, accent)
		)
	end
	return out
end

local function crag(rand: () -> number, H: number, base: string, accent: string): { Shape }
	local out = {}
	table.insert(out, ball("range", 0, -0.25 * H, 0, 0.55 * H, base))
	local n = 3 + math.floor(rand() * 3)
	for i = 1, n do
		local w = H * (0.14 + rand() * 0.1)
		local top = if i == 1 then H else H * (0.55 + rand() * 0.4)
		local length = top + 0.35 * H
		local a, d = rand() * TAU, if i == 1 then 0 else H * 0.28 * rand()
		local material = if i % 2 == 0 then accent else base
		table.insert(
			out,
			box(
				"block",
				"range",
				math.cos(a) * d,
				top - length / 2,
				math.sin(a) * d,
				w,
				length,
				w * (0.7 + rand() * 0.4),
				rand() * TAU,
				(rand() - 0.5) * 0.5,
				material
			)
		)
	end
	return out
end

local function cliff(rand: () -> number, H: number, base: string, accent: string, yawOut: number): { Shape }
	local out = {}
	-- Local frame: +X along the playable edge, +Z away from it.
	local cy, sy = math.cos(yawOut), math.sin(yawOut)
	local function at(lx: number, lz: number): (number, number)
		return lx * cy + lz * sy, -lx * sy + lz * cy
	end
	local n = 2 + math.floor(rand() * 2)
	local length = H * (0.8 + rand() * 0.5)
	local thick = H * (0.4 + rand() * 0.2)
	for i = 1, n do
		local top = H * (0.7 + rand() * 0.3)
		local tall = top + H * 0.4
		local lx = (i - (n + 1) / 2) * length * 0.75
		local x, z = at(lx, rand() * thick * 0.5)
		table.insert(
			out,
			box(
				"block",
				"range",
				x,
				top - tall / 2,
				z,
				length,
				tall,
				thick,
				yawOut + (rand() - 0.5) * 0.35,
				-rand() * 0.12,
				base
			)
		)
	end
	-- Talus: a wedge along the foot, low side toward the playable area (a wedge's slope faces its -Z).
	local tw, th, td = length * n * 0.7, H * 0.3, H * 0.4
	local x, z = at(0, -thick / 2 - td * 0.35)
	table.insert(out, box("wedge", "range", x, th / 2 - 5, z, tw, th + 10, td, yawOut, 0, accent))
	return out
end

local function crater(rand: () -> number, H: number, base: string, accent: string): { Shape }
	local out = {}
	local r = H * (1.3 + rand() * 0.3)
	table.insert(out, ball("range", 0, H - r, 0, r, base))
	local carve = H * (0.8 + rand() * 0.2)
	table.insert(out, ball("range", 0, H + carve * 0.55, 0, carve, "Air"))
	-- Boulders on the rim.
	local rim = math.sqrt(math.max(carve * carve - (carve * 0.55) ^ 2, 0))
	for _ = 1, 2 + math.floor(rand() * 3) do
		local a = rand() * TAU
		local rr = H * (0.08 + rand() * 0.06)
		local surface = (H - r) + math.sqrt(math.max(r * r - rim * rim, 0))
		table.insert(out, ball("range", math.cos(a) * rim, surface - rr * 0.3, math.sin(a) * rim, rr, accent))
	end
	return out
end

local FEATURES = { hill = hill, peak = peak, crag = crag, cliff = cliff, crater = crater }
Backdrop.Features = { "hill", "peak", "crag", "cliff", "crater" }

-- Builds one feature for tests (shapes around the origin).
function Backdrop.feature(kind: string, seed: number, H: number, base: string, accent: string): { Shape }
	local f = FEATURES[kind]
	assert(f, `Unknown backdrop feature {kind}`)
	return f(Lane.random(seed), H, base, accent, 0)
end

type Row = {
	slots: number,
	gap: number, -- chance a slot stays empty
	offset: { number }, -- first try: centre this far beyond the protected edge
	maxOffset: number, -- give up past this
	height: { number },
	kind: string,
	style: Style,
}

type Protect = {
	edge: (ux: number, uz: number) -> number, -- distance from the centre to the protected edge along (ux, uz)
	clear: (s: Shape, ox: number, oz: number) -> boolean, -- far enough from the playable area
	allowed: (s: Shape, ox: number, oz: number) -> boolean, -- inside the region this backdrop may touch
}

-- Places a row of features around the protected area: one candidate per angular slot (some left empty for gaps),
-- pushed outward until every shape clears the playable area, dropped if it leaves the allowed region first.
local function placeRow(rand: () -> number, row: Row, protect: Protect, out: { Shape })
	for i = 0, row.slots - 1 do
		local skip = rand() < row.gap
		local a = (i + 0.15 + rand() * 0.7) / row.slots * TAU
		local H = lerp(row.height, rand())
		local base = row.style.base[1 + math.floor(rand() * #row.style.base)]
		local ux, uz = math.cos(a), math.sin(a)
		local shapes = FEATURES[row.kind](rand, H, base, row.style.accent, math.atan2(ux, uz))
		local edge = protect.edge(ux, uz)
		local d = edge + lerp(row.offset, rand())
		if skip then
			continue
		end
		while d <= edge + row.maxOffset do
			local ox, oz = ux * d, uz * d
			local ok, allowed = true, true
			for _, s in shapes do
				if not protect.allowed(s, ox, oz) then
					allowed = false
					break
				end
				if not protect.clear(s, ox, oz) then
					ok = false
				end
			end
			if not allowed then
				break
			end
			if ok then
				local reach = 0
				for _, s in shapes do
					s.x += ox
					s.z += oz
					table.insert(out, s)
					reach = math.max(reach, math.sqrt((s.x - ox) ^ 2 + (s.z - oz) ^ 2) + (extents(s)))
				end
				local style = row.style
				if style.snow and style.snowLine and base ~= style.snow then
					local snow: Shape = {
						kind = "snow",
						tag = "range",
						material = style.snow,
						x = ox,
						y = H * style.snowLine,
						z = oz,
						radius = reach,
						top = H + 8,
						from = { base },
					}
					if protect.allowed(snow, 0, 0) then
						table.insert(out, snow)
					end
				end
				break
			end
			d += 8
		end
	end
end

local function fieldProtect(): Protect
	local arena = Backdrop.ArenaBounds
	local o = Backdrop.ArenaOrigin
	local reserved: Box = {
		minX = arena.minX + o.x - 10,
		maxX = arena.maxX + o.x + 10,
		minY = arena.minY,
		maxY = arena.maxY,
		minZ = arena.minZ + o.z - 10,
		maxZ = arena.maxZ + o.z + 10,
	}
	local keep = LobbyLayout.FieldRadius + Backdrop.FieldClearance
	return {
		edge = function()
			return LobbyLayout.FieldRadius
		end,
		clear = function(s, ox, oz)
			local reach = Backdrop.reachAbove(s, 0)
			return reach < 0 or math.sqrt((s.x + ox) ^ 2 + (s.z + oz) ^ 2) - reach >= keep
		end,
		allowed = function(s, ox, oz)
			local h = if s.kind == "snow" then 0 else (extents(s))
			return math.sqrt((s.x + ox) ^ 2 + (s.z + oz) ^ 2) + h <= Backdrop.LobbyMaxRadius + 250
				and outside(s, reserved, ox, oz)
		end,
	}
end

-- The lobby's ring: hills just beyond the field, snowy mountains behind, plus a grass lip around the field rim
-- that hides the step from the field (top 0) down to the horizon ground (top -4).
function Backdrop.lobby(seed: number?): { Shape }
	local rand = Lane.random(seed or 20251031)
	local out: { Shape } = {}
	local R = LobbyLayout.FieldRadius
	local steps = math.floor(TAU * R / 10)
	for i = 0, steps - 1 do
		local a = i / steps * TAU
		local r = 16
		local top = 1.5 + rand() * 2
		table.insert(out, ball("rim", math.cos(a) * (R + 2), top - r, math.sin(a) * (R + 2), r, "Grass"))
	end
	local protect = fieldProtect()
	placeRow(rand, {
		slots = 28,
		gap = 0.25,
		offset = { 60, 180 },
		maxOffset = 360,
		height = Backdrop.LobbyHills.nearHeight,
		kind = "hill",
		style = Backdrop.LobbyHills,
	}, protect, out)
	placeRow(rand, {
		slots = 22,
		gap = 0.2,
		offset = { 330, 520 },
		maxOffset = Backdrop.LobbyMaxRadius - R,
		height = Backdrop.LobbyPeaks.nearHeight,
		kind = "peak",
		style = Backdrop.LobbyPeaks,
	}, protect, out)
	return out
end

-- Low grass mounds in the lobby field's outskirts. `isFree(x, z, reach)` says whether a mound reaching `reach`
-- studs around (x, z) keeps clear of paths, plots and zones (Lobby.luau owns those lists).
function Backdrop.fieldMounds(seed: number, count: number, isFree: (number, number, number) -> boolean): { Shape }
	local rand = Lane.random(seed)
	local out: { Shape } = {}
	local placed: { { number } } = {}
	local rMin, rMax = 330, LobbyLayout.FieldRadius - 40
	for _ = 1, count * 8 do
		if #placed >= count then
			break
		end
		local a = rand() * TAU
		local d = rMin + math.sqrt(rand()) * (rMax - rMin)
		local x, z = math.cos(a) * d, math.sin(a) * d
		local H = 4 + rand() * 9
		local r = H * (3 + rand())
		local reach = math.sqrt(r * r - (r - H) ^ 2)
		if d + reach > LobbyLayout.FieldRadius - 8 or not isFree(x, z, reach) then
			continue
		end
		local overlaps = false
		for _, p in placed do
			if math.sqrt((x - p[1]) ^ 2 + (z - p[2]) ^ 2) < reach + p[3] then
				overlaps = true
				break
			end
		end
		if overlaps then
			continue
		end
		table.insert(placed, { x, z, reach })
		table.insert(out, ball("mound", x, H - r, z, r, if rand() < 0.7 then "Grass" else "LeafyGrass"))
		if rand() < 0.5 then
			local ra = rand() * TAU
			local rr = 2 + rand() * 2.5
			local rx, rz = x + math.cos(ra) * reach * 0.3, z + math.sin(ra) * reach * 0.3
			table.insert(out, ball("mound", rx, H * 0.7, rz, rr, "Rock"))
		end
	end
	return out
end

-- Lobby mound footprints, for keeping trees off them: { x, z, reach } per shape.
function Backdrop.footprints(shapes: { Shape }): { { number } }
	local out = {}
	for _, s in shapes do
		local reach = Backdrop.reachAbove(s, 0)
		if reach >= 0 then
			table.insert(out, { s.x, s.z, reach })
		end
	end
	return out
end

local function arenaProtect(hw: number, hd: number): Protect
	return {
		edge = function(ux, uz)
			local tx = if math.abs(ux) > 1e-6 then hw / math.abs(ux) else math.huge
			local tz = if math.abs(uz) > 1e-6 then hd / math.abs(uz) else math.huge
			return math.min(tx, tz)
		end,
		clear = function(s, ox, oz)
			local reach = Backdrop.reachAbove(s, 0)
			return reach < 0 or Backdrop.rectDistance(s.x + ox, s.z + oz, hw, hd) - reach >= Backdrop.ArenaClearance
		end,
		allowed = function(s, ox, oz)
			return Backdrop.inside(s, Backdrop.ArenaBounds, ox, oz)
		end,
	}
end

local function laneDistance(x: number, z: number, points: { Point }): number
	local best = math.huge
	local p = { x = x, z = z }
	for i = 1, #points - 1 do
		best = math.min(best, Lane.pointSegmentDistance(p, points[i], points[i + 1]))
	end
	return best
end
Backdrop.laneDistance = laneDistance

-- One dungeon's backdrop, arena-local: a skirt hiding the floor's side, the shallow sea for water themes, a near
-- and a far row of themed features, and a few low mounds in the floor corners away from the lane.
function Backdrop.arena(dungeonId: string, layout: LaneLayout?): { Shape }
	local style = Backdrop.Styles[dungeonId]
	assert(style, `No backdrop style for dungeon {dungeonId}`)
	local lane = layout or Lane.layout(dungeonId)
	local rand = Lane.random(Lane.seed("backdrop:" .. dungeonId))
	local hw, hd = Lane.Arena.width / 2, Lane.Arena.depth / 2
	local out: { Shape } = {}
	local b = Backdrop.ArenaBounds

	if style.water then
		-- Water from y = -6 up to -1.5: above the horizon ground (-4), below the floor top, never touching the floor.
		local inner, top, bottom = 8, -1.5, -6
		local h, cy = top - bottom, (top + bottom) / 2
		local function sea(minX: number, maxX: number, minZ: number, maxZ: number)
			table.insert(
				out,
				box(
					"block",
					"water",
					(minX + maxX) / 2,
					cy,
					(minZ + maxZ) / 2,
					maxX - minX,
					h,
					maxZ - minZ,
					0,
					0,
					"Water"
				)
			)
		end
		sea(b.minX + 4, b.maxX - 4, hd + inner, b.maxZ - 4) -- tower side
		sea(b.minX + 4, b.maxX - 4, b.minZ + 4, -hd - inner) -- gate side
		sea(b.minX + 4, -hw - inner, -hd - inner, hd + inner) -- west
		sea(hw + inner, b.maxX - 4, -hd - inner, hd + inner) -- east
	end

	-- Skirt: balls along the floor edge, top 1.2 below the floor top, covering the floor's side down to the ground.
	local function skirt(x: number, z: number)
		local r = 12
		table.insert(out, ball("skirt", x, -1.2 - r, z, r, style.ground))
	end
	for x = -hw, hw, 10 do
		skirt(x, -hd - 3)
		skirt(x, hd + 3)
	end
	for z = -hd + 10, hd - 10, 10 do
		skirt(-hw - 3, z)
		skirt(hw + 3, z)
	end

	local protect = arenaProtect(hw, hd)
	placeRow(rand, {
		slots = 22,
		gap = 0.2,
		offset = { 40, 140 },
		maxOffset = 220,
		height = style.nearHeight,
		kind = style.near,
		style = style,
	}, protect, out)
	placeRow(rand, {
		slots = 18,
		gap = 0.15,
		offset = { 200, 330 },
		maxOffset = 400,
		height = style.farHeight,
		kind = style.far,
		style = style,
	}, protect, out)

	-- Mounds in the floor corners, well away from the lane, the gate and the tower (and the spawns beside it).
	for _, corner in { { -1, -1 }, { 1, -1 }, { -1, 1 }, { 1, 1 } } do
		local made = 0
		for _ = 1, 16 do
			if made >= 2 then
				break
			end
			local x = corner[1] * (hw - 12 - rand() * hw * 0.4)
			local z = corner[2] * (hd - 12 - rand() * hd * 0.45)
			local H = 3 + rand() * 4
			local r = H * (2.5 + rand())
			local reach = math.sqrt(r * r - (r - H) ^ 2)
			local towerD = math.sqrt((x - lane.tower.x) ^ 2 + (z - lane.tower.z) ^ 2)
			if
				laneDistance(x, z, lane.points) - reach < Backdrop.MoundLaneClearance
				or towerD - reach < Backdrop.MoundTowerClearance
			then
				continue
			end
			made += 1
			table.insert(out, ball("mound", x, H - r, z, r, style.ground))
			if rand() < 0.6 then
				local w = 2 + rand() * 3
				local a = rand() * TAU
				table.insert(
					out,
					box(
						"block",
						"mound",
						x + math.cos(a) * reach * 0.25,
						H * 0.6,
						z + math.sin(a) * reach * 0.25,
						w,
						w * 1.3,
						w * 0.9,
						rand() * TAU,
						(rand() - 0.5) * 0.6,
						style.accent
					)
				)
			end
		end
	end
	return out
end

-- Axis-aligned bounds of a plan (full extents), or nil for an empty plan.
function Backdrop.bounds(shapes: { Shape }): Box?
	local out: Box? = nil
	for _, s in shapes do
		local hx, hz = halfXZ(s)
		local minY, maxY
		if s.kind == "snow" then
			minY, maxY = s.y, s.top :: number
		else
			local _, v = extents(s)
			minY, maxY = s.y - v, s.y + v
		end
		if not out then
			out = { minX = s.x - hx, maxX = s.x + hx, minY = minY, maxY = maxY, minZ = s.z - hz, maxZ = s.z + hz }
		else
			local o = out :: Box
			o.minX = math.min(o.minX, s.x - hx)
			o.maxX = math.max(o.maxX, s.x + hx)
			o.minY = math.min(o.minY, minY)
			o.maxY = math.max(o.maxY, maxY)
			o.minZ = math.min(o.minZ, s.z - hz)
			o.maxZ = math.max(o.maxZ, s.z + hz)
		end
	end
	return out
end

-- The Air fills that undo a plan: every solid shape again, a voxel bigger all round, so the smoothed edges go too.
-- Cheaper than clearing the plan's whole bounding box (most of which is empty sky). Snow regions and carves
-- only change terrain the solid shapes made, so they need nothing of their own.
function Backdrop.clearing(shapes: { Shape }): { Shape }
	local out = {}
	for _, s in shapes do
		if s.kind == "snow" or s.material == "Air" then
			continue
		end
		if s.kind == "ball" then
			table.insert(out, ball(s.tag, s.x, s.y, s.z, (s.radius :: number) + 4, "Air"))
		else
			local size = s.size :: { number }
			table.insert(
				out,
				box(
					"block",
					s.tag,
					s.x,
					s.y,
					s.z,
					size[1] + 8,
					size[2] + 8,
					size[3] + 8,
					s.yaw or 0,
					s.tilt or 0,
					"Air"
				)
			)
		end
	end
	return out
end
return Backdrop
