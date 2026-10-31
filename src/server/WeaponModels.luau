-- Class weapons handed to the player as Tools: the primary (slot 1) is equipped in the right hand, the melee
-- secondary (slot 2) waits in the Backpack until Combat swaps it in with WeaponModels.equip. The player keeps their
-- own avatar; only the Tool (plus the Tank's shield on the left forearm and the Scout's second pistol in the left hand)
-- is added. Firing still goes through Weapon.client.luau -> Remotes.Fire; the Tool is purely visual, so nothing about
-- it is trusted by the server.
--
-- Each weapon is built from its uploaded mesh (src/shared/ModelIds.luau, loaded once per weapon with
-- InsertService:LoadAsset and cached as a template), sized and gripped by src/shared/WeaponMeshes.luau so it matches
-- the showcase. Every Tool carries an Attachment "Muzzle" at its business end (tracers, flashes, melee sparks start
-- there; the Scout's left pistol has "MuzzleLeft"). The Part-built builders below are the fallback when an id is
-- missing or LoadAsset fails, and the Tank's Flail is always procedural. They point their business end along the
-- Handle's -Z, which is where a held tool faces.

local InsertService = game:GetService("InsertService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ModelIds = require(ReplicatedStorage.Shared.ModelIds)
local WeaponMeshes = require(ReplicatedStorage.Shared.WeaponMeshes)

local WeaponModels = {}

-- Builders are authored at roughly R6 scale; R15 avatars want weapons about 1.7x bigger.
local SCALE = 1.7

local function part(parent: Instance, name: string, size: Vector3, offset: CFrame, color: Color3, shape: Enum.PartType?)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size * SCALE
	offset = CFrame.new(offset.Position * SCALE) * offset.Rotation
	p.Color = color
	p.Material = Enum.Material.SmoothPlastic
	p.Shape = shape or Enum.PartType.Block
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Massless = true
	p.CFrame = (parent :: BasePart).CFrame * offset
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = parent :: BasePart
	weld.Part1 = p
	weld.Parent = p
	p.Parent = parent.Parent
	return p
end

local GUN_METAL = Color3.fromRGB(60, 60, 70)
local WOOD = Color3.fromRGB(120, 80, 45)
local STEEL = Color3.fromRGB(170, 175, 185)
local DARK_GRIP = Color3.fromRGB(35, 35, 40)
local BRASS = Color3.fromRGB(190, 150, 70)

-- A short bladed melee weapon: grip, guard, blade (and an optional tip) along -Z.
local function blade(h: Part, gripLength: number, bladeSize: Vector3, bladeColor: Color3, guardWidth: number): CFrame
	h.Size = Vector3.new(0.16, 0.2, gripLength)
	h.Color = DARK_GRIP
	part(h, "Guard", Vector3.new(guardWidth, 0.12, 0.1), CFrame.new(0, 0, -gripLength / 2 - 0.05), BRASS)
	part(h, "Blade", bladeSize, CFrame.new(0, 0, -gripLength / 2 - 0.1 - bladeSize.Z / 2), bladeColor)
	return CFrame.new(0, 0, 0)
end

-- Each builder gets the Handle (already sized/positioned) and adds detail parts to its parent.
-- Returns the Grip CFrame (hand point in Handle space).
local builders: { [string]: (handle: Part) -> CFrame } = {
	AssaultRifle = function(h)
		h.Size = Vector3.new(0.3, 0.45, 1.8)
		h.Color = GUN_METAL
		part(h, "Barrel", Vector3.new(0.15, 0.15, 1), CFrame.new(0, 0.1, -1.3), STEEL)
		part(h, "Stock", Vector3.new(0.25, 0.4, 0.7), CFrame.new(0, -0.05, 1.2), WOOD)
		part(h, "Mag", Vector3.new(0.2, 0.6, 0.3), CFrame.new(0, -0.45, 0.1), GUN_METAL)
		return CFrame.new(0, -0.3, 0.5)
	end,
	Shotgun = function(h)
		h.Size = Vector3.new(0.3, 0.4, 1.6)
		h.Color = WOOD
		part(h, "Barrel", Vector3.new(0.18, 0.18, 1.3), CFrame.new(0, 0.12, -1.35), STEEL)
		part(h, "Pump", Vector3.new(0.26, 0.22, 0.5), CFrame.new(0, -0.06, -1.1), WOOD)
		part(h, "Stock", Vector3.new(0.25, 0.45, 0.7), CFrame.new(0, -0.08, 1.1), WOOD)
		return CFrame.new(0, -0.28, 0.45)
	end,
	SMG = function(h)
		h.Size = Vector3.new(0.3, 0.4, 1)
		h.Color = GUN_METAL
		part(h, "Barrel", Vector3.new(0.12, 0.12, 0.5), CFrame.new(0, 0.05, -0.7), STEEL)
		part(h, "Mag", Vector3.new(0.18, 0.7, 0.22), CFrame.new(0, -0.5, 0), GUN_METAL)
		return CFrame.new(0, -0.25, 0.25)
	end,
	BoltRifle = function(h)
		h.Size = Vector3.new(0.3, 0.4, 2)
		h.Color = WOOD
		part(h, "Barrel", Vector3.new(0.14, 0.14, 1.6), CFrame.new(0, 0.1, -1.7), STEEL)
		part(h, "Scope", Vector3.new(0.18, 0.18, 0.8), CFrame.new(0, 0.4, -0.2), GUN_METAL, Enum.PartType.Cylinder)
		part(h, "Stock", Vector3.new(0.25, 0.45, 0.8), CFrame.new(0, -0.05, 1.3), WOOD)
		return CFrame.new(0, -0.3, 0.6)
	end,
	Flamethrower = function(h)
		h.Size = Vector3.new(0.45, 0.45, 1.6)
		h.Color = Color3.fromRGB(150, 60, 40)
		part(h, "Nozzle", Vector3.new(0.3, 0.3, 1.2), CFrame.new(0, 0, -1.3), STEEL)
		part(h, "Tank", Vector3.new(0.5, 0.5, 0.7), CFrame.new(0, -0.5, 0.5), Color3.fromRGB(200, 170, 60))
		part(h, "Grip", Vector3.new(0.2, 0.5, 0.2), CFrame.new(0, -0.45, -0.3), GUN_METAL)
		return CFrame.new(0, -0.35, 0.3)
	end,
	GrenadeLauncher = function(h)
		h.Size = Vector3.new(0.6, 0.6, 1.4)
		h.Color = Color3.fromRGB(70, 90, 60)
		part(h, "Barrel", Vector3.new(0.5, 0.5, 1), CFrame.new(0, 0, -1.1), GUN_METAL)
		part(h, "Stock", Vector3.new(0.3, 0.4, 0.6), CFrame.new(0, -0.1, 0.9), GUN_METAL)
		return CFrame.new(0, -0.4, 0.3)
	end,
	DualPistols = function(h)
		h.Size = Vector3.new(0.25, 0.35, 0.7)
		h.Color = GUN_METAL
		part(h, "Barrel", Vector3.new(0.12, 0.12, 0.3), CFrame.new(0, 0.08, -0.5), STEEL)
		part(h, "Grip", Vector3.new(0.22, 0.5, 0.25), CFrame.new(0, -0.35, 0.2), WOOD)
		return CFrame.new(0, -0.3, 0.2)
	end,
	GreatAxe = function(h)
		h.Size = Vector3.new(0.2, 0.2, 3.2)
		h.Color = WOOD
		part(h, "Blade", Vector3.new(0.15, 1.6, 0.9), CFrame.new(0, 0, -1.3), STEEL)
		part(h, "BackBlade", Vector3.new(0.15, 1, 0.5), CFrame.new(0, 0, -0.65), STEEL)
		return CFrame.new(0, 0, 1)
	end,
	Staff = function(h)
		h.Size = Vector3.new(0.2, 0.2, 4)
		h.Color = WOOD
		part(
			h,
			"Orb",
			Vector3.new(0.6, 0.6, 0.6),
			CFrame.new(0, 0, -2.1),
			Color3.fromRGB(90, 140, 255),
			Enum.PartType.Ball
		)
		return CFrame.new(0, 0, 0.8)
	end,
	Flail = function(h)
		h.Size = Vector3.new(0.18, 0.18, 1.4)
		h.Color = WOOD
		part(h, "Chain", Vector3.new(0.08, 0.08, 1.2), CFrame.new(0, 0, -1.3), STEEL)
		part(h, "Ball", Vector3.new(0.7, 0.7, 0.7), CFrame.new(0, 0, -2.2), GUN_METAL, Enum.PartType.Ball)
		return CFrame.new(0, 0, 0.4)
	end,
	-- Melee secondaries (slot 2).
	CombatKnife = function(h)
		return blade(h, 0.45, Vector3.new(0.05, 0.16, 0.6), STEEL, 0.35)
	end,
	Karambit = function(h)
		local grip = blade(h, 0.4, Vector3.new(0.05, 0.14, 0.35), STEEL, 0.25)
		-- the hooked tip curls down from the end of the blade
		part(
			h,
			"Hook",
			Vector3.new(0.05, 0.3, 0.12),
			CFrame.new(0, -0.1, -0.68) * CFrame.Angles(math.rad(-30), 0, 0),
			STEEL
		)
		part(h, "Ring", Vector3.new(0.05, 0.2, 0.2), CFrame.new(0, 0, 0.3), STEEL, Enum.PartType.Cylinder)
		return grip
	end,
	Scalpel = function(h)
		h.Size = Vector3.new(0.08, 0.1, 0.6)
		h.Color = STEEL
		part(h, "Blade", Vector3.new(0.03, 0.1, 0.18), CFrame.new(0, -0.01, -0.38), Color3.fromRGB(220, 225, 235))
		return CFrame.new(0, 0, 0.05)
	end,
	Hammer = function(h)
		h.Size = Vector3.new(0.14, 0.14, 1.2)
		h.Color = WOOD
		part(
			h,
			"Head",
			Vector3.new(0.3, 0.3, 0.7),
			CFrame.new(0, 0.1, -0.65) * CFrame.Angles(math.rad(90), 0, 0),
			STEEL
		)
		part(h, "Claw", Vector3.new(0.12, 0.12, 0.3), CFrame.new(0, 0.32, -0.75), GUN_METAL)
		return CFrame.new(0, 0, 0.35)
	end,
	Sword = function(h)
		return blade(h, 0.55, Vector3.new(0.06, 0.24, 2.2), STEEL, 0.7)
	end,
	Dagger = function(h)
		local grip = blade(h, 0.4, Vector3.new(0.05, 0.18, 0.7), Color3.fromRGB(150, 160, 200), 0.4)
		part(h, "Pommel", Vector3.new(0.14, 0.14, 0.14), CFrame.new(0, 0, 0.25), BRASS, Enum.PartType.Ball)
		return grip
	end,
	Machete = function(h)
		local grip = blade(h, 0.5, Vector3.new(0.05, 0.3, 1.4), STEEL, 0.2)
		part(h, "Spine", Vector3.new(0.06, 0.06, 1.4), CFrame.new(0, 0.15, -0.95), GUN_METAL)
		return grip
	end,
	Hatchet = function(h)
		h.Size = Vector3.new(0.14, 0.14, 1.1)
		h.Color = WOOD
		part(h, "Head", Vector3.new(0.08, 0.45, 0.35), CFrame.new(0, 0.18, -0.45), STEEL)
		part(h, "Poll", Vector3.new(0.12, 0.15, 0.15), CFrame.new(0, -0.1, -0.45), GUN_METAL)
		return CFrame.new(0, 0, 0.3)
	end,
}

-- Mesh templates ---------------------------------------------------------------------------------------------------

-- A weapon assembled from its uploaded mesh: a Model of welded parts with one named "Handle" (carrying the "Muzzle"
-- attachment), and the hand frame in Handle space (Tool.Grip, or the weld offset for off-hand pieces).
type Assembly = { model: Model, grip: CFrame }

local assemblies: { [string]: Assembly | false } = {} -- false: tried and failed, use the fallback
local loading: { [string]: number } = {} -- weapon -> os.clock() its load started
-- Waiting for a mesh longer than this gives the Part placeholder instead (LoadAsset can stall); the load keeps going
-- in the background and later gives use the mesh once it lands.
local LOAD_TIMEOUT = 8

local function vec(v: WeaponMeshes.Vec): Vector3
	return Vector3.new(v.x, v.y, v.z)
end

local function tbl(v: Vector3): WeaponMeshes.Vec
	return { x = v.X, y = v.Y, z = v.Z }
end

local function axisVector(axis: WeaponMeshes.Axis): Vector3
	local v = WeaponMeshes.axis(axis)
	return vec(v)
end

local function quiet(p: BasePart)
	p.Anchored = false
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Massless = true
end

-- Axis-aligned (world axes, which are the model's own axes as uploaded) bounds of every part.
local function bounds(parts: { BasePart }): (Vector3, Vector3)
	local min = Vector3.one * math.huge
	local max = -Vector3.one * math.huge
	for _, p in parts do
		local half = p.Size / 2
		for _, sx in { -1, 1 } do
			for _, sy in { -1, 1 } do
				for _, sz in { -1, 1 } do
					local corner = p.CFrame:PointToWorldSpace(half * Vector3.new(sx, sy, sz))
					min = min:Min(corner)
					max = max:Max(corner)
				end
			end
		end
	end
	return min, max
end

local function assemble(name: string, mesh: WeaponMeshes.Mesh): Assembly?
	local id = (ModelIds :: { [string]: number })[mesh.model]
	if type(id) ~= "number" then
		return nil
	end
	local ok, container = pcall(InsertService.LoadAsset, InsertService, id)
	if not ok or typeof(container) ~= "Instance" then
		warn(`WeaponModels: LoadAsset {id} for {name} failed ({container}); using the Part placeholder`)
		return nil
	end
	local parts: { BasePart } = {}
	for _, d in (container :: Instance):GetDescendants() do
		if d:IsA("BasePart") then
			table.insert(parts, d)
		elseif d:IsA("JointInstance") or d:IsA("WeldConstraint") or d:IsA("Script") then
			d:Destroy() -- welds are rebuilt below; uploaded models never need scripts
		end
	end
	if #parts == 0 then
		container:Destroy()
		warn(`WeaponModels: asset {id} for {name} has no parts; using the Part placeholder`)
		return nil
	end

	-- Scale about the box centre so the longest side is the showcase length.
	local min, max = bounds(parts)
	local center = (min + max) / 2
	local k = WeaponMeshes.scale(mesh, tbl(max - min))
	local model = Instance.new("Model")
	model.Name = name
	local handle = parts[1]
	for _, p in parts do
		quiet(p)
		p.Size *= k
		p.CFrame = CFrame.new(center + (p.Position - center) * k) * p.CFrame.Rotation
		for _, m in p:GetChildren() do
			if m:IsA("SpecialMesh") then
				m.Scale *= k
			end
		end
		p.Parent = model
		if p.Size.X * p.Size.Y * p.Size.Z > handle.Size.X * handle.Size.Y * handle.Size.Z then
			handle = p
		end
	end
	container:Destroy()
	min = center + (min - center) * k
	max = center + (max - center) * k
	handle.Name = "Handle"
	for _, p in parts do
		if p ~= handle then
			local weld = Instance.new("Weld")
			weld.Part0 = handle
			weld.Part1 = p
			weld.C0 = handle.CFrame:ToObjectSpace(p.CFrame)
			weld.Parent = p
		end
	end

	-- The hand frame, in the model's axes: its -Z (look) is where the hand points, its +Y the back of the hand. Guns
	-- put the muzzle along the look with the model's top up; melee stands the blade along +Y with the edge forward;
	-- the shield mounts at the back of its face.
	local forward = axisVector(mesh.forward)
	local gripAt = vec(WeaponMeshes.point(mesh.forward, tbl(min), tbl(max), mesh.grip))
	local gripWorld
	if mesh.kind == "melee" and mesh.edge then
		gripWorld = CFrame.lookAt(gripAt, gripAt + axisVector(mesh.edge), forward)
	else
		gripWorld = CFrame.lookAt(gripAt, gripAt + forward, Vector3.yAxis)
	end
	local muzzleAt = vec(WeaponMeshes.point(mesh.forward, tbl(min), tbl(max), mesh.muzzle))
	local muzzle = Instance.new("Attachment")
	muzzle.Name = "Muzzle"
	muzzle.CFrame = handle.CFrame:ToObjectSpace(CFrame.lookAt(muzzleAt, muzzleAt + forward))
	muzzle.Parent = handle
	return { model = model, grip = handle.CFrame:ToObjectSpace(gripWorld) }
end

-- The cached template for a weapon's mesh (loads it on first use; yields up to LOAD_TIMEOUT), or nil when it must
-- fall back to Parts.
local function getAssembly(name: string): Assembly?
	local mesh = WeaponMeshes.get(name)
	if not mesh then
		return nil
	end
	while loading[name] do
		if os.clock() - loading[name] > LOAD_TIMEOUT then
			return nil
		end
		task.wait()
	end
	local cached = assemblies[name]
	if cached == nil then
		loading[name] = os.clock()
		local ok, result = pcall(assemble, name, mesh)
		if not ok then
			warn(`WeaponModels: building {name} failed: {result}`)
		end
		cached = if ok and result then result else false
		assemblies[name] = cached
		loading[name] = nil
	end
	return if cached then cached else nil
end

-- Moves a fresh copy of a template's parts into `parent`; returns the copied Handle.
local function cloneInto(asm: Assembly, parent: Instance): BasePart
	local copy = asm.model:Clone()
	local handle = copy:FindFirstChild("Handle") :: BasePart
	for _, child in copy:GetChildren() do
		child.Parent = parent
	end
	copy:Destroy()
	return handle
end

-- Fallback builds get a Muzzle at the far end of their parts along the Handle's -Z.
local function addMuzzle(handle: BasePart, name: string)
	local tip = -handle.Size.Z / 2
	for _, p in (handle.Parent :: Instance):GetChildren() do
		if p:IsA("BasePart") and p ~= handle then
			local rel = handle.CFrame:ToObjectSpace(p.CFrame)
			local reach = math.abs(rel.RightVector.Z) * p.Size.X
				+ math.abs(rel.UpVector.Z) * p.Size.Y
				+ math.abs(rel.LookVector.Z) * p.Size.Z
			tip = math.min(tip, rel.Position.Z - reach / 2)
		end
	end
	local muzzle = Instance.new("Attachment")
	muzzle.Name = name
	muzzle.CFrame = CFrame.new(0, 0, tip)
	muzzle.Parent = handle
end

-- Off-hand pieces --------------------------------------------------------------------------------------------------

local function limb(character: Model, names: { string }): BasePart?
	for _, n in names do
		local p = character:FindFirstChild(n)
		if p and p:IsA("BasePart") then
			return p
		end
	end
	return nil
end

-- Welds `handle` so its frame `c1` sits at `c0` on `body`.
local function weldTo(body: BasePart, handle: BasePart, c0: CFrame, c1: CFrame)
	local weld = Instance.new("Weld")
	weld.Name = "OffhandWeld"
	weld.Part0 = body
	weld.Part1 = handle
	weld.C0 = c0
	weld.C1 = c1
	weld.Parent = handle
end

local function tagOffhand(container: Instance, before: { [Instance]: boolean })
	for _, child in container:GetChildren() do
		if not before[child] and child:IsA("BasePart") then
			child:SetAttribute("Offhand", true)
		end
	end
end

local function children(container: Instance): { [Instance]: boolean }
	local set = {}
	for _, child in container:GetChildren() do
		set[child] = true
	end
	return set
end

-- Tank: the round shield in front of the left forearm, face forward.
local function attachShield(tool: Tool, character: Model)
	local arm = limb(character, { "LeftLowerArm", "Left Arm" })
	if not arm then
		return
	end
	local before = children(tool)
	local asm = getAssembly("Shield")
	if tool.Parent ~= character then
		return -- unequipped while the mesh loaded
	end
	if asm then
		local handle = cloneInto(asm, tool)
		weldTo(arm, handle, CFrame.new(0, -arm.Size.Y * 0.1, -arm.Size.Z / 2 - 0.05), asm.grip)
		handle.Name = "Shield"
	else
		local shield = Instance.new("Part")
		shield.Name = "Shield"
		shield.Shape = Enum.PartType.Cylinder
		shield.Size = Vector3.new(0.25, 2.4, 2.4)
		shield.Color = Color3.fromRGB(150, 110, 60)
		shield.Material = Enum.Material.Wood
		quiet(shield)
		shield.Parent = tool
		weldTo(arm, shield, CFrame.new(-arm.Size.X / 2 - 0.15, 0, 0), CFrame.new())
	end
	tagOffhand(tool, before)
end

-- Scout: a second pistol closed in the left hand, its muzzle attachment named MuzzleLeft.
local function attachLeftPistol(tool: Tool, character: Model)
	local hand = limb(character, { "LeftHand", "Left Arm" })
	if not hand then
		return
	end
	local gripAtt = hand:FindFirstChild("LeftGripAttachment")
	local c0 = if gripAtt and gripAtt:IsA("Attachment")
		then gripAtt.CFrame
		else CFrame.new(0, -hand.Size.Y / 2, 0) * CFrame.Angles(-math.pi / 2, 0, 0)
	local before = children(tool)
	local asm = getAssembly("DualPistols")
	if tool.Parent ~= character then
		return -- unequipped while the mesh loaded
	end
	if asm then
		local handle = cloneInto(asm, tool)
		handle.Name = "LeftPistol"
		local muzzle = handle:FindFirstChild("Muzzle")
		if muzzle then
			muzzle.Name = "MuzzleLeft"
		end
		weldTo(hand, handle, c0, asm.grip)
	else
		local pistol = Instance.new("Part")
		pistol.Name = "LeftPistol"
		pistol.Size = Vector3.new(0.25, 0.35, 0.9) * SCALE
		pistol.Color = GUN_METAL
		quiet(pistol)
		pistol.Parent = tool
		addMuzzle(pistol, "MuzzleLeft")
		weldTo(hand, pistol, c0, CFrame.new(0, -0.2, 0.2))
	end
	tagOffhand(tool, before)
end

local offhand: { [string]: (tool: Tool, character: Model) -> () } = {
	Flail = attachShield,
	DualPistols = attachLeftPistol,
}

-- Bumped by every give/remove so a give still loading its meshes knows it was superseded.
local generation: { [Player]: number } = {}
-- The slot Combat last asked for, applied when a give that was still loading hands its Tools over.
local wantedSlot: { [Player]: number } = {}

Players.PlayerRemoving:Connect(function(player)
	generation[player] = nil
	wantedSlot[player] = nil
end)

function WeaponModels.remove(player: Player)
	generation[player] = (generation[player] or 0) + 1
	local character = player.Character
	local backpack = player:FindFirstChildOfClass("Backpack")
	for _, container in { character, backpack } do
		if container then
			for _, child in container:GetChildren() do
				if child:IsA("Tool") and child:GetAttribute("ClassWeapon") then
					child:Destroy()
				end
			end
		end
	end
end

local function newTool(weaponName: string, slot: number): Tool
	local tool = Instance.new("Tool")
	tool.Name = weaponName
	tool.CanBeDropped = false
	tool.RequiresHandle = true
	tool.ManualActivationOnly = true -- clicks are handled by Weapon.client.luau, not Tool.Activated
	tool:SetAttribute("ClassWeapon", true)
	tool:SetAttribute("WeaponSlot", slot)
	return tool
end

-- The Part placeholder for `weaponName` (fallback), or nil when there is no builder either.
local function buildPlaceholder(tool: Tool, weaponName: string): boolean
	local build = builders[weaponName]
	if not build then
		return false
	end
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.CanCollide = false
	handle.CanQuery = false
	handle.CanTouch = false
	handle.Massless = true
	handle.Material = Enum.Material.SmoothPlastic
	handle.Parent = tool
	local gripPoint = build(handle)
	handle.Size = handle.Size * SCALE -- builders set the handle size themselves, so scale after
	gripPoint = CFrame.new(gripPoint.Position * SCALE) * gripPoint.Rotation
	-- Builders model the muzzle/blade along the Handle's -Z, which is the way a held tool points, so no extra turn
	-- (a half turn here held the rifle backwards in the Studio test of 2026-10-31).
	tool.Grip = gripPoint
	addMuzzle(handle, "Muzzle")
	return true
end

-- Builds the Tool for `weaponName`, tagged with its loadout slot; nil when there is neither a mesh nor a builder.
-- May yield the first time a weapon's mesh loads.
local function buildTool(weaponName: string, slot: number): Tool?
	local tool = newTool(weaponName, slot)
	local asm = getAssembly(weaponName)
	if asm then
		cloneInto(asm, tool)
		tool.Grip = asm.grip
	elseif not buildPlaceholder(tool, weaponName) then
		warn(`No weapon model for {weaponName}`)
		tool:Destroy()
		return nil
	end

	tool.Equipped:Connect(function()
		local character = tool.Parent
		local attach = offhand[weaponName]
		if attach and character and character:IsA("Model") then
			attach(tool, character)
		end
	end)
	tool.Unequipped:Connect(function()
		for _, child in tool:GetChildren() do
			if child:GetAttribute("Offhand") then
				child:Destroy()
			end
		end
	end)
	return tool
end

-- Builds the primary (equipped on the current character) and the optional melee secondary (in the Backpack) for the
-- player's class. Never yields: the Tools are built in a separate thread (a first mesh load can take a moment, or fall
-- back to the Part placeholder after LOAD_TIMEOUT), so Combat.setLoadout and the class setup after it run at once.
function WeaponModels.give(player: Player, primary: string, secondary: string?)
	WeaponModels.remove(player)
	wantedSlot[player] = 1
	local token = generation[player]
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not character or not humanoid or humanoid.Health <= 0 then
		return
	end
	task.spawn(function()
		local main = buildTool(primary, 1)
		local side = if secondary then buildTool(secondary, 2) else nil
		-- Only hand them over if no newer give/remove happened and this is still the same living character.
		local backpack = player:FindFirstChildOfClass("Backpack")
		if
			generation[player] ~= token
			or player.Character ~= character
			or humanoid.Health <= 0
			or not character.Parent
			or not backpack
		then
			for _, t in { main, side } do
				if t then
					t:Destroy()
				end
			end
			return
		end
		if side then
			side.Parent = backpack
		end
		if main then
			if wantedSlot[player] == 2 and side then
				main.Parent = backpack
				humanoid:EquipTool(side)
			else
				main.Parent = character -- parenting to the character equips it
			end
		end
	end)
end

-- Puts the Tool for loadout `slot` in the player's hand (the other one goes back to the Backpack).
-- Combat calls this after validating the slot; the Tool is only the visual.
function WeaponModels.equip(player: Player, slot: number)
	wantedSlot[player] = slot
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local backpack = player:FindFirstChildOfClass("Backpack")
	if not humanoid or humanoid.Health <= 0 or not backpack then
		return
	end
	for _, child in backpack:GetChildren() do
		if child:IsA("Tool") and child:GetAttribute("ClassWeapon") and child:GetAttribute("WeaponSlot") == slot then
			humanoid:EquipTool(child)
			return
		end
	end
end

-- Loads every mesh template in the background at server start so the first run hands weapons out at once.
task.spawn(function()
	local names = {}
	for name in WeaponMeshes.Weapons do
		table.insert(names, name)
	end
	table.sort(names)
	for _, name in names do
		task.spawn(getAssembly, name)
	end
end)

return WeaponModels
