-- Engineer turrets: server-owned Part models that shoot the nearest creature. Rules (max 3, oldest
-- replaced, repair maths, overclock timing) live in shared Skills.Turret so they are unit-tested.
-- Creatures standing next to a turret chew on it; at 0 health it is destroyed. Melee repairs it.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Skills = require(ReplicatedStorage.Shared.Skills)
local Damage = require(script.Parent.Damage)

local skillFx = ReplicatedStorage.Remotes.SkillFx :: RemoteEvent

local Turrets = {}

export type Turret = {
	model: Model,
	base: Part,
	head: Part,
	owner: Player,
	health: number,
	maxHealth: number,
	placedAt: number,
	lastFired: number?,
	overclockUntil: number?,
}

local byPlayer: { [Player]: { Turret } } = {}
local byPart: { [BasePart]: Turret } = {}
local heartbeat: RBXScriptConnection? = nil

local function publishCount(player: Player)
	local list = byPlayer[player]
	player:SetAttribute("Turrets", if list then #list else 0)
end

local function setHealth(t: Turret, health: number)
	t.health = math.clamp(health, 0, t.maxHealth)
	t.model:SetAttribute("Health", t.health)
end

local function build(owner: Player, position: Vector3, lookAt: Vector3): Turret
	local model = Instance.new("Model")
	model.Name = "Turret"

	local base = Instance.new("Part")
	base.Name = "Base"
	base.Shape = Enum.PartType.Cylinder
	base.Size = Vector3.new(0.6, 2.6, 2.6)
	base.CFrame = CFrame.new(position + Vector3.new(0, 0.3, 0)) * CFrame.Angles(0, 0, math.rad(90))
	base.Anchored = true
	base.Color = Color3.fromRGB(80, 85, 95)
	base.Material = Enum.Material.Metal
	base.Parent = model

	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = Vector3.new(1.4, 1.2, 1.6)
	head.CFrame = CFrame.lookAt(position + Vector3.new(0, 1.4, 0), Vector3.new(lookAt.X, position.Y + 1.4, lookAt.Z))
	head.Anchored = true
	head.Color = Color3.fromRGB(200, 140, 50)
	head.Material = Enum.Material.Metal
	head.Parent = model

	local barrel = Instance.new("Part")
	barrel.Name = "Barrel"
	barrel.Size = Vector3.new(0.35, 0.35, 1.8)
	barrel.CFrame = head.CFrame * CFrame.new(0, 0.15, -1.4)
	barrel.Anchored = true
	barrel.Color = Color3.fromRGB(50, 50, 60)
	barrel.Material = Enum.Material.Metal
	barrel.Parent = model
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = head
	weld.Part1 = barrel
	weld.Parent = barrel

	model.PrimaryPart = head
	model:SetAttribute("Owner", owner.UserId)
	model:SetAttribute("MaxHealth", Skills.Turret.Health)
	model.Parent = Workspace

	local t: Turret = {
		model = model,
		base = base,
		head = head,
		owner = owner,
		health = Skills.Turret.Health,
		maxHealth = Skills.Turret.Health,
		placedAt = os.clock(),
		lastFired = nil,
		overclockUntil = nil,
	}
	setHealth(t, t.maxHealth)
	byPart[base] = t
	byPart[head] = t
	byPart[barrel] = t
	return t
end

local function destroy(t: Turret)
	for _, child in t.model:GetChildren() do
		if child:IsA("BasePart") then
			byPart[child] = nil
		end
	end
	t.model:Destroy()
end

local function step(dt: number)
	local now = os.clock()
	for player, list in byPlayer do
		for i = #list, 1, -1 do
			local t = list[i]
			-- Creatures next to the turret damage it.
			local chewing =
				#Skills.inRadius(t.base.Position, Damage.positions(Damage.creatures()), Skills.Turret.BumpRadius)
			if chewing > 0 then
				setHealth(t, t.health - Skills.Turret.BumpDamagePerSecond * dt)
				if t.health <= 0 then
					destroy(t)
					table.remove(list, i)
					publishCount(player)
					continue
				end
			end

			local target = Damage.nearest(t.head.Position, Skills.Turret.Range)
			if target then
				local aim = target.part.Position
				t.head.CFrame = CFrame.lookAt(t.head.Position, Vector3.new(aim.X, t.head.Position.Y, aim.Z))
				if Skills.Turret.canFire(t.lastFired, t.overclockUntil, now) then
					t.lastFired = now
					Damage.hit(target, Skills.Turret.Damage, player.UserId)
					skillFx:FireAllClients({ kind = "turretShot", from = t.head.Position, to = aim })
				end
			end
		end
	end
end

local function ensureLoop()
	if not heartbeat then
		heartbeat = RunService.Heartbeat:Connect(step)
	end
end

-- Puts a turret down for `player`. Replaces the oldest when the cap is reached.
function Turrets.place(player: Player, position: Vector3, lookAt: Vector3): Turret
	local list = byPlayer[player] or {}
	byPlayer[player] = list

	local placedAt = {}
	for i, t in list do
		placedAt[i] = t.placedAt
	end
	local index, replaced = Skills.Turret.placeIndex(placedAt)
	if replaced then
		destroy(list[index])
	end
	local t = build(player, position, lookAt)
	list[index] = t
	publishCount(player)
	ensureLoop()
	return t
end

function Turrets.get(inst: Instance?): Turret?
	return if inst and inst:IsA("BasePart") then byPart[inst] else nil
end

function Turrets.count(player: Player): number
	local list = byPlayer[player]
	return if list then #list else 0
end

-- One melee swing's worth of repair (+25% of max).
function Turrets.repair(t: Turret)
	setHealth(t, Skills.Turret.repair(t.health, t.maxHealth))
end

function Turrets.overclock(player: Player, seconds: number)
	local untilTime = os.clock() + seconds
	for _, t in byPlayer[player] or ({} :: { Turret }) do
		t.overclockUntil = untilTime
		t.model:SetAttribute("OverclockUntil", untilTime)
	end
end

function Turrets.removeFor(player: Player)
	for _, t in byPlayer[player] or ({} :: { Turret }) do
		destroy(t)
	end
	byPlayer[player] = nil
	if player.Parent then
		publishCount(player)
	end
end

function Turrets.clear()
	for player in byPlayer do
		Turrets.removeFor(player)
	end
	if heartbeat then
		heartbeat:Disconnect()
		heartbeat = nil
	end
end

function Turrets.init()
	Players.PlayerRemoving:Connect(Turrets.removeFor)
end

return Turrets
