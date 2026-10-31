-- Placeholder class weapons built from Parts and handed to the player as Tools: the primary (slot 1)
-- is equipped in the right hand, the melee secondary (slot 2) waits in the Backpack until Combat
-- swaps it in with WeaponModels.equip. The player keeps their own avatar; only the Tool (and the Tank's shield on
-- the left arm) is added. Firing still goes through Weapon.client.luau -> Remotes.Fire; the Tool is
-- purely visual, so nothing about it is trusted by the server.
-- Models point their business end along the Handle's -Z, which is where a held tool faces.

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

-- Extra part welded to the left arm while the tool is equipped (Tank shield, Scout's second pistol).
local offhand: { [string]: (arm: BasePart) -> BasePart } = {
	Flail = function(arm)
		local shield = Instance.new("Part")
		shield.Name = "Shield"
		shield.Size = Vector3.new(2.4, 2.4, 0.25)
		shield.Shape = Enum.PartType.Cylinder
		shield.Size = Vector3.new(0.25, 2.4, 2.4)
		shield.Color = Color3.fromRGB(150, 110, 60)
		shield.Material = Enum.Material.Wood
		shield.CanCollide = false
		shield.CanQuery = false
		shield.Massless = true
		shield.CFrame = arm.CFrame * CFrame.new(-arm.Size.X / 2 - 0.15, 0, 0)
		return shield
	end,
	DualPistols = function(arm)
		local pistol = Instance.new("Part")
		pistol.Name = "LeftPistol"
		pistol.Size = Vector3.new(0.25, 0.35, 0.9)
		pistol.Color = GUN_METAL
		pistol.CanCollide = false
		pistol.CanQuery = false
		pistol.Massless = true
		pistol.CFrame = arm.CFrame * CFrame.new(0, -arm.Size.Y / 2 - 0.1, -0.3)
		return pistol
	end,
}

local function leftArm(character: Model): BasePart?
	local arm = character:FindFirstChild("LeftLowerArm") or character:FindFirstChild("Left Arm")
	return if arm and arm:IsA("BasePart") then arm else nil
end

local function attachOffhand(tool: Tool, weaponName: string)
	local make = offhand[weaponName]
	local character = tool.Parent
	if not make or not character or not character:IsA("Model") then
		return
	end
	local arm = leftArm(character)
	if not arm then
		return
	end
	local p = make(arm)
	p.Anchored = false
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = arm
	weld.Part1 = p
	weld.Parent = p
	p.Parent = tool
end

function WeaponModels.remove(player: Player)
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

-- Builds the Tool for `weaponName`, tagged with its loadout slot; nil when there is no builder.
local function buildTool(weaponName: string, slot: number): Tool?
	local build = builders[weaponName]
	if not build then
		warn(`No weapon model for {weaponName}`)
		return nil
	end

	local tool = Instance.new("Tool")
	tool.Name = weaponName
	tool.CanBeDropped = false
	tool.RequiresHandle = true
	tool.ManualActivationOnly = true -- clicks are handled by Weapon.client.luau, not Tool.Activated
	tool:SetAttribute("ClassWeapon", true)
	tool:SetAttribute("WeaponSlot", slot)

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
	-- Builders model the muzzle/blade along the Handle's -Z; the hand's grip axis points the other way, so turn
	-- the handle around or the weapon sits reversed in the hand (seen in the first Studio test).
	tool.Grip = gripPoint * CFrame.Angles(0, math.pi, 0)

	tool.Equipped:Connect(function()
		attachOffhand(tool, weaponName)
	end)
	tool.Unequipped:Connect(function()
		for _, child in tool:GetChildren() do
			if child:IsA("BasePart") and child.Name ~= "Handle" and child:FindFirstChildOfClass("WeldConstraint") then
				local weld = child:FindFirstChildOfClass("WeldConstraint") :: WeldConstraint
				if weld.Part0 and weld.Part0.Parent ~= tool then
					child:Destroy()
				end
			end
		end
	end)
	return tool
end

-- Builds the primary (equipped on the current character) and the optional melee secondary (in the
-- Backpack) for the player's class.
function WeaponModels.give(player: Player, primary: string, secondary: string?)
	WeaponModels.remove(player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not character or not humanoid or humanoid.Health <= 0 then
		return
	end
	local main = buildTool(primary, 1)
	if main then
		main.Parent = character -- parenting to the character equips it
	end
	local backpack = player:FindFirstChildOfClass("Backpack")
	if secondary and backpack then
		local side = buildTool(secondary, 2)
		if side then
			side.Parent = backpack
		end
	end
end

-- Puts the Tool for loadout `slot` in the player's hand (the other one goes back to the Backpack).
-- Combat calls this after validating the slot; the Tool is only the visual.
function WeaponModels.equip(player: Player, slot: number)
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

return WeaponModels
