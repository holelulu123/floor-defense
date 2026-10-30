-- Class purchase and selection remotes. Everything is validated against shared Classes rules and the
-- player's saved data; the client only ever sends a class id.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Classes = require(ReplicatedStorage.Shared.Classes)
local PlayerData = require(script.Parent.PlayerData)

local buyClass = ReplicatedStorage.Remotes.BuyClass :: RemoteFunction
local selectClass = ReplicatedStorage.Remotes.SelectClass :: RemoteFunction

local ClassService = {}

export type Hooks = {
	-- May this player change class right now? (lobby, or the prep phase of their run)
	canSwitch: (Player) -> boolean,
	-- Called after a successful switch so an in-progress run can re-equip the player.
	onSwitch: (Player) -> (),
}

local function reply(ok: boolean, reason: string?, player: Player)
	local data = PlayerData.get(player)
	return { ok = ok, reason = reason, gems = data and data.Gems or 0, class = PlayerData.classOf(player) }
end

function ClassService.init(hooks: Hooks)
	buyClass.OnServerInvoke = function(player, classId)
		if not Classes.find(classId) then
			return reply(false, "unknown class", player)
		end
		local ok, why = PlayerData.buyClass(player, classId)
		if ok then
			PlayerData.save(player) -- a purchase is worth an immediate save
		end
		return reply(ok, why, player)
	end

	selectClass.OnServerInvoke = function(player, classId)
		if not Classes.find(classId) then
			return reply(false, "unknown class", player)
		end
		if not hooks.canSwitch(player) then
			return reply(false, "cannot change class mid-run", player)
		end
		local ok, why = PlayerData.selectClass(player, classId)
		if ok then
			hooks.onSwitch(player)
		end
		return reply(ok, why, player)
	end
end

return ClassService
