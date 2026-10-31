-- Builds a dungeon arena out of Parts from the shared lane layout: floor, one winding lane, a gate at
-- the lane start, the dungeon's tower (the Town Hall target) at the far end and player spawns beside
-- it. Everything lives in one Folder so a run can be torn down with a single Destroy. Tower and gate are the
-- theme's imported props (ModelIds "Prop_<name>", sized by ModelFit to the showcase proportions); a missing id
-- or a failed load falls back to placeholder slabs. The tower always carries an invisible "TownHall" Part
-- sized to it: that Part is what TownHall.luau tags and what raycasts (Medic repair) hit, since the meshes
-- themselves are CanQuery = false. Building yields while the props load (in parallel, once per server).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Dungeons = require(ReplicatedStorage.Shared.Dungeons)
local Lane = require(ReplicatedStorage.Shared.Lane)
local ModelFit = require(ReplicatedStorage.Shared.ModelFit)
local Roster = require(ReplicatedStorage.Shared.Roster)
local Backdrop = require(script.Parent.Backdrop)
local Models = require(script.Parent.Models)

local Arena = {}

-- Far enough from the lobby (a grass disc of radius 588 at the origin, see LobbyLayout) that a
-- 360 x 280 arena (z from 1360 to 1640) never overlaps it.
Arena.Origin = Vector3.new(0, 0, 1500)
local LANE_THICKNESS = 0.2
local TOWER_SIZE = 16
local GATE_HEIGHT = 12
local TOWER_FRONT = 8 -- the tower's front face sits this far before its lane point (the lane stops 10 short)
-- Floor slab depth: top at y = 0, bottom above the HorizonGround top (y = -4) so the two never share a plane; the
-- backdrop's terrain skirt covers its sides.
local FLOOR_THICKNESS = 3.5

local function part(props: { [string]: any }): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in props do
		(p :: any)[k] = v
	end
	return p
end

local function rgb(c: { number }): Color3
	return Color3.fromRGB(c[1], c[2], c[3])
end

export type Built = {
	dungeonId: string,
	folder: Folder,
	townHall: Part,
	gates: { Instance }, -- one gate (Model or placeholder Part): the lane start
	spawns: { Vector3 },
	lane: { Vector3 }, -- world-space route, gate first, ending just short of the tower
	laneWidth: number,
}

-- Arena-local lane point to world space, on the floor top.
local function toWorld(p: Lane.Point): Vector3
	return Arena.Origin + Vector3.new(p.x, 0, p.z)
end

-- The theme prop as a fitted Model (pivot at the centre of its bounds, front along -Z) and its extents, or nil.
local function loadProp(name: string, height: number, maxWidth: number, maxDepth: number): (Model?, Vector3?)
	local key = ModelFit.propKey(name)
	if not Models.has(key) then
		return nil, nil
	end
	local model, size = Models.fitted(key, ModelFit.yaw(key, ModelFit.PropFiles[name]), function(s: Vector3)
		return ModelFit.fitScale(s.X, s.Y, s.Z, height, maxWidth, maxDepth)
	end)
	if model then
		for _, d in model:GetDescendants() do
			if d:IsA("BasePart") then
				d.CanCollide = true -- players bump into the tower; rays pass through to the hit Part
			end
		end
	end
	return model, size
end

-- Loads the tower and gate props side by side so the run start waits for one round trip, not two.
local function loadProps(theme: Roster.Theme)
	local tower: { model: Model?, size: Vector3? } = {}
	local gate: { model: Model?, size: Vector3? } = {}
	local pending = 2
	local caller = coroutine.running()
	local function done()
		pending -= 1
		if pending == 0 and coroutine.status(caller) == "suspended" then
			task.spawn(caller)
		end
	end
	task.spawn(function()
		tower.model, tower.size = loadProp(
			theme.tower,
			ModelFit.towerHeight(theme.towerHeight),
			ModelFit.TowerMaxWidth,
			ModelFit.TowerMaxDepth
		)
		done()
	end)
	task.spawn(function()
		gate.model, gate.size =
			loadProp(theme.gate, ModelFit.gateHeight(theme.gateHeight), ModelFit.GateMaxWidth, ModelFit.GateMaxDepth)
		done()
	end)
	if pending > 0 then
		coroutine.yield()
	end
	return tower, gate
end

function Arena.build(dungeonId: string?): Built
	Arena.destroy()

	local id = dungeonId or Dungeons.List[1].id
	local dungeon = Dungeons.get(id)
	local theme = Roster.theme(id)
	local layout = Lane.layout(id)
	-- Mountains and corner mounds in Terrain; fills in over the next frames while the props load.
	Backdrop.buildArena(id, Arena.Origin, layout)

	local folder = Instance.new("Folder")
	folder.Name = "Arena"
	folder:SetAttribute("Dungeon", id)
	folder:SetAttribute("Family", dungeon.family)

	part({
		Name = "Floor",
		Size = Vector3.new(Lane.Arena.width, FLOOR_THICKNESS, Lane.Arena.depth),
		Position = Arena.Origin - Vector3.new(0, FLOOR_THICKNESS / 2, 0),
		Color = rgb(theme.ground),
		Material = Enum.Material.Grass,
		Parent = folder,
	})

	-- One Part per lane segment, stretched a little past both ends so the joints never show a gap.
	local laneFolder = Instance.new("Folder")
	laneFolder.Name = "Lane"
	laneFolder.Parent = folder
	local lane: { Vector3 } = {}
	for i, p in layout.points do
		lane[i] = toWorld(p)
	end
	for i = 1, #lane - 1 do
		local a, b = lane[i], lane[i + 1]
		local length = (b - a).Magnitude
		if length < 0.01 then
			continue
		end
		-- Segments overlap at joints and on tight bends; equal tops z-fight (the flickering floor seen in Studio), so
		-- every segment gets its own top, 0.004 studs apart (about +0.5 at the far end of a long lane: invisible).
		local thickness = LANE_THICKNESS + i * 0.004
		local mid = (a + b) / 2 + Vector3.new(0, thickness / 2, 0)
		part({
			Name = `Lane{i}`,
			Size = Vector3.new(layout.width, thickness, length + layout.width * 0.5),
			CFrame = CFrame.lookAt(mid, mid + (b - a)),
			Color = rgb(theme.path),
			Material = Enum.Material.Cobblestone,
			Parent = laneFolder,
		})
	end

	local towerProp, gateProp = loadProps(theme)

	-- Gate at the lane start, facing along the first segment.
	local gateDir = (lane[2] - lane[1]).Unit
	local gate: Instance
	if gateProp.model and gateProp.size then
		local centre = lane[1] + Vector3.new(0, gateProp.size.Y / 2, 0)
		gateProp.model.Name = "Gate"
		gateProp.model:PivotTo(CFrame.lookAt(centre, centre + gateDir))
		gateProp.model.Parent = folder
		gate = gateProp.model
	else
		gate = part({
			Name = "Gate",
			Size = Vector3.new(layout.width + 6, GATE_HEIGHT, 2),
			CFrame = CFrame.lookAt(lane[1] + Vector3.new(0, GATE_HEIGHT / 2, 0), lane[1] + gateDir * 10),
			Color = Color3.fromRGB(40, 40, 50),
			Material = Enum.Material.Slate,
			Parent = folder,
		})
	end
	gate:SetAttribute("Model", theme.gate)

	-- The tower is the Town Hall: a Model named after the theme prop, holding the hit part. The prop faces the
	-- gate side (-Z) with its front face just behind the end of the lane.
	local towerPos = toWorld(layout.tower)
	local tower = Instance.new("Model")
	tower.Name = theme.tower
	local towerSize: Vector3
	local towerCentre: Vector3
	if towerProp.model and towerProp.size then
		towerSize = towerProp.size
		towerCentre = towerPos + Vector3.new(0, towerSize.Y / 2, -TOWER_FRONT + towerSize.Z / 2)
		towerProp.model.Name = "Prop"
		towerProp.model:PivotTo(CFrame.new(towerCentre))
		towerProp.model.Parent = tower
	else
		local height = ModelFit.towerHeight(theme.towerHeight)
		towerSize = Vector3.new(TOWER_SIZE, height, TOWER_SIZE)
		towerCentre = towerPos + Vector3.new(0, height / 2, 0)
	end
	local hasProp = towerProp.model ~= nil
	local townHall = part({
		Name = "TownHall",
		Size = Vector3.new(math.max(4, towerSize.X), math.max(4, towerSize.Y), math.max(4, towerSize.Z)),
		Position = towerCentre,
		Color = Color3.fromRGB(190, 170, 120),
		Material = Enum.Material.Brick,
		Transparency = if hasProp then 1 else 0,
		CastShadow = not hasProp,
		CanCollide = not hasProp, -- with a prop the meshes collide and this box only takes raycasts
		Parent = tower,
	})
	townHall:SetAttribute("Model", theme.tower)
	tower.PrimaryPart = townHall
	tower.Parent = folder

	-- Players stand beside the tower, on the gate side, clear of the lane's final approach.
	local spawns = {}
	local halfWidth = math.max(TOWER_SIZE, towerSize.X) / 2
	for _, x in { -(halfWidth + 14), -(halfWidth + 6), halfWidth + 6, halfWidth + 14 } do
		table.insert(spawns, towerPos + Vector3.new(x, 3, -4))
	end

	folder.Parent = Workspace
	return {
		dungeonId = id,
		folder = folder,
		townHall = townHall,
		gates = { gate },
		spawns = spawns,
		lane = lane,
		laneWidth = layout.width,
	}
end

function Arena.destroy()
	local existing = Workspace:FindFirstChild("Arena")
	if existing then
		existing:Destroy()
		Backdrop.clearArena()
	end
end

return Arena
