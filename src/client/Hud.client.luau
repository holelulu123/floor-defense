-- Minimal run HUD: wave, phase, Town Hall health, coins and score. Driven only by RunState events.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local runState = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("RunState") :: RemoteEvent

local gui = Instance.new("ScreenGui")
gui.Name = "Hud"
gui.ResetOnSpawn = false
gui.Enabled = false

local function label(name: string, y: number): TextLabel
	local l = Instance.new("TextLabel")
	l.Name = name
	l.Size = UDim2.fromOffset(320, 28)
	l.Position = UDim2.fromOffset(16, y)
	l.BackgroundTransparency = 1
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.Font = Enum.Font.GothamBold
	l.TextSize = 22
	l.TextColor3 = Color3.new(1, 1, 1)
	l.TextStrokeTransparency = 0.5
	l.Parent = gui
	return l
end

local waveLabel = label("Wave", 16)
local townHallLabel = label("TownHall", 48)
local coinsLabel = label("Coins", 80)
local scoreLabel = label("Score", 112)

gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

runState.OnClientEvent:Connect(function(state)
	gui.Enabled = state.phase ~= "ended"
	if state.phase == "prep" then
		waveLabel.Text = `Wave {state.wave} in {state.secondsLeft}s`
	elseif state.phase == "cleared" then
		waveLabel.Text = `Wave {state.wave} cleared!`
	else
		waveLabel.Text = `Wave {state.wave}`
	end
	townHallLabel.Text = `Town Hall {state.townHallHealth}/{state.townHallMax}`
	coinsLabel.Text = `Coins {state.coins}`
	scoreLabel.Text = `Score {state.score}  Kills {state.kills}`
end)
