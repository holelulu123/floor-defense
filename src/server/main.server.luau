-- Server entry point.

local Players = game:GetService("Players")

local Monetization = require(script.Parent.Monetization)
local PlayerData = require(script.Parent.PlayerData)

Monetization.init()

Players.PlayerAdded:Connect(PlayerData.load)
for _, player in Players:GetPlayers() do
	task.spawn(PlayerData.load, player)
end
Players.PlayerRemoving:Connect(PlayerData.release)

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
