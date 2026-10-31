-- Drives one run: prep phase, spawn the wave, wait for it to clear, repeat until the Town Hall falls.
-- Waves are composed from the dungeon's roster (Waves.composition) and every creature walks the
-- arena's lane. Coins and score are handed to the Run via callbacks so this module knows nothing
-- about players.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Dungeons = require(ReplicatedStorage.Shared.Dungeons)
local Waves = require(ReplicatedStorage.Shared.Waves)
local Arena = require(script.Parent.Arena)
local Creatures = require(script.Parent.Creatures)
local TownHall = require(script.Parent.TownHall)

local WaveManager = {}

export type Hooks = {
	onKill: (killer: number?, creatureId: string, coins: number) -> (),
	onWaveCleared: (wave: number, bonus: number) -> (),
	onPhase: (phase: string, wave: number, secondsLeft: number) -> (),
}

export type Session = {
	mode: string,
	dungeonId: string,
	familyId: string,
	difficulty: number, -- Dungeons.difficulty: creature health and Town Hall damage
	townHall: TownHall.TownHall,
	arena: Arena.Built,
	hooks: Hooks,
	wave: number,
	running: boolean,
}

local function prepPhase(session: Session)
	for left = Config.PrepSeconds, 1, -1 do
		if not session.running then
			return
		end
		session.hooks.onPhase("prep", session.wave, left)
		task.wait(1)
	end
end

local function spawnWave(session: Session)
	for _, group in Waves.composition(session.familyId, session.wave, session.mode) do
		local stats = Waves.stats(group.creature, session.wave, session.mode, session.difficulty)
		for _ = 1, group.count do
			if not session.running then
				return
			end
			Creatures.spawn(group.creature, stats, session.arena.lane, session.arena.folder, function(creature, killer)
				session.hooks.onKill(killer, creature.id, creature.coins)
			end, function(creature)
				session.townHall:takeDamage(creature.damage)
			end)
			task.wait(Config.SpawnInterval)
		end
	end
end

function WaveManager.start(
	mode: string,
	dungeonId: string,
	townHall: TownHall.TownHall,
	arena: Arena.Built,
	hooks: Hooks
): Session
	local session: Session = {
		mode = mode,
		dungeonId = dungeonId,
		familyId = Dungeons.get(dungeonId).family,
		difficulty = Dungeons.get(dungeonId).difficulty,
		townHall = townHall,
		arena = arena,
		hooks = hooks,
		wave = 0,
		running = true,
	}

	townHall.destroyed.Event:Once(function()
		session.running = false
	end)
	Creatures.preload(session.familyId) -- creature models load during the first prep countdown

	task.spawn(function()
		while session.running do
			session.wave += 1
			prepPhase(session)
			if not session.running then
				break
			end

			hooks.onPhase("wave", session.wave, 0)
			spawnWave(session)
			while session.running and Creatures.count() > 0 do
				task.wait(0.25)
			end

			if session.running then
				hooks.onWaveCleared(session.wave, Waves.waveBonus(session.wave))
			end
		end
		Creatures.clear()
		hooks.onPhase("ended", session.wave, 0)
	end)

	return session
end

function WaveManager.stop(session: Session)
	session.running = false
end

return WaveManager
