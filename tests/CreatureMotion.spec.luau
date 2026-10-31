-- Run with: lune run test   (or lune run tests/CreatureMotion.spec)
local CreatureMotion = require("../src/shared/CreatureMotion")
local Roster = require("../src/shared/Roster")

local function eq(got, want, label)
	assert(got == want, `{label}: got {got}, want {want}`)
end
local function near(got, want, label)
	assert(math.abs(got - want) < 1e-6, `{label}: got {got}, want {want}`)
end

-- gait picks
eq(
	CreatureMotion.gait("Runner", false, "assets/creatures/kenney-graveyard/character-zombie.glb"),
	"walk",
	"zombie walks"
)
eq(CreatureMotion.gait("Runner", false, "assets/creatures/quaternius-cute-monsters/Skull.glb"), "hop", "skull hops")
eq(CreatureMotion.gait("Runner", false, "assets/creatures/quaternius-monsters/Blob_GreenBlob.glb"), "hop", "blob hops")
eq(CreatureMotion.gait("Runner", false, "assets/creatures/kenney-blobs/character-oozi.glb"), "hop", "kenney blob")
eq(CreatureMotion.gait("Runner", false, "assets/creatures/quaternius-easy-enemies/Frog.glb"), "hop", "frog hops")
eq(
	CreatureMotion.gait("Shielder", false, "assets/creatures/quaternius-monsters/Big_Orc_Skull.glb"),
	"walk",
	"orc skull walks"
)
eq(CreatureMotion.gait("Flyer", true, "assets/creatures/quaternius-cute-monsters/Bat.glb"), "fly", "bat flies")
eq(CreatureMotion.gait("Boss", true, "x/Flying_Dragon.glb"), "fly", "flying boss flies")
eq(
	CreatureMotion.gait("Boss", false, "assets/creatures/quaternius-monsters/Big_Frog.glb"),
	"stomp",
	"ground boss stomps"
)
eq(CreatureMotion.gait("Runner", false, nil), "walk", "no model walks")

local counts = { walk = 0, hop = 0, fly = 0, stomp = 0 }
for _, list in Roster.Families do
	for _, c in list do
		local g = CreatureMotion.gait(c.archetype, c.flying, c.model)
		counts[g] += 1
	end
end
assert(counts.hop >= 10 and counts.fly >= 10 and counts.stomp >= 10 and counts.walk > counts.hop, "gait mix")

-- cadence grows with speed and is capped
assert(CreatureMotion.cadence("walk", 5, 3) < CreatureMotion.cadence("walk", 7, 3), "faster walks step faster")
eq(CreatureMotion.cadence("walk", 28, 3), 2.6, "runner cadence capped")
eq(CreatureMotion.cadence("stomp", 0, 10), 0, "standing still")
assert(CreatureMotion.cadence("stomp", 13, 10) < CreatureMotion.cadence("walk", 13, 10), "bosses stomp slower")

-- standing still settles to rest on the ground gaits
for _, g in { "walk", "hop", "stomp" } do
	for _, phase in { 0, 0.3, 0.77 } do
		local p = CreatureMotion.pose(g :: any, phase, 1.2, 3, 0)
		near(p.lift, 0, `{g} rest lift`)
		near(p.pitch, 0, `{g} rest pitch`)
		near(p.roll, 0, `{g} rest roll`)
	end
end

-- hop arc: on the ground at the ends, highest mid-hop
near(CreatureMotion.pose("hop", 0, 0, 3, 1).lift, 0, "hop starts grounded")
near(CreatureMotion.pose("hop", 0.5, 0, 3, 1).lift, 1.5, "hop peak is half the height")
assert(CreatureMotion.pose("hop", 0.2, 0, 3, 1).pitch > 0, "nose up rising")
assert(CreatureMotion.pose("hop", 0.8, 0, 3, 1).pitch < 0, "nose down landing")

-- walk sway alternates and bob never dips below the hitbox centre
assert(CreatureMotion.pose("walk", 0.25, 0, 3, 1).roll > 0, "sway left")
assert(CreatureMotion.pose("walk", 0.75, 0, 3, 1).roll < 0, "sway right")
for i = 0, 20 do
	assert(CreatureMotion.pose("walk", i / 20, 0, 3, 1).lift >= 0, "bob above ground")
end

-- flyers bank into turns and bob without moving
assert(CreatureMotion.pose("fly", 0, 0, 2, 1, 2).roll < CreatureMotion.pose("fly", 0, 0, 2, 1, -2).roll, "bank")
assert(math.abs(CreatureMotion.pose("fly", 0, 0.4, 2, 0).lift) > 0, "hover bob")
assert(math.abs(CreatureMotion.pose("fly", 0, 0, 2, 1, 100).roll) <= 0.55, "bank capped")

-- bars clear the highest pose
assert(CreatureMotion.barLift("hop", 3) >= CreatureMotion.pose("hop", 0.5, 0, 3, 1).lift, "bar above hop")

-- death: upright and opaque at 0, tipped, sunk and gone at 1
local d0, d1 = CreatureMotion.death(0, 3), CreatureMotion.death(1, 3)
near(d0.tip, 0, "starts upright")
near(d0.fade, 0, "starts opaque")
near(d0.sink, 0, "starts on the ground")
near(d1.tip, math.pi / 2, "ends tipped over")
near(d1.fade, 1, "ends faded")
near(d1.sink, 1.8, "ends sunk")
assert(CreatureMotion.death(0.5, 3).tip > CreatureMotion.death(0.2, 3).tip, "tips progressively")

-- hit pulse
near(CreatureMotion.hitPulse(0), 1 + CreatureMotion.HitPulseScale, "pulse peak")
near(CreatureMotion.hitPulse(1), 1, "pulse over")
near(CreatureMotion.hitPulse(-1), 1, "no pulse before a hit")

print("CreatureMotion: ok")
