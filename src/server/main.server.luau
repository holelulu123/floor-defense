-- Server entry point. A server is either the lobby or a reserved run server; Studio runs both in
-- one place so the loop can be tested without teleporting.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")

local Config = require(ReplicatedStorage.Shared.Config)
local Lobby = require(script.Parent.Lobby)
local Monetization = require(script.Parent.Monetization)
local PlayerData = require(script.Parent.PlayerData)
local Run = require(script.Parent.Run)

Monetization.init()

Players.PlayerAdded:Connect(PlayerData.load)
for _, player in Players:GetPlayers() do
	task.spawn(PlayerData.load, player)
end
Players.PlayerRemoving:Connect(PlayerData.release)

local runPlaceId = if Config.RunPlaceId ~= 0 then Config.RunPlaceId else game.PlaceId
local isReservedServer = game.PrivateServerId ~= "" and game.PrivateServerOwnerId == 0
local canTeleport = not RunService:IsStudio()

local function startLocalRun(mode: string, players: { Player })
	Lobby.setLocked(true)
	Run.start(mode, players, function(_, wave)
		print(`Run ended on wave {wave}`)
		Lobby.setLocked(false)
		for _, player in players do
			if player.Parent then
				player:LoadCharacter()
			end
		end
	end)
end

local function teleportToRun(mode: string, players: { Player })
	local ok, code = pcall(TeleportService.ReserveServer, TeleportService, runPlaceId)
	if not ok then
		warn(`ReserveServer failed: {code}`)
		return
	end
	local options = Instance.new("TeleportOptions")
	options.ReservedServerAccessCode = code
	options:SetTeleportData({ mode = mode })
	local sent, err = pcall(TeleportService.TeleportAsync, TeleportService, runPlaceId, players, options)
	if not sent then
		warn(`TeleportAsync failed: {err}`)
	end
end

if isReservedServer then
	-- Run server: the first arrival carries the mode; everyone in the teleport group arrives together.
	local first = Players:GetPlayers()[1] or Players.PlayerAdded:Wait()
	local data = first:GetJoinData().TeleportData
	local mode = if type(data) == "table" and data.mode then data.mode else "Solo"
	task.wait(3) -- let the rest of the group load in
	Run.start(mode, Players:GetPlayers(), function()
		task.wait(5)
		TeleportService:TeleportAsync(game.PlaceId, Players:GetPlayers())
	end)
else
	Lobby.start(function(mode, players)
		if Run.isActive() then
			return
		end
		if canTeleport then
			teleportToRun(mode, players)
		else
			startLocalRun(mode, players)
		end
	end)
end

-- Save everyone in parallel before the server shuts down.
game:BindToClose(function()
	local pending = 0
	for _, player in Players:GetPlayers() do
		pending += 1
		task.spawn(function()
			PlayerData.release(player)
			pending -= 1
		end)
	end
	while pending > 0 do
		task.wait()
	end
end)
