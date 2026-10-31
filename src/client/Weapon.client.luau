-- Client side of shooting: input, aiming, a local cooldown for feel, tracers and a crosshair.
-- The server decides hits; this script only tells it where we aimed. Skill keys (Q/E) send the
-- skill index plus the same aim ray; when the server confirms a skill, its move (shared SkillVisuals) plays here and
-- SkillEffects.client.luau draws the effect.
-- Weapon keys: 1 = primary, 2 = melee secondary (Remotes.EquipSlot), R = reload (Remotes.Reload). The
-- server owns the active slot and the magazine; the client only skips shots it knows would be refused.
-- Shots start at the equipped Tool's "Muzzle" attachment (WeaponModels.luau; the Scout alternates with "MuzzleLeft")
-- with a short flash; melee swings start at the head. Weapon animations (scripts/roblox/make-animations.luau, ids in
-- ModelIds as Anim_<name>) play on the Humanoid's Animator: the hold pose loops while a class Tool is equipped, the
-- recoil / swing / cast plays per shot. Melee swings whoosh; melee hits spark and flash the creature.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Classes = require(ReplicatedStorage.Shared.Classes)
local ModelIds = require(ReplicatedStorage.Shared.ModelIds) :: { [string]: number }
local SkillVisuals = require(ReplicatedStorage.Shared.SkillVisuals)
local Skills = require(ReplicatedStorage.Shared.Skills)
local WeaponMeshes = require(ReplicatedStorage.Shared.WeaponMeshes)
local Weapons = require(ReplicatedStorage.Shared.Weapons)

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local fireRemote = remotes:WaitForChild("Fire") :: RemoteEvent
local equipSlot = remotes:WaitForChild("EquipSlot") :: RemoteEvent
local reloadRemote = remotes:WaitForChild("Reload") :: RemoteEvent
local hitFx = remotes:WaitForChild("HitFx") :: RemoteEvent
local useSkill = remotes:WaitForChild("UseSkill") :: RemoteEvent
local skillFx = remotes:WaitForChild("SkillFx") :: RemoteEvent

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

local TRACER_SECONDS = 0.06
local FLASH_SECONDS = 0.06
local AIM_RANGE = 1000

-- Crosshair -------------------------------------------------------------------------------------

local gui = Instance.new("ScreenGui")
gui.Name = "Crosshair"
gui.ResetOnSpawn = false
gui.Enabled = false

local dot = Instance.new("Frame")
dot.AnchorPoint = Vector2.new(0.5, 0.5)
dot.Position = UDim2.fromScale(0.5, 0.5)
dot.Size = UDim2.fromOffset(6, 6)
dot.BackgroundColor3 = Color3.new(1, 1, 1)
dot.BorderSizePixel = 0
dot.Parent = gui
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(1, 0)
corner.Parent = dot

gui.Parent = player:WaitForChild("PlayerGui")

local function flashHit()
	dot.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
	dot.Size = UDim2.fromOffset(10, 10)
	task.delay(0.1, function()
		dot.BackgroundColor3 = Color3.new(1, 1, 1)
		dot.Size = UDim2.fromOffset(6, 6)
	end)
end

-- Tracers ---------------------------------------------------------------------------------------

local function drawTracer(from: Vector3, to: Vector3)
	local length = (to - from).Magnitude
	if length < 0.5 then
		return
	end
	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Material = Enum.Material.Neon
	part.Color = Color3.fromRGB(255, 230, 120)
	part.Size = Vector3.new(0.1, 0.1, length)
	part.CFrame = CFrame.lookAt(from, to) * CFrame.new(0, 0, -length / 2)
	part.Parent = camera
	task.delay(TRACER_SECONDS, part.Destroy, part)
end

-- Muzzles, flashes and melee feedback ------------------------------------------------------------

local function classTool(character: Model?): Tool?
	local tool = character and character:FindFirstChildOfClass("Tool")
	return if tool and tool:GetAttribute("ClassWeapon") then tool else nil
end

-- The muzzle attachments on a character's class Tool (right hand first; the Scout's left pistol second).
local function muzzles(character: Model?): { Attachment }
	local tool = classTool(character)
	local out = {}
	if tool then
		for _, name in { "Muzzle", "MuzzleLeft" } do
			local a = tool:FindFirstChild(name, true)
			if a and a:IsA("Attachment") then
				table.insert(out, a)
			end
		end
	end
	return out
end

local function flashColor(weaponName: string?): Color3
	if weaponName == "Staff" then
		return Color3.fromRGB(140, 180, 255)
	elseif weaponName == "Flamethrower" then
		return Color3.fromRGB(255, 140, 40)
	end
	return Color3.fromRGB(255, 220, 130)
end

-- A small bright flash with a light at the muzzle for FLASH_SECONDS.
local function muzzleFlash(position: Vector3, color: Color3)
	local flash = Instance.new("Part")
	flash.Name = "MuzzleFlash"
	flash.Anchored = true
	flash.CanCollide = false
	flash.CanQuery = false
	flash.CanTouch = false
	flash.CastShadow = false
	flash.Material = Enum.Material.Neon
	flash.Shape = Enum.PartType.Ball
	flash.Color = color
	flash.Transparency = 0.15
	flash.Size = Vector3.one * 0.45
	flash.CFrame = CFrame.new(position)
	local light = Instance.new("PointLight")
	light.Color = color
	light.Brightness = 6
	light.Range = 10
	light.Shadows = false
	light.Parent = flash
	flash.Parent = Workspace
	task.delay(FLASH_SECONDS, flash.Destroy, flash)
end

local function playSound(key: string, parent: Instance, volume: number)
	local id = ModelIds[key]
	if not id then
		return
	end
	local sound = Instance.new("Sound")
	sound.SoundId = `rbxassetid://{id}`
	sound.Volume = volume
	sound.PlaybackSpeed = 0.92 + math.random() * 0.16
	sound.RollOffMaxDistance = 80
	sound.Parent = parent
	sound:Play()
	sound.Ended:Once(function()
		sound:Destroy()
	end)
	task.delay(3, function()
		if sound.Parent then
			sound:Destroy()
		end
	end)
end

-- Melee hit: a burst of sparks at the contact point and a 0.1 s white flash on the creature.
local function meleeHit(position: Vector3, target: Instance?)
	local holder = Instance.new("Part")
	holder.Name = "HitSpark"
	holder.Anchored = true
	holder.CanCollide = false
	holder.CanQuery = false
	holder.CanTouch = false
	holder.Transparency = 1
	holder.Size = Vector3.one * 0.2
	holder.CFrame = CFrame.new(position)
	local sparks = Instance.new("ParticleEmitter")
	sparks.Rate = 0
	sparks.Color = ColorSequence.new(Color3.fromRGB(255, 240, 180), Color3.fromRGB(255, 140, 40))
	sparks.LightEmission = 1
	sparks.Size = NumberSequence.new(0.25, 0)
	sparks.Lifetime = NumberRange.new(0.12, 0.25)
	sparks.Speed = NumberRange.new(12, 22)
	sparks.SpreadAngle = Vector2.new(180, 180)
	sparks.Drag = 6
	sparks.Parent = holder
	local glow = Instance.new("PointLight")
	glow.Color = Color3.fromRGB(255, 200, 120)
	glow.Brightness = 3
	glow.Range = 6
	glow.Parent = holder
	holder.Parent = Workspace
	sparks:Emit(16)
	playSound("Sound_MeleeHit", holder, 0.8)
	task.delay(0.08, glow.Destroy, glow)
	task.delay(1, holder.Destroy, holder)

	if target and target:IsDescendantOf(Workspace) then
		-- A creature may be one part or a model of parts: flash the whole model when it has one.
		local parent = target.Parent
		local adornee = if parent and parent:IsA("Model") and parent ~= Workspace then parent else target
		local highlight = Instance.new("Highlight")
		highlight.Adornee = adornee
		highlight.FillColor = Color3.new(1, 1, 1)
		highlight.FillTransparency = 0.35
		highlight.OutlineColor = Color3.fromRGB(255, 220, 120)
		highlight.OutlineTransparency = 0
		highlight.DepthMode = Enum.HighlightDepthMode.Occluded
		highlight.Parent = adornee
		task.delay(0.1, highlight.Destroy, highlight)
	end
end

-- Weapon animations ---------------------------------------------------------------------------------

local tracks: { [string]: AnimationTrack } = {}
local tracksFor: Animator? = nil
local heldTool: Tool? = nil
local holdTrack: AnimationTrack? = nil

-- The loaded track for animation `name` (Anim_<name> in ModelIds) on the current character, or nil.
local function track(name: string?): AnimationTrack?
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
	if animator ~= tracksFor then
		tracks = {}
		tracksFor = animator
	end
	if not animator or not name then
		return nil
	end
	if tracks[name] then
		return tracks[name]
	end
	local id = ModelIds["Anim_" .. name]
	if not id then
		return nil
	end
	local animation = Instance.new("Animation")
	animation.AnimationId = `rbxassetid://{id}`
	local ok, loaded = pcall(animator.LoadAnimation, animator, animation)
	if not ok then
		warn(`Weapon: could not load animation {name}: {loaded}`)
		return nil
	end
	tracks[name] = loaded
	return loaded
end

-- Keeps the hold pose of the equipped class Tool looping (called every frame; cheap when nothing changed).
local function updateHold()
	local tool = classTool(player.Character)
	if tool == heldTool then
		return
	end
	heldTool = tool
	if holdTrack then
		holdTrack:Stop(0.15)
		holdTrack = nil
	end
	if tool then
		-- Load this class's skill moves now so their first use plays at full length.
		local class = Classes.find(player:GetAttribute("Class"))
		for _, skill in if class then class.skills else {} do
			local visual = SkillVisuals.forSkill(skill.id)
			if visual then
				track(visual.anim)
			end
		end
		local holdName = WeaponMeshes.animationsFor(tool.Name)
		local t = track(holdName)
		if t then
			t.Looped = true
			t:Play(0.15)
			holdTrack = t
		end
	end
end

-- The recoil / swing / cast for one shot, sped up when the weapon fires faster than the clip is long.
local function playAction(weaponName: string, interval: number)
	local _, actionName = WeaponMeshes.animationsFor(weaponName)
	local t = track(actionName)
	if not t then
		return
	end
	local speed = if t.Length > 0 and interval > 0 then math.max(1, t.Length / interval) else 1
	t:Stop(0)
	t:Play(0.04, 1, speed)
end

-- Aiming ----------------------------------------------------------------------------------------

local function currentWeapon(): Weapons.Weapon?
	return Weapons.find(player:GetAttribute("Weapon"))
end

-- The server-published magazine of the active weapon: false when the shot would be refused.
local function hasRound(def: Weapons.Weapon): boolean
	if not def.magazine or player:GetAttribute("WeaponSlot") ~= 1 then
		return true
	end
	local ammo = player:GetAttribute("Ammo")
	return player:GetAttribute("Reloading") ~= true and (type(ammo) ~= "number" or ammo > 0)
end

local useLeftMuzzle = false

-- Returns the shot origin (the equipped Tool's muzzle; the head for melee or when there is no muzzle) and the
-- direction from it toward whatever is under the crosshair / cursor. `melee` keeps the head origin, so the swing
-- reach is measured from the body.
local function aim(melee: boolean?): (Vector3?, Vector3?)
	local character = player.Character
	local head = character and character:FindFirstChild("Head") :: BasePart?
	if not head then
		return nil, nil
	end

	local ray
	if UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter then
		ray = camera:ViewportPointToRay(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
	else
		-- GetMouseLocation is already in viewport space (inset included), so pair it with ViewportPointToRay.
		local mouse = UserInputService:GetMouseLocation()
		ray = camera:ViewportPointToRay(mouse.X, mouse.Y)
	end

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character :: Instance }
	local hit = Workspace:Raycast(ray.Origin, ray.Direction * AIM_RANGE, params)
	local target = if hit then hit.Position else ray.Origin + ray.Direction * AIM_RANGE

	local origin = head.Position
	if not melee then
		local list = muzzles(character)
		if #list > 1 then
			useLeftMuzzle = not useLeftMuzzle -- dual pistols take turns
		end
		local muzzle = list[if useLeftMuzzle and #list > 1 then 2 else 1]
		-- A muzzle past the aim point (target right against the barrel) would shoot backwards: keep the head then.
		if muzzle and (target - muzzle.WorldPosition).Magnitude > 1 then
			origin = muzzle.WorldPosition
		end
	end
	return origin, (target - origin).Unit
end

-- Firing ----------------------------------------------------------------------------------------

local holding = false
local lastShot = 0

local function tryFire()
	local def = currentWeapon()
	if not def then
		return
	end
	local now = os.clock()
	local rateMult = Skills.buffValue(
		player:GetAttribute("FireRateMult") :: number?,
		player:GetAttribute("FireRateMultUntil") :: number?,
		Workspace:GetServerTimeNow(),
		1
	)
	if now - lastShot < Weapons.interval(def) / rateMult then
		return
	end
	if not hasRound(def) then
		return -- the server reloads an empty magazine on its own
	end
	local origin, direction = aim(def.melee)
	if not origin or not direction then
		return
	end
	lastShot = now
	fireRemote:FireServer(origin, direction)
	playAction(def.name, Weapons.interval(def) / rateMult)
	local character = player.Character
	if def.melee then
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if root then
			playSound("Sound_Whoosh", root, 0.7)
		end
	else
		drawTracer(origin, origin + direction * def.range)
		muzzleFlash(origin, flashColor(def.name))
	end
end

-- Skills ----------------------------------------------------------------------------------------

local SKILL_KEYS = { [Enum.KeyCode.Q] = 1, [Enum.KeyCode.E] = 2 }
local SLOT_KEYS = {
	[Enum.KeyCode.One] = 1,
	[Enum.KeyCode.KeypadOne] = 1,
	[Enum.KeyCode.Two] = 2,
	[Enum.KeyCode.KeypadTwo] = 2,
}

-- Roblox's default hotbar would also grab 1/2 and let the player unequip everything; weapon slots
-- are ours, so hide it. SetCoreGuiEnabled can fail while the CoreGui is still loading, so retry.
task.spawn(function()
	for _ = 1, 20 do
		if pcall(StarterGui.SetCoreGuiEnabled, StarterGui, Enum.CoreGuiType.Backpack, false) then
			return
		end
		task.wait(0.5)
	end
end)

local function useSkillIndex(index: number)
	if not currentWeapon() then
		return -- not in a run
	end
	local origin, direction = aim()
	useSkill:FireServer(index, origin, direction)
end

-- Hud.client.luau fires this bindable when a skill button is tapped (touch / mouse).
local skillButtonPressed = Instance.new("BindableEvent")
skillButtonPressed.Name = "SkillButtonPressed"
skillButtonPressed.Parent = player:WaitForChild("PlayerScripts")
skillButtonPressed.Event:Connect(useSkillIndex)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		holding = true
		tryFire()
	elseif input.UserInputType == Enum.UserInputType.Keyboard then
		local index = SKILL_KEYS[input.KeyCode]
		local slot = SLOT_KEYS[input.KeyCode]
		if index then
			useSkillIndex(index)
		elseif slot and currentWeapon() then
			equipSlot:FireServer(slot)
		elseif input.KeyCode == Enum.KeyCode.R and currentWeapon() then
			reloadRemote:FireServer()
		end
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		holding = false
	end
end)

RunService.RenderStepped:Connect(function()
	local def = currentWeapon()
	gui.Enabled = def ~= nil
	updateHold()
	if holding and def and def.automatic then
		tryFire()
	end
end)

hitFx.OnClientEvent:Connect(
	function(
		shooterUserId: number,
		origin: Vector3,
		endpoint: Vector3,
		hit: boolean,
		target: Instance?,
		melee: boolean?
	)
		if typeof(origin) ~= "Vector3" or typeof(endpoint) ~= "Vector3" then
			return
		end
		local hitTarget = if typeof(target) == "Instance" then target else nil
		if shooterUserId == player.UserId then
			if hit then
				flashHit()
				if melee then
					meleeHit(endpoint, hitTarget)
				end
			end
			return
		end
		local shooter = Players:GetPlayerByUserId(shooterUserId)
		local character = shooter and shooter.Character
		if melee then
			local root = character and character:FindFirstChild("HumanoidRootPart")
			if root then
				playSound("Sound_Whoosh", root, 0.5)
			end
			if hit then
				meleeHit(endpoint, hitTarget)
			end
			return
		end
		-- Start at the shooter's muzzle as this client sees it (the reported origin lags their replicated arm).
		local from = origin
		local best = 4
		for _, muzzle in muzzles(character) do
			local d = (muzzle.WorldPosition - origin).Magnitude
			if d < best then
				best = d
				from = muzzle.WorldPosition
			end
		end
		drawTracer(from, endpoint)
		local tool = classTool(character)
		muzzleFlash(from, flashColor(tool and tool.Name))
	end
)

-- Skill moves: when the server confirms one of our skills (the SkillFx broadcast tagged `cast` with us as caster),
-- play its animation from shared SkillVisuals. Played on our own Animator, so it replicates to everyone else. The
-- effects themselves are drawn by SkillEffects.client.luau for every player in the run.

local skillPlays = 0

local function playSkillMove(skillId: any, duration: any)
	local visual = SkillVisuals.forSkill(skillId)
	local t = visual and track(visual.anim)
	if not visual or not t then
		return
	end
	skillPlays += 1
	local play = skillPlays
	t.Looped = false
	t:Stop(0)
	t:Play(0.1)
	local length = if t.Length > 0 then t.Length else 1
	if visual.holdPose and type(duration) == "number" and duration > length then
		-- Freeze on the last (braced) frame for the skill's duration, then let the hold pose back in.
		task.delay(length - 0.05, function()
			if play == skillPlays and t.IsPlaying then
				t:AdjustSpeed(0)
			end
		end)
		task.delay(duration, function()
			if play == skillPlays then
				t:Stop(0.3)
			end
		end)
	else
		-- Blend back into the hold pose instead of snapping from the clip's rest frame.
		task.delay(math.max(0, length - 0.2), function()
			if play == skillPlays and t.IsPlaying then
				t:Stop(0.2)
			end
		end)
	end
end

skillFx.OnClientEvent:Connect(function(fx)
	if type(fx) ~= "table" then
		return
	end
	if fx.kind == "turretShot" and typeof(fx.from) == "Vector3" and typeof(fx.to) == "Vector3" then
		drawTracer(fx.from, fx.to)
	elseif fx.cast == true and fx.caster == player then
		playSkillMove(fx.skill, fx.duration)
	end
end)
