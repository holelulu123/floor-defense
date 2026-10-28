-- Drives one run: prep phase, spawn the wave, wait for it to clear, repeat until the Town Hall falls.
-- Coins and score are handed to the Run via callbacks so this module knows nothing about players.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Waves = require(ReplicatedStorage.Shared.Waves)
local Creatures = require(script.Parent.Creatures)
local TownHall = require(script.Parent.TownHall)

local WaveManager = {}

export type Hooks = {
	onKill: (killer: number?, archetype: string, coins: number) -> (),
	onWaveCleared: (wave: number, bonus: number) -> (),
	onPhase: (phase: string, wave: number, secondsLeft: number) -> (),
}

export type Session = {
	mode: string,
	townHall: TownHall.TownHall,
	gates: { Part },
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
	local goal = session.townHall.part.Position
	local gateIndex = 0
	for _, group in Waves.composition(session.wave, session.mode) do
		local health = Waves.creatureHealth(group.archetype, session.wave, session.mode)
		local coins = Waves.coinsFor(group.archetype, session.mode)
		for _ = 1, group.count do
			if not session.running then
				return
			end
			gateIndex = gateIndex % #session.gates + 1
			Creatures.spawn(
				group.archetype,
				health,
				coins,
				session.gates[gateIndex],
				goal,
				Config.ArriveDistance + session.townHall.part.Size.X / 2,
				function(creature, killer)
					session.hooks.onKill(killer, creature.archetype, creature.coins)
				end,
				function(creature)
					session.townHall:takeDamage(creature.damage)
				end
			)
			task.wait(Config.SpawnInterval)
		end
	end
end

function WaveManager.start(mode: string, townHall: TownHall.TownHall, gates: { Part }, hooks: Hooks): Session
	local session: Session = {
		mode = mode,
		townHall = townHall,
		gates = gates,
		hooks = hooks,
		wave = 0,
		running = true,
	}

	townHall.destroyed.Event:Once(function()
		session.running = false
	end)

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
