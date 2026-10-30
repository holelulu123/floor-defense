-- Run HUD: wave, phase, Town Hall health, coins and score (from RunState events), plus the two class
-- skill buttons with keybind, name and cooldown countdown (from SkillFx events) and, for the
-- Engineer, the placed turret count (from the player's Turrets attribute).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Classes = require(ReplicatedStorage.Shared.Classes)

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local runState = remotes:WaitForChild("RunState") :: RemoteEvent
local skillFx = remotes:WaitForChild("SkillFx") :: RemoteEvent

local player = Players.LocalPlayer

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
local classLabel = label("Class", 144)

-- Skill buttons ---------------------------------------------------------------------------------

type SkillButton = { frame: TextButton, name: TextLabel, cooldown: TextLabel, readyAt: number, total: number }

local skillButtons: { SkillButton } = {}

local function skillButton(index: number): SkillButton
	local frame = Instance.new("TextButton")
	frame.Name = "Skill" .. index
	frame.AnchorPoint = Vector2.new(0.5, 1)
	frame.Position = UDim2.new(0.5, (index - 1.5) * 150, 1, -24)
	frame.Size = UDim2.fromOffset(136, 72)
	frame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	frame.BackgroundTransparency = 0.25
	frame.BorderSizePixel = 0
	frame.Text = ""
	frame.AutoButtonColor = true
	frame.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = frame

	local key = Instance.new("TextLabel")
	key.Size = UDim2.fromOffset(28, 22)
	key.Position = UDim2.fromOffset(6, 4)
	key.BackgroundColor3 = Color3.fromRGB(230, 230, 240)
	key.TextColor3 = Color3.fromRGB(20, 20, 30)
	key.Font = Enum.Font.GothamBold
	key.TextSize = 14
	key.Text = Classes.SkillKeys[index]
	key.Parent = frame
	local keyCorner = Instance.new("UICorner")
	keyCorner.CornerRadius = UDim.new(0, 4)
	keyCorner.Parent = key

	local name = Instance.new("TextLabel")
	name.Size = UDim2.new(1, -12, 0, 22)
	name.Position = UDim2.fromOffset(6, 28)
	name.BackgroundTransparency = 1
	name.Font = Enum.Font.GothamBold
	name.TextSize = 15
	name.TextColor3 = Color3.new(1, 1, 1)
	name.TextXAlignment = Enum.TextXAlignment.Left
	name.TextTruncate = Enum.TextTruncate.AtEnd
	name.Text = ""
	name.Parent = frame

	local cooldown = Instance.new("TextLabel")
	cooldown.Size = UDim2.new(1, -12, 0, 18)
	cooldown.Position = UDim2.fromOffset(6, 50)
	cooldown.BackgroundTransparency = 1
	cooldown.Font = Enum.Font.Gotham
	cooldown.TextSize = 14
	cooldown.TextColor3 = Color3.fromRGB(180, 255, 180)
	cooldown.TextXAlignment = Enum.TextXAlignment.Left
	cooldown.Text = "Ready"
	cooldown.Parent = frame

	local button: SkillButton = { frame = frame, name = name, cooldown = cooldown, readyAt = 0, total = 1 }
	frame.Activated:Connect(function()
		local bindable = player:WaitForChild("PlayerScripts"):FindFirstChild("SkillButtonPressed")
		if bindable then
			(bindable :: BindableEvent):Fire(index)
		end
	end)
	return button
end

skillButtons[1] = skillButton(1)
skillButtons[2] = skillButton(2)

local turretLabel = Instance.new("TextLabel")
turretLabel.Name = "Turrets"
turretLabel.AnchorPoint = Vector2.new(0.5, 1)
turretLabel.Position = UDim2.new(0.5, 0, 1, -100)
turretLabel.Size = UDim2.fromOffset(200, 22)
turretLabel.BackgroundTransparency = 1
turretLabel.Font = Enum.Font.GothamBold
turretLabel.TextSize = 16
turretLabel.TextColor3 = Color3.fromRGB(255, 200, 120)
turretLabel.TextStrokeTransparency = 0.5
turretLabel.Visible = false
turretLabel.Parent = gui

local function refreshClass()
	local id = player:GetAttribute("Class")
	local class = Classes.find(id)
	if not class then
		return
	end
	classLabel.Text = `{class.id}  ({class.weapon})`
	for i, button in skillButtons do
		button.name.Text = class.skills[i].name
		button.total = class.skills[i].cooldown
		button.readyAt = 0
	end
	turretLabel.Visible = class.id == "Engineer"
end

local function refreshTurrets()
	local n = player:GetAttribute("Turrets")
	turretLabel.Text = `Turrets {if type(n) == "number" then n else 0}/{Classes.Turrets.MaxPlaced}`
end

player:GetAttributeChangedSignal("Class"):Connect(refreshClass)
player:GetAttributeChangedSignal("Turrets"):Connect(refreshTurrets)
refreshClass()
refreshTurrets()

skillFx.OnClientEvent:Connect(function(fx)
	if type(fx) ~= "table" then
		return
	end
	if fx.kind == "cooldown" and skillButtons[fx.index] then
		skillButtons[fx.index].readyAt = os.clock() + fx.cooldown
	elseif fx.kind == "failed" and skillButtons[fx.index] then
		local button = skillButtons[fx.index]
		button.cooldown.Text = "No target"
		button.cooldown.TextColor3 = Color3.fromRGB(255, 160, 120)
		task.delay(0.8, function()
			if os.clock() >= button.readyAt then
				button.cooldown.Text = "Ready"
				button.cooldown.TextColor3 = Color3.fromRGB(180, 255, 180)
			end
		end)
	elseif fx.kind == "reset" then
		for _, button in skillButtons do
			button.readyAt = 0
		end
	end
end)

RunService.RenderStepped:Connect(function()
	if not gui.Enabled then
		return
	end
	local now = os.clock()
	for _, button in skillButtons do
		local left = button.readyAt - now
		if left > 0 then
			button.cooldown.Text = string.format("%.1f s", left)
			button.cooldown.TextColor3 = Color3.fromRGB(255, 220, 120)
			button.frame.BackgroundColor3 = Color3.fromRGB(50, 40, 40)
		else
			if button.cooldown.Text ~= "No target" then
				button.cooldown.Text = "Ready"
				button.cooldown.TextColor3 = Color3.fromRGB(180, 255, 180)
			end
			button.frame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
		end
	end
end)

gui.Parent = player:WaitForChild("PlayerGui")

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
