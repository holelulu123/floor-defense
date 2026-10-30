-- Server entry point. A server is either the lobby or a reserved run server; Studio runs both in
-- one place so the loop can be tested without teleporting.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")

local Config = require(ReplicatedStorage.Shared.Config)
local Dungeons = require(ReplicatedStorage.Shared.Dungeons)
local ClassService = require(script.Parent.ClassService)
local Combat = require(script.Parent.Combat)
local Lobby = require(script.Parent.Lobby)
local Monetization = require(script.Parent.Monetization)
local PlayerData = require(script.Parent.PlayerData)
local Run = require(script.Parent.Run)
local Skills = require(script.Parent.Skills)
local Turrets = require(script.Parent.Turrets)

Monetization.init()
Combat.init()
Turrets.init()
Skills.init()
ClassService.init({
	canSwitch = Run.canSwitchClass,
	onSwitch = Run.equipClass, -- no-op outside a run; re-equips during prep
})

Players.PlayerAdded:Connect(PlayerData.load)
for _, player in Players:GetPlayers() do
	task.spawn(PlayerData.load, player)
end
Players.PlayerRemoving:Connect(PlayerData.release)

local runPlaceId = if Config.RunPlaceId ~= 0 then Config.RunPlaceId else game.PlaceId
local isReservedServer = game.PrivateServerId ~= "" and game.PrivateServerOwnerId == 0
local canTeleport = not RunService:IsStudio()

local function startLocalRun(mode: string, players: { Player }, dungeonId: string)
	Lobby.setLocked(true)
	Run.start(mode, players, function(_, wave)
		print(`Run ended on wave {wave} in {dungeonId}`)
		Lobby.setLocked(false)
		for _, player in players do
			if player.Parent then
				player:LoadCharacter()
			end
		end
	end, dungeonId)
end

local function teleportToRun(mode: string, players: { Player }, dungeonId: string)
	local ok, code = pcall(TeleportService.ReserveServer, TeleportService, runPlaceId)
	if not ok then
		warn(`ReserveServer failed: {code}`)
		return
	end
	local options = Instance.new("TeleportOptions")
	options.ReservedServerAccessCode = code
	options:SetTeleportData({ mode = mode, dungeonId = dungeonId })
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
	-- Teleport data comes from the lobby server, but check it names a real dungeon all the same.
	local dungeonId = Dungeons.List[1].id
	if type(data) == "table" and type(data.dungeonId) == "string" and pcall(Dungeons.get, data.dungeonId) then
		dungeonId = data.dungeonId
	end
	task.wait(3) -- let the rest of the group load in
	Run.start(mode, Players:GetPlayers(), function()
		task.wait(5)
		TeleportService:TeleportAsync(game.PlaceId, Players:GetPlayers())
	end, dungeonId)
else
	Lobby.start(function(mode, players, dungeonId)
		if Run.isActive() then
			return
		end
		if canTeleport then
			teleportToRun(mode, players, dungeonId)
		else
			startLocalRun(mode, players, dungeonId)
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
