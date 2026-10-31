-- Run HUD: wave, phase, Town Hall health, coins, score and kills (one icon row each, from RunState events),
-- plus the two class skill buttons with keybind, name and cooldown countdown (from SkillFx events) and, for the
-- Engineer, the placed turret count (from the player's Turrets attribute). A left-edge panel under the
-- wave/coins text shows the Town Hall HP (its server-written Health/MaxHealth attributes) and each party
-- member's Humanoid HP; it stays clear of the class panel on the right edge during prep.
-- Bottom right: the two weapon slots (1 primary, 2 melee; the active one highlighted, from WeaponSlot)
-- and the ammo readout "28 / 30" or "RELOADING" (Ammo / MagazineSize / Reloading attributes written by
-- server Combat), hidden for weapons without a magazine.
-- Icons (Icons.get) are shown where an asset id has been filled in: wave/coins/score/kills rows, skill
-- buttons, ammo/reload readout and the HP panel heart; without one the text-only look stays.
-- Diamonds, level and XP: Profile.client.luau.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Classes = require(ReplicatedStorage.Shared.Classes)
local HealthBar = require(ReplicatedStorage.Shared.HealthBar)
local Icons = require(ReplicatedStorage.Shared.Icons)
local Weapons = require(ReplicatedStorage.Shared.Weapons)

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local runState = remotes:WaitForChild("RunState") :: RemoteEvent
local skillFx = remotes:WaitForChild("SkillFx") :: RemoteEvent

local player = Players.LocalPlayer

local gui = Instance.new("ScreenGui")
gui.Name = "Hud"
gui.ResetOnSpawn = false
gui.Enabled = false

-- One top-left text row; with `iconKey` (and its id filled in) a 24 px icon sits left of the text.
local ROW_ICON = 24
local function label(name: string, y: number, iconKey: string?): TextLabel
	local iconId = if iconKey then Icons.get(iconKey) else nil
	local x = 16
	if iconId then
		local icon = Instance.new("ImageLabel")
		icon.Name = name .. "Icon"
		icon.Size = UDim2.fromOffset(ROW_ICON, ROW_ICON)
		icon.Position = UDim2.fromOffset(16, y + 2)
		icon.BackgroundTransparency = 1
		icon.Image = iconId
		icon.Parent = gui
		x = 16 + ROW_ICON + 6
	end
	local l = Instance.new("TextLabel")
	l.Name = name
	l.Size = UDim2.fromOffset(320, 28)
	l.Position = UDim2.fromOffset(x, y)
	l.BackgroundTransparency = 1
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.Font = Enum.Font.GothamBold
	l.TextSize = 22
	l.TextColor3 = Color3.new(1, 1, 1)
	l.TextStrokeTransparency = 0.5
	l.Parent = gui
	return l
end

local waveLabel = label("Wave", 16, "wave")
local coinsLabel = label("Coins", 46, "coins")
local scoreLabel = label("Score", 76, "score")
local killsLabel = label("Kills", 106, "kills")
local classLabel = label("Class", 136)

-- Health panel (left edge, under the wave/coins text) ----------------------------------------------

local PANEL_WIDTH = 260

local panel = Instance.new("Frame")
panel.Name = "HealthPanel"
panel.AnchorPoint = Vector2.new(0, 0)
panel.Position = UDim2.fromOffset(16, 174)
panel.Size = UDim2.fromOffset(PANEL_WIDTH, 0)
panel.AutomaticSize = Enum.AutomaticSize.Y
panel.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
panel.BackgroundTransparency = 0.35
panel.BorderSizePixel = 0
panel.Parent = gui
do
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 10)
	c.Parent = panel
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 10)
	pad.PaddingBottom = UDim.new(0, 10)
	pad.PaddingLeft = UDim.new(0, 10)
	pad.PaddingRight = UDim.new(0, 10)
	pad.Parent = panel
	local list = Instance.new("UIListLayout")
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Padding = UDim.new(0, 6)
	list.Parent = panel
end

type PanelBar = { root: Frame, name: TextLabel, fill: Frame, value: TextLabel }

-- A titled bar: name on the left, "HP / Max" on the right (or inside the bar when big).
local function panelBar(order: number, title: string, barHeight: number): PanelBar
	local root = Instance.new("Frame")
	root.Name = "Bar" .. order
	root.LayoutOrder = order
	root.BackgroundTransparency = 1
	root.Size = UDim2.new(1, 0, 0, 20 + barHeight)
	root.Parent = panel

	local name = Instance.new("TextLabel")
	name.Size = UDim2.new(1, 0, 0, 18)
	name.BackgroundTransparency = 1
	name.Font = Enum.Font.GothamBold
	name.TextSize = if barHeight >= 20 then 18 else 15
	name.TextColor3 = Color3.new(1, 1, 1)
	name.TextStrokeTransparency = 0.5
	name.TextXAlignment = Enum.TextXAlignment.Left
	name.TextTruncate = Enum.TextTruncate.AtEnd
	name.Text = title
	name.Parent = root

	local back = Instance.new("Frame")
	back.Position = UDim2.fromOffset(0, 20)
	back.Size = UDim2.new(1, 0, 0, barHeight)
	back.BackgroundColor3 = Color3.fromRGB(10, 10, 14)
	back.BorderSizePixel = 0
	back.Parent = root
	local bc = Instance.new("UICorner")
	bc.CornerRadius = UDim.new(0, 5)
	bc.Parent = back

	local fill = Instance.new("Frame")
	fill.Size = UDim2.fromScale(1, 1)
	fill.BorderSizePixel = 0
	fill.Parent = back
	local fc = Instance.new("UICorner")
	fc.CornerRadius = UDim.new(0, 5)
	fc.Parent = fill

	local value = Instance.new("TextLabel")
	value.BackgroundTransparency = 1
	value.Font = Enum.Font.GothamBold
	value.TextColor3 = Color3.new(1, 1, 1)
	value.TextStrokeTransparency = 0.3
	value.ZIndex = 2
	if barHeight >= 20 then
		value.Size = UDim2.fromScale(1, 1)
		value.TextSize = 18
		value.Parent = back
	else
		value.Size = UDim2.new(1, 0, 0, 18)
		value.TextSize = 14
		value.TextXAlignment = Enum.TextXAlignment.Right
		value.Parent = root
	end
	return { root = root, name = name, fill = fill, value = value }
end

local function setBar(bar: PanelBar, health: number?, maxHealth: number?)
	local f = HealthBar.fraction(health, maxHealth)
	bar.fill.Size = UDim2.fromScale(f, 1)
	bar.fill.BackgroundColor3 = Color3.fromRGB(HealthBar.color(f))
	bar.value.Text = HealthBar.label(health, maxHealth)
end

local townHallBar = panelBar(1, "Town Hall", 28)
local heartIcon = Icons.get("health")
if heartIcon then
	local heart = Instance.new("ImageLabel")
	heart.Size = UDim2.fromOffset(18, 18)
	heart.BackgroundTransparency = 1
	heart.Image = heartIcon
	heart.Parent = townHallBar.root
	townHallBar.name.Position = UDim2.fromOffset(22, 0)
	townHallBar.name.Size = UDim2.new(1, -22, 0, 18)
end
local partyHeader = Instance.new("TextLabel")
partyHeader.LayoutOrder = 2
partyHeader.Size = UDim2.new(1, 0, 0, 18)
partyHeader.BackgroundTransparency = 1
partyHeader.Font = Enum.Font.Gotham
partyHeader.TextSize = 13
partyHeader.TextColor3 = Color3.fromRGB(190, 190, 205)
partyHeader.TextXAlignment = Enum.TextXAlignment.Left
partyHeader.Text = "PARTY"
partyHeader.Parent = panel

local party: { number } = {} -- UserIds from the server's RunState
local partyBars: { PanelBar } = {}
local lastTownHall: { health: number, max: number } = { health = 0, max = 0 }

local function refreshHealthPanel()
	local hall = CollectionService:GetTagged("TownHall")[1]
	local h = hall and hall:GetAttribute("Health")
	local m = hall and hall:GetAttribute("MaxHealth")
	if type(h) == "number" and type(m) == "number" then
		setBar(townHallBar, h, m)
	else -- not streamed in yet: fall back to the last RunState numbers
		setBar(townHallBar, lastTownHall.health, lastTownHall.max)
	end

	for i, userId in party do
		local bar = partyBars[i]
		if not bar then
			bar = panelBar(2 + i, "", 10)
			partyBars[i] = bar
		end
		bar.root.Visible = true
		local member = Players:GetPlayerByUserId(userId)
		bar.name.Text = if member then member.DisplayName else "(left)"
		local humanoid = member and member.Character and member.Character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			setBar(bar, humanoid.Health, humanoid.MaxHealth)
		else
			setBar(bar, 0, 0)
		end
	end
	for i = #party + 1, #partyBars do
		partyBars[i].root.Visible = false
	end
end

-- Skill buttons ---------------------------------------------------------------------------------

type SkillButton = {
	frame: TextButton,
	icon: ImageLabel,
	name: TextLabel,
	cooldown: TextLabel,
	shade: Frame, -- dark cover that drains downward as the cooldown runs out
	seconds: TextLabel, -- big seconds left, over the icon
	stroke: UIStroke,
	scale: UIScale,
	readyAt: number,
	total: number,
	cooling: boolean,
}

local SKILL_W, SKILL_H, SKILL_ICON = 204, 92, 60
local READY_GREEN = Color3.fromRGB(120, 255, 140)

local skillButtons: { SkillButton } = {}

local function skillButton(index: number): SkillButton
	local frame = Instance.new("TextButton")
	frame.Name = "Skill" .. index
	frame.AnchorPoint = Vector2.new(0.5, 1)
	frame.Position = UDim2.new(0.5, (index - 1.5) * (SKILL_W + 14), 1, -20)
	frame.Size = UDim2.fromOffset(SKILL_W, SKILL_H)
	frame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	frame.BackgroundTransparency = 0.2
	frame.BorderSizePixel = 0
	frame.Text = ""
	frame.AutoButtonColor = true
	frame.ClipsDescendants = true
	frame.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = frame
	local stroke = Instance.new("UIStroke")
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Thickness = 3
	stroke.Color = READY_GREEN
	stroke.Transparency = 1
	stroke.Parent = frame
	local scale = Instance.new("UIScale")
	scale.Parent = frame

	-- Skill icon (left) once its asset id is filled in; set per class in refreshClass.
	local icon = Instance.new("ImageLabel")
	icon.Name = "Icon"
	icon.Position = UDim2.fromOffset(12, (SKILL_H - SKILL_ICON) / 2)
	icon.Size = UDim2.fromOffset(SKILL_ICON, SKILL_ICON)
	icon.BackgroundTransparency = 1
	icon.Visible = false
	icon.Parent = frame

	local key = Instance.new("TextLabel")
	key.Size = UDim2.fromOffset(26, 22)
	key.Position = UDim2.fromOffset(6, 6)
	key.BackgroundColor3 = Color3.fromRGB(230, 230, 240)
	key.TextColor3 = Color3.fromRGB(20, 20, 30)
	key.Font = Enum.Font.GothamBold
	key.TextSize = 15
	key.Text = Classes.SkillKeys[index]
	key.ZIndex = 5
	key.Parent = frame
	local keyCorner = Instance.new("UICorner")
	keyCorner.CornerRadius = UDim.new(0, 4)
	keyCorner.Parent = key

	local textX = 12 + SKILL_ICON + 10
	local name = Instance.new("TextLabel")
	name.Size = UDim2.new(1, -(textX + 8), 0, 40)
	name.Position = UDim2.fromOffset(textX, 12)
	name.BackgroundTransparency = 1
	name.Font = Enum.Font.GothamBold
	name.TextSize = 18
	name.TextWrapped = true
	name.TextColor3 = Color3.new(1, 1, 1)
	name.TextXAlignment = Enum.TextXAlignment.Left
	name.TextYAlignment = Enum.TextYAlignment.Center
	name.Text = ""
	name.Parent = frame

	local cooldown = Instance.new("TextLabel")
	cooldown.Size = UDim2.new(1, -(textX + 8), 0, 22)
	cooldown.Position = UDim2.fromOffset(textX, 56)
	cooldown.BackgroundTransparency = 1
	cooldown.Font = Enum.Font.GothamBold
	cooldown.TextSize = 16
	cooldown.TextColor3 = Color3.fromRGB(180, 255, 180)
	cooldown.TextXAlignment = Enum.TextXAlignment.Left
	cooldown.Text = "Ready"
	cooldown.Parent = frame

	local shade = Instance.new("Frame")
	shade.Name = "Cooldown"
	shade.AnchorPoint = Vector2.new(0, 1)
	shade.Position = UDim2.fromScale(0, 1)
	shade.Size = UDim2.fromScale(1, 0)
	shade.BackgroundColor3 = Color3.new(0, 0, 0)
	shade.BackgroundTransparency = 0.4
	shade.BorderSizePixel = 0
	shade.ZIndex = 3
	shade.Parent = frame

	local seconds = Instance.new("TextLabel")
	seconds.Position = icon.Position
	seconds.Size = icon.Size
	seconds.BackgroundTransparency = 1
	seconds.Font = Enum.Font.GothamBlack
	seconds.TextSize = 30
	seconds.TextColor3 = Color3.fromRGB(255, 225, 130)
	seconds.TextStrokeTransparency = 0.2
	seconds.ZIndex = 4
	seconds.Visible = false
	seconds.Parent = frame

	local button: SkillButton = {
		frame = frame,
		icon = icon,
		name = name,
		cooldown = cooldown,
		shade = shade,
		seconds = seconds,
		stroke = stroke,
		scale = scale,
		readyAt = 0,
		total = 1,
		cooling = false,
	}
	frame.Activated:Connect(function()
		local bindable = player:WaitForChild("PlayerScripts"):FindFirstChild("SkillButtonPressed")
		if bindable then
			(bindable :: BindableEvent):Fire(index)
		end
	end)
	return button
end

-- Cooldown over: a green ring flashes and the button pops.
local function flashReady(button: SkillButton)
	button.stroke.Transparency = 0
	TweenService:Create(button.stroke, TweenInfo.new(0.6), { Transparency = 1 }):Play()
	button.scale.Scale = 1.1
	TweenService:Create(button.scale, TweenInfo.new(0.35, Enum.EasingStyle.Back), { Scale = 1 }):Play()
end

skillButtons[1] = skillButton(1)
skillButtons[2] = skillButton(2)

-- Engineer: placed turrets, in a panel on the right over the two weapon slots (icon, count and one pip per turret).
local TURRET_PANEL_W = 2 * 176 + 8 -- spans both weapon slots below it
local turretPanel = Instance.new("Frame")
turretPanel.Name = "Turrets"
turretPanel.AnchorPoint = Vector2.new(1, 1)
turretPanel.Position = UDim2.new(1, -24, 1, -70 - 50 - 8)
turretPanel.Size = UDim2.fromOffset(TURRET_PANEL_W, 46)
turretPanel.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
turretPanel.BackgroundTransparency = 0.25
turretPanel.BorderSizePixel = 0
turretPanel.Visible = false
turretPanel.Parent = gui
do
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 8)
	c.Parent = turretPanel
end
local turretIcon = Instance.new("ImageLabel")
turretIcon.Size = UDim2.fromOffset(38, 38)
turretIcon.Position = UDim2.fromOffset(6, 4)
turretIcon.BackgroundTransparency = 1
turretIcon.Image = Icons.get("skill_place_turret") or ""
turretIcon.Parent = turretPanel
local turretTitle = Instance.new("TextLabel")
turretTitle.Position = UDim2.fromOffset(52, 0)
turretTitle.Size = UDim2.fromOffset(90, 46)
turretTitle.BackgroundTransparency = 1
turretTitle.Font = Enum.Font.GothamBold
turretTitle.TextSize = 18
turretTitle.TextColor3 = Color3.new(1, 1, 1)
turretTitle.TextXAlignment = Enum.TextXAlignment.Left
turretTitle.Text = "Turrets"
turretTitle.Parent = turretPanel
local turretPips: { Frame } = {}
for i = 1, Classes.Turrets.MaxPlaced do
	local pip = Instance.new("Frame")
	pip.AnchorPoint = Vector2.new(0, 0.5)
	pip.Position = UDim2.new(0, 140 + (i - 1) * 30, 0.5, 0)
	pip.Size = UDim2.fromOffset(22, 22)
	pip.BorderSizePixel = 0
	pip.Parent = turretPanel
	local pc = Instance.new("UICorner")
	pc.CornerRadius = UDim.new(0, 5)
	pc.Parent = pip
	turretPips[i] = pip
end
local turretLabel = Instance.new("TextLabel")
turretLabel.AnchorPoint = Vector2.new(1, 0)
turretLabel.Position = UDim2.new(1, -12, 0, 0)
turretLabel.Size = UDim2.fromOffset(90, 46)
turretLabel.BackgroundTransparency = 1
turretLabel.Font = Enum.Font.GothamBlack
turretLabel.TextSize = 26
turretLabel.TextColor3 = Color3.fromRGB(255, 200, 120)
turretLabel.TextXAlignment = Enum.TextXAlignment.Right
turretLabel.Parent = turretPanel

-- Weapon slots and ammo (bottom right) --------------------------------------------------------------

local SLOT_ACTIVE = Color3.fromRGB(255, 210, 90)
local SLOT_IDLE = Color3.fromRGB(30, 30, 40)

local ammoLabel = Instance.new("TextLabel")
ammoLabel.Name = "Ammo"
ammoLabel.AnchorPoint = Vector2.new(1, 1)
ammoLabel.Position = UDim2.new(1, -24, 1, -24)
ammoLabel.Size = UDim2.fromOffset(220, 40)
ammoLabel.BackgroundTransparency = 1
ammoLabel.Font = Enum.Font.GothamBlack
ammoLabel.TextSize = 34
ammoLabel.TextXAlignment = Enum.TextXAlignment.Right
ammoLabel.TextColor3 = Color3.new(1, 1, 1)
ammoLabel.TextStrokeTransparency = 0.4
ammoLabel.Visible = false
ammoLabel.Parent = gui

-- Ammo / reload icon left of the readout, once the asset ids are filled in.
local ammoIconId = Icons.get("ammo")
local reloadIconId = Icons.get("reload")
local ammoIcon = Instance.new("ImageLabel")
ammoIcon.Name = "AmmoIcon"
ammoIcon.AnchorPoint = Vector2.new(1, 0.5)
ammoIcon.Size = UDim2.fromOffset(30, 30)
ammoIcon.BackgroundTransparency = 1
ammoIcon.Visible = false
ammoIcon.Parent = gui

type SlotBox = { frame: Frame, key: TextLabel, icon: ImageLabel, name: TextLabel }

local SLOT_W, SLOT_H, SLOT_ICON = 176, 50, 42

local function slotBox(slot: number): SlotBox
	local frame = Instance.new("Frame")
	frame.Name = "Slot" .. slot
	frame.AnchorPoint = Vector2.new(1, 1)
	frame.Position = UDim2.new(1, -24 - (2 - slot) * (SLOT_W + 8), 1, -70)
	frame.Size = UDim2.fromOffset(SLOT_W, SLOT_H)
	frame.BackgroundColor3 = SLOT_IDLE
	frame.BackgroundTransparency = 0.25
	frame.BorderSizePixel = 0
	frame.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = frame

	local key = Instance.new("TextLabel")
	key.Size = UDim2.fromOffset(22, 22)
	key.Position = UDim2.fromOffset(4, (SLOT_H - 22) / 2)
	key.BackgroundColor3 = Color3.fromRGB(230, 230, 240)
	key.TextColor3 = Color3.fromRGB(20, 20, 30)
	key.Font = Enum.Font.GothamBold
	key.TextSize = 14
	key.Text = Classes.WeaponKeys[slot]
	key.Parent = frame
	local keyCorner = Instance.new("UICorner")
	keyCorner.CornerRadius = UDim.new(0, 4)
	keyCorner.Parent = key

	-- Weapon icon (Icons "weapon_<Name>"), hidden when the weapon has none.
	local icon = Instance.new("ImageLabel")
	icon.Name = "Icon"
	icon.Size = UDim2.fromOffset(SLOT_ICON, SLOT_ICON)
	icon.Position = UDim2.fromOffset(30, (SLOT_H - SLOT_ICON) / 2)
	icon.BackgroundTransparency = 1
	icon.ScaleType = Enum.ScaleType.Fit
	icon.Parent = frame

	local name = Instance.new("TextLabel")
	name.Size = UDim2.new(1, -(34 + SLOT_ICON + 4), 1, 0)
	name.Position = UDim2.fromOffset(34 + SLOT_ICON, 0)
	name.TextWrapped = true
	name.BackgroundTransparency = 1
	name.Font = Enum.Font.GothamBold
	name.TextSize = 14
	name.TextColor3 = Color3.new(1, 1, 1)
	name.TextXAlignment = Enum.TextXAlignment.Left
	name.TextTruncate = Enum.TextTruncate.AtEnd
	name.Parent = frame
	return { frame = frame, key = key, icon = icon, name = name }
end

local slotBoxes = { slotBox(1), slotBox(2) }

local function refreshWeapon()
	local class = Classes.find(player:GetAttribute("Class"))
	local active = player:GetAttribute("WeaponSlot")
	for slot, box in slotBoxes do
		local weaponName = class and Classes.weaponInSlot(class.id, slot)
		box.frame.Visible = weaponName ~= nil
		box.name.Text = if weaponName then weaponName:gsub("(%l)(%u)", "%1 %2") else "" -- "Assault Rifle"
		local image = weaponName and Icons.get("weapon_" .. weaponName)
		box.icon.Image = image or ""
		box.icon.Visible = image ~= nil
		local isActive = active == slot
		box.frame.BackgroundColor3 = if isActive then SLOT_ACTIVE else SLOT_IDLE
		box.name.TextColor3 = if isActive then Color3.fromRGB(20, 20, 30) else Color3.new(1, 1, 1)
	end

	local def = Weapons.find(player:GetAttribute("Weapon"))
	local ammo = player:GetAttribute("Ammo")
	local size = player:GetAttribute("MagazineSize")
	local showAmmo = def ~= nil and def.magazine ~= nil and active == 1 and type(size) == "number"
	ammoLabel.Visible = showAmmo
	ammoIcon.Visible = false
	if not showAmmo then
		return
	end
	local reloading = player:GetAttribute("Reloading") == true
	local iconId = if reloading then reloadIconId else ammoIconId
	if iconId then
		ammoIcon.Image = iconId
		ammoIcon.Visible = true
	end
	if reloading then
		ammoLabel.Text = "RELOADING"
		ammoLabel.TextColor3 = Color3.fromRGB(255, 200, 90)
	else
		local n = if type(ammo) == "number" then ammo else 0
		ammoLabel.Text = `{n} / {size}`
		ammoLabel.TextColor3 = if n <= math.ceil((size :: number) * 0.2)
			then Color3.fromRGB(255, 110, 90)
			else Color3.new(1, 1, 1)
	end
	if ammoIcon.Visible then -- just left of the right-aligned text
		ammoIcon.Position = UDim2.new(1, -24 - ammoLabel.TextBounds.X - 8, 1, -44)
	end
end

for _, attribute in { "Weapon", "WeaponSlot", "Ammo", "MagazineSize", "Reloading" } do
	player:GetAttributeChangedSignal(attribute):Connect(refreshWeapon)
end

local function refreshClass()
	local id = player:GetAttribute("Class")
	local class = Classes.find(id)
	if not class then
		return
	end
	classLabel.Text = `{class.id}  ({class.weapon})`
	for i, button in skillButtons do
		button.name.Text = class.skills[i].name
		local image = Icons.get(Icons.skillKey(class.skills[i].name))
		button.icon.Image = image or ""
		button.icon.Visible = image ~= nil
		button.total = class.skills[i].cooldown
		button.readyAt = 0
	end
	turretPanel.Visible = class.id == "Engineer"
	refreshWeapon()
end

local function refreshTurrets()
	local n = player:GetAttribute("Turrets")
	local placed = if type(n) == "number" then n else 0
	turretLabel.Text = `{placed} / {Classes.Turrets.MaxPlaced}`
	for i, pip in turretPips do
		pip.BackgroundColor3 = if i <= placed then Color3.fromRGB(255, 190, 90) else Color3.fromRGB(70, 70, 82)
	end
end

player:GetAttributeChangedSignal("Class"):Connect(refreshClass)
player:GetAttributeChangedSignal("Turrets"):Connect(refreshTurrets)
refreshClass()
refreshTurrets()
refreshWeapon()

skillFx.OnClientEvent:Connect(function(fx)
	if type(fx) ~= "table" then
		return
	end
	if fx.kind == "cooldown" and skillButtons[fx.index] then
		local button = skillButtons[fx.index]
		button.readyAt = os.clock() + fx.cooldown
		button.total = math.max(fx.cooldown, 0.01)
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

local nextPanelRefresh = 0

RunService.RenderStepped:Connect(function()
	if not gui.Enabled then
		return
	end
	local now = os.clock()
	if now >= nextPanelRefresh then
		nextPanelRefresh = now + 0.1
		refreshHealthPanel()
	end
	for _, button in skillButtons do
		local left = button.readyAt - now
		if left > 0 then
			button.cooling = true
			button.shade.Size = UDim2.fromScale(1, math.clamp(left / button.total, 0, 1))
			button.seconds.Visible = true
			button.seconds.Text = if left < 10 then string.format("%.1f", left) else tostring(math.ceil(left))
			button.cooldown.Text = "Cooling down"
			button.cooldown.TextColor3 = Color3.fromRGB(255, 220, 120)
		else
			if button.cooling then
				button.cooling = false
				button.shade.Size = UDim2.fromScale(1, 0)
				button.seconds.Visible = false
				flashReady(button)
			end
			if button.cooldown.Text ~= "No target" then
				button.cooldown.Text = "Ready"
				button.cooldown.TextColor3 = Color3.fromRGB(180, 255, 180)
			end
		end
	end
end)

-- Countdown to the next wave, big in the middle of the screen (above the crosshair); red for the last 10 seconds.
local COUNTDOWN_RED = 10
local countdown = Instance.new("Frame")
countdown.Name = "WaveCountdown"
countdown.AnchorPoint = Vector2.new(0.5, 0.5)
countdown.Position = UDim2.fromScale(0.5, 0.16)
countdown.Size = UDim2.fromOffset(320, 120)
countdown.BackgroundTransparency = 1
countdown.Visible = false
countdown.Parent = gui
local countdownTitle = Instance.new("TextLabel")
countdownTitle.Size = UDim2.new(1, 0, 0, 30)
countdownTitle.BackgroundTransparency = 1
countdownTitle.Font = Enum.Font.GothamBold
countdownTitle.TextSize = 26
countdownTitle.TextColor3 = Color3.new(1, 1, 1)
countdownTitle.TextStrokeTransparency = 0.3
countdownTitle.Parent = countdown
local countdownNumber = Instance.new("TextLabel")
countdownNumber.Position = UDim2.fromOffset(0, 30)
countdownNumber.Size = UDim2.new(1, 0, 0, 90)
countdownNumber.BackgroundTransparency = 1
countdownNumber.Font = Enum.Font.GothamBlack
countdownNumber.TextSize = 84
countdownNumber.TextStrokeTransparency = 0.2
countdownNumber.Parent = countdown

local function showCountdown(state)
	if state.phase ~= "prep" or type(state.secondsLeft) ~= "number" or state.secondsLeft <= 0 then
		countdown.Visible = false
		return
	end
	countdown.Visible = true
	countdownTitle.Text = `Wave {state.wave} starts in`
	countdownNumber.Text = tostring(math.ceil(state.secondsLeft))
	countdownNumber.TextColor3 = if state.secondsLeft <= COUNTDOWN_RED
		then Color3.fromRGB(255, 70, 60)
		else Color3.new(1, 1, 1)
end

gui.Parent = player:WaitForChild("PlayerGui")

runState.OnClientEvent:Connect(function(state)
	gui.Enabled = state.phase ~= "ended"
	showCountdown(state)
	if state.phase == "prep" then
		waveLabel.Text = `Wave {state.wave} in {state.secondsLeft}s`
	elseif state.phase == "cleared" then
		waveLabel.Text = `Wave {state.wave} cleared!`
	else
		waveLabel.Text = `Wave {state.wave}`
	end
	lastTownHall.health = state.townHallHealth
	lastTownHall.max = state.townHallMax
	if type(state.party) == "table" then
		party = state.party
	end
	coinsLabel.Text = `Coins {state.coins}`
	scoreLabel.Text = `Score {state.score}`
	killsLabel.Text = `Kills {state.kills}`
end)
