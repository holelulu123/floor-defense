-- Builds the Terrain backdrops planned by Shared.Backdrop: the lobby's ring of hills and snowy mountains (once per
-- lobby start) and each dungeon's themed ring around the arena (once per arena build, after clearing the previous
-- dungeon's). All Terrain work runs on one worker, a few milliseconds per frame, so it never stalls the server;
-- each build logs how long it took and warns past WARN_SECONDS.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Plan = require(ReplicatedStorage.Shared.Backdrop)
local Lane = require(ReplicatedStorage.Shared.Lane)

local Backdrop = {}

local FRAME_BUDGET = 0.008 -- seconds of Terrain work per frame
local WARN_SECONDS = 3

type Shape = Plan.Shape

local terrain = Workspace.Terrain
local queue: { () -> () } = {}
local working = false
local arenaGeneration = 0
local arenaShapes: { Shape } = {} -- world-space shapes of the arena backdrop currently in Terrain (maybe partly)

local materials: { [string]: Enum.Material } = {}
for _, name in Plan.TerrainMaterials do
	local ok, m = pcall(function()
		return (Enum.Material :: any)[name]
	end)
	if ok and m then
		materials[name] = m
	else
		warn(`Backdrop: Enum.Material.{name} does not exist`)
	end
end

local function enqueue(job: () -> ())
	table.insert(queue, job)
	if working then
		return
	end
	working = true
	task.spawn(function()
		while #queue > 0 do
			local next = table.remove(queue, 1) :: () -> ()
			local ok, err = pcall(next)
			if not ok then
				warn(`Backdrop: {err}`)
			end
		end
		working = false
	end)
end

local function offsetShape(s: Shape, ox: number, oz: number): Shape
	local copy = table.clone(s)
	copy.x += ox
	copy.z += oz
	return copy
end

local function apply(s: Shape)
	local material = materials[s.material]
	if not material then
		return
	end
	if s.kind == "ball" then
		terrain:FillBall(Vector3.new(s.x, s.y, s.z), s.radius :: number, material)
	elseif s.kind == "block" or s.kind == "wedge" then
		local size = s.size :: { number }
		local cf = CFrame.new(s.x, s.y, s.z) * CFrame.Angles(0, s.yaw or 0, 0) * CFrame.Angles(s.tilt or 0, 0, 0)
		local v = Vector3.new(size[1], size[2], size[3])
		if s.kind == "wedge" then
			terrain:FillWedge(cf, v, material)
		else
			terrain:FillBlock(cf, v, material)
		end
	elseif s.kind == "snow" then
		local r = s.radius :: number
		local region = Region3.new(Vector3.new(s.x - r, s.y, s.z - r), Vector3.new(s.x + r, s.top :: number, s.z + r))
			:ExpandToGrid(4)
		for _, from in s.from :: { string } do
			local source = materials[from]
			if source then
				terrain:ReplaceMaterial(region, 4, source, material)
			end
		end
	end
end

-- Runs the shapes in order within the frame budget. Returns false if `stillWanted` turned false part way.
local function run(shapes: { Shape }, stillWanted: (() -> boolean)?): (boolean, number)
	local busy = 0
	local sliceStart = os.clock()
	for _, s in shapes do
		if stillWanted and not stillWanted() then
			return false, busy
		end
		apply(s)
		local now = os.clock()
		if now - sliceStart >= FRAME_BUDGET then
			busy += now - sliceStart
			task.wait()
			sliceStart = os.clock()
		end
	end
	busy += os.clock() - sliceStart
	return true, busy
end

local function report(what: string, count: number, started: number, busy: number)
	local wall = os.clock() - started
	local line = `Backdrop: {what}: {count} terrain shapes in {string.format("%.2f", wall)} s`
		.. ` ({string.format("%.2f", busy)} s of Terrain work)`
	if wall > WARN_SECONDS then
		warn(line)
	else
		print(line)
	end
end

-- The lobby ring plus the field mounds Lobby.luau placed (world space). Terrain fills are idempotent, so a second
-- lobby start just fills the same shapes again.
function Backdrop.buildLobby(extra: { Shape }?)
	local shapes = Plan.lobby()
	if extra then
		table.move(extra, 1, #extra, #shapes + 1, shapes)
	end
	enqueue(function()
		local started = os.clock()
		local _, busy = run(shapes)
		report("lobby", #shapes, started, busy)
	end)
end

-- Removes whatever arena backdrop is in Terrain (queued behind any build in progress, which it cancels).
function Backdrop.clearArena()
	arenaGeneration += 1
	enqueue(function()
		if #arenaShapes == 0 then
			return
		end
		local started = os.clock()
		local clearing = Plan.clearing(arenaShapes)
		arenaShapes = {}
		local _, busy = run(clearing)
		report("arena cleared", #clearing, started, busy)
	end)
end

-- Clears the previous dungeon's backdrop and builds this one's around the arena at `origin`. Returns at once; the
-- terrain fills in over the next frames (the prep phase hides it). `layout` is the arena's lane (arena-local).
function Backdrop.buildArena(dungeonId: string, origin: Vector3, layout: Lane.Layout?)
	assert(
		origin.X == Plan.ArenaOrigin.x and origin.Z == Plan.ArenaOrigin.z,
		"Backdrop.ArenaOrigin must match Arena.Origin (the lobby ring keeps out of the arena's backdrop region)"
	)
	Backdrop.clearArena()
	local generation = arenaGeneration
	enqueue(function()
		if generation ~= arenaGeneration then
			return -- a newer build or a clear was asked for meanwhile
		end
		local started = os.clock()
		local shapes = {}
		for i, s in Plan.arena(dungeonId, layout) do
			shapes[i] = offsetShape(s, origin.X, origin.Z)
		end
		arenaShapes = shapes -- recorded first so a cancelled build still gets cleared
		local finished, busy = run(shapes, function()
			return generation == arenaGeneration
		end)
		report(if finished then `arena {dungeonId}` else `arena {dungeonId} (cancelled)`, #shapes, started, busy)
	end)
end

return Backdrop
