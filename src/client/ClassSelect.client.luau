-- Class select panel: a list of the classes with role, weapon, skills, Free / Locked (cost) and a
-- Buy or Select button. Only shown during the prep countdown before wave 1 of a run (it opens by itself
-- there); hidden in the lobby and once wave 1 starts, and C only toggles it while it is allowed.
-- Sits on the right edge below the profile widget; the HUD's HP panel is on the left so they never overlap.
-- All state (diamonds, owned classes, selected class) comes from player attributes the server publishes;
-- buttons only invoke BuyClass / SelectClass and show the server's answer. Icons (Icons.get) replace the
-- text look where an asset id has been filled in: class emblems on the cards, the diamond count.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Classes = require(ReplicatedStorage.Shared.Classes)
local Icons = require(ReplicatedStorage.Shared.Icons)
local Progression = require(ReplicatedStorage.Shared.Progression)

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local buyClass = remotes:WaitForChild("BuyClass") :: RemoteFunction
local selectClass = remotes:WaitForChild("SelectClass") :: RemoteFunction
local runState = remotes:WaitForChild("RunState") :: RemoteEvent

local player = Players.LocalPlayer

local gui = Instance.new("ScreenGui")
gui.Name = "ClassSelect"
gui.ResetOnSpawn = false

local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(1, 0)
panel.Position = UDim2.new(1, -16, 0, 84) -- below the profile widget (Profile.client.luau)
panel.Size = UDim2.new(0, 360, 1, -270) -- ends above the turret panel and weapon slots (bottom right)
panel.BackgroundColor3 = Color3.fromRGB(24, 24, 32)
panel.BackgroundTransparency = 0.15
panel.BorderSizePixel = 0
panel.Parent = gui
local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 12)
panelCorner.Parent = panel

local header = Instance.new("TextLabel")
header.Size = UDim2.new(1, -16, 0, 32)
header.Position = UDim2.fromOffset(8, 6)
header.BackgroundTransparency = 1
header.Font = Enum.Font.GothamBold
header.TextSize = 20
header.TextColor3 = Color3.new(1, 1, 1)
header.TextXAlignment = Enum.TextXAlignment.Left
header.Text = "Classes"
header.Parent = panel

local diamondIcon = Icons.get("diamonds")
local diamondsLabel = Instance.new("TextLabel")
diamondsLabel.Size = UDim2.fromOffset(150, 32)
diamondsLabel.AnchorPoint = Vector2.new(1, 0)
diamondsLabel.Position = UDim2.new(1, -8, 0, 6)
diamondsLabel.BackgroundTransparency = 1
diamondsLabel.Font = Enum.Font.GothamBold
diamondsLabel.TextSize = 16
diamondsLabel.TextColor3 = Color3.fromRGB(140, 220, 255)
diamondsLabel.TextXAlignment = Enum.TextXAlignment.Right
diamondsLabel.Parent = panel
if diamondIcon then
	local image = Instance.new("ImageLabel")
	image.Size = UDim2.fromOffset(22, 22)
	image.AnchorPoint = Vector2.new(1, 0.5)
	image.Position = UDim2.new(1, -158, 0, 22)
	image.BackgroundTransparency = 1
	image.Image = diamondIcon
	image.Parent = panel
end

local hint = Instance.new("TextLabel")
hint.Size = UDim2.new(1, -16, 0, 18)
hint.Position = UDim2.fromOffset(8, 36)
hint.BackgroundTransparency = 1
hint.Font = Enum.Font.Gotham
hint.TextSize = 13
hint.TextColor3 = Color3.fromRGB(180, 180, 190)
hint.TextXAlignment = Enum.TextXAlignment.Left
hint.Text = "Pick your class before wave 1. Press C to hide."
hint.Parent = panel

local list = Instance.new("ScrollingFrame")
list.Position = UDim2.fromOffset(8, 58)
list.Size = UDim2.new(1, -16, 1, -66)
list.BackgroundTransparency = 1
list.BorderSizePixel = 0
list.ScrollBarThickness = 6
list.AutomaticCanvasSize = Enum.AutomaticSize.Y
list.CanvasSize = UDim2.new()
list.Parent = panel
local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 6)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = list

type Row = { frame: Frame, status: TextLabel, button: TextButton, class: Classes.Class }
local rows: { Row } = {}

local function owned(): { string }
	local raw = player:GetAttribute("OwnedClasses")
	return if type(raw) == "string" and raw ~= "" then string.split(raw, ",") else {}
end

local function refresh()
	local diamonds = player:GetAttribute("Diamonds")
	local count = Progression.formatNumber(if type(diamonds) == "number" then diamonds else 0)
	diamondsLabel.Text = if diamondIcon then count else `{count} Diamonds`
	local ownedList = owned()
	local selected = player:GetAttribute("Class")
	for _, row in rows do
		local c = row.class
		local isOwned = Classes.isOwned(c.id, ownedList)
		if c.id == selected then
			row.status.Text = "Selected"
			row.status.TextColor3 = Color3.fromRGB(140, 255, 160)
			row.button.Text = "Selected"
			row.button.BackgroundColor3 = Color3.fromRGB(50, 90, 60)
		elseif isOwned then
			row.status.Text = if c.free then "Free" else "Owned"
			row.status.TextColor3 = Color3.fromRGB(200, 200, 210)
			row.button.Text = "Select"
			row.button.BackgroundColor3 = Color3.fromRGB(60, 90, 160)
		else
			row.status.Text = `Locked: {Progression.formatNumber(c.cost)} Diamonds`
			row.status.TextColor3 = Color3.fromRGB(255, 200, 120)
			row.button.Text = "Buy"
			row.button.BackgroundColor3 = Color3.fromRGB(150, 110, 40)
		end
		row.frame.BackgroundColor3 = if c.id == selected then Color3.fromRGB(40, 55, 45) else Color3.fromRGB(38, 38, 48)
	end
end

local function flash(row: Row, text: string)
	row.status.Text = text
	row.status.TextColor3 = Color3.fromRGB(255, 120, 120)
	task.delay(1.5, refresh)
end

local busy = false
local function onButton(row: Row)
	if busy then
		return
	end
	busy = true
	local c = row.class
	local remote = if Classes.isOwned(c.id, owned()) then selectClass else buyClass
	local ok, result = pcall(remote.InvokeServer, remote, c.id)
	busy = false
	if not ok or type(result) ~= "table" then
		flash(row, "Try again")
		return
	end
	if result.ok then
		refresh()
	else
		flash(row, tostring(result.reason or "Not allowed"))
	end
end

local function buildRow(c: Classes.Class, order: number)
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, -8, 0, 92)
	frame.BackgroundColor3 = Color3.fromRGB(38, 38, 48)
	frame.BorderSizePixel = 0
	frame.LayoutOrder = order
	frame.Parent = list
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = frame

	-- Class emblem (drawn by scripts/make-icons.py) when its icon id is filled in; text starts after it.
	local emblem = Icons.get("class_" .. c.id)
	local textX = 10
	if emblem then
		local image = Instance.new("ImageLabel")
		image.Size = UDim2.fromOffset(56, 56)
		image.Position = UDim2.fromOffset(8, 18)
		image.BackgroundTransparency = 1
		image.Image = emblem
		image.Parent = frame
		textX = 72
	end

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -100 - textX, 0, 22)
	title.Position = UDim2.fromOffset(textX, 6)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.TextSize = 17
	title.TextColor3 = Color3.new(1, 1, 1)
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Text = `{c.id}  -  {c.role}`
	title.Parent = frame

	local detail = Instance.new("TextLabel")
	detail.Size = UDim2.new(1, -100 - textX, 0, 40)
	detail.Position = UDim2.fromOffset(textX, 28)
	detail.BackgroundTransparency = 1
	detail.Font = Enum.Font.Gotham
	detail.TextSize = 12
	detail.TextWrapped = true
	detail.TextColor3 = Color3.fromRGB(200, 200, 210)
	detail.TextXAlignment = Enum.TextXAlignment.Left
	detail.TextYAlignment = Enum.TextYAlignment.Top
	detail.Text =
		`{c.weapon}. {c.skills[1].name} ({c.skills[1].cooldown}s), {c.skills[2].name} ({c.skills[2].cooldown}s). {c.passive}`
	detail.Parent = frame

	local status = Instance.new("TextLabel")
	status.Size = UDim2.new(1, -100 - textX, 0, 18)
	status.Position = UDim2.fromOffset(textX, 70)
	status.BackgroundTransparency = 1
	status.Font = Enum.Font.GothamBold
	status.TextSize = 13
	status.TextXAlignment = Enum.TextXAlignment.Left
	status.Parent = frame

	local button = Instance.new("TextButton")
	button.AnchorPoint = Vector2.new(1, 0.5)
	button.Position = UDim2.new(1, -10, 0.5, 0)
	button.Size = UDim2.fromOffset(84, 36)
	button.Font = Enum.Font.GothamBold
	button.TextSize = 15
	button.TextColor3 = Color3.new(1, 1, 1)
	button.BorderSizePixel = 0
	button.Parent = frame
	local buttonCorner = Instance.new("UICorner")
	buttonCorner.CornerRadius = UDim.new(0, 6)
	buttonCorner.Parent = button

	local row: Row = { frame = frame, status = status, button = button, class = c }
	button.Activated:Connect(function()
		onButton(row)
	end)
	table.insert(rows, row)
end

for i, c in Classes.List do
	buildRow(c, i)
end

for _, attribute in { "Diamonds", "OwnedClasses", "Class" } do
	player:GetAttributeChangedSignal(attribute):Connect(refresh)
end
refresh()
gui.Parent = player:WaitForChild("PlayerGui")

-- Visibility: only in the prep countdown before wave 1 (where the server accepts SelectClass). It opens by
-- itself when a run's prep starts; C toggles it only while it is allowed.
local allowed = false
local hiddenByUser = false

local function updateVisible()
	panel.Visible = allowed and not hiddenByUser
end

runState.OnClientEvent:Connect(function(state)
	if type(state) ~= "table" then
		return
	end
	local nowAllowed = state.phase == "prep" and state.wave == 1
	if nowAllowed and not allowed then
		hiddenByUser = false -- a new run: open automatically
	end
	allowed = nowAllowed
	updateVisible()
end)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed or input.KeyCode ~= Enum.KeyCode.C or not allowed then
		return
	end
	hiddenByUser = not hiddenByUser
	updateVisible()
end)

updateVisible()
