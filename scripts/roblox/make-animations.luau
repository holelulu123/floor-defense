-- Authors the weapon animations as R15 KeyframeSequences and writes one .rbxm per animation to build/animations/.
-- Upload them with `scripts/roblox/import-models.py --animations build/animations/*.rbxm` (ids land in
-- assets/roblox-models.json as Anim_<Name> and in src/shared/ModelIds.luau). The names match
-- src/shared/WeaponMeshes.luau `Animations`; Weapon.client.luau plays them through the Humanoid's Animator.
--
-- Usage: lune run scripts/roblox/make-animations.luau
--
-- Each pose is a Motor6D Transform in the joint's (C0) frame, given as {pitch, yaw, roll} degrees and built as
-- Ry(yaw) * Rx(pitch) * Rz(roll). On R15: +pitch swings an arm forward/up from hanging (and bends an elbow, and leans
-- the upper torso back), +yaw turns toward the character's left, +roll lifts a right arm out to the side.
-- Joints an animation does not key are left to the walk/idle animations (pass-through parent poses have Weight 0).

local fs = require("@lune/fs")
local roblox = require("@lune/roblox")

local CFrame = roblox.CFrame
local Enum = roblox.Enum
local Instance = roblox.Instance

type Rot = { number }
type Frame = { [string]: Rot }
type Anim = { loop: boolean, priority: string, keys: { { time: number, pose: Frame } }, linear: boolean? }

local PARENT = {
	LowerTorso = "HumanoidRootPart",
	UpperTorso = "LowerTorso",
	Head = "UpperTorso",
	RightUpperArm = "UpperTorso",
	RightLowerArm = "RightUpperArm",
	RightHand = "RightLowerArm",
	LeftUpperArm = "UpperTorso",
	LeftLowerArm = "LeftUpperArm",
	LeftHand = "LeftLowerArm",
	RightUpperLeg = "LowerTorso",
	RightLowerLeg = "RightUpperLeg",
	LeftUpperLeg = "LowerTorso",
	LeftLowerLeg = "LeftUpperLeg",
}

-- Copies `base` with `over` laid on top.
local function with(base: Frame, over: Frame): Frame
	local out = table.clone(base)
	for k, v in over do
		out[k] = v
	end
	return out
end

-- Hold poses ----------------------------------------------------------------------------------------------------

-- Two-handed gun: torso turned a little to the right so the left hand reaches the foregrip, right arm straight
-- along the barrel (its yaw cancels the torso's so the gun points ahead), head turned back to face forward.
local RIFLE: Frame = {
	UpperTorso = { 0, -25, 0 },
	Head = { 0, 25, 0 },
	RightUpperArm = { 88, 25, 0 },
	RightLowerArm = { 0, 0, 0 },
	LeftUpperArm = { 78, -22, 0 },
	LeftLowerArm = { 18, 0, 0 },
}
-- Both arms out front, one pistol each, angled in a touch.
local PISTOLS: Frame = {
	RightUpperArm = { 88, 8, 0 },
	RightLowerArm = { 0, 0, 0 },
	LeftUpperArm = { 88, -8, 0 },
	LeftLowerArm = { 0, 0, 0 },
}
-- One-handed blade: forearm raised so the blade stands up and leans forward.
local MELEE: Frame = {
	RightUpperArm = { 25, 0, 10 },
	RightLowerArm = { 55, 0, 0 },
}
-- Two-handed axe across the body, head up.
local HEAVY: Frame = {
	UpperTorso = { 0, -15, 0 },
	RightUpperArm = { 40, 15, 0 },
	RightLowerArm = { 40, 0, 0 },
	LeftUpperArm = { 50, -35, 0 },
	LeftLowerArm = { 45, 0, 0 },
}
-- Staff upright beside the body, forearm level.
local STAFF: Frame = {
	RightUpperArm = { 15, 0, 8 },
	RightLowerArm = { 70, 0, 0 },
}

local function hold(pose: Frame): Anim
	return { loop = true, priority = "Action2", keys = { { time = 0, pose = pose }, { time = 1, pose = pose } } }
end

local ANIMS: { [string]: Anim } = {
	HoldRifle = hold(RIFLE),
	HoldPistols = hold(PISTOLS),
	HoldMelee = hold(MELEE),
	HoldHeavy = hold(HEAVY),
	HoldStaff = hold(STAFF),
	-- Short kick: the muzzle climbs and settles.
	RecoilRifle = {
		loop = false,
		priority = "Action3",
		keys = {
			{ time = 0, pose = RIFLE },
			{
				time = 0.04,
				pose = with(RIFLE, {
					UpperTorso = { 3, -25, 0 },
					RightUpperArm = { 95, 25, 0 },
					LeftUpperArm = { 84, -22, 0 },
				}),
			},
			{ time = 0.15, pose = RIFLE },
		},
	},
	RecoilPistols = {
		loop = false,
		priority = "Action3",
		keys = {
			{ time = 0, pose = PISTOLS },
			{
				time = 0.04,
				pose = with(PISTOLS, {
					RightUpperArm = { 98, 8, 0 },
					RightLowerArm = { 8, 0, 0 },
					LeftUpperArm = { 98, -8, 0 },
					LeftLowerArm = { 8, 0, 0 },
				}),
			},
			{ time = 0.15, pose = PISTOLS },
		},
	},
	-- Overhead diagonal slash: wind up high and out to the right, cut down across to the left hip.
	Swing = {
		loop = false,
		priority = "Action3",
		keys = {
			{ time = 0, pose = with(MELEE, { UpperTorso = { 0, 0, 0 } }) },
			{
				time = 0.1,
				pose = { UpperTorso = { 0, -15, 0 }, RightUpperArm = { 165, 0, 25 }, RightLowerArm = { 35, 0, 0 } },
			},
			{
				time = 0.22,
				pose = { UpperTorso = { 0, 20, 0 }, RightUpperArm = { 45, 45, 0 }, RightLowerArm = { 10, 0, 0 } },
			},
			{ time = 0.35, pose = with(MELEE, { UpperTorso = { 0, 0, 0 } }) },
		},
	},
	-- Two-handed chop: lean back with the axe overhead, then drive it down in front.
	SwingHeavy = {
		loop = false,
		priority = "Action3",
		keys = {
			{ time = 0, pose = HEAVY },
			{
				time = 0.22,
				pose = {
					UpperTorso = { 10, -10, 0 },
					RightUpperArm = { 170, 10, 10 },
					RightLowerArm = { 25, 0, 0 },
					LeftUpperArm = { 170, -20, -10 },
					LeftLowerArm = { 25, 0, 0 },
				},
			},
			{
				time = 0.38,
				pose = {
					UpperTorso = { -20, 15, 0 },
					RightUpperArm = { 35, 15, 0 },
					RightLowerArm = { 5, 0, 0 },
					LeftUpperArm = { 45, -35, 0 },
					LeftLowerArm = { 10, 0, 0 },
				},
			},
			{ time = 0.6, pose = HEAVY },
		},
	},
	-- Staff cast: push the staff out toward the target, hold a beat, draw it back.
	Cast = {
		loop = false,
		priority = "Action3",
		keys = {
			{ time = 0, pose = with(STAFF, { UpperTorso = { 0, 0, 0 } }) },
			{
				time = 0.1,
				pose = { UpperTorso = { -6, 0, 0 }, RightUpperArm = { 75, 5, 0 }, RightLowerArm = { 5, 0, 0 } },
			},
			{
				time = 0.22,
				pose = { UpperTorso = { -6, 0, 0 }, RightUpperArm = { 75, 5, 0 }, RightLowerArm = { 5, 0, 0 } },
			},
			{ time = 0.4, pose = with(STAFF, { UpperTorso = { 0, 0, 0 } }) },
		},
	},
}

-- Skill moves -----------------------------------------------------------------------------------------------------
-- Ported from showcase/index.html makeRigClips ('skill-*'), same timings. The showcase keys each joint as an angle
-- `x` in radians about the joint's X axis (sign -1 on the avatar rig, F = -pi/2 is an arm straight forward) and,
-- for `te` tracks, a twist `y` about the vertical. On our rot() convention that is pitch = -x and yaw = +y (an
-- arm at F is pitch 90, a torso at +x leans forward). Tracks with different key times are sampled linearly at
-- the union of their times (three.js slerps one axis, which is linear in angle). The upper body is always keyed
-- (unkeyed joints at rest) so the class hold pose underneath does not leak into the move; legs are keyed only
-- by moves done standing still (kneel, nova stance) and otherwise stay with the walk. Action4 beats the hold
-- (Action2) and the per-shot recoil (Action3).

type Track = { times: { number }, x: { number }, y: { number }? }

local F = -math.pi / 2
local K = { 0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0 }
local UPPER = { "UpperTorso", "Head", "RightUpperArm", "RightLowerArm", "LeftUpperArm", "LeftLowerArm" }

local function tr(times: { number }, x: { number }): Track
	return { times = times, x = x }
end

-- `te` in the showcase: {x, y} per key.
local function te(times: { number }, xy: { { number } }): Track
	local x, y = {}, {}
	for i, v in xy do
		x[i], y[i] = v[1], v[2]
	end
	return { times = times, x = x, y = y }
end

local function sample(times: { number }, values: { number }, t: number): number
	if t <= times[1] then
		return values[1]
	end
	for i = 2, #times do
		if t <= times[i] then
			local a = (t - times[i - 1]) / math.max(1e-6, times[i] - times[i - 1])
			return values[i - 1] + (values[i] - values[i - 1]) * a
		end
	end
	return values[#values]
end

local function skill(duration: number, tracks: { [string]: Track }): Anim
	local timeSet = { [0] = true, [duration] = true }
	for _, t in tracks do
		for _, time in t.times do
			timeSet[time] = true
		end
	end
	local times = {}
	for time in timeSet do
		if time <= duration then
			table.insert(times, time)
		end
	end
	table.sort(times)
	local keys = {}
	for _, time in times do
		local pose: Frame = {}
		for _, joint in UPPER do
			pose[joint] = { 0, 0, 0 }
		end
		for joint, t in tracks do
			local x = sample(t.times, t.x, time)
			local y = if t.y then sample(t.times, t.y, time) else 0
			pose[joint] = { -math.deg(x), math.deg(y), 0 }
		end
		table.insert(keys, { time = time, pose = pose })
	end
	return { loop = false, priority = "Action4", keys = keys, linear = true }
end

local SKILLS: { [string]: Anim } = {
	-- three quick kicks with the support hand on the gun
	SkillBurst = skill(1.0, {
		RightUpperArm = tr(K, { F, F - 0.45, F, F - 0.45, F, F - 0.45, F, F, F, F, F }),
		LeftUpperArm = tr(
			K,
			{ F + 0.15, F - 0.3, F + 0.15, F - 0.3, F + 0.15, F - 0.3, F + 0.15, F + 0.15, F + 0.15, F + 0.15, F + 0.15 }
		),
		UpperTorso = tr(K, { 0, -0.16, 0, -0.16, 0, -0.16, 0, 0, 0, 0, 0 }),
		Head = tr(K, { 0, -0.12, 0, -0.12, 0, -0.12, 0, 0, 0, 0, 0 }),
	}),
	-- one heavy kick that rocks the whole upper body back
	SkillRecoil = skill(0.8, {
		RightUpperArm = tr({ 0, 0.06, 0.35, 0.8 }, { F, F - 0.7, F + 0.05, F }),
		LeftUpperArm = tr({ 0, 0.06, 0.35, 0.8 }, { F + 0.15, F - 0.5, F + 0.15, F + 0.15 }),
		UpperTorso = tr({ 0, 0.06, 0.35, 0.8 }, { 0, -0.3, 0.05, 0 }),
		Head = tr({ 0, 0.06, 0.4, 0.8 }, { 0, -0.25, 0, 0 }),
	}),
	-- off-hand lob: the gun stays aimed in the right hand while the left winds up and throws
	SkillToss = skill(0.9, {
		RightUpperArm = tr({ 0, 0.9 }, { F, F }),
		LeftUpperArm = tr({ 0, 0.3, 0.45, 0.6, 0.9 }, { 0, -2.9, -2.2, -0.6, 0 }),
		LeftLowerArm = tr({ 0, 0.3, 0.45, 0.6, 0.9 }, { 0, -1.2, -0.3, 0, 0 }),
		UpperTorso = te({ 0, 0.3, 0.55, 0.9 }, { { 0, 0 }, { -0.2, -0.35 }, { 0.3, 0.25 }, { 0, 0 } }),
	}),
	-- full turn with the weapon arm out (the whole body turns on the root joint)
	SkillSpin = skill(0.9, {
		LowerTorso = te(
			{ 0, 0.15, 0.4, 0.65, 0.9 },
			{ { 0, 0 }, { 0, 0.4 }, { 0, 2.4 }, { 0, 4.4 }, { 0, 2 * math.pi } }
		),
		RightUpperArm = tr({ 0, 0.15, 0.75, 0.9 }, { 0, -1.6, -1.6, 0 }),
		LeftUpperArm = tr({ 0, 0.15, 0.75, 0.9 }, { 0, -0.9, -0.9, 0 }),
		UpperTorso = tr({ 0, 0.15, 0.75, 0.9 }, { 0, 0.2, 0.2, 0 }),
	}),
	-- wide horizontal swing: arm up and out, upper body twists across
	SkillCleave = skill(0.8, {
		UpperTorso = te({ 0, 0.3, 0.5, 0.8 }, { { 0, 0 }, { -0.1, 0.9 }, { 0.25, -0.9 }, { 0, 0 } }),
		RightUpperArm = tr({ 0, 0.3, 0.5, 0.8 }, { 0, -2.6, -1.3, 0 }),
		LeftUpperArm = tr({ 0, 0.3, 0.5, 0.8 }, { 0, -1.0, -0.6, 0 }),
	}),
	-- shield arm held across the front, braced (the client freezes the last frame for Iron Wall's duration)
	SkillShield = skill(1.0, {
		LeftUpperArm = tr({ 0, 0.2, 1 }, { 0, -0.4, -0.4 }),
		RightUpperArm = tr({ 0, 0.2, 1 }, { 0, 0.45, 0.45 }),
		UpperTorso = tr({ 0, 0.2, 1 }, { 0, 0.18, 0.18 }),
	}),
	-- leaning sprint burst (legs stay with the run cycle: the dash moves the character)
	SkillDash = skill(0.5, {
		UpperTorso = tr({ 0, 0.1, 0.4, 0.5 }, { 0, 0.55, 0.55, 0 }),
		RightUpperArm = tr({ 0, 0.1, 0.4, 0.5 }, { F, 0.9, 0.9, F }),
		LeftUpperArm = tr({ 0, 0.1, 0.4, 0.5 }, { F, 0.9, 0.9, F }),
	}),
	-- raise the weapon hand overhead and thrust it at the target
	SkillCast = skill(0.9, {
		RightUpperArm = tr({ 0, 0.3, 0.45, 0.6, 0.9 }, { 0, -2.8, -2.8, -1.45, 0 }),
		RightLowerArm = tr({ 0, 0.3, 0.6, 0.9 }, { 0, -0.5, 0, 0 }),
		UpperTorso = tr({ 0, 0.3, 0.6, 0.9 }, { 0, -0.15, 0.2, 0 }),
		LeftUpperArm = tr({ 0, 0.3, 0.6, 0.9 }, { 0, -0.6, 0.3, 0 }),
	}),
	-- both hands up, slam down: area spell
	SkillNova = skill(1.2, {
		RightUpperArm = tr({ 0, 0.4, 0.6, 0.9, 1.2 }, { 0, -3.0, -0.4, -0.4, 0 }),
		LeftUpperArm = tr({ 0, 0.4, 0.6, 0.9, 1.2 }, { 0, -3.0, -0.4, -0.4, 0 }),
		UpperTorso = tr({ 0, 0.4, 0.6, 0.9, 1.2 }, { 0, -0.25, 0.45, 0.45, 0 }),
		RightUpperLeg = tr({ 0, 0.6, 0.9, 1.2 }, { 0, -0.5, -0.5, 0 }),
		LeftUpperLeg = tr({ 0, 0.6, 0.9, 1.2 }, { 0, 0.4, 0.4, 0 }),
	}),
	-- power-up: arms flexed up, chest out, shaking
	SkillRoar = skill(1.2, {
		RightUpperArm = tr(K, { 0, -2.7, -2.85, -2.7, -2.85, -2.7, -2.85, -2.7, -2.85, -1.2, 0 }),
		LeftUpperArm = tr(K, { 0, -2.7, -2.85, -2.7, -2.85, -2.7, -2.85, -2.7, -2.85, -1.2, 0 }),
		RightLowerArm = tr({ 0, 0.2, 0.9, 1.0 }, { 0, -0.35, -0.35, 0 }),
		LeftLowerArm = tr({ 0, 0.2, 0.9, 1.0 }, { 0, -0.35, -0.35, 0 }),
		UpperTorso = tr({ 0, 0.2, 0.9, 1.0 }, { 0, -0.28, -0.28, 0 }),
		Head = tr({ 0, 0.2, 0.9, 1.0 }, { 0, -0.35, -0.35, 0 }),
	}),
	-- steady two-handed aim, head down to the sights, slow sweep
	SkillAim = skill(1.6, {
		UpperTorso = te({ 0, 0.4, 1.2, 1.6 }, { { 0.08, 0 }, { 0.08, 0.25 }, { 0.08, -0.25 }, { 0.08, 0 } }),
		RightUpperArm = tr({ 0, 1.6 }, { F, F }),
		LeftUpperArm = tr({ 0, 1.6 }, { F + 0.12, F + 0.12 }),
		Head = tr({ 0, 1.6 }, { 0.18, 0.18 }),
	}),
	-- sweeping a stream left to right
	SkillSweep = skill(1.5, {
		UpperTorso = te({ 0, 0.35, 1.1, 1.5 }, { { 0, 0 }, { 0.05, 0.7 }, { 0.05, -0.7 }, { 0, 0 } }),
		RightUpperArm = tr({ 0, 0.1, 1.4, 1.5 }, { F, F + 0.1, F + 0.1, F }),
		LeftUpperArm = tr({ 0, 0.1, 1.4, 1.5 }, { F + 0.15, F + 0.2, F + 0.2, F + 0.15 }),
	}),
	-- kneel and set something on the ground (knees bend too, which the blocky showcase dummy lacks)
	SkillPlace = skill(1.0, {
		UpperTorso = tr({ 0, 0.35, 0.65, 1 }, { 0, 0.75, 0.75, 0 }),
		RightUpperArm = tr({ 0, 0.35, 0.65, 1 }, { 0, -1.2, -1.2, 0 }),
		RightUpperLeg = tr({ 0, 0.35, 0.65, 1 }, { 0, -1.1, -1.1, 0 }),
		RightLowerLeg = tr({ 0, 0.35, 0.65, 1 }, { 0, 1.2, 1.2, 0 }),
		LeftUpperLeg = tr({ 0, 0.35, 0.65, 1 }, { 0, 0.6, 0.6, 0 }),
		LeftLowerLeg = tr({ 0, 0.35, 0.65, 1 }, { 0, 0.9, 0.9, 0 }),
	}),
}
for name, anim in SKILLS do
	ANIMS[name] = anim
end

local function rot(r: Rot): any
	local d = math.rad
	return CFrame.Angles(0, d(r[2]), 0) * CFrame.Angles(d(r[1]), 0, 0) * CFrame.Angles(0, 0, d(r[3]))
end

-- Builds the pose tree of one keyframe: every keyed joint plus its parents up to HumanoidRootPart.
local function buildKeyframe(time: number, frame: Frame, joints: { string }, linear: boolean?): any
	local keyframe = Instance.new("Keyframe")
	keyframe.Time = time
	local poses = {}
	local function poseFor(name: string): any
		if poses[name] then
			return poses[name]
		end
		local pose = Instance.new("Pose")
		pose.Name = name
		pose.Weight = 0
		pose.CFrame = CFrame.new()
		pose.EasingStyle = if linear then Enum.PoseEasingStyle.Linear else Enum.PoseEasingStyle.Cubic
		pose.EasingDirection = Enum.PoseEasingDirection.Out
		poses[name] = pose
		local parent = PARENT[name]
		pose.Parent = if parent then poseFor(parent) else keyframe
		return pose
	end
	for _, name in joints do
		local pose = poseFor(name)
		pose.Weight = 1
		pose.CFrame = rot(frame[name] or { 0, 0, 0 })
	end
	return keyframe
end

local OUT = "build/animations"
fs.writeDir(OUT)
local names = {}
for name in ANIMS do
	table.insert(names, name)
end
table.sort(names)
for _, name in names do
	local anim = ANIMS[name]
	-- The same joints in every keyframe, so nothing pops in or out mid-clip.
	local set, joints = {}, {}
	for _, key in anim.keys do
		for joint in key.pose do
			if not set[joint] then
				set[joint] = true
				table.insert(joints, joint)
			end
		end
	end
	table.sort(joints)
	local seq = Instance.new("KeyframeSequence")
	seq.Name = name
	seq.Loop = anim.loop
	seq.Priority = (Enum.AnimationPriority :: any)[anim.priority]
	for _, key in anim.keys do
		buildKeyframe(key.time, key.pose, joints, anim.linear).Parent = seq
	end
	fs.writeFile(`{OUT}/{name}.rbxm`, roblox.serializeModel({ seq }))
	print(`{OUT}/{name}.rbxm`)
end
