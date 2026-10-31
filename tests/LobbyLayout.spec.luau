-- Run with: lune run test   (or lune run tests/LobbyLayout.spec)
local Dungeons = require("../src/shared/Dungeons")
local LobbyLayout = require("../src/shared/LobbyLayout")
local Waves = require("../src/shared/Waves")

local function eq(got, want, label)
	assert(got == want, `{label}: got {got}, want {want}`)
end

local function near(got, want, tol, label)
	assert(math.abs(got - want) <= tol, `{label}: got {got}, want {want} +- {tol}`)
end

-- scale and headline numbers match the showcase at 1.4 studs per metre
eq(LobbyLayout.StudsPerMetre, 1.4, "studs per metre")
near(LobbyLayout.FieldRadius, 588, 0.01, "field radius")
near(LobbyLayout.RingRadius, 231, 0.01, "dungeon ring radius")
near(LobbyLayout.PadRingRadius, 189, 0.01, "pad ring radius")
assert(
	LobbyLayout.PadRingRadius < LobbyLayout.RingRadius - LobbyLayout.Diorama.depth / 2,
	"pads sit in front of the diorama"
)

-- every mode is a real wave mode with the right party size
eq(#LobbyLayout.Modes, 3, "three pad kinds")
for _, m in LobbyLayout.Modes do
	local wm = Waves.Modes[m.mode]
	assert(wm, `mode {m.mode} exists in Waves.Modes`)
	assert(m.countdown > 0, `{m.mode} has a countdown`)
end

-- plots: one per dungeon in unlock order, on the far (-z) side, west to east
local plots = LobbyLayout.plots()
eq(#plots, #Dungeons.List, "one plot per dungeon")
for i, plot in plots do
	eq(plot.dungeonId, Dungeons.List[i].id, `plot {i} is dungeon {i}`)
	near(math.sqrt(plot.x ^ 2 + plot.z ^ 2), LobbyLayout.RingRadius, 0.01, `plot {i} on the ring`)
	assert(plot.z < 0, `plot {i} is on the far side`)
	if i > 1 then
		assert(plot.x > plots[i - 1].x, `plot {i} is east of plot {i - 1}`)
	end
end
assert(plots[1].x < -200, "first dungeon is in the west")
assert(plots[#plots].x > 200, "last dungeon is in the east")

-- dioramas must not overlap along the arc
local plotGap = math.sqrt((plots[2].x - plots[1].x) ^ 2 + (plots[2].z - plots[1].z) ^ 2)
assert(plotGap > LobbyLayout.Diorama.width, `diorama spacing {plotGap} exceeds width {LobbyLayout.Diorama.width}`)

-- pads: 10 dungeons x 3 modes, unique, >= 8 studs apart, inside the field, near their own plot
local pads = LobbyLayout.pads()
eq(#pads, #Dungeons.List * #LobbyLayout.Modes, "pad count")
local seen = {}
for i, pad in pads do
	local key = `{pad.dungeonId}/{pad.mode}`
	assert(not seen[key], `{key} appears once`)
	seen[key] = true
	assert(Dungeons.get(pad.dungeonId), `{key} names a real dungeon`)
	eq(pad.capacity, LobbyLayout.mode(pad.mode).capacity, `{key} capacity`)
	eq(pad.countdown, LobbyLayout.mode(pad.mode).countdown, `{key} countdown`)
	eq(pad.position[2], 0, `{key} sits on the ground`)
	assert(LobbyLayout.inField(pad.position[1], pad.position[3]), `{key} inside the field`)
	assert(
		LobbyLayout.inField(pad.position[1] + LobbyLayout.PadRadius, pad.position[3] + LobbyLayout.PadRadius),
		`{key} rim inside the field`
	)

	local plot = plots[math.ceil(i / #LobbyLayout.Modes)]
	eq(pad.dungeonId, plot.dungeonId, `pad {i} belongs to plot {plot.index}`)
	local toPlot = math.sqrt((pad.position[1] - plot.x) ^ 2 + (pad.position[3] - plot.z) ^ 2)
	assert(toPlot < 60, `{key} is within 60 studs of its plot ({toPlot})`)
	-- the pad is between the plaza and the plot
	local padR = math.sqrt(pad.position[1] ^ 2 + pad.position[3] ^ 2)
	assert(padR > LobbyLayout.PlazaRadius and padR < LobbyLayout.RingRadius, `{key} between plaza and ring`)

	for j = 1, i - 1 do
		local other = pads[j]
		local d = math.sqrt((pad.position[1] - other.position[1]) ^ 2 + (pad.position[3] - other.position[3]) ^ 2)
		assert(d >= 8, `pads {j} and {i} are {d} apart, want >= 8`)
		assert(d >= LobbyLayout.PadRadius * 2, `pads {j} and {i} do not overlap`)
	end
end

-- pads of one dungeon are in mode order along the arc, centred on the plot's radial line
for p = 1, #plots do
	local base = (p - 1) * #LobbyLayout.Modes
	local cx, cz = 0, 0
	for j = 1, #LobbyLayout.Modes do
		eq(pads[base + j].mode, LobbyLayout.Modes[j].mode, `plot {p} pad {j} mode order`)
		cx += pads[base + j].position[1] / #LobbyLayout.Modes
		cz += pads[base + j].position[3] / #LobbyLayout.Modes
	end
	near(cx, plots[p].ux * LobbyLayout.PadRingRadius, 0.01, `plot {p} pads centred (x)`)
	near(cz, plots[p].uz * LobbyLayout.PadRingRadius, 0.01, `plot {p} pads centred (z)`)
end

-- zones sit on the near side, inside the field, clear of the plaza
eq(#LobbyLayout.Zones, 5, "five zones")
for _, zone in LobbyLayout.Zones do
	assert(zone.z > 0, `{zone.id} on the near side`)
	assert(LobbyLayout.inField(zone.x + zone.radius, zone.z + zone.radius), `{zone.id} inside the field`)
	assert(math.sqrt(zone.x ^ 2 + zone.z ^ 2) - zone.radius > LobbyLayout.PlazaRadius, `{zone.id} clear of the plaza`)
end

-- every dungeon has its own accent colour for the lobby light pillar and sign
local seenAccent = {}
for _, dungeon in Dungeons.List do
	local c = LobbyLayout.Accents[dungeon.id]
	assert(c, `{dungeon.id} has an accent colour`)
	local key = `{c[1]},{c[2]},{c[3]}`
	assert(not seenAccent[key], `{dungeon.id} accent is unique`)
	seenAccent[key] = true
	assert(math.max(c[1], c[2], c[3]) >= 160, `{dungeon.id} accent is bright`)
end

print("LobbyLayout.spec: ok")
