-- Server-authoritative shooting. The client reports an origin and a direction; the server checks
-- the player is alive and nearby, enforces the weapon's fire rate (with skill buffs), raycasts, and
-- applies damage through Damage.hit. Nothing the client sends is trusted as a hit.
-- Class passives that ride on a shot live here too: Engineer swings repair their turrets, Medic
-- shots patch the Town Hall, Berserker melee hits harder, Sniper Overwatch crits, Demolisher splash.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Skills = require(ReplicatedStorage.Shared.Skills)
local Weapons = require(ReplicatedStorage.Shared.Weapons)
local Creatures = require(script.Parent.Creatures)
local Damage = require(script.Parent.Damage)
local TownHall = require(script.Parent.TownHall)
local Turrets = require(script.Parent.Turrets)

local fireRemote = ReplicatedStorage.Remotes.Fire :: RemoteEvent
local hitFx = ReplicatedStorage.Remotes.HitFx :: RemoteEvent

local Combat = {}

-- How far the reported origin may be from the character's head before the shot is rejected.
local ORIGIN_SLACK = 6
-- Medic passive: a shot into the Town Hall from this close repairs it instead.
local TOWN_HALL_REPAIR_REACH = 12
local TOWN_HALL_REPAIR_PER_HIT = 5

local equipped: { [Player]: Weapons.Weapon } = {}
local lastFired: { [Player]: number } = {}
local townHall: TownHall.TownHall? = nil

local function isVector(v: any): boolean
	return typeof(v) == "Vector3" and v == v -- NaN check
end

local function classOf(player: Player): string?
	local id = player:GetAttribute("Class")
	return if type(id) == "string" then id else nil
end

-- Value of a timed buff stored as `<stat>` / `<stat>Until` attributes on the player.
function Combat.buff(player: Player, stat: string, default: number): number
	return Skills.buffValue(
		player:GetAttribute(stat) :: number?,
		player:GetAttribute(stat .. "Until") :: number?,
		os.clock(),
		default
	)
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

local function onFire(player: Player, origin: any, direction: any)
	local def = equipped[player]
	if not def or not isVector(origin) or not isVector(direction) then
		return
	end

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local head = character and character:FindFirstChild("Head")
	if not humanoid or humanoid.Health <= 0 or not head then
		return
	end
	if (origin - (head :: BasePart).Position).Magnitude > ORIGIN_SLACK then
		return
	end
	if direction.Magnitude < 0.5 then
		return
	end

	local now = os.clock()
	if not Weapons.canFire(def, lastFired[player], now, Combat.buff(player, "FireRateMult", 1)) then
		return
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

	-- Engineer: a swing at one of your own turrets repairs it.
	local turret = Turrets.get(hitInstance)
	if turret and turret.owner == player and classId == "Engineer" then
		if (endpoint - origin).Magnitude <= Skills.Turret.RepairReach then
			Turrets.repair(turret)
			hitFx:FireAllClients(player.UserId, origin, endpoint, true)
		end
		return
	end

	-- Medic: shots into the Town Hall from close range repair it.
	if townHall and hitInstance == townHall.part and classId == "Medic" then
		if (endpoint - origin).Magnitude <= TOWN_HALL_REPAIR_REACH then
			townHall:repair(TOWN_HALL_REPAIR_PER_HIT * Skills.Passives.Medic.repairMult)
			hitFx:FireAllClients(player.UserId, origin, endpoint, true)
		end
		return
	end

	local damage = shotDamage(player, def)
	if def.splash then
		local radius = Skills.splashRadius(classId or "", def.splash)
		local count = Damage.area(endpoint, radius, damage, player.UserId)
		hitFx:FireAllClients(player.UserId, origin, endpoint, count > 0)
		return
	end

	if creature then
		Damage.hit(creature, damage, player.UserId)
		if def.burn and creature.health > 0 then
			Damage.burn(creature, def.burn, player.UserId)
		end
	end
	hitFx:FireAllClients(player.UserId, origin, endpoint, creature ~= nil)
end

function Combat.setWeapon(player: Player, weaponName: string?)
	if weaponName then
		equipped[player] = Weapons.get(weaponName)
	else
		equipped[player] = nil
	end
	lastFired[player] = nil
	player:SetAttribute("Weapon", weaponName)
end

-- The Town Hall of the active run (nil between runs); used by the Medic repair passive.
function Combat.setTownHall(hall: TownHall.TownHall?)
	townHall = hall
end

function Combat.init()
	fireRemote.OnServerEvent:Connect(onFire)
	Players.PlayerRemoving:Connect(function(player)
		equipped[player] = nil
		lastFired[player] = nil
	end)
end

return Combat
