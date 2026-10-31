-- One run of Floor Defense for a fixed group of players: builds the arena, moves the players in,
-- runs waves, tracks per-player coins and score, and reports the result when the Town Hall falls.
-- In-run coins reset every run; the final score, XP and Diamonds (Progression.xpForRun / diamondsForRun
-- from the dungeon and the wave reached) are persisted via PlayerData and announced with RunResults.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Dungeons = require(ReplicatedStorage.Shared.Dungeons)
local Progression = require(ReplicatedStorage.Shared.Progression)
local Arena = require(script.Parent.Arena)
local Combat = require(script.Parent.Combat)
local PlayerData = require(script.Parent.PlayerData)
local Skills = require(script.Parent.Skills)
local TownHall = require(script.Parent.TownHall)
local WaveManager = require(script.Parent.WaveManager)

local runState = ReplicatedStorage.Remotes.RunState :: RemoteEvent
local runResults = ReplicatedStorage.Remotes.RunResults :: RemoteEvent

local Run = {}

export type PlayerRun = { coins: number, score: number, kills: number }

local current: {
	mode: string,
	dungeonId: string,
	players: { [number]: PlayerRun },
	session: WaveManager.Session,
	arena: Arena.Built,
	townHall: TownHall.TownHall,
	phase: string,
	wave: number,
	connections: { RBXScriptConnection },
}? =
	nil

local function broadcast(phase: string, wave: number, secondsLeft: number)
	if not current then
		return
	end
	local party = {}
	for userId in current.players do
		table.insert(party, userId)
	end
	table.sort(party)
	for _, player in Players:GetPlayers() do
		local pr = current.players[player.UserId]
		if pr then
			runState:FireClient(player, {
				party = party, -- UserIds in this run, for the HUD's party health panel
				phase = phase,
				wave = wave,
				secondsLeft = secondsLeft,
				townHallHealth = current.townHall.health,
				townHallMax = current.townHall.maxHealth,
				coins = pr.coins,
				score = pr.score,
				kills = pr.kills,
			})
		end
	end
end

local function moveIn(player: Player, spawn: Vector3)
	local character = player.Character or player.CharacterAdded:Wait()
	character:PivotTo(CFrame.new(spawn))
end

function Run.isActive(): boolean
	return current ~= nil
end

function Run.playerRun(player: Player): PlayerRun?
	return current and current.players[player.UserId]
end

-- Classes are picked in the prep countdown before wave 1 of the player's own run; never in the lobby and
-- never once wave 1 has started.
function Run.canSwitchClass(player: Player): boolean
	return current ~= nil and current.players[player.UserId] ~= nil and current.phase == "prep" and current.wave <= 1
end

-- Gives the player their selected class's weapons (stats + Tools, slot 1 in hand) and passives. Called at run
-- start, after a respawn during the run, and when the class is switched during prep.
function Run.equipClass(player: Player)
	if not current or not current.players[player.UserId] then
		return
	end
	Combat.setLoadout(player, PlayerData.classOf(player)) -- primary + melee Tools, full magazine
	Skills.applyClass(player)
end

function Run.start(mode: string, players: { Player }, onEnd: (mode: string, wave: number) -> (), dungeonId: string?)
	assert(current == nil, "a run is already active")

	local arena = Arena.build(dungeonId)
	local townHall = TownHall.new(arena.townHall, Config.TownHallHealth)

	local runPlayers: { [number]: PlayerRun } = {}
	for i, player in players do
		runPlayers[player.UserId] = { coins = 0, score = 0, kills = 0 }
		player:SetAttribute("InRun", true) -- clients hide the lobby level tag
		moveIn(player, arena.spawns[(i - 1) % #arena.spawns + 1])
	end

	local session
	session = WaveManager.start(mode, arena.dungeonId, townHall, arena, {
		onKill = function(killer, _archetype, coins)
			local pr = killer and runPlayers[killer]
			if pr then
				pr.coins += coins
				pr.score += coins
				pr.kills += 1
				local killerPlayer = Players:GetPlayerByUserId(killer)
				if killerPlayer then
					Skills.onKill(killerPlayer)
				end
			end
		end,
		onWaveCleared = function(wave, bonus)
			for _, pr in runPlayers do
				pr.score += bonus
			end
			broadcast("cleared", wave, 0)
		end,
		onPhase = function(phase, wave, secondsLeft)
			if current then
				current.phase = phase
				current.wave = wave
			end
			broadcast(phase, wave, secondsLeft)
			if phase == "ended" then
				Run.finish(wave)
				onEnd(mode, wave)
			end
		end,
	})

	local connections = {}
	current = {
		mode = mode,
		dungeonId = arena.dungeonId,
		players = runPlayers,
		session = session,
		arena = arena,
		townHall = townHall,
		phase = "prep",
		wave = 1,
		connections = connections,
	}
	Combat.setTownHall(townHall)
	Skills.beginRun(players, townHall)
	for _, player in players do
		Run.equipClass(player)
		table.insert(
			connections,
			player.CharacterAdded:Connect(function()
				task.delay(0.2, Run.equipClass, player) -- let the Humanoid and limbs finish loading
			end)
		)
	end
	broadcast("prep", 1, Config.PrepSeconds)
end

function Run.finish(wave: number)
	if not current then
		return
	end
	local finished = current
	current = nil

	WaveManager.stop(finished.session)
	for _, connection in finished.connections do
		connection:Disconnect()
	end
	Skills.endRun()
	Combat.setTownHall(nil)
	-- Rewards are computed here from server state only (dungeon, wave reached, mode).
	local dungeonIndex = Dungeons.indexOf(finished.dungeonId) or 1
	local xp = Progression.xpForRun(dungeonIndex, wave, finished.mode)
	local diamonds = Progression.diamondsForRun(dungeonIndex, wave, finished.mode)
	for _, player in Players:GetPlayers() do
		local pr = finished.players[player.UserId]
		if pr then
			player:SetAttribute("InRun", nil)
			PlayerData.recordScore(player, finished.mode, pr.score)
			local award = PlayerData.awardRun(player, xp, diamonds)
			if award then
				runResults:FireClient(player, {
					xp = award.xp,
					diamonds = award.diamonds,
					level = award.level,
					levelsGained = award.levelsGained,
					text = Progression.resultsLine(award.xp, award.diamonds, award.levelsGained, award.level),
				})
				task.spawn(PlayerData.save, player) -- rewards are worth an immediate save
			end
			Combat.setLoadout(player, nil)
		end
	end
	finished.townHall:destroy()
	Arena.destroy()
end

return Run
