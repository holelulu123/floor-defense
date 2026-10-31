-- Password gate (live lobby servers only). Every player who joins is held in place, with the AccessLocked attribute
-- set, until they send the right password through Remotes.SubmitPassword; the client (AccessGate.client.luau) shows
-- the box. Rules (tries, timeout) live in Shared.AccessGate. The password itself is kept in the "Access" DataStore
-- (key "password"), set with scripts/roblox/set-password.py, so it is never in the code or the repo. No password set
-- means the gate is open. Studio (no DataStore access) and reserved run servers (players arrive by teleport from a
-- gated lobby) skip the gate.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local AccessGate = require(ReplicatedStorage.Shared.AccessGate)

local submit = ReplicatedStorage.Remotes.SubmitPassword :: RemoteFunction

local isReservedServer = game.PrivateServerId ~= "" and game.PrivateServerOwnerId == 0
if RunService:IsStudio() or isReservedServer then
	submit.OnServerInvoke = function()
		return true
	end
	return
end

local LOCKED = "AccessLocked"
local password: string? = nil
local loaded = false -- false until the first successful DataStore read

type State = { tries: number, lastTry: number }
local states: { [Player]: State } = {}

local function hold(player: Player, held: boolean)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		root.Anchored = held
	end
end

local function unlock(player: Player)
	states[player] = nil
	player:SetAttribute(LOCKED, nil)
	hold(player, false)
end

local function onPlayer(player: Player)
	if loaded and password == nil then
		return -- gate open
	end
	states[player] = { tries = 0, lastTry = 0 }
	player:SetAttribute(LOCKED, true)
	player.CharacterAdded:Connect(function()
		if player:GetAttribute(LOCKED) then
			task.defer(hold, player, true)
		end
	end)
	hold(player, true)
	task.delay(AccessGate.TimeoutSeconds, function()
		if player.Parent and player:GetAttribute(LOCKED) then
			player:Kick("This game is private. Ask the owner for the password.")
		end
	end)
end

-- Reads the password; retried until one read succeeds, then refreshed every minute so a change applies to new joins.
local store = DataStoreService:GetDataStore(AccessGate.StoreName)
local function refresh()
	local ok, value = pcall(store.GetAsync, store, AccessGate.StoreKey)
	if not ok then
		warn("AccessGate: could not read the password:", value)
		return
	end
	password = AccessGate.clean(value)
	if not loaded then
		loaded = true
		if password == nil then
			warn("AccessGate: no password set; the game is open to everyone")
			for _, player in Players:GetPlayers() do
				unlock(player)
			end
		end
	end
end

submit.OnServerInvoke = function(player: Player, input: any): (boolean, number?)
	local state = states[player]
	if not state then
		return true -- not locked
	end
	local now = os.clock()
	if now - state.lastTry < AccessGate.MinSecondsBetweenTries or not loaded then
		return false, AccessGate.MaxTries - state.tries
	end
	state.lastTry = now
	if AccessGate.matches(input, password) then
		unlock(player)
		return true
	end
	state.tries += 1
	local left = AccessGate.MaxTries - state.tries
	if left <= 0 then
		player:Kick("Wrong password.")
	end
	return false, left
end

Players.PlayerAdded:Connect(onPlayer)
for _, player in Players:GetPlayers() do
	task.spawn(onPlayer, player)
end
Players.PlayerRemoving:Connect(function(player)
	states[player] = nil
end)

task.spawn(function()
	while true do
		refresh()
		task.wait(if loaded then 60 else 5)
	end
end)
