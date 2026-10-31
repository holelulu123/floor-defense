-- Password screen: covers everything while the server holds this player (AccessLocked attribute, see
-- src/server/AccessGate.server.luau). The answer goes to the server, which decides; nothing is checked here.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local submit = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("SubmitPassword") :: RemoteFunction
local player = Players.LocalPlayer

local gui = Instance.new("ScreenGui")
gui.Name = "AccessGate"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 100
gui.Enabled = false

local cover = Instance.new("Frame")
cover.Size = UDim2.fromScale(1, 1)
cover.BackgroundColor3 = Color3.fromRGB(14, 16, 22)
cover.Active = true -- swallows clicks meant for the game behind
cover.Parent = gui

local box = Instance.new("Frame")
box.AnchorPoint = Vector2.new(0.5, 0.5)
box.Position = UDim2.fromScale(0.5, 0.5)
box.Size = UDim2.fromOffset(420, 250)
box.BackgroundColor3 = Color3.fromRGB(30, 32, 42)
box.Parent = cover
do
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 14)
	c.Parent = box
end

local function text(y: number, height: number, size: number, value: string, color: Color3): TextLabel
	local l = Instance.new("TextLabel")
	l.Position = UDim2.fromOffset(20, y)
	l.Size = UDim2.new(1, -40, 0, height)
	l.BackgroundTransparency = 1
	l.Font = Enum.Font.GothamBold
	l.TextSize = size
	l.TextColor3 = color
	l.TextWrapped = true
	l.Text = value
	l.Parent = box
	return l
end

text(18, 36, 30, "Floor Defense", Color3.fromRGB(255, 209, 102))
text(58, 24, 16, "This game is private. Enter the password to play.", Color3.fromRGB(210, 214, 225))

local input = Instance.new("TextBox")
input.Position = UDim2.fromOffset(20, 100)
input.Size = UDim2.new(1, -40, 0, 44)
input.BackgroundColor3 = Color3.fromRGB(16, 18, 24)
input.TextColor3 = Color3.new(1, 1, 1)
input.PlaceholderText = "Password"
input.PlaceholderColor3 = Color3.fromRGB(120, 124, 140)
input.Font = Enum.Font.GothamBold
input.TextSize = 20
input.Text = ""
input.ClearTextOnFocus = false
input.Parent = box
do
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 8)
	c.Parent = input
end

local button = Instance.new("TextButton")
button.Position = UDim2.fromOffset(20, 156)
button.Size = UDim2.new(1, -40, 0, 42)
button.BackgroundColor3 = Color3.fromRGB(70, 160, 90)
button.TextColor3 = Color3.new(1, 1, 1)
button.Font = Enum.Font.GothamBlack
button.TextSize = 20
button.Text = "Enter"
button.Parent = box
do
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 8)
	c.Parent = button
end

local status = text(206, 30, 15, "", Color3.fromRGB(255, 130, 110))

local busy = false
local function send()
	if busy then
		return
	end
	busy = true
	status.Text = "Checking..."
	local ok, right, left = pcall(submit.InvokeServer, submit, input.Text)
	busy = false
	if not ok then
		status.Text = "Could not reach the server, try again."
	elseif right then
		status.Text = ""
	else
		input.Text = ""
		status.Text = if type(left) == "number" then `Wrong password. {left} tries left.` else "Wrong password."
	end
end
button.Activated:Connect(send)
input.FocusLost:Connect(function(enter)
	if enter then
		send()
	end
end)

local function refresh()
	gui.Enabled = player:GetAttribute("AccessLocked") == true
end
player:GetAttributeChangedSignal("AccessLocked"):Connect(refresh)
refresh()
gui.Parent = player:WaitForChild("PlayerGui")
