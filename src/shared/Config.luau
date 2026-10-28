-- Game-wide constants shared by server and client.
-- Replace the 0 IDs with real ones from the Creator Dashboard (Monetization > Passes / Developer Products).

return {
	DataStoreName = "PlayerData_v1",

	-- Persistent per-player fields. In-run coins and score live in Run.luau and are never saved.
	DefaultData = {
		Gems = 0,
		Level = 1,
		BestScoreSolo = 0,
		BestScoreDuo = 0,
		BestScoreSquad = 0,
		OwnedCharacters = {},
		Mastery = {},
	},

	GamePasses = {
		VIP = 0,
	},

	Products = {
		Gems500 = 0,
	},

	-- Floor pads in the lobby. Mode names must match Waves.Modes.
	Pads = {
		{ mode = "Solo", capacity = 1, countdown = 5, position = { -24, 0, 20 } },
		{ mode = "Duo", capacity = 2, countdown = 10, position = { 0, 0, 20 } },
		{ mode = "Squad", capacity = 4, countdown = 15, position = { 24, 0, 20 } },
	},

	-- Leave 0 to run inside the same place (reserved server of game.PlaceId).
	RunPlaceId = 0,

	Camera = {
		DefaultFirstPerson = false, -- design says first person on PC; flipped to third for playtesting
		ToggleKey = Enum.KeyCode.V,
		MaxZoom = 30,
	},

	StartingWeapon = "AssaultRifle",

	TownHallHealth = 1000,
	PrepSeconds = 30,
	SpawnInterval = 0.4, -- seconds between creatures in a wave
	ArriveDistance = 6, -- studs from the Town Hall at which a creature hits it
}
