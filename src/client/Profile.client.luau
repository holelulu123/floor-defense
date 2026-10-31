-- Player profile, built locally from attributes the server publishes (nothing here is sent back):
--  * top-right widget, in the lobby and in runs: Diamonds (icon from Icons.get("diamonds") when filled in),
--    "Lv 7" and a thin XP bar with "1,240 / 3,726 XP" (Diamonds, Level, XP, XPToNext attributes);
--  * the end-of-run results line from Remotes.RunResults ("+340 XP, +25 Diamonds, Level up! Lv 4");
--  * a level tag above every player's head (Lv + XP bar), hidden while that player is in a run (the server
--    sets their InRun attribute); the overhead HP bar from HealthBars.client.luau stays.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Icons = require(ReplicatedStorage.Shared.Icons)
local Progression = require(ReplicatedStorage.Shared.Progression)

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local runResults = remotes:WaitForChild("RunResults") :: RemoteEvent

local player = Players.LocalPlayer

local XP_COLOR = Color3.fromRGB(120, 200, 255)
local DIAMOND_COLOR = Color3.fromRGB(140, 220, 255)

type Progress = { level: number, xp: number, need: number, diamonds: number }

local function progressOf(p: Player): Progress
	local level = p:GetAttribute("Level")
	local xp = p:GetAttribute("XP")
	local need = p:GetAttribute("XPToNext")
	local diamonds = p:GetAttribute("Diamonds")
	return {
		level = if type(level) == "number" then level else 1,
		xp = if type(xp) == "number" then xp else 0,
		need = if type(need) == "number" then need else -1, -- -1: not loaded yet
		diamonds = if type(diamonds) == "number" then diamonds else 0,
	}
end

local function xpText(p: Progress): string
	if p.need < 0 then
		return "Loading..." -- the save is still loading (Studio retries the DataStore first)
	elseif p.need == 0 then
		return "Max level"
	end
	return `{Progression.formatNumber(p.xp)} / {Progression.formatNumber(p.need)} XP`
end

local function xpFraction(p: Progress): number
	return if p.need > 0 then math.clamp(p.xp / p.need, 0, 1) elseif p.need == 0 then 1 else 0
end

local function bar(parent: Instance, position: UDim2, size: UDim2): Frame
	local back = Instance.new("Frame")
	back.Position = position
	back.Size = size
	back.BackgroundColor3 = Color3.fromRGB(10, 10, 14)
	back.BorderSizePixel = 0
	back.Parent = parent
	local bc = Instance.new("UICorner")
	bc.CornerRadius = UDim.new(1, 0)
	bc.Parent = back
	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.fromScale(0, 1)
	fill.BackgroundColor3 = XP_COLOR
	fill.BorderSizePixel = 0
	fill.Parent = back
	local fc = Instance.new("UICorner")
	fc.CornerRadius = UDim.new(1, 0)
	fc.Parent = fill
	return fill
end

local function text(parent: Instance, size: number, color: Color3): TextLabel
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Font = Enum.Font.GothamBold
	l.TextSize = size
	l.TextColor3 = color
	l.TextStrokeTransparency = 0.5
	l.Parent = parent
	return l
end

-- Top-right widget -------------------------------------------------------------------------------------

local gui = Instance.new("ScreenGui")
gui.Name = "Profile"
gui.ResetOnSpawn = false
gui.DisplayOrder = 1

local widget = Instance.new("Frame")
widget.Name = "Widget"
widget.AnchorPoint = Vector2.new(0.5, 0) -- top centre: the Roblox player list owns the top-right corner
widget.Position = UDim2.new(0.5, 0, 0, 8)
widget.Size = UDim2.fromOffset(300, 64)
widget.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
widget.BackgroundTransparency = 0.35
widget.BorderSizePixel = 0
widget.Parent = gui
do
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 10)
	c.Parent = widget
end

local diamondIcon = Icons.get("diamonds")
local diamondsLabel = text(widget, 20, DIAMOND_COLOR)
diamondsLabel.AnchorPoint = Vector2.new(1, 0)
diamondsLabel.Position = UDim2.new(1, -12, 0, 6)
diamondsLabel.Size = UDim2.fromOffset(150, 24)
diamondsLabel.TextXAlignment = Enum.TextXAlignment.Right
if diamondIcon then
	local image = Instance.new("ImageLabel")
	image.Name = "DiamondIcon"
	image.AnchorPoint = Vector2.new(1, 0)
	image.Size = UDim2.fromOffset(24, 24)
	image.BackgroundTransparency = 1
	image.Image = diamondIcon
	image.Parent = widget
	local function place()
		image.Position = UDim2.new(1, -12 - diamondsLabel.TextBounds.X - 6, 0, 6)
	end
	diamondsLabel:GetPropertyChangedSignal("TextBounds"):Connect(place)
	place()
end

local levelLabel = text(widget, 20, Color3.new(1, 1, 1))
levelLabel.Position = UDim2.fromOffset(12, 6)
levelLabel.Size = UDim2.fromOffset(120, 24)
levelLabel.TextXAlignment = Enum.TextXAlignment.Left

local widgetFill = bar(widget, UDim2.fromOffset(12, 36), UDim2.new(1, -24, 0, 6))
local widgetXp = text(widget, 12, Color3.fromRGB(200, 210, 225))
widgetXp.Position = UDim2.fromOffset(12, 44)
widgetXp.Size = UDim2.new(1, -24, 0, 16)
widgetXp.TextXAlignment = Enum.TextXAlignment.Right

local results = text(gui, 18, Color3.fromRGB(255, 225, 120))
results.Name = "RunResults"
results.AnchorPoint = Vector2.new(0.5, 0)
results.Position = UDim2.new(0.5, 0, 0, 78)
results.Size = UDim2.fromOffset(420, 24)
results.TextXAlignment = Enum.TextXAlignment.Center
results.TextStrokeTransparency = 0.3
results.Visible = false

local function refreshWidget()
	local p = progressOf(player)
	local count = Progression.formatNumber(p.diamonds)
	diamondsLabel.Text = if diamondIcon then count else `{count} Diamonds`
	levelLabel.Text = `Lv {p.level}`
	widgetFill.Size = UDim2.fromScale(xpFraction(p), 1)
	widgetXp.Text = xpText(p)
end

for _, attribute in { "Diamonds", "Level", "XP", "XPToNext" } do
	player:GetAttributeChangedSignal(attribute):Connect(refreshWidget)
end
refreshWidget()
gui.Parent = player:WaitForChild("PlayerGui")

local resultsShownAt = 0
runResults.OnClientEvent:Connect(function(info)
	if type(info) ~= "table" or type(info.text) ~= "string" then
		return
	end
	results.Text = info.text
	results.Visible = true
	local shownAt = os.clock()
	resultsShownAt = shownAt
	task.delay(10, function()
		if resultsShownAt == shownAt then
			results.Visible = false
		end
	end)
end)

-- Overhead level tags -----------------------------------------------------------------------------------

local TAG_NAME = "LevelTagGui"
local TAG_OFFSET = 3.5 -- studs above the top of the head; the HP bar sits at 2.9

type Tag = { gui: BillboardGui, level: TextLabel, fill: Frame, xp: TextLabel }
local tags: { [Player]: Tag } = {}

local function refreshTag(p: Player)
	local tag = tags[p]
	if not tag then
		return
	end
	local progress = progressOf(p)
	tag.gui.Enabled = p:GetAttribute("InRun") ~= true
	tag.level.Text = `Lv {progress.level}`
	tag.fill.Size = UDim2.fromScale(xpFraction(progress), 1)
	tag.xp.Text = xpText(progress)
end

local function buildTag(p: Player, character: Model)
	local head = character:WaitForChild("Head", 10) :: BasePart?
	if not head or not head:IsA("BasePart") then
		return
	end
	local old = head:FindFirstChild(TAG_NAME)
	if old then
		old:Destroy()
	end
	local billboard = Instance.new("BillboardGui")
	billboard.Name = TAG_NAME
	billboard.Adornee = head
	billboard.Size = UDim2.fromScale(2.6, 0.8) -- studs, so it shrinks with distance like the avatar
	billboard.StudsOffsetWorldSpace = Vector3.new(0, head.Size.Y / 2 + TAG_OFFSET, 0)
	billboard.MaxDistance = 70
	billboard.LightInfluence = 0

	local level = text(billboard, 14, Color3.new(1, 1, 1))
	level.Size = UDim2.fromScale(1, 0.45)
	level.TextScaled = true
	local fill = bar(billboard, UDim2.fromScale(0.1, 0.5), UDim2.fromScale(0.8, 0.12))
	local xp = text(billboard, 10, Color3.fromRGB(210, 220, 235))
	xp.Position = UDim2.fromScale(0, 0.66)
	xp.Size = UDim2.fromScale(1, 0.32)
	xp.TextScaled = true
	billboard.Parent = head

	tags[p] = { gui = billboard, level = level, fill = fill, xp = xp }
	refreshTag(p)
end

local function watch(p: Player)
	for _, attribute in { "Level", "XP", "XPToNext", "InRun" } do
		p:GetAttributeChangedSignal(attribute):Connect(function()
			refreshTag(p)
		end)
	end
	p.CharacterAdded:Connect(function(character)
		buildTag(p, character)
	end)
	if p.Character then
		task.spawn(buildTag, p, p.Character)
	end
end

for _, p in Players:GetPlayers() do
	watch(p)
end
Players.PlayerAdded:Connect(watch)
Players.PlayerRemoving:Connect(function(p)
	tags[p] = nil
end)
