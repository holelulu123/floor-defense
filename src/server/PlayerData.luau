-- Loads, caches and saves per-player data in a DataStore.

local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local store = DataStoreService:GetDataStore(Config.DataStoreName)
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
	local ok, saved = retry(function()
		return store:GetAsync(key(player))
	end)
	if not ok then
		player:Kick("Could not load your data. Please rejoin.")
		return
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
	local ok = retry(function()
		store:SetAsync(key(player), data)
	end)
	return ok
end

function PlayerData.release(player: Player)
	PlayerData.save(player)
	sessions[player] = nil
end

function PlayerData.addCoins(player: Player, amount: number)
	local data = sessions[player]
	if data then
		data.Coins += amount
	end
end

return PlayerData
