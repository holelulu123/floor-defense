-- Lobby dungeon markers per player: each plot's light pillar and big name sign (built by Lobby.luau, tagged
-- "LobbyDungeonMarker") shine in the dungeon's accent colour once the local player's Level reaches the dungeon's
-- unlock level, and stay grey with "LOCKED - reach Level N" until then. Visual only: the pads check levels on the
-- server. Studio playtests unlock everything (Config.UnlockAllInStudio), like the pads.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)

local TAG = "LobbyDungeonMarker"
local LOCKED_GREY = Color3.fromRGB(150, 150, 158)
local WHITE = Color3.new(1, 1, 1)

local player = Players.LocalPlayer
local unlockAll = Config.UnlockAllInStudio and RunService:IsStudio()

local function apply(marker: Instance)
	local need = marker:GetAttribute("UnlockLevel")
	local accent = marker:GetAttribute("Accent")
	if typeof(need) ~= "number" or typeof(accent) ~= "Color3" then
		return
	end
	local level = player:GetAttribute("Level")
	local open = unlockAll or need <= 1 or (typeof(level) == "number" and level >= need)
	local color = if open then accent else LOCKED_GREY

	local beam = marker:FindFirstChild("Beam")
	if beam and beam:IsA("BasePart") then
		beam.Color = color
		beam.Transparency = if open then 0.15 else 0.55
	end
	local glow = marker:FindFirstChild("Glow")
	if glow and glow:IsA("BasePart") then
		glow.Color = color
		glow.Transparency = if open then 0.82 else 0.93
	end
	local light = marker:FindFirstChildWhichIsA("PointLight", true)
	if light then
		light.Enabled = open
	end
	local sign = marker:FindFirstChild("NameSign", true)
	if sign then
		local title = sign:FindFirstChild("Title")
		local subtitle = sign:FindFirstChild("Subtitle")
		if title and title:IsA("TextLabel") then
			title.TextColor3 = if open then accent:Lerp(WHITE, 0.35) else LOCKED_GREY
		end
		if subtitle and subtitle:IsA("TextLabel") then
			subtitle.TextColor3 = if open then WHITE else Color3.fromRGB(205, 205, 210)
			subtitle.Text = if not open
				then `LOCKED - reach Level {need}`
				elseif need > 1 then `Level {need} - open`
				else "Level 1 - start here"
		end
	end
end

local function applyAll()
	for _, marker in CollectionService:GetTagged(TAG) do
		apply(marker)
	end
end

CollectionService:GetInstanceAddedSignal(TAG):Connect(function(marker)
	apply(marker)
	-- Streaming can deliver the sign after the model itself; catch it when it lands.
	marker.DescendantAdded:Connect(function()
		apply(marker)
	end)
end)
for _, marker in CollectionService:GetTagged(TAG) do
	marker.DescendantAdded:Connect(function()
		apply(marker)
	end)
end
player:GetAttributeChangedSignal("Level"):Connect(applyAll)

-- The beams are 160 studs tall and show over the arena's horizon; hide the markers while this player is in a run.
local hidden: { [Instance]: number } = {}
local function applyRunVisibility()
	local inRun = player:GetAttribute("InRun") == true
	for _, marker in CollectionService:GetTagged(TAG) do
		for _, d in marker:GetDescendants() do
			if d:IsA("BasePart") then
				if inRun and hidden[d] == nil then
					hidden[d] = d.LocalTransparencyModifier
					d.LocalTransparencyModifier = 1
				elseif not inRun and hidden[d] ~= nil then
					d.LocalTransparencyModifier = hidden[d]
					hidden[d] = nil
				end
			elseif d:IsA("BillboardGui") or d:IsA("PointLight") then
				d.Enabled = not inRun
			end
		end
	end
end
player:GetAttributeChangedSignal("InRun"):Connect(applyRunVisibility)
applyAll()
applyRunVisibility()
