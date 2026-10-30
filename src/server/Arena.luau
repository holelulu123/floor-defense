-- Builds a dungeon arena out of Parts from the shared lane layout: floor, one winding lane, a gate at
-- the lane start, the dungeon's tower (the Town Hall target) at the far end and player spawns beside
-- it. Everything lives in one Folder so a run can be torn down with a single Destroy. Tower and gate
-- are placeholder Parts named after the theme's prop until the meshes are imported.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Dungeons = require(ReplicatedStorage.Shared.Dungeons)
local Lane = require(ReplicatedStorage.Shared.Lane)
local Roster = require(ReplicatedStorage.Shared.Roster)

local Arena = {}

-- Far enough from the 120 x 120 lobby at the origin that a 360 x 280 arena never overlaps it.
Arena.Origin = Vector3.new(0, 0, 600)
local LANE_THICKNESS = 0.2
local TOWER_SIZE = 16
local GATE_HEIGHT = 12
local STUDS_PER_METRE = 2.5 -- for prop heights the theme lists in showcase metres

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
	gates: { Part }, -- one gate: the lane start
	spawns: { Vector3 },
	lane: { Vector3 }, -- world-space route, gate first, ending just short of the tower
	laneWidth: number,
}

-- Arena-local lane point to world space, on the floor top.
local function toWorld(p: Lane.Point): Vector3
	return Arena.Origin + Vector3.new(p.x, 0, p.z)
end

function Arena.build(dungeonId: string?): Built
	Arena.destroy()

	local id = dungeonId or Dungeons.List[1].id
	local dungeon = Dungeons.get(id)
	local theme = Roster.theme(id)
	local layout = Lane.layout(id)

	local folder = Instance.new("Folder")
	folder.Name = "Arena"
	folder:SetAttribute("Dungeon", id)
	folder:SetAttribute("Family", dungeon.family)

	part({
		Name = "Floor",
		Size = Vector3.new(Lane.Arena.width, 1, Lane.Arena.depth),
		Position = Arena.Origin - Vector3.new(0, 0.5, 0),
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
		local mid = (a + b) / 2 + Vector3.new(0, LANE_THICKNESS / 2, 0)
		part({
			Name = `Lane{i}`,
			Size = Vector3.new(layout.width, LANE_THICKNESS, length + layout.width * 0.5),
			CFrame = CFrame.lookAt(mid, mid + (b - a)),
			Color = rgb(theme.path),
			Material = Enum.Material.Cobblestone,
			Parent = laneFolder,
		})
	end

	-- Gate at the lane start, facing along the first segment.
	local gateDir = (lane[2] - lane[1]).Unit
	local gate = part({
		Name = "Gate",
		Size = Vector3.new(layout.width + 6, GATE_HEIGHT, 2),
		CFrame = CFrame.lookAt(lane[1] + Vector3.new(0, GATE_HEIGHT / 2, 0), lane[1] + gateDir * 10),
		Color = Color3.fromRGB(40, 40, 50),
		Material = Enum.Material.Slate,
		Parent = folder,
	})
	gate:SetAttribute("Model", theme.gate)

	-- The tower is the Town Hall: a Model named after the theme prop, holding the hit part.
	local towerPos = toWorld(layout.tower)
	local towerHeight = math.max(14, theme.towerHeight * STUDS_PER_METRE)
	local tower = Instance.new("Model")
	tower.Name = theme.tower
	local townHall = part({
		Name = "TownHall",
		Size = Vector3.new(TOWER_SIZE, towerHeight, TOWER_SIZE),
		Position = towerPos + Vector3.new(0, towerHeight / 2, 0),
		Color = Color3.fromRGB(190, 170, 120),
		Material = Enum.Material.Brick,
		Parent = tower,
	})
	townHall:SetAttribute("Model", theme.tower)
	tower.PrimaryPart = townHall
	tower.Parent = folder

	-- Players stand beside the tower, on the gate side, clear of the lane's final approach.
	local spawns = {}
	for _, x in { -22, -14, 14, 22 } do
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
	end
end

return Arena
