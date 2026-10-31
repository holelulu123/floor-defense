-- Server-authoritative shooting. The client reports an origin and a direction; the server checks
-- the player is alive and nearby, enforces the weapon's fire rate (with skill buffs) and magazine,
-- raycasts, and applies damage through Damage.hit. Nothing the client sends is trusted as a hit.
-- Class passives that ride on a shot live here too: Engineer melee repairs their turrets, Medic
-- shots patch the Town Hall, Berserker melee hits harder, Sniper Overwatch crits, Demolisher splash.
--
-- Loadout: slot 1 is the class primary, slot 2 its melee secondary (Classes `secondary`). The client
-- asks for a slot with Remotes.EquipSlot(slot) and for a reload with Remotes.Reload(); the server owns
-- which slot is active and the primary's magazine (shared Weapons magazine helpers), and publishes
-- player attributes for the HUD: Weapon (active weapon name), WeaponSlot, Ammo, MagazineSize,
-- Reloading, ReloadEnd (Workspace:GetServerTimeNow() seconds). Ammo/MagazineSize are nil without a
-- magazine. An empty magazine reloads on its own.
--
-- Remotes.HitFx(shooterUserId, origin, endpoint, hit, target?, melee?) goes to every client after each accepted
-- shot: tracers and muzzle flashes for guns, sparks and a hit flash on `target` (the creature's part) for melee.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Classes = require(ReplicatedStorage.Shared.Classes)
local Skills = require(ReplicatedStorage.Shared.Skills)
local Weapons = require(ReplicatedStorage.Shared.Weapons)
local Creatures = require(script.Parent.Creatures)
local Damage = require(script.Parent.Damage)
local TownHall = require(script.Parent.TownHall)
local Turrets = require(script.Parent.Turrets)
local WeaponModels = require(script.Parent.WeaponModels)

local fireRemote = ReplicatedStorage.Remotes.Fire :: RemoteEvent
local equipSlotRemote = ReplicatedStorage.Remotes.EquipSlot :: RemoteEvent
local reloadRemote = ReplicatedStorage.Remotes.Reload :: RemoteEvent
local hitFx = ReplicatedStorage.Remotes.HitFx :: RemoteEvent

local Combat = {}

-- How far the reported origin (the weapon's Muzzle attachment, or the head for melee) may be from the
-- HumanoidRootPart before the shot is rejected. A muzzle past a wall is pulled back to the body (see muzzleOrigin).
local ORIGIN_SLACK = 8
-- Medic passive: a shot into the Town Hall from this close repairs it instead.
local TOWN_HALL_REPAIR_REACH = 12
local TOWN_HALL_REPAIR_PER_HIT = 5

type Loadout = {
	classId: string,
	slots: { [number]: Weapons.Weapon }, -- 1 primary, 2 secondary (absent for the Tank)
	active: number,
	magazine: Weapons.Magazine?, -- the primary's; nil for melee and magic primaries
	reloadToken: number, -- bumped whenever a scheduled reload completion must be ignored
}

local loadouts: { [Player]: Loadout } = {}
-- One clock across both slots, so swapping weapons never resets the fire-rate check.
local lastFired: { [Player]: number } = {}
local townHall: TownHall.TownHall? = nil

local function isVector(v: any): boolean
	return typeof(v) == "Vector3" and v == v -- NaN check
end

local function classOf(player: Player): string?
	local id = player:GetAttribute("Class")
	return if type(id) == "string" then id else nil
end

-- Value of a timed buff stored as `<stat>` / `<stat>Until` attributes on the player
-- (Until is in Workspace:GetServerTimeNow() seconds, see server Skills.luau).
function Combat.buff(player: Player, stat: string, default: number): number
	return Skills.buffValue(
		player:GetAttribute(stat) :: number?,
		player:GetAttribute(stat .. "Until") :: number?,
		Workspace:GetServerTimeNow(),
		default
	)
end

-- Loadout and magazine -------------------------------------------------------------------------------

local function serverNow(): number
	return Workspace:GetServerTimeNow()
end

local function activeWeapon(player: Player): Weapons.Weapon?
	local loadout = loadouts[player]
	return loadout and loadout.slots[loadout.active]
end

local function publish(player: Player)
	local loadout = loadouts[player]
	local def = loadout and loadout.slots[loadout.active]
	player:SetAttribute("Weapon", def and def.name)
	player:SetAttribute("WeaponSlot", loadout and loadout.active)
	local mag = loadout and loadout.magazine
	local reloading = mag ~= nil and Weapons.isReloading(mag, serverNow())
	player:SetAttribute("Ammo", mag and mag.ammo)
	player:SetAttribute("MagazineSize", mag and mag.size)
	player:SetAttribute("Reloading", if mag then reloading else nil)
	player:SetAttribute("ReloadEnd", if mag and reloading then mag.reloadUntil else nil)
end

-- Starts a reload of the primary's magazine (no-op when full, already reloading or magazine-less) and
-- schedules the attribute update for when it completes.
local function startReload(player: Player)
	local loadout = loadouts[player]
	local mag = loadout and loadout.magazine
	if not loadout or not mag then
		return
	end
	local seconds = Weapons.reloadTime(loadout.slots[1], loadout.classId)
	if not seconds or not Weapons.beginReload(mag, seconds, serverNow()) then
		return
	end
	loadout.reloadToken += 1
	local token = loadout.reloadToken
	publish(player)
	task.delay(seconds, function()
		if loadouts[player] == loadout and loadout.reloadToken == token then
			Weapons.settle(mag, serverNow() + 0.05) -- task.delay can wake a frame early
			publish(player)
		end
	end)
end

local function shotDamage(player: Player, def: Weapons.Weapon): number
	local damage = def.damage * Combat.buff(player, "DamageMult", 1)
	local classId = classOf(player)
	if def.melee and classId == "Berserker" then
		damage *= Skills.Passives.Berserker.meleeMult
	end
	-- Sniper Overwatch: the next N shots inside the window are crits.
	local crits = player:GetAttribute("CritShots")
	if type(crits) == "number" and crits > 0 and Combat.buff(player, "CritShots", 0) > 0 then
		player:SetAttribute("CritShots", crits - 1)
		damage *= Skills.Effects.Overwatch.multiplier
	end
	return damage
end

-- The ray origin the server uses for a reported muzzle position: nil when it is too far from the character, and the
-- HumanoidRootPart when anything stands between the body and the muzzle (no shooting through a wall by pressing the
-- gun against it; a creature at point-blank range is still in the ray's path from the body).
local function muzzleOrigin(character: Model, root: BasePart, origin: Vector3): Vector3?
	local offset = origin - root.Position
	if offset.Magnitude > ORIGIN_SLACK then
		return nil
	end
	if offset.Magnitude < 0.05 then
		return origin
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character }
	if Workspace:Raycast(root.Position, offset, params) then
		return root.Position
	end
	return origin
end

local function onFire(player: Player, origin: any, direction: any)
	local def = activeWeapon(player)
	if not def or not isVector(origin) or not isVector(direction) then
		return
	end

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not character or not humanoid or humanoid.Health <= 0 or not root or not root:IsA("BasePart") then
		return
	end
	local checked = muzzleOrigin(character, root, origin)
	if not checked then
		return
	end
	origin = checked
	if direction.Magnitude < 0.5 then
		return
	end

	local now = os.clock()
	if not Weapons.canFire(def, lastFired[player], now, Combat.buff(player, "FireRateMult", 1)) then
		return
	end
	-- Only the primary has a magazine; melee secondaries never run dry.
	local loadout = loadouts[player]
	local mag = if loadout and loadout.active == 1 then loadout.magazine else nil
	if mag then
		if not Weapons.consume(mag, serverNow()) then
			startReload(player) -- empty and somehow not reloading yet: start now
			return
		end
		publish(player)
		if mag.ammo <= 0 then
			startReload(player) -- empty: reload on its own
		end
	end
	lastFired[player] = now

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character }

	local result = Workspace:Raycast(origin, direction.Unit * def.range, params)
	local endpoint = if result then result.Position else origin + direction.Unit * def.range
	local hitInstance = result and result.Instance
	local creature = if hitInstance then Creatures.get(hitInstance) else nil
	local classId = classOf(player)

	-- Engineer: a melee hit (the Hammer) on one of your own turrets repairs it; shots just stop there.
	local turret = Turrets.get(hitInstance)
	if turret and turret.owner == player and classId == "Engineer" then
		if def.melee and (endpoint - origin).Magnitude <= Skills.Turret.RepairReach then
			Turrets.repair(turret)
			hitFx:FireAllClients(player.UserId, origin, endpoint, true, nil, def.melee == true)
		end
		return
	end

	-- Medic: shots into the Town Hall from close range repair it.
	if townHall and hitInstance == townHall.part and classId == "Medic" then
		if (endpoint - origin).Magnitude <= TOWN_HALL_REPAIR_REACH then
			townHall:repair(TOWN_HALL_REPAIR_PER_HIT * Skills.Passives.Medic.repairMult)
			hitFx:FireAllClients(player.UserId, origin, endpoint, true, nil, def.melee == true)
		end
		return
	end

	-- Melee: forgive a ray that just missed (lag, fast creatures) by taking the nearest creature in the swing arc.
	if def.melee and not creature then
		local list = Damage.creatures()
		local hits = Skills.inCone(
			root.Position,
			direction,
			Damage.positions(list),
			def.range + Weapons.MeleeArc.slack,
			Weapons.MeleeArc.halfAngle
		)
		local best, bestDist = nil, math.huge
		for _, i in hits do
			local d = (list[i].part.Position - root.Position).Magnitude
			if d < bestDist and math.abs(list[i].part.Position.Y - root.Position.Y) < 12 then
				best, bestDist = list[i], d
			end
		end
		if best then
			creature = best
			endpoint = best.part.Position
		end
	end

	local damage = shotDamage(player, def)
	if def.splash then
		local radius = Skills.splashRadius(classId or "", def.splash)
		local count = Damage.area(endpoint, radius, damage, player.UserId)
		hitFx:FireAllClients(player.UserId, origin, endpoint, count > 0, nil, def.melee == true)
		return
	end

	if creature then
		Damage.hit(creature, damage, player.UserId)
		if def.burn and creature.health > 0 then
			Damage.burn(creature, def.burn, player.UserId)
		end
	end
	hitFx:FireAllClients(
		player.UserId,
		origin,
		endpoint,
		creature ~= nil,
		creature and creature.part,
		def.melee == true
	)
end

-- Arms the player with their class loadout (slot 1 active, full magazine), or disarms them with nil.
-- Builds the matching Tools too. Called at run start, after a respawn, on a prep class switch and at
-- run end.
function Combat.setLoadout(player: Player, classId: string?)
	local old = loadouts[player]
	if old then
		old.reloadToken += 1
	end
	lastFired[player] = nil
	local class = Classes.find(classId)
	if not class then
		loadouts[player] = nil
		WeaponModels.remove(player)
		publish(player)
		return
	end
	local primary = Weapons.get(class.weapon)
	local slots = { [1] = primary }
	if class.secondary then
		slots[2] = Weapons.get(class.secondary)
	end
	loadouts[player] = {
		classId = class.id,
		slots = slots,
		active = 1,
		magazine = Weapons.newMagazine(primary),
		reloadToken = 0,
	}
	WeaponModels.give(player, class.weapon, class.secondary)
	publish(player)
end

-- Instantly fills the player's magazine and cancels a running reload (Trooper's Ammo Crate).
function Combat.refill(player: Player)
	local loadout = loadouts[player]
	if loadout and loadout.magazine then
		loadout.reloadToken += 1
		Weapons.refill(loadout.magazine)
		publish(player)
	end
end

local function onEquipSlot(player: Player, slot: any)
	local loadout = loadouts[player]
	if not loadout or (slot ~= 1 and slot ~= 2) or not loadout.slots[slot] or loadout.active == slot then
		return
	end
	loadout.active = slot
	WeaponModels.equip(player, slot)
	publish(player)
end

local function onReload(player: Player)
	local loadout = loadouts[player]
	if loadout and loadout.active == 1 then
		startReload(player)
	end
end

-- The Town Hall of the active run (nil between runs); used by the Medic repair passive.
function Combat.setTownHall(hall: TownHall.TownHall?)
	townHall = hall
end

function Combat.init()
	fireRemote.OnServerEvent:Connect(onFire)
	equipSlotRemote.OnServerEvent:Connect(onEquipSlot)
	reloadRemote.OnServerEvent:Connect(onReload)
	Players.PlayerRemoving:Connect(function(player)
		loadouts[player] = nil
		lastFired[player] = nil
	end)
end

return Combat
