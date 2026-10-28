-- Loads, caches and saves per-player data in a DataStore.

local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

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

	if player.Parent then
		sessions[player] = data
	end
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
	end
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
