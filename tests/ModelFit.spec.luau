-- Run with: lune run test   (or lune run tests/ModelFit.spec)
-- Sizing/facing rules for imported models, and that every roster creature and theme prop has an import entry.
local fs = require("@lune/fs")
local ModelFit = require("../src/shared/ModelFit")
local Roster = require("../src/shared/Roster")

local function eq(got, want, label)
	assert(got == want, `{label}: got {got}, want {want}`)
end
local function near(got, want, label)
	assert(math.abs(got - want) < 1e-6, `{label}: got {got}, want {want}`)
end

-- keys follow import-models.py (non-word characters -> "_")
eq(ModelFit.creatureKey("Zombie"), "Creature_Zombie", "plain key")
eq(ModelFit.creatureKey("Skull Hopper"), "Creature_Skull_Hopper", "space")
eq(ModelFit.creatureKey("S-Ghost"), "Creature_S_Ghost", "dash")
eq(ModelFit.propKey("arch_gate"), "Prop_arch_gate", "prop key")

-- import lists: key -> source file
local function readList(path: string): { [string]: string }
	local out = {}
	for line in fs.readFile(path):gmatch("[^\n]+") do
		local key, src = line:match("^(%S+)%s+(%S+)")
		if key and key:sub(1, 1) ~= "#" then
			out[key] = src
		end
	end
	return out
end
local creatures = readList("assets/import-lists/creatures.txt")
local props = readList("assets/import-lists/props.txt")

for familyId, list in Roster.Families do
	for _, c in list do
		local key = ModelFit.creatureKey(c.id)
		eq(creatures[key], c.model, `{familyId}/{c.id} import entry {key}`)
		assert(ModelFit.pack(c.model) ~= nil, `{c.id} model path has a pack`)
		local pack = ModelFit.pack(c.model) :: string
		assert(ModelFit.PackYaw[pack] ~= nil, `pack {pack} has a yaw entry`)
	end
end
for dungeonId, theme in Roster.Themes do
	for _, name in { theme.tower, theme.gate } do
		local key = ModelFit.propKey(name)
		eq(props[key], ModelFit.PropFiles[name], `{dungeonId} prop {name} import entry`)
		local pack = ModelFit.pack(ModelFit.PropFiles[name]) :: string
		assert(ModelFit.PackYaw[pack] ~= nil, `prop pack {pack} has a yaw entry`)
	end
end

-- pack, yaw, body scale
eq(ModelFit.pack("assets/creatures/kenney-graveyard/character-zombie.glb"), "kenney-graveyard", "pack")
eq(ModelFit.pack("nope.glb"), nil, "no pack")
near(
	ModelFit.yaw("Creature_Zombie", "assets/creatures/kenney-graveyard/character-zombie.glb"),
	0,
	"faces forward (seen in Studio 2026-10-31)"
)
ModelFit.KeyYaw.Test = 90
near(ModelFit.yaw("Test", "assets/creatures/kenney-graveyard/x.glb"), math.pi / 2, "key override")
ModelFit.KeyYaw.Test = nil
near(ModelFit.yaw("X", "assets/creatures/unknown-pack/x.glb"), math.rad(ModelFit.DefaultYaw), "default yaw")
near(ModelFit.bodyScale(4, "assets/creatures/kenney-mini-characters/a.glb"), 1, "mini characters unit fix")
near(ModelFit.bodyScale(4.4, "assets/creatures/kenney-mini-characters/a.glb"), 1.1, "mini characters bigger")
near(ModelFit.bodyScale(1.3, "assets/creatures/kaykit-skeletons/a.glb"), 1.3, "plain scale")
for _, list in Roster.Families do
	for _, c in list do
		local s = ModelFit.bodyScale(c.scale, c.model)
		assert(s >= 0.4 and s <= 2.6, `{c.id} body scale {s} is plausible`)
	end
end

-- fitScale: by height, by half the longest side for long bodies, footprint caps
near(ModelFit.fitScale(1, 2, 1, 4), 2, "height fit")
near(ModelFit.fitScale(1, 0.5, 6, 3), 1, "long snake by half its length")
near(ModelFit.fitScale(10, 10, 40, 20, 80, 40), 1, "depth cap")
near(ModelFit.fitScale(50, 10, 10, 20, 40, nil), 0.8, "width cap")
near(ModelFit.fitScale(0, 0, 0, 3), 1, "empty model is left alone")

-- prop heights keep the showcase proportions
assert(ModelFit.towerHeight(7) > 30 and ModelFit.towerHeight(7) < 40, "crypt tower about 36 studs")
eq(ModelFit.towerHeight(1), ModelFit.TowerMinHeight, "tower minimum")
assert(ModelFit.gateHeight(4) > ModelFit.GateMinHeight, "gate scales")
eq(ModelFit.gateHeight(0.5), ModelFit.GateMinHeight, "gate minimum")

-- creature heights: a Runner (3 studs raw) stands as tall as a player; nothing smaller than 4.5 or above 4 players
near(ModelFit.creatureHeight(3), 5, "runner is player height")
eq(ModelFit.creatureHeight(1), ModelFit.MinCreatureHeight, "small creatures grow to the minimum")
eq(ModelFit.creatureHeight(22), 20, "bosses stop at 4x a player")

print("ModelFit: ok")
