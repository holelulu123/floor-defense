-- Builds the placeholder Graveyard arena out of Parts, far enough from the lobby not to overlap.
-- Returns the Town Hall part, the spawn gates and the player spawn points. Everything lives in
-- one Folder so a run can be torn down with a single Destroy.

local Workspace = game:GetService("Workspace")

local Arena = {}

Arena.Origin = Vector3.new(0, 0, 600)
local FLOOR_SIZE = 200
local GATE_DISTANCE = 90

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

export type Built = {
	folder: Folder,
	townHall: Part,
	gates: { Part },
	spawns: { Vector3 },
}

function Arena.build(): Built
	Arena.destroy()

	local folder = Instance.new("Folder")
	folder.Name = "Arena"

	part({
		Name = "Floor",
		Size = Vector3.new(FLOOR_SIZE, 1, FLOOR_SIZE),
		Position = Arena.Origin - Vector3.new(0, 0.5, 0),
		Color = Color3.fromRGB(60, 70, 60),
		Material = Enum.Material.Grass,
		Parent = folder,
	})

	local townHall = part({
		Name = "TownHall",
		Size = Vector3.new(12, 14, 12),
		Position = Arena.Origin + Vector3.new(0, 7, 0),
		Color = Color3.fromRGB(190, 170, 120),
		Material = Enum.Material.Brick,
		Parent = folder,
	})

	local gates = {}
	for i, dir in { Vector3.new(0, 0, -1), Vector3.new(-1, 0, 0), Vector3.new(1, 0, 0) } do
		table.insert(
			gates,
			part({
				Name = "Gate" .. i,
				Size = Vector3.new(10, 8, 2),
				CFrame = CFrame.lookAt(Arena.Origin + dir * GATE_DISTANCE + Vector3.new(0, 4, 0), Arena.Origin),
				Color = Color3.fromRGB(40, 40, 50),
				Material = Enum.Material.Slate,
				Parent = folder,
			})
		)
	end

	local spawns = {}
	for i = 0, 3 do
		local angle = math.rad(45 + 90 * i)
		table.insert(spawns, Arena.Origin + Vector3.new(math.cos(angle) * 14, 3, math.sin(angle) * 14))
	end

	folder.Parent = Workspace
	return { folder = folder, townHall = townHall, gates = gates, spawns = spawns }
end

function Arena.destroy()
	local existing = Workspace:FindFirstChild("Arena")
	if existing then
		existing:Destroy()
	end
end

return Arena
