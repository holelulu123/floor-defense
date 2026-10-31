local Classes = require("../src/shared/Classes")
local ModelIds = require("../src/shared/ModelIds")
local SkillVisuals = require("../src/shared/SkillVisuals")
local Skills = require("../src/shared/Skills")

local function eq(got, want, label)
	assert(got == want, `{label}: got {tostring(got)}, want {tostring(want)}`)
end

local function set(list)
	local out = {}
	for _, v in list do
		assert(not out[v], `duplicate {v}`)
		out[v] = true
	end
	return out
end

local anims = set(SkillVisuals.Animations)
local effects = set(SkillVisuals.Effects)

-- showcase/catalog.js: each skill's anim and SKILL_FX kind
local SHOWCASE = {
	BurstFire = { "SkillBurst", "burst" },
	AmmoCrate = { "SkillToss", "crate" },
	FlailSweep = { "SkillSpin", "sweep" },
	IronWall = { "SkillShield", "shield" },
	Dash = { "SkillDash", "dash" },
	MarkTarget = { "SkillAim", "mark" },
	RepairPulse = { "SkillCast", "repair" },
	Overcharge = { "SkillRoar", "overcharge" },
	PlaceTurret = { "SkillPlace", "turret" },
	Overclock = { "SkillCast", "overclock" },
	Cleave = { "SkillCleave", "cleave" },
	Rage = { "SkillRoar", "rage" },
	ArcaneBolt = { "SkillCast", "arcane" },
	FrostNova = { "SkillNova", "nova" },
	FlameSweep = { "SkillSweep", "flames" },
	FireWall = { "SkillToss", "firewall" },
	PiercingShot = { "SkillRecoil", "pierce" },
	Overwatch = { "SkillAim", "laser" },
	FragToss = { "SkillToss", "grenade" },
	ClusterBomb = { "SkillRecoil", "cluster" },
}

local count, usedFx, usedAnim = 0, {}, {}
for _, c in Classes.List do
	for i, s in c.skills do
		count += 1
		local v = SkillVisuals.forSkill(s.id)
		assert(v, `{s.id} has visuals`)
		assert(anims[v.anim], `{s.id} animation {v.anim} is listed`)
		assert(effects[v.fx], `{s.id} effect {v.fx} is listed`)
		assert(ModelIds["Anim_" .. v.anim], `{s.id} animation Anim_{v.anim} is uploaded`)
		eq(v.anim, SHOWCASE[s.id][1], `{s.id} animation matches the showcase`)
		eq(v.fx, SHOWCASE[s.id][2], `{s.id} effect matches the showcase`)
		assert(not usedFx[v.fx], `{s.id} effect {v.fx} is its own`)
		usedFx[v.fx] = true
		usedAnim[v.anim] = true
		assert(Skills.effectFor(c.id, i), `{s.id} has a server effect`)
		assert(SkillVisuals.fxDelay(v.fx) >= 0 and SkillVisuals.fxDelay(v.fx) < 1, `{s.id} fx delay under a second`)
	end
end
eq(count, 20, "20 skills")
for name in effects do
	assert(usedFx[name], `effect {name} is used by a skill`)
end
for name in anims do
	assert(usedAnim[name], `animation {name} is used by a skill`)
end
eq(SkillVisuals.forSkill("Nope"), nil, "unknown skill")
eq(SkillVisuals.forSkill(42), nil, "junk skill id")
eq(SkillVisuals.BySkill.IronWall.holdPose, true, "Iron Wall holds the braced pose")

print("SkillVisuals: ok")
