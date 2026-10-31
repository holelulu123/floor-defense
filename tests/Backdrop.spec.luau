-- Run with: lune run test   (or lune run tests/Backdrop.spec)
local Backdrop = require("../src/shared/Backdrop")
local Dungeons = require("../src/shared/Dungeons")
local Lane = require("../src/shared/Lane")
local LobbyLayout = require("../src/shared/LobbyLayout")

local function eq(got, want, label)
	assert(got == want, `{label}: got {got}, want {want}`)
end

local valid = {}
for _, m in Backdrop.TerrainMaterials do
	valid[m] = true
end

local function serialize(shapes)
	local parts = {}
	for _, s in shapes do
		table.insert(parts, `{s.kind}:{s.material}:{s.x}:{s.y}:{s.z}:{s.radius or 0}`)
	end
	return table.concat(parts, "|")
end

local function checkShapes(shapes, label)
	for i, s in shapes do
		assert(valid[s.material], `{label} shape {i}: unknown terrain material {s.material}`)
		if s.kind == "ball" then
			assert((s.radius :: number) > 0, `{label} shape {i}: ball radius`)
		elseif s.kind == "block" or s.kind == "wedge" then
			local size = s.size :: { number }
			assert(size[1] > 0 and size[2] > 0 and size[3] > 0, `{label} shape {i}: box size`)
		elseif s.kind == "snow" then
			assert((s.top :: number) > s.y, `{label} shape {i}: snow region height`)
			local side = (s.radius :: number) * 2
			assert(side * side * ((s.top :: number) - s.y) / 64 < 4e6, `{label} shape {i}: snow region too big`)
			for _, m in s.from :: { string } do
				assert(valid[m], `{label} shape {i}: snow source {m}`)
			end
		else
			error(`{label} shape {i}: unknown kind {s.kind}`)
		end
		-- Nothing flat at the field top or the horizon ground: only unrotated blocks have flat tops.
		if s.kind == "block" and (s.tilt or 0) == 0 then
			local top = Backdrop.topOf(s)
			assert(math.abs(top) > 0.05 and math.abs(top + 4) > 0.05, `{label} shape {i}: flat top at {top}`)
		end
	end
end

local function topOfRanges(shapes)
	local best = 0
	for _, s in shapes do
		if s.tag == "range" and s.material ~= "Air" and s.kind ~= "snow" then
			best = math.max(best, Backdrop.topOf(s))
		end
	end
	return best
end

-- Lobby ----------------------------------------------------------------------------------------------------------
local lobby = Backdrop.lobby()
checkShapes(lobby, "lobby")
eq(serialize(lobby), serialize(Backdrop.lobby()), "lobby plan is deterministic")
assert(serialize(lobby) ~= serialize(Backdrop.lobby(7)), "a different seed gives a different lobby")

local o = Backdrop.ArenaOrigin
local reserved = {
	minX = Backdrop.ArenaBounds.minX + o.x,
	maxX = Backdrop.ArenaBounds.maxX + o.x,
	minY = Backdrop.ArenaBounds.minY,
	maxY = Backdrop.ArenaBounds.maxY,
	minZ = Backdrop.ArenaBounds.minZ + o.z,
	maxZ = Backdrop.ArenaBounds.maxZ + o.z,
}
local sectors = {}
local ranges = 0
for i, s in lobby do
	assert(Backdrop.outside(s, reserved), `lobby shape {i} reaches into the arena's backdrop region`)
	local d = math.sqrt(s.x * s.x + s.z * s.z)
	if s.tag == "range" then
		local reach = Backdrop.reachAbove(s, 0)
		assert(
			reach < 0 or d - reach >= LobbyLayout.FieldRadius + Backdrop.FieldClearance - 1e-6,
			`lobby range shape {i} comes within {d - reach} of the field centre`
		)
		if s.kind ~= "snow" and s.material ~= "Air" then
			ranges += 1
			assert(d <= Backdrop.LobbyMaxRadius + 250, `lobby shape {i} too far out ({d})`)
			sectors[math.floor((math.atan2(s.z, s.x) + math.pi) / (math.pi * 2) * 36)] = true
		end
	elseif s.tag == "rim" then
		assert(math.abs(d - LobbyLayout.FieldRadius) < 6, `rim shape {i} hugs the field edge`)
		local top = Backdrop.topOf(s)
		assert(top > 0.5 and top < 5, `rim shape {i} stays a low lip ({top})`)
		assert(s.y - (s.radius :: number) < Backdrop.Ground, `rim shape {i} reaches the horizon ground`)
	else
		error(`unexpected lobby tag {s.tag}`)
	end
end
assert(ranges >= 60, `lobby has a real ring of mountains ({ranges} shapes)`)
local covered = 0
for k = 0, 35 do
	if sectors[k] then
		covered += 1
	end
end
assert(covered >= 26 and covered <= 36, `lobby ring covers most directions ({covered}/36 sectors)`)
local top = topOfRanges(lobby)
assert(top >= 180 and top <= 270, `lobby peaks reach {top}`)

-- snow on the lobby peaks
local snowy = 0
for _, s in lobby do
	if s.kind == "snow" then
		snowy += 1
		eq(s.material, "Snow", "lobby snow caps")
	end
end
assert(snowy >= 8, `lobby has snowy mountains ({snowy})`)

-- Field mounds: inside the outskirts, only where the predicate allows, never overlapping each other.
local mounds = Backdrop.fieldMounds(5, 12, function()
	return true
end)
assert(#mounds >= 12, `field mounds placed ({#mounds})`)
checkShapes(mounds, "field mounds")
for i, s in mounds do
	local d = math.sqrt(s.x * s.x + s.z * s.z)
	assert(d >= 320 and d <= LobbyLayout.FieldRadius, `field mound {i} in the outskirts ({d})`)
	assert(Backdrop.topOf(s) <= 14, `field mound {i} is low`)
end
eq(#Backdrop.fieldMounds(5, 12, function()
	return false
end), 0, "no mounds where the lobby forbids them")

-- Arenas ----------------------------------------------------------------------------------------------------------
local hw, hd = Lane.Arena.width / 2, Lane.Arena.depth / 2
for _, dungeon in Dungeons.List do
	local id = dungeon.id
	assert(Backdrop.Styles[id], `{id} has a backdrop style`)
	local layout = Lane.layout(id)
	local plan = Backdrop.arena(id, layout)
	checkShapes(plan, id)
	eq(serialize(plan), serialize(Backdrop.arena(id)), `{id} plan is deterministic`)

	local count, mound = 0, 0
	for i, s in plan do
		assert(Backdrop.inside(s, Backdrop.ArenaBounds), `{id} shape {i} leaves ArenaBounds`)
		local reach = Backdrop.reachAbove(s, 0)
		if s.tag == "range" then
			if s.kind ~= "snow" and s.material ~= "Air" then
				count += 1
			end
			assert(
				reach < 0 or Backdrop.rectDistance(s.x, s.z, hw, hd) - reach >= Backdrop.ArenaClearance - 1e-6,
				`{id} range shape {i} too close to the floor`
			)
		elseif s.tag == "skirt" then
			assert(Backdrop.topOf(s) < -1, `{id} skirt shape {i} stays under the floor top`)
		elseif s.tag == "water" then
			eq(s.material, "Water", `{id} water`)
			local size = s.size :: { number }
			local bx = math.max(math.abs(s.x) - size[1] / 2, 0)
			local bz = math.max(math.abs(s.z) - size[3] / 2, 0)
			-- the box's nearest point to the floor centre lies outside the floor
			assert(
				math.abs(s.x) - size[1] / 2 >= hw or math.abs(s.z) - size[3] / 2 >= hd,
				`{id} water {i} overlaps the floor ({bx}, {bz})`
			)
			assert(Backdrop.topOf(s) < 0 and Backdrop.topOf(s) > Backdrop.Ground, `{id} water level`)
		elseif s.tag == "mound" then
			mound += 1
			assert(
				Backdrop.laneDistance(s.x, s.z, layout.points) - math.max(reach, 0)
					>= Backdrop.MoundLaneClearance - 1e-6,
				`{id} mound {i} too close to the lane`
			)
			assert(Backdrop.topOf(s) <= 12, `{id} mound {i} is low`)
		else
			error(`unexpected tag {s.tag}`)
		end
	end
	assert(count >= 40, `{id} has a ring of features ({count} shapes)`)
	assert(mound >= 2, `{id} has some mounds on the floor ({mound})`)
	local t = topOfRanges(plan)
	local style = Backdrop.Styles[id]
	assert(t >= style.farHeight[1], `{id} peaks reach {t}`)
	local b = Backdrop.bounds(plan) :: Backdrop.Box
	assert(b.minX >= Backdrop.ArenaBounds.minX and b.maxZ <= Backdrop.ArenaBounds.maxZ, `{id} bounds`)
	if style.water then
		local water = 0
		for _, s in plan do
			if s.material == "Water" then
				water += 1
			end
		end
		assert(water > 0, `{id} has a sea`)
	end
end

-- Clearing an arena fills every solid shape again with Air, a voxel bigger (wedges are cleared as whole boxes).
local plan = Backdrop.arena("Station")
local clear = Backdrop.clearing(plan)
local solid = 0
for _, s in plan do
	if s.kind ~= "snow" and s.material ~= "Air" then
		solid += 1
		local c = clear[solid]
		eq(c.material, "Air", "clearing fills with Air")
		eq(c.x, s.x, "clearing in place")
		if s.kind == "ball" then
			assert((c.radius :: number) >= (s.radius :: number) + 4, "clearing ball is larger")
		else
			eq(c.kind, "block", "boxes and wedges clear as blocks")
			assert((c.size :: { number })[2] >= (s.size :: { number })[2] + 8, "clearing box is larger")
		end
	end
end
eq(#clear, solid, "one Air fill per solid shape")

print("Backdrop.spec: ok")
