-- One winding lane per dungeon, in studs. Pure and deterministic (no Roblox APIs) so Lune can test it
-- and the server, the client and any tool agree on the exact route for a dungeon id.
--
-- Same recipe as the showcase's `laneCurve`: the arena is cut into a coarse grid of cells at least
-- 2.6 lane widths across; a seeded self-avoiding walk goes from the gate cell on the near edge
-- (z min) to the centre cell on the far edge (z max), mostly sideways, sometimes forward, now and
-- then back for a switchback. The jittered cell centres are smoothed with two rounds of Chaikin
-- corner cutting, then the polyline is rejected if it leaves the arena, comes back within 1.4 lane
-- widths of itself, or is not in the wanted length band. The candidate closest to the target length
-- wins, so every dungeon has its own snake of bends, and the same one every visit.
--
-- Scale: the showcase draws a 260 x 200 m arena with a 450 to 700 m lane. Taken literally at
-- 3.5 studs per metre that is a 2,000+ stud lane that a Runner (14 studs/s) would need 2.5 minutes
-- for, so the game uses about 1.4 studs per metre: a 360 x 280 stud arena, a 10 stud lane and a route
-- of 600 to 1,000 studs (target 800). A Runner crosses it in about a minute, a Brute in two.

local Lane = {}

export type Point = { x: number, z: number }
export type Arena = { width: number, depth: number }
export type Layout = {
	points: { Point },
	gate: Point, -- lane start, on the near edge
	tower: Point, -- the Town Hall; the lane ends just short of it
	width: number,
	length: number,
}

Lane.Arena = { width = 360, depth = 280 } :: Arena
Lane.Width = 10
Lane.TargetLength = 800
Lane.LengthBand = { min = 600, max = 1000 }
Lane.TowerClearance = 10 -- the lane ends this far before the tower centre
Lane.Attempts = 200

local TWO32 = 4294967296

-- Multiply two 32-bit unsigned integers modulo 2^32 without losing precision in a double.
local function mul32(a: number, b: number): number
	local hi = (a * bit32.rshift(b, 16)) % TWO32
	return (hi * 65536 + a * bit32.band(b, 0xFFFF)) % TWO32
end

-- mulberry32: a tiny deterministic generator returning numbers in [0, 1).
local function rng(seed: number): () -> number
	local t = seed % TWO32
	return function()
		t = (t + 0x6D2B79F5) % TWO32
		local r = bit32.bxor(t, bit32.rshift(t, 15))
		r = mul32(r, bit32.bor(1, t))
		r = bit32.bxor(r, (r + mul32(bit32.bxor(r, bit32.rshift(r, 7)), bit32.bor(61, r))) % TWO32)
		r = bit32.bxor(r, bit32.rshift(r, 14))
		return r / TWO32
	end
end

-- The same generator for other pure layout modules (Backdrop) that want seeded, platform-independent randomness.
Lane.random = rng

function Lane.seed(text: string): number
	local h = 7
	for i = 1, #text do
		h = (h * 31 + string.byte(text, i)) % TWO32
	end
	return h
end

function Lane.length(points: { Point }): number
	local total = 0
	for i = 2, #points do
		local a, b = points[i - 1], points[i]
		total += math.sqrt((b.x - a.x) ^ 2 + (b.z - a.z) ^ 2)
	end
	return total
end

-- Chaikin corner cutting: replaces every interior corner with two points a quarter of the way along
-- each neighbouring segment. Endpoints stay put.
local function chaikin(points: { Point }, rounds: number): { Point }
	local out = points
	for _ = 1, rounds do
		local next = { out[1] }
		for i = 1, #out - 1 do
			local a, b = out[i], out[i + 1]
			table.insert(next, { x = a.x * 0.75 + b.x * 0.25, z = a.z * 0.75 + b.z * 0.25 })
			table.insert(next, { x = a.x * 0.25 + b.x * 0.75, z = a.z * 0.25 + b.z * 0.75 })
		end
		table.insert(next, out[#out])
		out = next
	end
	return out
end

local function pointSegmentDistance(p: Point, a: Point, b: Point): number
	local dx, dz = b.x - a.x, b.z - a.z
	local lenSq = dx * dx + dz * dz
	local t = 0
	if lenSq > 0 then
		t = math.clamp(((p.x - a.x) * dx + (p.z - a.z) * dz) / lenSq, 0, 1)
	end
	local cx, cz = a.x + dx * t, a.z + dz * t
	return math.sqrt((p.x - cx) ^ 2 + (p.z - cz) ^ 2)
end
Lane.pointSegmentDistance = pointSegmentDistance

local function cross(ax: number, az: number, bx: number, bz: number): number
	return ax * bz - az * bx
end

-- True when segments a-b and c-d cross or touch.
function Lane.segmentsIntersect(a: Point, b: Point, c: Point, d: Point): boolean
	local d1 = cross(d.x - c.x, d.z - c.z, a.x - c.x, a.z - c.z)
	local d2 = cross(d.x - c.x, d.z - c.z, b.x - c.x, b.z - c.z)
	local d3 = cross(b.x - a.x, b.z - a.z, c.x - a.x, c.z - a.z)
	local d4 = cross(b.x - a.x, b.z - a.z, d.x - a.x, d.z - a.z)
	if ((d1 > 0 and d2 < 0) or (d1 < 0 and d2 > 0)) and ((d3 > 0 and d4 < 0) or (d3 < 0 and d4 > 0)) then
		return true
	end
	-- Collinear overlaps and touching endpoints count as intersections too.
	local function onSegment(p: Point, q: Point, r: Point): boolean
		return math.min(p.x, r.x) <= q.x
			and q.x <= math.max(p.x, r.x)
			and math.min(p.z, r.z) <= q.z
			and q.z <= math.max(p.z, r.z)
	end
	return (d1 == 0 and onSegment(c, a, d))
		or (d2 == 0 and onSegment(c, b, d))
		or (d3 == 0 and onSegment(a, c, b))
		or (d4 == 0 and onSegment(a, d, b))
end

-- Shortest distance between two segments.
function Lane.segmentDistance(a: Point, b: Point, c: Point, d: Point): number
	if Lane.segmentsIntersect(a, b, c, d) then
		return 0
	end
	return math.min(
		pointSegmentDistance(a, c, d),
		pointSegmentDistance(b, c, d),
		pointSegmentDistance(c, a, b),
		pointSegmentDistance(d, a, b)
	)
end

-- Checks a smoothed polyline: inside the arena with a lane-width margin, and no two stretches of lane
-- that are more than `neighbourArc` apart along the route come within `clearance` of each other.
-- Returns true, or false plus a reason.
function Lane.validate(points: { Point }, arena: Arena, width: number, clearance: number?): (boolean, string?)
	local minGap = clearance or width * 1.4
	local neighbourArc = width * 2.6
	local halfW, halfD = arena.width / 2, arena.depth / 2
	for _, p in points do
		if math.abs(p.x) > halfW - width or p.z < -halfD + 2 or p.z > halfD - 2 then
			return false, "out of bounds"
		end
	end
	local arc = { 0 }
	for i = 2, #points do
		local a, b = points[i - 1], points[i]
		arc[i] = arc[i - 1] + math.sqrt((b.x - a.x) ^ 2 + (b.z - a.z) ^ 2)
	end
	for i = 1, #points - 2 do
		for j = i + 2, #points - 1 do
			if arc[j] - arc[i + 1] >= neighbourArc then
				if Lane.segmentDistance(points[i], points[i + 1], points[j], points[j + 1]) < minGap then
					return false, "self overlap"
				end
			elseif Lane.segmentsIntersect(points[i], points[i + 1], points[j], points[j + 1]) then
				return false, "self intersection"
			end
		end
	end
	return true, nil
end

local function straightLane(gateZ: number, endZ: number): { Point }
	return { { x = 0, z = gateZ }, { x = 0, z = endZ } }
end

type Cell = { c: number, k: number }

-- One attempt at a self-avoiding grid walk from row 0 to the centre cell of the top row.
local function gridWalk(r: () -> number, cols: number, rows: number): { Cell }?
	local mid = (cols - 1) / 2
	local seen: { [string]: boolean } = {}
	local walk: { Cell } = {}
	local c = math.floor(mid + (r() - 0.5) * cols * 0.6)
	local k = 0
	local dir = if r() < 0.5 then 1 else -1
	local function push(cc: number, kk: number)
		table.insert(walk, { c = cc, k = kk })
		seen[`{cc},{kk}`] = true
	end
	local function free(cc: number, kk: number): boolean
		return cc >= 0 and cc < cols and kk >= 0 and kk < rows and not seen[`{cc},{kk}`]
	end
	push(c, k)
	for _ = 1, cols * rows do
		if k == rows - 1 and math.abs(c - mid) <= 0.5 then
			return walk
		end
		local opts: { { number } } = {}
		if free(c + dir, k) then
			table.insert(opts, { c + dir, k, 0.55 }) -- keep sweeping sideways
		end
		if free(c - dir, k) then
			table.insert(opts, { c - dir, k, 0.12 }) -- turn back early
		end
		if free(c, k + 1) then
			table.insert(opts, { c, k + 1, if k == rows - 1 then 0 else 0.3 })
		end
		if k > 0 and free(c, k - 1) then
			table.insert(opts, { c, k - 1, 0.07 }) -- switchback
		end
		local total = 0
		for _, o in opts do
			total += o[3]
		end
		if total == 0 then
			return nil
		end
		local pick = r() * total
		local chosen = opts[#opts]
		for _, o in opts do
			pick -= o[3]
			if pick <= 0 then
				chosen = o
				break
			end
		end
		if chosen[1] ~= c then
			dir = if chosen[1] > c then 1 else -1
		else
			dir = if r() < 0.5 then 1 else -1
		end
		c, k = chosen[1], chosen[2]
		push(c, k)
	end
	return nil
end

-- Full layout for a dungeon: the smoothed lane points plus the gate and tower positions, in arena-local
-- studs (origin at the arena centre, x across, z from the gate edge toward the tower edge).
function Lane.layout(dungeonId: string, arena: Arena?): Layout
	local a = arena or Lane.Arena
	local width = Lane.Width
	local gateZ = -a.depth / 2 + a.depth * 0.07
	local towerZ = a.depth / 2 - a.depth * 0.12
	local endZ = towerZ - Lane.TowerClearance
	local span = endZ - gateZ

	local cell = math.max(width * 2.6, math.min(a.width * 0.8, span) / 8)
	local cols = math.floor(a.width * 0.84 / cell)
	local rows = math.floor((span - cell * 0.5) / cell)

	local best: { Point }? = nil
	local bestScore = -math.huge
	if cols >= 2 and rows >= 2 then
		local r = rng(Lane.seed(dungeonId))
		local function cx(c: number): number
			return (c - (cols - 1) / 2) * cell
		end
		local function cz(k: number): number
			return gateZ + cell * 0.9 + k * cell
		end
		for _ = 1, Lane.Attempts do
			local walk = gridWalk(r, cols, rows)
			if not walk then
				continue
			end
			local pts: { Point } = { { x = cx(walk[1].c) * 0.6, z = gateZ } }
			for _, cellPos in walk do
				table.insert(pts, {
					x = cx(cellPos.c) + (r() - 0.5) * cell * 0.25,
					z = cz(cellPos.k) + (r() - 0.5) * cell * 0.25,
				})
			end
			table.insert(pts, { x = 0, z = endZ })
			local smooth = chaikin(pts, 2)
			local len = Lane.length(smooth)
			if len < Lane.LengthBand.min or len > Lane.LengthBand.max then
				continue
			end
			if not Lane.validate(smooth, a, width) then
				continue
			end
			local score = -math.abs(len - Lane.TargetLength)
			if score > bestScore then
				best, bestScore = smooth, score
			end
		end
	end

	local points = best or straightLane(gateZ, endZ)
	return {
		points = points,
		gate = points[1],
		tower = { x = 0, z = towerZ },
		width = width,
		length = Lane.length(points),
	}
end

-- Just the route, gate first, tower end last.
function Lane.waypoints(dungeonId: string, arena: Arena?): { Point }
	return Lane.layout(dungeonId, arena).points
end

return Lane
