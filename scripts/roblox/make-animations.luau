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
type Anim = { loop: boolean, priority: string, keys: { { time: number, pose: Frame } } }

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

local function rot(r: Rot): any
	local d = math.rad
	return CFrame.Angles(0, d(r[2]), 0) * CFrame.Angles(d(r[1]), 0, 0) * CFrame.Angles(0, 0, d(r[3]))
end

-- Builds the pose tree of one keyframe: every keyed joint plus its parents up to HumanoidRootPart.
local function buildKeyframe(time: number, frame: Frame, joints: { string }): any
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
		pose.EasingStyle = Enum.PoseEasingStyle.Cubic
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
		buildKeyframe(key.time, key.pose, joints).Parent = seq
	end
	fs.writeFile(`{OUT}/{name}.rbxm`, roblox.serializeModel({ seq }))
	print(`{OUT}/{name}.rbxm`)
end
