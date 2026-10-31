-- Overhead HP bars, built locally from server-written state so nothing here is trusted back:
--  * every instance tagged "HealthBar" (creatures, turrets, the Town Hall) reads its Health/MaxHealth
--    attributes, and its HealthBar attribute picks the style;
--  * every player character reads its Humanoid's Health/MaxHealth.
-- Bars are parented to their adornee, so they disappear with it, and never replicate.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local HealthBar = require(ReplicatedStorage.Shared.HealthBar)

local BAR_NAME = "HealthBarGui"

type Style = {
	size: UDim2, -- scale units on a BillboardGui are studs; offset units are pixels
	offset: number, -- studs above the top of the adornee
	maxDistance: number,
	alwaysOnTop: boolean,
	hideWhenFull: boolean,
	numeric: boolean,
}

local STYLES: { [string]: Style } = {
	creature = {
		size = UDim2.fromScale(3, 0.32),
		offset = 0.9,
		maxDistance = 90,
		alwaysOnTop = false,
		hideWhenFull = true,
		numeric = false,
	},
	turret = {
		size = UDim2.fromScale(2.6, 0.3),
		offset = 1.2,
		maxDistance = 80,
		alwaysOnTop = false,
		hideWhenFull = false,
		numeric = false,
	},
	townhall = {
		size = UDim2.fromOffset(280, 34),
		offset = 4,
		maxDistance = 600,
		alwaysOnTop = true,
		hideWhenFull = false,
		numeric = true,
	},
	player = {
		size = UDim2.fromOffset(72, 8),
		offset = 2.9, -- above the Humanoid name tag
		maxDistance = 70,
		alwaysOnTop = false,
		hideWhenFull = false,
		numeric = false,
	},
}

type Bar = { gui: BillboardGui, fill: Frame, text: TextLabel?, style: Style }

local function corner(parent: Instance, radius: number)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = parent
end

local function makeBar(adornee: BasePart, style: Style, extraOffset: number?): Bar
	local old = adornee:FindFirstChild(BAR_NAME)
	if old then
		old:Destroy()
	end

	local gui = Instance.new("BillboardGui")
	gui.Name = BAR_NAME
	gui.Adornee = adornee
	gui.Size = style.size
	gui.StudsOffsetWorldSpace = Vector3.new(0, adornee.Size.Y / 2 + style.offset + (extraOffset or 0), 0)
	gui.MaxDistance = style.maxDistance
	gui.AlwaysOnTop = style.alwaysOnTop
	gui.LightInfluence = 0
	gui.ResetOnSpawn = false

	local back = Instance.new("Frame")
	back.Name = "Back"
	back.Size = UDim2.fromScale(1, 1)
	back.BackgroundColor3 = Color3.fromRGB(20, 20, 26)
	back.BackgroundTransparency = 0.2
	back.BorderSizePixel = 0
	back.Parent = gui
	corner(back, if style.numeric then 8 else 3)
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.new(0, 0, 0)
	stroke.Thickness = if style.numeric then 2 else 1
	stroke.Transparency = 0.3
	stroke.Parent = back

	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.fromScale(1, 1)
	fill.BorderSizePixel = 0
	fill.Parent = back
	corner(fill, if style.numeric then 8 else 3)

	local text: TextLabel? = nil
	if style.numeric then
		local t = Instance.new("TextLabel")
		t.Name = "Value"
		t.Size = UDim2.fromScale(1, 1)
		t.BackgroundTransparency = 1
		t.Font = Enum.Font.GothamBlack
		t.TextScaled = true
		t.TextColor3 = Color3.new(1, 1, 1)
		t.TextStrokeTransparency = 0.2
		t.ZIndex = 2
		t.Parent = back
		local pad = Instance.new("UIPadding")
		pad.PaddingTop = UDim.new(0, 5)
		pad.PaddingBottom = UDim.new(0, 5)
		pad.Parent = t
		text = t
	end

	gui.Parent = adornee
	return { gui = gui, fill = fill, text = text, style = style }
end

local function render(bar: Bar, health: number?, maxHealth: number?, title: string?)
	local f = HealthBar.fraction(health, maxHealth)
	bar.fill.Size = UDim2.fromScale(f, 1)
	bar.fill.BackgroundColor3 = Color3.fromRGB(HealthBar.color(f))
	bar.gui.Enabled = HealthBar.shouldShow(f, bar.style.hideWhenFull)
	if bar.text then
		local value = HealthBar.label(health, maxHealth)
		bar.text.Text = if title then `{title}  {value}` else value
	end
end

-- Tagged instances ------------------------------------------------------------------------------

local function adorneeOf(inst: Instance): BasePart?
	if inst:IsA("BasePart") then
		return inst
	elseif inst:IsA("Model") then
		return inst.PrimaryPart
	end
	return nil
end

local tagged: { [Instance]: { RBXScriptConnection } } = {}

local function untrack(inst: Instance)
	local conns = tagged[inst]
	if conns then
		for _, c in conns do
			c:Disconnect()
		end
		tagged[inst] = nil
	end
end

local function track(inst: Instance)
	if tagged[inst] then
		return
	end
	local kind = inst:GetAttribute("HealthBar")
	local style = STYLES[if type(kind) == "string" then kind else "creature"] or STYLES.creature
	local adornee = adorneeOf(inst)
	if not adornee then
		return
	end
	-- HealthBarOffset (studs): extra height for creatures whose animated model rises above its hitbox (hops, bobs).
	local extra = inst:GetAttribute("HealthBarOffset")
	local bar = makeBar(adornee, style, if type(extra) == "number" then extra else nil)
	local title = if kind == "townhall" then "Town Hall" else nil
	local function update()
		local h, m = inst:GetAttribute("Health"), inst:GetAttribute("MaxHealth")
		render(bar, if type(h) == "number" then h else nil, if type(m) == "number" then m else nil, title)
	end
	tagged[inst] = {
		inst:GetAttributeChangedSignal("Health"):Connect(update),
		inst:GetAttributeChangedSignal("MaxHealth"):Connect(update),
		inst.Destroying:Connect(function()
			untrack(inst)
		end),
	}
	update()
end

CollectionService:GetInstanceAddedSignal("HealthBar"):Connect(track)
CollectionService:GetInstanceRemovedSignal("HealthBar"):Connect(function(inst)
	untrack(inst)
	local adornee = adorneeOf(inst)
	local gui = adornee and adornee:FindFirstChild(BAR_NAME)
	if gui then
		gui:Destroy()
	end
end)
for _, inst in CollectionService:GetTagged("HealthBar") do
	task.spawn(track, inst)
end

-- Player characters -----------------------------------------------------------------------------

local function onCharacter(character: Model)
	local humanoid = character:WaitForChild("Humanoid", 10) :: Humanoid?
	local head = character:WaitForChild("Head", 10) :: BasePart?
	if not humanoid or not head then
		return
	end
	-- Our bar replaces the default damaged-only bar so there aren't two stacked over the name.
	humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	local bar = makeBar(head, STYLES.player)
	local function update()
		render(bar, humanoid.Health, humanoid.MaxHealth, nil)
	end
	humanoid.HealthChanged:Connect(update)
	humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(update)
	update()
end

local function onPlayer(player: Player)
	player.CharacterAdded:Connect(onCharacter)
	if player.Character then
		task.spawn(onCharacter, player.Character)
	end
end

Players.PlayerAdded:Connect(onPlayer)
for _, player in Players:GetPlayers() do
	onPlayer(player)
end
