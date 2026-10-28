-- Server-authoritative shooting. The client reports an origin and a direction; the server checks
-- the player is alive and nearby, enforces the weapon's fire rate, raycasts, and applies damage.
-- Nothing the client sends is trusted as a hit.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Weapons = require(ReplicatedStorage.Shared.Weapons)
local Creatures = require(script.Parent.Creatures)

local fireRemote = ReplicatedStorage.Remotes.Fire :: RemoteEvent
local hitFx = ReplicatedStorage.Remotes.HitFx :: RemoteEvent

local Combat = {}

-- How far the reported origin may be from the character's head before the shot is rejected.
local ORIGIN_SLACK = 6

local equipped: { [Player]: Weapons.Weapon } = {}
local lastFired: { [Player]: number } = {}

local function isVector(v: any): boolean
	return typeof(v) == "Vector3" and v == v -- NaN check
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
	if not Weapons.canFire(def, lastFired[player], now) then
		return
	end
	lastFired[player] = now

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character }

	local result = Workspace:Raycast(origin, direction.Unit * def.range, params)
	local endpoint = if result then result.Position else origin + direction.Unit * def.range
	local creature = result and Creatures.get(result.Instance)
	if creature then
		Creatures.damage(creature, def.damage, player.UserId)
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

function Combat.init()
	fireRemote.OnServerEvent:Connect(onFire)
	Players.PlayerRemoving:Connect(function(player)
		equipped[player] = nil
		lastFired[player] = nil
	end)
end

return Combat
