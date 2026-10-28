-- One run of Floor Defense for a fixed group of players: builds the arena, moves the players in,
-- runs waves, tracks per-player coins and score, and reports the result when the Town Hall falls.
-- In-run coins reset every run; only the final score is persisted via PlayerData.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Arena = require(script.Parent.Arena)
local PlayerData = require(script.Parent.PlayerData)
local TownHall = require(script.Parent.TownHall)
local WaveManager = require(script.Parent.WaveManager)

local runState = ReplicatedStorage.Remotes.RunState :: RemoteEvent

local Run = {}

export type PlayerRun = { coins: number, score: number, kills: number }

local current: {
	mode: string,
	players: { [number]: PlayerRun },
	session: WaveManager.Session,
	arena: Arena.Built,
	townHall: TownHall.TownHall,
}? =
	nil

local function broadcast(phase: string, wave: number, secondsLeft: number)
	if not current then
		return
	end
	for _, player in Players:GetPlayers() do
		local pr = current.players[player.UserId]
		if pr then
			runState:FireClient(player, {
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

function Run.start(mode: string, players: { Player }, onEnd: (mode: string, wave: number) -> ())
	assert(current == nil, "a run is already active")

	local arena = Arena.build()
	local townHall = TownHall.new(arena.townHall, Config.TownHallHealth)

	local runPlayers: { [number]: PlayerRun } = {}
	for i, player in players do
		runPlayers[player.UserId] = { coins = 0, score = 0, kills = 0 }
		moveIn(player, arena.spawns[(i - 1) % #arena.spawns + 1])
	end

	local session
	session = WaveManager.start(mode, townHall, arena.gates, {
		onKill = function(killer, _archetype, coins)
			local pr = killer and runPlayers[killer]
			if pr then
				pr.coins += coins
				pr.score += coins
				pr.kills += 1
			end
		end,
		onWaveCleared = function(wave, bonus)
			for _, pr in runPlayers do
				pr.score += bonus
			end
			broadcast("cleared", wave, 0)
		end,
		onPhase = function(phase, wave, secondsLeft)
			broadcast(phase, wave, secondsLeft)
			if phase == "ended" then
				Run.finish(wave)
				onEnd(mode, wave)
			end
		end,
	})

	current = { mode = mode, players = runPlayers, session = session, arena = arena, townHall = townHall }
	broadcast("prep", 1, Config.PrepSeconds)
end

function Run.finish(wave: number)
	if not current then
		return
	end
	local finished = current
	current = nil

	WaveManager.stop(finished.session)
	for _, player in Players:GetPlayers() do
		local pr = finished.players[player.UserId]
		if pr then
			PlayerData.recordScore(player, finished.mode, pr.score)
			PlayerData.addGems(player, wave)
		end
	end
	finished.townHall:destroy()
	Arena.destroy()
end

return Run
