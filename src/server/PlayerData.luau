-- Loads, caches and saves per-player data in a DataStore.

local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Classes = require(ReplicatedStorage.Shared.Classes)
local Config = require(ReplicatedStorage.Shared.Config)

-- GetDataStore throws in Studio until the place is published with API access enabled.
-- Without a store we run on in-memory defaults so the game is still playable locally.
local storeOk, store = pcall(DataStoreService.GetDataStore, DataStoreService, Config.DataStoreName)
if not storeOk then
	warn(`DataStore unavailable, player data will not persist: {store}`)
	store = nil
end

local sessions: { [Player]: { [string]: any } } = {}

local PlayerData = {}

local function key(player: Player): string
	return "player_" .. player.UserId
end

local function retry(fn: () -> any): (boolean, any)
	for attempt = 1, 3 do
		local ok, result = pcall(fn)
		if ok then
			return true, result
		end
		warn(`DataStore attempt {attempt} failed: {result}`)
		task.wait(2 ^ attempt)
	end
	return false, nil
end

function PlayerData.load(player: Player)
	local saved = nil
	if store then
		local ok, result = retry(function()
			return store:GetAsync(key(player))
		end)
		if not ok then
			player:Kick("Could not load your data. Please rejoin.")
			return
		end
		saved = result
	end

	local data = table.clone(Config.DefaultData)
	if type(saved) == "table" then
		for field, value in saved do
			data[field] = value
		end
	end
	data.ProcessedReceipts = data.ProcessedReceipts or {}
	data.OwnedClasses = if type(data.OwnedClasses) == "table" then data.OwnedClasses else {}
	if not Classes.find(data.Class) or not Classes.isOwned(data.Class, data.OwnedClasses) then
		data.Class = Classes.List[1].id
	end

	if player.Parent then
		sessions[player] = data
		PlayerData.publish(player)
	end
end

-- Mirror the fields the UI needs onto player attributes (read-only on the client).
function PlayerData.publish(player: Player)
	local data = sessions[player]
	if not data then
		return
	end
	player:SetAttribute("Gems", data.Gems)
	player:SetAttribute("Level", data.Level)
	player:SetAttribute("Class", data.Class)
	player:SetAttribute("OwnedClasses", table.concat(data.OwnedClasses, ","))
end

function PlayerData.get(player: Player): { [string]: any }?
	return sessions[player]
end

function PlayerData.save(player: Player): boolean
	local data = sessions[player]
	if not data then
		return false
	end
	if not store then
		return true -- nothing to persist to; treat as saved so Studio sessions keep working
	end
	local ok = retry(function()
		store:SetAsync(key(player), data)
	end)
	return ok
end

function PlayerData.release(player: Player)
	PlayerData.save(player)
	sessions[player] = nil
end

function PlayerData.addGems(player: Player, amount: number)
	local data = sessions[player]
	if data then
		data.Gems += amount
		PlayerData.publish(player)
	end
end

-- Player level (unlocks dungeons; see Dungeons.isUnlocked). 1 until the data has loaded.
function PlayerData.levelOf(player: Player): number
	local data = sessions[player]
	return if data and type(data.Level) == "number" then data.Level else 1
end

-- Class the player will use in their next run (always one they own).
function PlayerData.classOf(player: Player): string
	local data = sessions[player]
	return if data then data.Class else Classes.List[1].id
end

-- Spends gems on a locked class. Returns false and a reason when the purchase is not possible.
function PlayerData.buyClass(player: Player, classId: string): (boolean, string?)
	local data = sessions[player]
	if not data then
		return false, "data not loaded"
	end
	local left, why = Classes.tryBuy(classId, data.Gems, data.OwnedClasses)
	if left == nil then
		return false, why
	end
	data.Gems = left
	table.insert(data.OwnedClasses, classId)
	PlayerData.publish(player)
	return true, nil
end

-- Picks a class the player owns. Returns false and a reason otherwise.
function PlayerData.selectClass(player: Player, classId: string): (boolean, string?)
	local data = sessions[player]
	if not data then
		return false, "data not loaded"
	end
	if not Classes.isOwned(classId, data.OwnedClasses) then
		return false, "locked"
	end
	data.Class = classId
	PlayerData.publish(player)
	return true, nil
end

-- Records a finished run's score against the mode's best. Returns true if it is a new best.
function PlayerData.recordScore(player: Player, mode: string, score: number): boolean
	local data = sessions[player]
	if not data then
		return false
	end
	local field = "BestScore" .. mode
	if score > (data[field] or 0) then
		data[field] = score
		return true
	end
	return false
end

return PlayerData
