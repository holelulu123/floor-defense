-- What each class skill looks like on the client: the caster's R15 move (an Anim_<anim> id in ModelIds, authored by
-- scripts/roblox/make-animations.luau from the showcase's makeRigClips 'skill-*' clips) and the effect drawn by
-- src/client/SkillEffects.client.luau (the showcase's skillFx kinds, catalog.js SKILL_FX). Pure data, no Roblox API.
--
-- The server tags every SkillFx broadcast with the skill id; clients look the visuals up here. `holdPose` keeps the
-- move's last frame for the skill's duration (Iron Wall's braced shield).

export type Visual = { anim: string, fx: string, holdPose: boolean? }

local SkillVisuals = {}

-- Every skill animation (build/animations/<name>.rbxm, uploaded as Anim_<name>).
SkillVisuals.Animations = {
	"SkillBurst",
	"SkillRecoil",
	"SkillToss",
	"SkillSpin",
	"SkillCleave",
	"SkillShield",
	"SkillDash",
	"SkillCast",
	"SkillNova",
	"SkillRoar",
	"SkillAim",
	"SkillSweep",
	"SkillPlace",
}

-- Every client effect, one per skill.
SkillVisuals.Effects = {
	"burst",
	"crate",
	"sweep",
	"shield",
	"dash",
	"mark",
	"repair",
	"overcharge",
	"turret",
	"overclock",
	"cleave",
	"rage",
	"arcane",
	"nova",
	"flames",
	"firewall",
	"pierce",
	"laser",
	"grenade",
	"cluster",
}

-- Skill id (Classes.luau) -> visuals. Animations follow each skill's `anim` in showcase/catalog.js.
SkillVisuals.BySkill = {
	BurstFire = { anim = "SkillBurst", fx = "burst" },
	AmmoCrate = { anim = "SkillToss", fx = "crate" },
	FlailSweep = { anim = "SkillSpin", fx = "sweep" },
	IronWall = { anim = "SkillShield", fx = "shield", holdPose = true },
	Dash = { anim = "SkillDash", fx = "dash" },
	MarkTarget = { anim = "SkillAim", fx = "mark" },
	RepairPulse = { anim = "SkillCast", fx = "repair" },
	Overcharge = { anim = "SkillRoar", fx = "overcharge" },
	PlaceTurret = { anim = "SkillPlace", fx = "turret" },
	Overclock = { anim = "SkillCast", fx = "overclock" },
	Cleave = { anim = "SkillCleave", fx = "cleave" },
	Rage = { anim = "SkillRoar", fx = "rage" },
	ArcaneBolt = { anim = "SkillCast", fx = "arcane" },
	FrostNova = { anim = "SkillNova", fx = "nova" },
	FlameSweep = { anim = "SkillSweep", fx = "flames" },
	FireWall = { anim = "SkillToss", fx = "firewall" },
	PiercingShot = { anim = "SkillRecoil", fx = "pierce" },
	Overwatch = { anim = "SkillAim", fx = "laser" },
	FragToss = { anim = "SkillToss", fx = "grenade" },
	ClusterBomb = { anim = "SkillRecoil", fx = "cluster" },
} :: { [string]: Visual }

function SkillVisuals.forSkill(skillId: any): Visual?
	return if type(skillId) == "string" then SkillVisuals.BySkill[skillId] else nil
end

-- Seconds into the move when the effect should start (the showcase delays effects to the throw / slam / thrust
-- moment so the motion reads first). The server applies the effect at once; this is only for drawing.
SkillVisuals.FxDelay = {
	crate = 0.45,
	nova = 0.5,
	firewall = 0.5,
	cleave = 0.25,
	repair = 0.4,
	turret = 0.35,
	overclock = 0.3,
} :: { [string]: number }

function SkillVisuals.fxDelay(fx: string): number
	return SkillVisuals.FxDelay[fx] or 0
end

return SkillVisuals
