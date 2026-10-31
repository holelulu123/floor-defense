-- Pure sizing and facing rules for the imported 3D models (src/shared/ModelIds.luau, loaded on the server with
-- InsertService:LoadAsset). No Roblox API so Lune can test it; the server applies the numbers to the Model.
--
-- Facing: every pack is authored glTF-style with the model's front along +Z (the showcase turns each holder with
-- Object3D.lookAt, which points +Z at the target, and no creature needs a `rot` fix there). glb2fbx.py exports with
-- Blender forward -Z / up Y, which keeps glTF +Z as +Z, so after import a model looks along +Z while a Roblox
-- CFrame looks along -Z: a half turn (180 degrees) about +Y makes it face its LookVector. If a pack shows up
-- walking backwards in Studio, change its entry here (degrees, about +Y, applied once to the template).

local ModelFit = {}

ModelFit.StudsPerMetre = 1.4 -- game scale, see DESIGN.md "Stud scale decision"

ModelFit.DefaultYaw = 0

-- Pack folder (assets/<kind>/<pack>/...) -> yaw fix in degrees. Listed explicitly so one pack can be flipped.
ModelFit.PackYaw = {
	["kaykit-bandits"] = 0,
	["kaykit-skeletons"] = 0,
	["kenney-blobs"] = 0,
	["kenney-blocky"] = 0,
	["kenney-cube-pets"] = 0,
	["kenney-graveyard"] = 0,
	["kenney-mini-characters"] = 0,
	["kenney-mini-dungeon"] = 0,
	["kenney-space"] = 0,
	["kenney-ufo"] = 0,
	["quaternius-alien"] = 0,
	["quaternius-animals"] = 0,
	["quaternius-animated-monsters"] = 0,
	["quaternius-cute-fish"] = 0,
	["quaternius-cute-monsters"] = 0,
	["quaternius-cyberpunk"] = 0,
	["quaternius-dinosaurs"] = 0,
	["quaternius-easy-enemies"] = 0,
	["quaternius-farm-animals"] = 0,
	["quaternius-mechs"] = 0,
	["quaternius-monsters"] = 0,
	["quaternius-platformer"] = 0,
	["quaternius-space"] = 0,
	["quaternius-zombie"] = 0,
	-- props
	["kaykit-dungeon"] = 0,
	["kaykit-halloween"] = 0,
	["quaternius-cyberpunk-props"] = 0,
	["quaternius-dungeon"] = 0,
	["quaternius-nature"] = 0,
	["quaternius-platformer-props"] = 0,
	["quaternius-rts"] = 0,
	["quaternius-ruins"] = 0,
	["quaternius-ships"] = 0,
	["quaternius-space-props"] = 0,
	["quaternius-village"] = 0,
} :: { [string]: number }

-- Per-key override (ModelIds key -> degrees) for a single model that faces differently from its pack.
ModelFit.KeyYaw = {} :: { [string]: number }

-- Theme prop name -> source file, for the pack lookup (same files as assets/import-lists/props.txt).
ModelFit.PropFiles = {
	Arch_Door = "assets/props/quaternius-ruins/Arch_Door.glb",
	Bars = "assets/props/quaternius-dungeon/Bars.glb",
	Base_Large = "assets/props/quaternius-space-props/Base_Large.glb",
	BirchTree_Dead_Snow_1 = "assets/props/quaternius-nature/BirchTree_Dead_Snow_1.glb",
	Boat = "assets/props/quaternius-ships/Boat.glb",
	Door = "assets/props/quaternius-cyberpunk-props/Door.glb",
	Fence = "assets/props/quaternius-village/Fence.glb",
	Mill = "assets/props/quaternius-village/Mill.glb",
	Ramp = "assets/props/quaternius-space-props/Ramp.glb",
	Sail_ship = "assets/props/quaternius-ships/Sail_ship.glb",
	Temple_FirstAge_Level3 = "assets/props/quaternius-rts/Temple_FirstAge_Level3.glb",
	Temple_SecondAge_Level3 = "assets/props/quaternius-rts/Temple_SecondAge_Level3.glb",
	TownCenter_SecondAge_Level3 = "assets/props/quaternius-rts/TownCenter_SecondAge_Level3.glb",
	Turret_Cannon = "assets/props/quaternius-cyberpunk-props/Turret_Cannon.glb",
	WatchTower_FirstAge_Level3 = "assets/props/quaternius-rts/WatchTower_FirstAge_Level3.glb",
	Willow_Dead_1 = "assets/props/quaternius-nature/Willow_Dead_1.glb",
	Wonder_SecondAge_Level3 = "assets/props/quaternius-rts/Wonder_SecondAge_Level3.glb",
	arch_gate = "assets/props/kaykit-halloween/arch_gate.gltf",
	crypt = "assets/props/kaykit-halloween/crypt.gltf",
} :: { [string]: string }

-- Some packs are modelled far smaller than the rest and the catalog's `scale` makes up for it (Kenney mini
-- characters are about 0.45 m tall, so the catalog lists them at scale 4). Dividing it out leaves the body-size
-- multiplier the game applies to the archetype size.
ModelFit.PackUnit = {
	["kenney-mini-characters"] = 4,
} :: { [string]: number }

-- ModelIds keys, as scripts/roblox/import-models.py names them (non-word characters become "_").
function ModelFit.creatureKey(creatureId: string): string
	return "Creature_" .. (creatureId:gsub("[^%w_]", "_"))
end

function ModelFit.propKey(propName: string): string
	return "Prop_" .. (propName:gsub("[^%w_]", "_"))
end

-- "assets/creatures/kenney-graveyard/character-zombie.glb" -> "kenney-graveyard".
function ModelFit.pack(path: string?): string?
	if type(path) ~= "string" then
		return nil
	end
	return path:match("^assets/[^/]+/([^/]+)/")
end

-- Yaw fix in radians for a ModelIds key whose source file is `path`.
function ModelFit.yaw(key: string, path: string?): number
	local deg = ModelFit.KeyYaw[key]
	if deg == nil then
		local pack = ModelFit.pack(path)
		deg = if pack then ModelFit.PackYaw[pack] else nil
	end
	return math.rad(deg or ModelFit.DefaultYaw)
end

-- Body-size multiplier on the archetype size for a roster creature (catalog scale minus the pack's unit fix).
function ModelFit.bodyScale(scale: number, path: string?): number
	local pack = ModelFit.pack(path)
	local unit = if pack then ModelFit.PackUnit[pack] else nil
	return scale / (unit or 1)
end

-- Scale factor that makes a model of extents (x, y, z) about `height` tall. Long, low bodies (snakes, fish,
-- dragons) are sized by half their longest horizontal extent instead, so a snake is not stretched to 20 studs.
-- Optional caps keep the scaled width (x) and depth (z) inside a footprint.
function ModelFit.fitScale(
	x: number,
	y: number,
	z: number,
	height: number,
	maxWidth: number?,
	maxDepth: number?
): number
	local measure = math.max(y, math.max(x, z) * 0.5)
	if measure <= 1e-6 or height <= 0 then
		return 1
	end
	local k = height / measure
	if maxWidth and x > 1e-6 then
		k = math.min(k, maxWidth / x)
	end
	if maxDepth and z > 1e-6 then
		k = math.min(k, maxDepth / z)
	end
	return k
end

-- Dungeon props: the showcase sizes the tower and gate by the theme's metres times a map factor (W / 64 = 4.06
-- on the 260 m map, x0.9 for the tower and x0.7 for the gate), so keep those proportions at 1.4 studs per metre.
local SHOWCASE_MAP_FACTOR = 260 / 64
ModelFit.TowerMinHeight = 14
ModelFit.TowerMaxWidth = 80
ModelFit.TowerMaxDepth = 40 -- room behind the tower before the arena edge
ModelFit.GateMinHeight = 6
ModelFit.GateMaxWidth = 40
ModelFit.GateMaxDepth = 20

function ModelFit.towerHeight(metres: number): number
	return math.max(ModelFit.TowerMinHeight, metres * SHOWCASE_MAP_FACTOR * 0.9 * ModelFit.StudsPerMetre)
end

function ModelFit.gateHeight(metres: number): number
	return math.max(ModelFit.GateMinHeight, metres * SHOWCASE_MAP_FACTOR * 0.7 * ModelFit.StudsPerMetre)
end

return ModelFit
