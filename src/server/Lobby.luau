-- Lobby hub built from Parts to the layout in LobbyLayout (the showcase's `showLobby`): a grass
-- field, a stone spawn plaza, an arc of dungeon dioramas in unlock order each with its own Solo, Duo
-- and Squad pads, brick paths and a ring road, the Scoreboard and Shop plazas and three reserved
-- plots. Pads count the players standing on them and fire onLaunch(mode, players, dungeonId) when the
-- countdown finishes; countdown rules live in PadLogic so they stay unit-testable. Meshes replace the
-- placeholder blocks later; every Part that stands in for a prop carries a "Model" attribute.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local BackdropPlan = require(ReplicatedStorage.Shared.Backdrop)
local Config = require(ReplicatedStorage.Shared.Config)
local Dungeons = require(ReplicatedStorage.Shared.Dungeons)
local LobbyLayout = require(ReplicatedStorage.Shared.LobbyLayout)
local PadLogic = require(ReplicatedStorage.Shared.PadLogic)
local ModelFit = require(ReplicatedStorage.Shared.ModelFit)
local Roster = require(ReplicatedStorage.Shared.Roster)
local Backdrop = require(script.Parent.Backdrop)
local Models = require(script.Parent.Models)
local PlayerData = require(script.Parent.PlayerData)

local Lobby = {}

local POLL_SECONDS = 0.2
local LOCKED_MESSAGE_SECONDS = 2

-- Ground layers, top surface heights. Each sits a little above the last so nothing z-fights.
local Y_FIELD = 0
local Y_PATCH = 0.05
local Y_PATH = 0.15 -- dungeon spokes (they only overlap each other under the plaza)
local Y_ZONE_PATH = 0.17 -- paths to the scoreboard, shop and reserved plots (+0.008 each, up to 0.21)
local Y_ROAD = 0.22 -- ring road segments, crossing the spokes; consecutive segments alternate +0.03
local Y_PLAZA = 0.3
-- Dungeon plinths: each diorama stands on its own stone block whose top is PLINTH_HEIGHT above the plaza plus
-- index * 0.01 (unique per plot), with a step half as high in front of it where the spoke arrives.
local PLINTH_HEIGHT = 2.4
local PAD_HEIGHT = 0.5

local GRASS = Color3.fromRGB(79, 138, 58)
local PATCHES = { Color3.fromRGB(90, 154, 66), Color3.fromRGB(70, 125, 51), Color3.fromRGB(98, 159, 72) }
local STONE = Color3.fromRGB(142, 133, 113)
local DIRT = Color3.fromRGB(122, 106, 74)
local BRICK = Color3.fromRGB(170, 112, 84)
local WOOD = Color3.fromRGB(90, 70, 50)
local MODE_COLORS = {
	Solo = Color3.fromRGB(123, 216, 143),
	Duo = Color3.fromRGB(95, 184, 255),
	Squad = Color3.fromRGB(255, 138, 95),
}
local MODE_SUBTITLES = { Solo = "1 player", Duo = "2 players", Squad = "4 players" }
local LOCKED_GREY = Color3.fromRGB(150, 150, 158)
local MARKER_TAG = "LobbyDungeonMarker" -- LobbyMarkers.client recolours these per player level
local BEAM_HEIGHT = 160

type Pad = {
	def: LobbyLayout.PadDef,
	unlockLevel: number,
	part: Part,
	label: TextLabel,
	logic: PadLogic.Pad,
	messageUntil: number,
}

local pads: { Pad } = {}
local locked = false
local unlockAll = Config.UnlockAllInStudio and RunService:IsStudio()

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

-- A flat disc with its top at `top`.
local function disc(name: string, x: number, z: number, radius: number, thickness: number, top: number, props): Part
	local p = part({
		Name = name,
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(thickness, radius * 2, radius * 2),
		CFrame = CFrame.new(x, top - thickness / 2, z) * CFrame.Angles(0, 0, math.pi / 2),
	})
	for k, v in props do
		(p :: any)[k] = v
	end
	return p
end

-- A flat strip from (x1, z1) to (x2, z2) with its top at `top`. Strips that overlap must get different tops (equal
-- tops z-fight: the flickering paths seen in Studio), see the Y_ layer constants.
local function strip(
	name: string,
	x1: number,
	z1: number,
	x2: number,
	z2: number,
	width: number,
	top: number,
	props
): Part
	local a = Vector3.new(x1, 0, z1)
	local b = Vector3.new(x2, 0, z2)
	local length = (b - a).Magnitude
	local thickness = 0.2
	local mid = (a + b) / 2 + Vector3.new(0, top - thickness / 2, 0)
	local p = part({
		Name = name,
		Size = Vector3.new(width, thickness, length + width * 0.5),
		CFrame = CFrame.lookAt(mid, mid + (b - a)),
	})
	for k, v in props do
		(p :: any)[k] = v
	end
	return p
end

local function brickProps(): { [string]: any }
	return { Color = BRICK, Material = Enum.Material.Brick }
end

-- Floating title over a point: big text plus a smaller line under it.
local function billboard(
	parent: Instance,
	height: number,
	text: string,
	sub: string,
	color: Color3,
	width: number,
	maxDistance: number?
): TextLabel
	local gui = Instance.new("BillboardGui")
	gui.Name = "Sign"
	-- Scale units on a BillboardGui are studs, so signs shrink with distance instead of piling up on screen.
	local studs = width / 20
	gui.Size = UDim2.fromScale(studs, studs * 0.3)
	gui.StudsOffsetWorldSpace = Vector3.new(0, height, 0)
	gui.MaxDistance = maxDistance or if width <= 170 then 110 else 260
	gui.AlwaysOnTop = false
	gui.Parent = parent

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.fromScale(1, 0.6)
	title.BackgroundTransparency = 1
	title.TextScaled = true
	title.Font = Enum.Font.GothamBlack
	title.TextColor3 = color
	title.TextStrokeTransparency = 0.3
	title.Text = text
	title.Parent = gui

	local subtitle = Instance.new("TextLabel")
	subtitle.Name = "Subtitle"
	subtitle.Position = UDim2.fromScale(0, 0.6)
	subtitle.Size = UDim2.fromScale(1, 0.4)
	subtitle.BackgroundTransparency = 1
	subtitle.TextScaled = true
	subtitle.Font = Enum.Font.GothamBold
	subtitle.TextColor3 = Color3.new(1, 1, 1)
	subtitle.TextStrokeTransparency = 0.4
	subtitle.Text = sub
	subtitle.Parent = gui
	return subtitle
end

local function post(x: number, z: number, height: number, parent: Instance, base: number?): Part
	local bottom = base or Y_PLAZA
	return part({
		Name = "Post",
		Size = Vector3.new(1, height, 1),
		Position = Vector3.new(x, bottom + height / 2, z),
		Color = WOOD,
		Material = Enum.Material.Wood,
		Parent = parent,
	})
end

-- Areas kept clear of trees: { x, z, radius } discs and path segments.
local keepClear: { { number } } = {}
local keepSpokes: { { number } } = {}

local function segmentDistance(x: number, z: number, s: { number }): number
	local dx, dz = s[3] - s[1], s[4] - s[2]
	local len2 = dx * dx + dz * dz
	local t = if len2 > 0 then math.clamp(((x - s[1]) * dx + (z - s[2]) * dz) / len2, 0, 1) else 0
	return math.sqrt((x - s[1] - dx * t) ^ 2 + (z - s[2] - dz * t) ^ 2)
end

local function isFree(x: number, z: number, margin: number?): boolean
	local m = margin or 0
	for _, k in keepClear do
		if math.sqrt((x - k[1]) ^ 2 + (z - k[2]) ^ 2) <= k[3] + m then
			return false
		end
	end
	for _, s in keepSpokes do
		if segmentDistance(x, z, s) <= 9 + m then
			return false
		end
	end
	return true
end

local function buildField(folder: Folder, random: Random)
	local field = disc("Field", 0, 0, LobbyLayout.FieldRadius, 2, Y_FIELD, {
		Color = GRASS,
		Material = Enum.Material.Grass,
	})
	field.Parent = folder

	local patches = Instance.new("Folder")
	patches.Name = "Meadow"
	patches.Parent = folder
	-- Patches never overlap each other: two coplanar discs z-fight (flickering meadow seen in Studio).
	local placed: { { number } } = {}
	for i = 1, 40 do
		local a = random:NextNumber() * math.pi * 2
		local d = 56 + random:NextNumber() * (LobbyLayout.FieldRadius - 84)
		local x, z, radius = math.cos(a) * d, math.sin(a) * d, 17 + random:NextNumber() * 42
		local clear = true
		for _, q in placed do
			if math.sqrt((x - q[1]) ^ 2 + (z - q[2]) ^ 2) < radius + q[3] + 2 then
				clear = false
				break
			end
		end
		if not clear then
			continue
		end
		table.insert(placed, { x, z, radius })
		disc(`Patch{i}`, x, z, radius, 0.2, Y_PATCH, {
			Color = PATCHES[i % 3 + 1],
			Material = Enum.Material.Grass,
			Parent = patches,
		})
	end
end

local function buildPlaza(folder: Folder)
	local plaza = Instance.new("Folder")
	plaza.Name = "SpawnPlaza"
	plaza.Parent = folder
	disc(
		"Plaza",
		0,
		0,
		LobbyLayout.PlazaRadius,
		0.6,
		Y_PLAZA,
		{ Color = STONE, Material = Enum.Material.Slate, Parent = plaza }
	)

	-- Bonfire placeholder in the middle, benches around it, spawns between the benches.
	local fire = part({
		Name = "Bonfire",
		Size = Vector3.new(4, 3, 4),
		Position = Vector3.new(0, Y_PLAZA + 1.5, 0),
		Color = Color3.fromRGB(255, 140, 40),
		Material = Enum.Material.Neon,
		Parent = plaza,
	})
	fire:SetAttribute("Model", "Bonfire_Lit")
	billboard(fire, 16, "SPAWN", "players arrive here", Color3.fromRGB(232, 233, 236), 220)

	for i = 0, 5 do
		local a = i / 6 * math.pi * 2
		local bench = part({
			Name = "Bench",
			Size = Vector3.new(5, 1.5, 1.5),
			CFrame = CFrame.new(math.cos(a) * 12.6, Y_PLAZA + 0.75, math.sin(a) * 12.6) * CFrame.Angles(0, -a, 0),
			Color = WOOD,
			Material = Enum.Material.WoodPlanks,
			Parent = plaza,
		})
		bench:SetAttribute("Model", "Bench_1")

		local sa = a + math.pi / 6
		local spawn = Instance.new("SpawnLocation")
		spawn.Name = `Spawn{i + 1}`
		spawn.Shape = Enum.PartType.Cylinder
		spawn.Size = Vector3.new(0.2, 6, 6)
		spawn.CFrame = CFrame.new(math.cos(sa) * 20, Y_PLAZA + 0.1, math.sin(sa) * 20)
			* CFrame.Angles(0, 0, math.pi / 2)
		spawn.Anchored = true
		spawn.Neutral = true
		spawn.Duration = 0
		spawn.Color = Color3.fromRGB(170, 162, 142)
		spawn.Material = Enum.Material.Slate
		spawn.TopSurface = Enum.SurfaceType.Smooth
		spawn.Parent = plaza
	end
	table.insert(keepClear, { 0, 0, LobbyLayout.PlazaRadius + 14 })
end

-- Brick ring road past every pad trio, as short straight segments along the arc.
local function buildRingRoad(folder: Folder)
	local road = Instance.new("Folder")
	road.Name = "RingRoad"
	road.Parent = folder
	local r = LobbyLayout.PadRingRadius
	local steps = 80
	local a0 = LobbyLayout.ArcStart - math.rad(2)
	local a1 = LobbyLayout.ArcEnd + math.rad(2)
	for i = 0, steps - 1 do
		local s = a0 + (a1 - a0) * i / steps
		local e = a0 + (a1 - a0) * (i + 1) / steps
		strip(
			`Road{i + 1}`,
			math.cos(s) * r,
			math.sin(s) * r,
			math.cos(e) * r,
			math.sin(e) * r,
			LobbyLayout.RingRoadWidth,
			Y_ROAD + (i % 2) * 0.03,
			{ Color = BRICK, Material = Enum.Material.Brick, Parent = road }
		)
	end
end

local function buildPad(def: LobbyLayout.PadDef, unlockLevel: number, parent: Instance): Pad
	local color = MODE_COLORS[def.mode] or Color3.fromRGB(200, 200, 200)
	local p = disc(
		`Pad_{def.dungeonId}_{def.mode}`,
		def.position[1],
		def.position[3],
		LobbyLayout.PadRadius,
		PAD_HEIGHT,
		def.position[2] + PAD_HEIGHT,
		{
			Color = color,
			Material = Enum.Material.Neon,
			Transparency = 0.35,
			Parent = parent,
		}
	)
	p:SetAttribute("Dungeon", def.dungeonId)
	p:SetAttribute("Mode", def.mode)
	p:SetAttribute("Capacity", def.capacity)
	local rim = disc("Rim", def.position[1], def.position[3], LobbyLayout.PadRadius + 0.6, 0.3, def.position[2] + 0.3, {
		Color = Color3.new(1, 1, 1),
		Material = Enum.Material.SmoothPlastic,
		Parent = p,
	})
	rim.Name = "Rim"
	local label = billboard(p, 7, def.mode:upper(), MODE_SUBTITLES[def.mode] or "", color, 170)
	return {
		def = def,
		unlockLevel = unlockLevel,
		part = p,
		label = label,
		logic = PadLogic.new(def.capacity, def.countdown),
		messageUntil = 0,
	}
end

-- Replaces a placeholder block with the theme's imported prop (same footprint, standing on the same floor, front
-- toward the placeholder's -Z) once the model has loaded; the block stays if the model is missing or fails.
local function swapForProp(placeholder: Part, propName: string, height: number, maxWidth: number)
	task.spawn(function()
		local key = ModelFit.propKey(propName)
		if not Models.has(key) then
			return
		end
		local model, size = Models.fitted(key, ModelFit.yaw(key, ModelFit.PropFiles[propName]), function(s: Vector3)
			return ModelFit.fitScale(s.X, s.Y, s.Z, height, maxWidth, maxWidth)
		end)
		if not model or not size or not placeholder.Parent then
			return
		end
		model:PivotTo(placeholder.CFrame * CFrame.new(0, (size.Y - placeholder.Size.Y) / 2, 0))
		model.Name = placeholder.Name
		model.Parent = placeholder.Parent
		placeholder:Destroy()
	end)
end

-- Whether a dungeon shows as open before any player's level is known (the client restyles it per player).
local function openByDefault(dungeon: Dungeons.Dungeon): boolean
	return unlockAll or dungeon.unlockLevel <= 1
end

local function markerSubtitle(dungeon: Dungeons.Dungeon, open: boolean): string
	if not open then
		return `LOCKED - reach Level {dungeon.unlockLevel}`
	end
	return if dungeon.unlockLevel > 1 then `Level {dungeon.unlockLevel} - open` else "Level 1 - start here"
end

-- What makes a plot read from the spawn plaza: a stone plinth with a step, a tall light pillar in the dungeon's
-- accent colour and a big name sign. Grouped in a persistent Model (streamed to every client from the start) tagged
-- for LobbyMarkers.client, which greys out the pillar and sign for dungeons above the local player's level.
local function buildMarker(
	dungeon: Dungeons.Dungeon,
	frame: CFrame,
	plinthTop: number,
	signHeight: number,
	parent: Instance
)
	local depth = LobbyLayout.Diorama.depth
	local width = LobbyLayout.Diorama.width
	local accent = rgb(LobbyLayout.accent(dungeon.id))
	local open = openByDefault(dungeon)
	local color = if open then accent else LOCKED_GREY

	local marker = Instance.new("Model")
	marker.Name = "Marker"
	marker.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
	marker:SetAttribute("Dungeon", dungeon.id)
	marker:SetAttribute("UnlockLevel", dungeon.unlockLevel)
	marker:SetAttribute("Accent", accent)

	-- The plinth sinks below the field so only its top and sides show.
	local bottom = Y_FIELD - 1
	local plinth = part({
		Name = "Plinth",
		Size = Vector3.new(width + 4, plinthTop - bottom, depth + 4),
		CFrame = frame * CFrame.new(0, (plinthTop + bottom) / 2, 0),
		Color = Color3.fromRGB(118, 112, 104),
		Material = Enum.Material.Cobblestone,
		Parent = marker,
	})
	marker.PrimaryPart = plinth
	-- Step where the spoke arrives: reaches 0.5 into the plinth, top halfway up (lower than the plinth top).
	local stepTop = (Y_PLAZA + plinthTop) / 2
	part({
		Name = "Step",
		Size = Vector3.new(LobbyLayout.PathWidth + 2, stepTop - bottom, 4.5),
		CFrame = frame * CFrame.new(0, (stepTop + bottom) / 2, -(depth + 4) / 2 - 2 + 0.5),
		Color = Color3.fromRGB(128, 121, 112),
		Material = Enum.Material.Cobblestone,
		Parent = marker,
	})

	-- Light pillar behind the tower; its foot is sunk into the plinth so no face sits on the plinth top, and the glow
	-- stays inside the plinth's footprint.
	local beamFoot = plinthTop - 1
	local beamPos = frame * CFrame.new(0, beamFoot + BEAM_HEIGHT / 2, depth / 2 - 1.6)
	local vertical = CFrame.Angles(0, 0, math.pi / 2) -- a Cylinder's axis is its X
	part({
		Name = "Beam",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(BEAM_HEIGHT, 2.6, 2.6),
		CFrame = beamPos * vertical,
		Color = color,
		Material = Enum.Material.Neon,
		Transparency = if open then 0.15 else 0.55,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		CastShadow = false,
		Parent = marker,
	})
	part({
		Name = "Glow",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(BEAM_HEIGHT - 10, 7, 7),
		CFrame = (beamPos * CFrame.new(0, -5, 0)) * vertical,
		Color = color,
		Material = Enum.Material.Neon,
		Transparency = if open then 0.82 else 0.93,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		CastShadow = false,
		Parent = marker,
	})
	local lightAt = Instance.new("Attachment")
	lightAt.Name = "BeamLight"
	lightAt.Position = Vector3.new(0, plinth.Size.Y / 2 + 8, depth / 2 - 2)
	lightAt.Parent = plinth
	local light = Instance.new("PointLight")
	light.Color = accent
	light.Range = 40
	light.Brightness = 2.5
	light.Enabled = open
	light.Parent = lightAt

	-- Name sign high over the diorama, readable across the field.
	local subtitle = billboard(
		plinth,
		plinth.Size.Y / 2 + signHeight,
		dungeon.name,
		markerSubtitle(dungeon, open),
		if open then accent:Lerp(Color3.new(1, 1, 1), 0.35) else LOCKED_GREY,
		880,
		1200
	)
	local sign = subtitle.Parent :: BillboardGui
	sign.Name = "NameSign"
	sign.LightInfluence = 0
	subtitle.TextColor3 = if open then Color3.new(1, 1, 1) else Color3.fromRGB(205, 205, 210)

	CollectionService:AddTag(marker, MARKER_TAG)
	marker.Parent = parent
	return marker
end

-- One dungeon's plot: brick spoke from the plaza, a themed diorama on a stone plinth with a mini tower and gate, a
-- light pillar and the name signs, and the three pads on the pad ring in front of it.
local function buildPlot(plot: LobbyLayout.Plot, folder: Folder, padFolder: Folder)
	local dungeon = Dungeons.get(plot.dungeonId)
	local theme = Roster.theme(plot.dungeonId)
	local plotFolder = Instance.new("Folder")
	plotFolder.Name = `Plot_{dungeon.id}`
	plotFolder.Parent = folder

	local radial = Vector3.new(plot.ux, 0, plot.uz)
	local centre = Vector3.new(plot.x, 0, plot.z)
	-- Diorama frame: -Z of the floor faces the plaza (the gate side), +Z is the tower side.
	local frame = CFrame.lookAt(centre, centre - radial)
	local depth = LobbyLayout.Diorama.depth
	local width = LobbyLayout.Diorama.width
	-- Plinth top (unique per plot); the diorama floor's top sits 0.3 above it, everything else stands on `base`.
	local plinthTop = Y_PLAZA + PLINTH_HEIGHT + plot.index * 0.01
	local base = plinthTop + 0.3
	local towerHeight = math.clamp(theme.towerHeight * 1.4 * 1.6, 16, 29)
	buildMarker(dungeon, frame, plinthTop, towerHeight + 16, plotFolder)

	local floor = part({
		Name = "Diorama",
		Size = Vector3.new(width, 0.6, depth),
		CFrame = frame * CFrame.new(0, base - 0.3, 0),
		Color = rgb(theme.ground),
		Material = Enum.Material.Grass,
		Parent = plotFolder,
	})
	floor:SetAttribute("Dungeon", dungeon.id)

	-- Mini lane down the middle in the theme's path colour, from the gate to the tower.
	part({
		Name = "MiniLane",
		Size = Vector3.new(4, 0.2, depth * 0.7),
		CFrame = frame * CFrame.new(0, base + 0.1, -depth * 0.05),
		Color = rgb(theme.path),
		Material = Enum.Material.Cobblestone,
		Parent = plotFolder,
	})

	local tower = part({
		Name = theme.tower,
		Size = Vector3.new(12, towerHeight, 12),
		CFrame = frame * CFrame.new(0, base + towerHeight / 2, depth / 2 - 12),
		Color = Color3.fromRGB(190, 170, 120),
		Material = Enum.Material.Brick,
		Parent = plotFolder,
	})
	tower:SetAttribute("Model", theme.tower)
	swapForProp(tower, theme.tower, towerHeight, 22)

	local gate = part({
		Name = theme.gate,
		Size = Vector3.new(8, 4, 1),
		CFrame = frame * CFrame.new(0, base + 2, -depth / 2 + 2),
		Color = Color3.fromRGB(40, 40, 50),
		Material = Enum.Material.Slate,
		Parent = plotFolder,
	})
	gate:SetAttribute("Model", theme.gate)
	swapForProp(gate, theme.gate, 6, 10)

	-- The sign: a post beside the gate with the name and unlock level.
	local signPost = post(
		plot.x - plot.tx * 8 - plot.ux * (depth / 2 - 4),
		plot.z - plot.tz * 8 - plot.uz * (depth / 2 - 4),
		10,
		plotFolder,
		base
	)
	signPost.Name = "SignPost"
	local sub = if dungeon.unlockLevel > 1 then `Unlocks at Level {dungeon.unlockLevel}` else "Level 1"
	billboard(signPost, 10, dungeon.name, sub, Color3.fromRGB(255, 180, 84), 280)

	-- Spoke from the plaza edge to the diorama's near edge.
	strip(
		`Spoke_{dungeon.id}`,
		plot.ux * LobbyLayout.SpokeStart,
		plot.uz * LobbyLayout.SpokeStart,
		plot.ux * LobbyLayout.SpokeEnd,
		plot.uz * LobbyLayout.SpokeEnd,
		LobbyLayout.PathWidth,
		Y_PATH,
		{ Color = BRICK, Material = Enum.Material.Brick, Parent = plotFolder }
	)
	table.insert(keepSpokes, { 0, 0, plot.ux * LobbyLayout.SpokeEnd, plot.uz * LobbyLayout.SpokeEnd })
	table.insert(keepClear, { plot.x, plot.z, width * 0.8 })
	table.insert(keepClear, { plot.ux * LobbyLayout.PadRingRadius, plot.uz * LobbyLayout.PadRingRadius, 26 })

	for j, m in LobbyLayout.Modes do
		local x, z = LobbyLayout.padPosition(plot, j)
		local def: LobbyLayout.PadDef = {
			dungeonId = dungeon.id,
			mode = m.mode,
			capacity = m.capacity,
			countdown = m.countdown,
			position = { x, 0, z },
		}
		table.insert(pads, buildPad(def, dungeon.unlockLevel, padFolder))
	end
end

-- Zone paths all start at the plaza centre and overlap each other, so each gets its own top (index * 0.008, staying
-- between the spokes at Y_PATH and the ring road at Y_ROAD).
local zonePathCount = 0

local function buildZone(zone: LobbyLayout.Zone, folder: Folder)
	local zoneFolder = Instance.new("Folder")
	zoneFolder.Name = `Zone_{zone.id}`
	zoneFolder.Parent = folder

	local isReserved = zone.square
	local floor
	if zone.square then
		floor = part({
			Name = "Plot",
			Size = Vector3.new(zone.radius * 2, 0.6, zone.radius * 2),
			Position = Vector3.new(zone.x, Y_PLAZA - 0.3, zone.z),
			Color = DIRT,
			Material = Enum.Material.Ground,
			Parent = zoneFolder,
		})
	else
		floor = disc(
			"Plaza",
			zone.x,
			zone.z,
			zone.radius,
			0.6,
			Y_PLAZA,
			{ Color = STONE, Material = Enum.Material.Slate, Parent = zoneFolder }
		)
	end
	local color = if isReserved
		then Color3.fromRGB(201, 204, 211)
		elseif zone.id == "Scoreboard" then Color3.fromRGB(255, 209, 102)
		else Color3.fromRGB(142, 240, 255)
	billboard(floor, 18, zone.title, zone.subtitle, color, 300)

	zonePathCount += 1
	local pathTop = Y_ZONE_PATH + (zonePathCount - 1) * 0.008
	strip(`Path_{zone.id}`, 0, 0, zone.x, zone.z, LobbyLayout.ZonePathWidth, pathTop, brickProps()).Parent = zoneFolder
	table.insert(keepSpokes, { 0, 0, zone.x, zone.z })
	table.insert(keepClear, { zone.x, zone.z, zone.radius + 11 })

	if zone.id == "Scoreboard" then
		-- The board: a wall facing the plaza with a Hall of Fame placeholder and one panel per board.
		local toPlaza = (Vector3.new(0, 0, 0) - Vector3.new(zone.x, 0, zone.z)).Unit
		local wallPos = Vector3.new(zone.x, 0, zone.z) - toPlaza * 8.4
		local wall = part({
			Name = "HallOfFame",
			Size = Vector3.new(25, 12.6, 1.1),
			CFrame = CFrame.lookAt(
				wallPos + Vector3.new(0, Y_PLAZA + 7.7, 0),
				wallPos + Vector3.new(0, Y_PLAZA + 7.7, 0) + toPlaza
			),
			Color = Color3.fromRGB(59, 58, 68),
			Material = Enum.Material.Slate,
			Parent = zoneFolder,
		})
		local gui = Instance.new("SurfaceGui")
		gui.Face = Enum.NormalId.Front
		gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		gui.PixelsPerStud = 40
		gui.Parent = wall
		local heading = Instance.new("TextLabel")
		heading.Size = UDim2.fromScale(1, 0.22)
		heading.BackgroundTransparency = 1
		heading.TextScaled = true
		heading.Font = Enum.Font.GothamBlack
		heading.TextColor3 = Color3.fromRGB(255, 209, 102)
		heading.Text = "Hall of Fame"
		heading.Parent = gui
		local boards = {
			{ "Solo", 123, 216, 143 },
			{ "Duo", 95, 184, 255 },
			{ "Squad", 255, 138, 95 },
			{ "Siege", 217, 140, 255 },
		}
		for i, b in boards do
			local panel = Instance.new("Frame")
			panel.Size = UDim2.fromScale(0.2, 0.66)
			panel.Position = UDim2.fromScale(0.04 + (i - 1) * 0.24, 0.28)
			panel.BackgroundColor3 = Color3.fromRGB(b[2] :: number, b[3] :: number, b[4] :: number)
			panel.BackgroundTransparency = 0.2
			panel.BorderSizePixel = 0
			panel.Parent = gui
			local name = Instance.new("TextLabel")
			name.Size = UDim2.fromScale(1, 0.15)
			name.BackgroundTransparency = 1
			name.TextScaled = true
			name.Font = Enum.Font.GothamBold
			name.TextColor3 = Color3.new(0.1, 0.1, 0.12)
			name.Text = b[1] :: string
			name.Parent = panel
			local empty = Instance.new("TextLabel")
			empty.Position = UDim2.fromScale(0, 0.4)
			empty.Size = UDim2.fromScale(1, 0.12)
			empty.BackgroundTransparency = 1
			empty.TextScaled = true
			empty.Font = Enum.Font.Gotham
			empty.TextColor3 = Color3.new(0.1, 0.1, 0.12)
			empty.Text = "coming soon"
			empty.Parent = panel
		end
		for _, side in { -13, 13 } do
			part({
				Name = "Post",
				Size = Vector3.new(1.1, 15.4, 1.1),
				CFrame = wall.CFrame * CFrame.new(side, 0, 0),
				Color = WOOD,
				Material = Enum.Material.Wood,
				Parent = zoneFolder,
			})
		end
	elseif zone.id == "Shop" then
		-- Market stall and smithy placeholders around the plaza edge.
		local stalls = {
			{ "MarketStand_1", -8, -14, 6, 6 },
			{ "MarketStand_2", 11, -8, 6, 6 },
			{ "Blacksmith", 11, 20, 12, 11 },
			{ "Crate", -17, 8, 2, 1.7 },
			{ "Barrel", -13, 13, 2, 1.8 },
		}
		for _, s in stalls do
			local stall = part({
				Name = s[1] :: string,
				Size = Vector3.new(s[4] :: number, s[5] :: number, s[4] :: number),
				Position = Vector3.new(
					zone.x + (s[2] :: number),
					Y_PLAZA + (s[5] :: number) / 2,
					zone.z + (s[3] :: number)
				),
				Color = Color3.fromRGB(150, 110, 70),
				Material = Enum.Material.WoodPlanks,
				Parent = zoneFolder,
			})
			stall:SetAttribute("Model", s[1])
		end
	end
end

-- Simple trees: a trunk and a leaf ball, scattered where nothing else stands.
local function buildTrees(folder: Folder, random: Random)
	local trees = Instance.new("Folder")
	trees.Name = "Trees"
	trees.Parent = folder
	local function scatter(count: number, rMin: number, rMax: number, hMin: number, hMax: number)
		for _ = 1, count do
			local x, z
			local tries = 0
			repeat
				local a = random:NextNumber() * math.pi * 2
				local d = rMin + math.sqrt(random:NextNumber()) * (rMax - rMin)
				x, z = math.cos(a) * d, math.sin(a) * d
				tries += 1
			until isFree(x, z) or tries >= 30
			if tries >= 30 then
				continue
			end
			local h = hMin + random:NextNumber() * (hMax - hMin)
			local tree = Instance.new("Model")
			tree.Name = "Tree"
			part({
				Name = "Trunk",
				Size = Vector3.new(1.6, h * 0.45, 1.6),
				Position = Vector3.new(x, Y_FIELD + h * 0.225, z),
				Color = Color3.fromRGB(92, 64, 40),
				Material = Enum.Material.Wood,
				Parent = tree,
			})
			part({
				Name = "Leaves",
				Shape = Enum.PartType.Ball,
				Size = Vector3.new(h * 0.6, h * 0.6, h * 0.6),
				Position = Vector3.new(x, Y_FIELD + h * 0.7, z),
				Color = PATCHES[random:NextInteger(1, 3)],
				Material = Enum.Material.Grass,
				Parent = tree,
			})
			tree.Parent = trees
		end
	end
	scatter(30, 84, LobbyLayout.RingRadius + 56, 11, 18)
	scatter(70, LobbyLayout.RingRadius + 84, LobbyLayout.FieldRadius - 35, 15, 25)
end

local function playersOn(pad: Pad): { Player }
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { pad.part }

	local size = LobbyLayout.PadRadius * 2
	local region = CFrame.new(pad.part.Position + Vector3.new(0, 4, 0))
	local found: { Player } = {}
	local seen: { [Player]: boolean } = {}
	for _, hit in Workspace:GetPartBoundsInBox(region, Vector3.new(size, 8, size), params) do
		local player = Players:GetPlayerFromCharacter(hit.Parent)
		if player and not seen[player] then
			seen[player] = true
			table.insert(found, player)
		end
	end
	return found
end

-- Occupants whose level is too low for the pad's dungeon.
local function lockedOut(pad: Pad, occupants: { Player }): { Player }
	local out = {}
	if unlockAll then
		return out
	end
	for _, player in occupants do
		if PlayerData.levelOf(player) < pad.unlockLevel then
			table.insert(out, player)
		end
	end
	return out
end

local function updatePad(pad: Pad, now: number, onLaunch: (mode: string, players: { Player }, dungeonId: string) -> ())
	local occupants = playersOn(pad)

	local blocked = lockedOut(pad, occupants)
	if #blocked > 0 then
		pad.logic:reset()
		pad.messageUntil = now + LOCKED_MESSAGE_SECONDS
		pad.label.Text = `Locked: {blocked[1].DisplayName} needs Level {pad.unlockLevel}`
		return
	end
	if now < pad.messageUntil and #occupants == 0 then
		return -- keep the lock message readable after the player steps off
	end

	local state, left = pad.logic:update(#occupants, now)
	if state == "waiting" then
		pad.label.Text = `{#occupants}/{pad.def.capacity} players`
	elseif state == "counting" then
		pad.label.Text = `starting in {math.ceil(left :: number)}`
	else
		pad.label.Text = "launching"
		onLaunch(pad.def.mode, { table.unpack(occupants, 1, pad.def.capacity) }, pad.def.dungeonId)
	end
end

function Lobby.start(onLaunch: (mode: string, players: { Player }, dungeonId: string) -> ())
	local existing = Workspace:FindFirstChild("Lobby")
	if existing then
		existing:Destroy()
	end
	table.clear(pads)
	table.clear(keepClear)
	table.clear(keepSpokes)

	local random = Random.new(20251030)
	local folder = Instance.new("Folder")
	folder.Name = "Lobby"

	buildField(folder, random)
	buildPlaza(folder)
	buildRingRoad(folder)

	local plots = Instance.new("Folder")
	plots.Name = "Dungeons"
	plots.Parent = folder
	local padFolder = Instance.new("Folder")
	padFolder.Name = "Pads"
	padFolder.Parent = folder
	for _, plot in LobbyLayout.plots() do
		buildPlot(plot, plots, padFolder)
	end

	local zones = Instance.new("Folder")
	zones.Name = "Zones"
	zones.Parent = folder
	for _, zone in LobbyLayout.Zones do
		buildZone(zone, zones)
	end

	-- Low grass mounds in the outskirts, clear of paths, plots and zones; trees keep off them.
	local mounds = BackdropPlan.fieldMounds(20251031, 14, function(x: number, z: number, reach: number): boolean
		return isFree(x, z, reach)
	end)
	for _, f in BackdropPlan.footprints(mounds) do
		table.insert(keepClear, { f[1], f[2], f[3] + 3 })
	end

	buildTrees(folder, random)
	folder.Parent = Workspace
	-- Terrain: the mounds, a grass lip round the field rim, hills and snowy mountains beyond (fills in over a few
	-- frames, see Backdrop.luau).
	Backdrop.buildLobby(mounds)

	task.spawn(function()
		while true do
			if not locked then
				local now = os.clock()
				for _, pad in pads do
					updatePad(pad, now, onLaunch)
				end
			end
			task.wait(POLL_SECONDS)
		end
	end)
end

-- Freeze pads while a run is in progress in this server (Studio / single-server mode).
function Lobby.setLocked(value: boolean)
	locked = value
	if locked then
		for _, pad in pads do
			pad.logic:reset()
			pad.label.Text = "run in progress"
		end
	end
end

return Lobby
