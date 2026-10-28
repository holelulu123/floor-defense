-- Lobby floor pads. Builds one pad per Config.Pads entry, counts the players standing on it, and
-- fires onLaunch with those players when the countdown finishes. Pad countdown rules live in
-- PadLogic so they stay unit-testable.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local PadLogic = require(ReplicatedStorage.Shared.PadLogic)

local Lobby = {}

local PAD_SIZE = Vector3.new(14, 1, 14)
local POLL_SECONDS = 0.2

type Pad = {
	def: { mode: string, capacity: number, countdown: number, position: { number } },
	part: Part,
	label: TextLabel,
	logic: PadLogic.Pad,
}

local pads: { Pad } = {}
local locked = false

local function buildPad(def): Pad
	local part = Instance.new("Part")
	part.Name = "Pad_" .. def.mode
	part.Size = PAD_SIZE
	part.Anchored = true
	part.Position = Vector3.new(def.position[1], def.position[2] + 0.5, def.position[3])
	part.Color = Color3.fromRGB(70, 120, 200)
	part.Material = Enum.Material.Neon
	part.Transparency = 0.5

	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(200, 60)
	gui.StudsOffset = Vector3.new(0, 6, 0)
	gui.AlwaysOnTop = true
	gui.Parent = part

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.5
	label.Parent = gui

	return { def = def, part = part, label = label, logic = PadLogic.new(def.capacity, def.countdown) }
end

local function playersOn(pad: Pad): { Player }
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { pad.part }

	local region = CFrame.new(pad.part.Position + Vector3.new(0, 4, 0))
	local found: { Player } = {}
	local seen: { [Player]: boolean } = {}
	for _, hit in Workspace:GetPartBoundsInBox(region, Vector3.new(PAD_SIZE.X, 8, PAD_SIZE.Z), params) do
		local player = Players:GetPlayerFromCharacter(hit.Parent)
		if player and not seen[player] then
			seen[player] = true
			table.insert(found, player)
		end
	end
	return found
end

local function buildFloor(parent: Instance)
	local floor = Instance.new("Part")
	floor.Name = "Floor"
	floor.Size = Vector3.new(120, 1, 120)
	floor.Position = Vector3.new(0, -0.5, 0)
	floor.Anchored = true
	floor.Color = Color3.fromRGB(90, 90, 100)
	floor.Parent = parent

	local spawn = Instance.new("SpawnLocation")
	spawn.Size = Vector3.new(8, 1, 8)
	spawn.Position = Vector3.new(0, 0.5, -20)
	spawn.Anchored = true
	spawn.Parent = parent
end

function Lobby.start(onLaunch: (mode: string, players: { Player }) -> ())
	local folder = Instance.new("Folder")
	folder.Name = "Lobby"
	buildFloor(folder)
	for _, def in Config.Pads do
		local pad = buildPad(def)
		pad.part.Parent = folder
		table.insert(pads, pad)
	end
	folder.Parent = Workspace

	task.spawn(function()
		while true do
			if not locked then
				local now = os.clock()
				for _, pad in pads do
					local occupants = playersOn(pad)
					local state, left = pad.logic:update(#occupants, now)
					if state == "waiting" then
						pad.label.Text = `{pad.def.mode} {#occupants}/{pad.def.capacity}`
					elseif state == "counting" then
						pad.label.Text = `{pad.def.mode} starting in {math.ceil(left :: number)}`
					else
						pad.label.Text = `{pad.def.mode} launching`
						onLaunch(pad.def.mode, { table.unpack(occupants, 1, pad.def.capacity) })
					end
				end
			end
			task.wait(POLL_SECONDS)
		end
	end)
end

-- Freeze pads while a run is in progress in this server (Studio / single-server mode).
function Lobby.setLocked(value: boolean)
	locked = value
	if locked then
		for _, pad in pads do
			pad.logic:reset()
			pad.label.Text = "run in progress"
		end
	end
end

return Lobby
