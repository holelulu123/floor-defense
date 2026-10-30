-- Run with: lune run test   (or lune run tests/Lane.spec)
local Dungeons = require("../src/shared/Dungeons")
local Lane = require("../src/shared/Lane")

local function eq(got, want, label)
	assert(got == want, `{label}: got {got}, want {want}`)
end

-- Independent geometry helpers so the test does not trust Lane's own validator.
local function orient(a, b, c)
	return (b.x - a.x) * (c.z - a.z) - (b.z - a.z) * (c.x - a.x)
end

local function properIntersect(a, b, c, d)
	local d1, d2 = orient(c, d, a), orient(c, d, b)
	local d3, d4 = orient(a, b, c), orient(a, b, d)
	return d1 * d2 < 0 and d3 * d4 < 0
end

local function pointSegDist(p, a, b)
	local dx, dz = b.x - a.x, b.z - a.z
	local l2 = dx * dx + dz * dz
	local t = if l2 > 0 then math.clamp(((p.x - a.x) * dx + (p.z - a.z) * dz) / l2, 0, 1) else 0
	return math.sqrt((p.x - a.x - dx * t) ^ 2 + (p.z - a.z - dz * t) ^ 2)
end

local function segDist(a, b, c, d)
	if properIntersect(a, b, c, d) then
		return 0
	end
	return math.min(pointSegDist(a, c, d), pointSegDist(b, c, d), pointSegDist(c, a, b), pointSegDist(d, a, b))
end

local function serialize(points)
	local parts = {}
	for _, p in points do
		table.insert(parts, string.format("%.3f,%.3f", p.x, p.z))
	end
	return table.concat(parts, ";")
end

local arena = Lane.Arena
local width = Lane.Width
local signatures = {}

for _, d in Dungeons.List do
	local layout = Lane.layout(d.id)
	local pts = layout.points
	assert(#pts >= 8, `{d.id}: lane has bends ({#pts} points)`)

	-- deterministic
	eq(serialize(Lane.waypoints(d.id)), serialize(pts), `{d.id}: same route every call`)

	-- gate on the near edge, tower on the far edge
	assert(pts[1].z < 0 and pts[#pts].z > 0, `{d.id}: runs from near edge to far edge`)
	eq(pts[1].x, layout.gate.x, `{d.id}: gate is the first point`)
	assert(layout.tower.z > pts[#pts].z, `{d.id}: lane ends short of the tower`)
	assert(math.abs(layout.tower.z - pts[#pts].z) <= Lane.TowerClearance + 0.001, `{d.id}: lane reaches the tower`)

	-- inside the arena
	for _, p in pts do
		assert(math.abs(p.x) <= arena.width / 2 - width, `{d.id}: x in bounds ({p.x})`)
		assert(p.z >= -arena.depth / 2 and p.z <= arena.depth / 2, `{d.id}: z in bounds ({p.z})`)
	end

	-- length band
	local len = Lane.length(pts)
	assert(len >= Lane.LengthBand.min and len <= Lane.LengthBand.max, `{d.id}: length {len} in band`)
	eq(layout.length, len, `{d.id}: layout.length`)

	-- no self-intersection anywhere, and stretches that are not neighbours along the route stay a
	-- lane width apart
	local arc = { 0 }
	for i = 2, #pts do
		arc[i] = arc[i - 1] + math.sqrt((pts[i].x - pts[i - 1].x) ^ 2 + (pts[i].z - pts[i - 1].z) ^ 2)
	end
	for i = 1, #pts - 2 do
		for j = i + 2, #pts - 1 do
			assert(not properIntersect(pts[i], pts[i + 1], pts[j], pts[j + 1]), `{d.id}: segments {i} and {j} cross`)
			if arc[j] - arc[i + 1] >= width * 2.6 then
				local dist = segDist(pts[i], pts[i + 1], pts[j], pts[j + 1])
				assert(dist >= width, `{d.id}: segments {i} and {j} only {dist} apart`)
			end
		end
	end

	-- different per dungeon
	local sig = serialize(pts)
	assert(not signatures[sig], `{d.id}: route differs from other dungeons`)
	signatures[sig] = d.id
end

-- the seed is a stable function of the id
eq(Lane.seed("Graveyard"), Lane.seed("Graveyard"), "seed is stable")
assert(Lane.seed("Graveyard") ~= Lane.seed("Swamp"), "seed differs per id")

-- a tiny arena falls back to a straight lane
local tiny = Lane.waypoints("Graveyard", { width = 40, depth = 40 })
eq(#tiny, 2, "tiny arena is a straight lane")

-- the geometry helpers agree with the test's own
assert(Lane.segmentsIntersect({ x = 0, z = 0 }, { x = 2, z = 2 }, { x = 0, z = 2 }, { x = 2, z = 0 }), "cross")
assert(not Lane.segmentsIntersect({ x = 0, z = 0 }, { x = 1, z = 0 }, { x = 0, z = 1 }, { x = 1, z = 1 }), "parallel")
eq(Lane.segmentDistance({ x = 0, z = 0 }, { x = 1, z = 0 }, { x = 0, z = 1 }, { x = 1, z = 1 }), 1, "parallel distance")

print("Lane.spec: ok")
