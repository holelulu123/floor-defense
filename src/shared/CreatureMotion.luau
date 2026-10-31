-- Procedural creature motion: the imported models are static meshes, so the client poses each one every frame
-- from its replicated position (CreatureVisuals.client). Pure maths, no Roblox API, so Lune can test it.
--
-- Gaits: "walk" bobs and sways with the step rhythm, "hop" jumps in arcs, "fly" floats on a sine and banks into
-- turns, "stomp" (ground bosses) is a heavy, slow walk. Angles are radians: pitch > 0 lifts the nose,
-- roll > 0 leans to the creature's left.

export type Gait = "walk" | "hop" | "fly" | "stomp"

export type Pose = {
	lift: number, -- studs above the hitbox centre
	pitch: number,
	roll: number,
}

export type DeathPose = {
	tip: number, -- radians tipped over (falls on its back)
	sink: number, -- studs below where it died
	fade: number, -- 0 opaque .. 1 gone
}

local CreatureMotion = {}

-- Model files (lower-case basename, or a whole pack) that hop rather than walk: blobs, slimes, skulls, frogs, fish.
CreatureMotion.HopPacks = { ["kenney-blobs"] = true, ["quaternius-cute-fish"] = true }
CreatureMotion.HopFiles = { ["skull.glb"] = true, ["slime.glb"] = true, ["frog.glb"] = true, ["big_fish.glb"] = true }
CreatureMotion.HopPrefixes = { "blob_" }

-- Studs travelled per gait cycle, as a multiple of body height, and the fastest cycle rate (per second) so a
-- 28 stud/s runner does not vibrate.
local STRIDE = { walk = 1.6, hop = 2.4, fly = 3, stomp = 2 }
local MAX_CADENCE = { walk = 2.6, hop = 2.2, fly = 1, stomp = 1.1 }

CreatureMotion.DeathSeconds = 0.6
CreatureMotion.ArriveSeconds = 0.3
CreatureMotion.HitPulseSeconds = 0.15
CreatureMotion.HitPulseScale = 0.15

function CreatureMotion.gait(archetype: string, flying: boolean, modelPath: string?): Gait
	if flying then
		return "fly"
	end
	if archetype == "Boss" then
		return "stomp"
	end
	if type(modelPath) == "string" then
		local pack = modelPath:match("^assets/[^/]+/([^/]+)/")
		local file = (modelPath:match("([^/]+)$") or modelPath):lower()
		if (pack and CreatureMotion.HopPacks[pack]) or CreatureMotion.HopFiles[file] then
			return "hop"
		end
		for _, prefix in CreatureMotion.HopPrefixes do
			if file:sub(1, #prefix) == prefix then
				return "hop"
			end
		end
	end
	return "walk"
end

-- Gait cycles per second at `speed` studs/s for a body `height` studs tall.
function CreatureMotion.cadence(gait: Gait, speed: number, height: number): number
	local stride = math.max(0.5, height * (STRIDE[gait] or STRIDE.walk))
	return math.min(math.max(0, speed) / stride, MAX_CADENCE[gait] or MAX_CADENCE.walk)
end

-- How far up a creature's health bar should sit above its hitbox so a hop or a bob never covers it.
function CreatureMotion.barLift(gait: Gait, height: number): number
	if gait == "hop" then
		return height * 0.5
	elseif gait == "fly" then
		return height * 0.2
	end
	return height * 0.08
end

-- Pose for gait-cycle `phase` (cycles, any real), clock `time` (seconds), body `height`, `moving` in [0, 1]
-- (0 = standing still, e.g. frozen; poses settle to rest) and `turn` (yaw rate, rad/s, for the flyers' bank).
function CreatureMotion.pose(
	gait: Gait,
	phase: number,
	time: number,
	height: number,
	moving: number,
	turn: number?
): Pose
	local m = math.clamp(moving, 0, 1)
	local a = phase * 2 * math.pi
	if gait == "hop" then
		local f = phase % 1
		return {
			lift = 4 * f * (1 - f) * height * 0.5 * m,
			pitch = (0.5 - f) * 0.4 * m, -- nose up on the way up, down on the way in
			roll = 0,
		}
	elseif gait == "fly" then
		local bank = math.clamp(-(turn or 0) * 0.15, -0.5, 0.5)
		return {
			lift = math.sin(time * 2 * math.pi * 0.6) * height * 0.18,
			pitch = -0.1 * m + math.sin(time * 2 * math.pi * 0.6 + 1) * 0.04,
			roll = bank + math.sin(time * 2 * math.pi * 0.35) * 0.05,
		}
	elseif gait == "stomp" then
		local s = math.abs(math.sin(a))
		return {
			lift = s * s * height * 0.05 * m, -- slow rise, hard drop onto each foot
			pitch = (0.03 + s * 0.03) * m,
			roll = math.sin(a) * 0.07 * m,
		}
	end
	return {
		lift = math.abs(math.sin(a)) * height * 0.07 * m, -- two footfalls per cycle
		pitch = -0.05 * m, -- lean into the run
		roll = math.sin(a) * 0.09 * m,
	}
end

-- Death over CreatureMotion.DeathSeconds: `alpha` 0 .. 1. Tips over first, then sinks and fades.
function CreatureMotion.death(alpha: number, height: number): DeathPose
	local t = math.clamp(alpha, 0, 1)
	local fall = math.min(1, t / 0.6)
	return {
		tip = (1 - (1 - fall) * (1 - fall)) * math.pi / 2,
		sink = math.max(0, (t - 0.4) / 0.6) * height * 0.6,
		fade = math.max(0, (t - 0.3) / 0.7),
	}
end

-- Scale multiplier `since` seconds after a hit: a quick swell that eases back to 1.
function CreatureMotion.hitPulse(since: number): number
	if since < 0 or since >= CreatureMotion.HitPulseSeconds then
		return 1
	end
	return 1 + CreatureMotion.HitPulseScale * (1 - since / CreatureMotion.HitPulseSeconds)
end

return CreatureMotion
