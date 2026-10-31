-- Run with: lune run tests/Environments.spec
local Dungeons = require("../src/shared/Dungeons")
local Environments = require("../src/shared/Environments")

local function range(value: any, lo: number, hi: number, label: string)
	assert(type(value) == "number" and value == value, `{label}: not a number ({value})`)
	assert(value >= lo and value <= hi, `{label}: {value} outside {lo}..{hi}`)
end

local function rgb(c: any, label: string)
	assert(type(c) == "table" and #c == 3, `{label}: want 3 channels`)
	for i, v in c do
		range(v, 0, 255, `{label}[{i}]`)
		assert(v == math.floor(v), `{label}[{i}]: not an integer ({v})`)
	end
end

local function check(env: any, name: string)
	range(env.clockTime, 0, 24, `{name} clockTime`)
	range(env.brightness, 0, 10, `{name} brightness`)
	rgb(env.ambient, `{name} ambient`)
	rgb(env.outdoorAmbient, `{name} outdoorAmbient`)
	local a = env.atmosphere
	range(a.density, 0, 1, `{name} atmosphere.density`)
	range(a.offset, 0, 1, `{name} atmosphere.offset`)
	rgb(a.color, `{name} atmosphere.color`)
	rgb(a.decay, `{name} atmosphere.decay`)
	range(a.glare, 0, 10, `{name} atmosphere.glare`)
	range(a.haze, 0, 10, `{name} atmosphere.haze`)
	range(env.clouds.cover, 0, 1, `{name} clouds.cover`)
	range(env.clouds.density, 0, 1, `{name} clouds.density`)
	rgb(env.clouds.color, `{name} clouds.color`)
	range(env.sunRays, 0, 1, `{name} sunRays`)
	range(env.grade.brightness, -1, 1, `{name} grade.brightness`)
	range(env.grade.contrast, -1, 1, `{name} grade.contrast`)
	range(env.grade.saturation, -1, 1, `{name} grade.saturation`)
	rgb(env.grade.tint, `{name} grade.tint`)
end

check(Environments.Lobby, "Lobby")
assert(Environments.Lobby.clockTime >= 10 and Environments.Lobby.clockTime <= 16, "lobby is daytime")
assert(Environments.Lobby.clouds.cover > 0, "lobby has clouds")

local count = 0
for _, d in Dungeons.List do
	local env = Environments.Dungeons[d.id]
	assert(env, `dungeon {d.id} has an environment`)
	check(env, d.id)
	assert(Environments.forZone(true, d.id) == env, `forZone picks {d.id}`)
	assert(Environments.forZone(nil, d.id) == Environments.Lobby, `{d.id} outside a run is the lobby`)
	count += 1
end
for id in Environments.Dungeons do
	assert(pcall(Dungeons.get, id), `environment {id} is a real dungeon`)
end

-- untrusted / missing attributes fall back to the lobby
assert(Environments.forZone(true, nil) == Environments.Lobby, "missing dungeon id")
assert(Environments.forZone(true, "Nowhere") == Environments.Lobby, "unknown dungeon id")
assert(Environments.forZone(true, 5) == Environments.Lobby, "non-string dungeon id")
assert(Environments.forZone("yes", "Graveyard") == Environments.Lobby, "InRun must be true")
range(Environments.TweenSeconds, 0.5, 5, "tween seconds")

print(`Environments: ok ({count} dungeons)`)
