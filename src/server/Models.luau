-- Loads the imported 3D models (src/shared/ModelIds.luau) with InsertService:LoadAsset, once per key, and hands out
-- clones that are anchored, non-colliding, invisible to raycasts and turned/scaled by the ModelFit rules.
-- Loading yields; concurrent callers for the same key wait for the one request. A missing id or a failed load
-- returns nil so callers can fall back to their placeholder Parts.

local InsertService = game:GetService("InsertService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ModelIds = (require(ReplicatedStorage.Shared.ModelIds) :: any) :: { [string]: number }

local Models = {}

local loaded: { [string]: Model } = {}
local failed: { [string]: boolean } = {}
local waiting: { [string]: { thread } } = {}

function Models.has(key: string): boolean
	return type(ModelIds[key]) == "number" and not failed[key]
end

-- The asset arrives as a container Model holding the uploaded Model (or loose MeshParts): unwrap it, drop any
-- scripts, anchor everything and give it an axis-aligned pivot at the centre of its bounds.
local function normalise(container: Instance): Model?
	local children = container:GetChildren()
	local model: Model
	if #children == 1 and children[1]:IsA("Model") then
		model = children[1] :: Model
		model.Parent = nil
	else
		model = Instance.new("Model")
		for _, child in children do
			child.Parent = model
		end
	end
	container:Destroy()

	local parts = 0
	for _, d in model:GetDescendants() do
		if d:IsA("LuaSourceContainer") then
			d:Destroy()
		elseif d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = false
			d.CanTouch = false
			d.CanQuery = false
			d.Massless = true
			parts += 1
		end
	end
	if parts == 0 then
		model:Destroy()
		return nil
	end
	model.PrimaryPart = nil
	model.WorldPivot = CFrame.identity
	local box = model:GetBoundingBox()
	model.WorldPivot = CFrame.new(box.Position)
	return model
end

local function fetch(key: string): Model?
	if loaded[key] then
		return loaded[key]
	end
	local id = ModelIds[key]
	if failed[key] or type(id) ~= "number" then
		return nil
	end
	local queue = waiting[key]
	if queue then
		table.insert(queue, coroutine.running())
		coroutine.yield()
		return loaded[key]
	end
	queue = {}
	waiting[key] = queue

	local ok, result = pcall(InsertService.LoadAsset, InsertService, id)
	local model = if ok then normalise(result) else nil
	if model then
		model.Name = key
		loaded[key] = model
	else
		failed[key] = true
		warn(`Models: could not load {key} ({id}): {if ok then "no parts" else result}`)
	end
	waiting[key] = nil
	for _, thread in queue do
		task.spawn(thread)
	end
	return model
end

-- A fresh copy of `key`, turned `yaw` radians about +Y so it faces its LookVector (-Z) and scaled by
-- fit(size) where size is its extents after the turn. The pivot is the centre of the result's bounds,
-- axis-aligned. Returns the model and its extents, or nil. Yields on the first load of a key.
function Models.fitted(key: string, yaw: number, fit: (size: Vector3) -> number): (Model?, Vector3?)
	local source = fetch(key)
	if not source then
		return nil, nil
	end
	local model = source:Clone()
	local centre = model.WorldPivot.Position
	model:PivotTo(CFrame.new(centre) * CFrame.Angles(0, yaw, 0))
	model.WorldPivot = CFrame.new(centre)
	local _, size = model:GetBoundingBox()
	local k = fit(size)
	if k > 0 and k == k and math.abs(k - 1) > 1e-4 then
		model:ScaleTo(model:GetScale() * k)
	end
	local box, extents = model:GetBoundingBox()
	model.WorldPivot = CFrame.new(box.Position)
	return model, extents
end

return Models
