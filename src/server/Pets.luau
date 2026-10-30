-- Summoner pet: a small server-moved Part that hovers by its owner and bites the nearest creature.
-- Pounce (skill 1) sends it at a creature for burst damage; Enrage (skill 2) doubles size and damage.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Skills = require(ReplicatedStorage.Shared.Skills)
local Damage = require(script.Parent.Damage)

local Pets = {}

export type Pet = {
	part: Part,
	owner: Player,
	lastBite: number,
	enragedUntil: number?,
	lungeAt: Vector3?, -- where the pet is currently flying to bite
}

local pets: { [Player]: Pet } = {}
local heartbeat: RBXScriptConnection? = nil

local function root(player: Player): BasePart?
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function damageMult(pet: Pet, now: number): number
	return if pet.enragedUntil and now < pet.enragedUntil then Skills.Effects.Enrage.multiplier else 1
end

local function step(dt: number)
	local now = os.clock()
	for player, pet in pets do
		local rootPart = root(player)
		if not rootPart then
			continue
		end

		local enraged = damageMult(pet, now) > 1
		local size = Skills.Pet.size * (if enraged then 2 else 1)
		if pet.part.Size.X ~= size then
			pet.part.Size = Vector3.new(size, size, size)
		end

		local home = rootPart.CFrame * CFrame.new(-2.5, 3, 1)
		local goal = pet.lungeAt or home.Position
		local pos = pet.part.Position
		local alpha = math.clamp(dt * 8, 0, 1)
		local nextPos = pos:Lerp(goal, alpha)
		if (goal - nextPos).Magnitude > 0.05 then
			pet.part.CFrame = CFrame.lookAt(nextPos, goal)
		else
			pet.part.Position = nextPos
		end
		if pet.lungeAt and (pet.part.Position - pet.lungeAt).Magnitude < 1.5 then
			pet.lungeAt = nil
		end

		if now - pet.lastBite >= Skills.Pet.interval then
			local target = Damage.nearest(rootPart.Position, Skills.Pet.range)
			if target then
				pet.lastBite = now
				pet.lungeAt = target.part.Position
				Damage.hit(target, Skills.Pet.damage * damageMult(pet, now), player.UserId)
			end
		end
	end
end

function Pets.spawn(player: Player)
	Pets.remove(player)
	local rootPart = root(player)
	if not rootPart then
		return
	end
	local part = Instance.new("Part")
	part.Name = "Pet"
	part.Size = Vector3.new(Skills.Pet.size, Skills.Pet.size, Skills.Pet.size)
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.Color = Color3.fromRGB(120, 60, 160)
	part.Material = Enum.Material.Neon
	part.CFrame = rootPart.CFrame * CFrame.new(-2.5, 3, 1)
	part:SetAttribute("Owner", player.UserId)
	part.Parent = Workspace
	pets[player] = { part = part, owner = player, lastBite = 0, enragedUntil = nil, lungeAt = nil }
	if not heartbeat then
		heartbeat = RunService.Heartbeat:Connect(step)
	end
end

function Pets.has(player: Player): boolean
	return pets[player] ~= nil
end

-- Pounce on the creature nearest to `point` (within `range`). Returns the creature hit, if any.
function Pets.pounce(player: Player, point: Vector3, range: number, damage: number)
	local pet = pets[player]
	if not pet then
		return nil
	end
	local target = Damage.nearest(point, range)
	if not target then
		return nil
	end
	pet.lungeAt = target.part.Position
	Damage.hit(target, damage * damageMult(pet, os.clock()), player.UserId)
	return target
end

function Pets.enrage(player: Player, seconds: number)
	local pet = pets[player]
	if pet then
		pet.enragedUntil = os.clock() + seconds
	end
end

function Pets.remove(player: Player)
	local pet = pets[player]
	if pet then
		pet.part:Destroy()
		pets[player] = nil
	end
end

function Pets.clear()
	for player in pets do
		Pets.remove(player)
	end
	if heartbeat then
		heartbeat:Disconnect()
		heartbeat = nil
	end
end

return Pets
