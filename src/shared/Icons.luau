-- UI icon asset ids, keyed by name. Fill the values with "rbxassetid://<id>" after uploading the PNGs
-- from assets/ui/icons/ (drawn by scripts/make-icons.py). An empty string means "no icon yet": the UI
-- then keeps its text-only look. Keys: currency and stats, skill_<snake_case skill name>, class_<ClassId>,
-- weapon_<Weapons.luau name>.

local Icons = {}

Icons.Ids = {
	diamonds = "rbxassetid://70824592917420",
	health = "rbxassetid://106034030060762",
	ammo = "rbxassetid://137845073299116",
	reload = "rbxassetid://78345908581049",
	wave = "rbxassetid://138561711626108",
	coins = "rbxassetid://124745264214527",
	score = "rbxassetid://131727180654380",
	kills = "rbxassetid://81073885106445",

	-- class skills (Classes.luau, two per class)
	skill_burst_fire = "rbxassetid://102291000254103",
	skill_ammo_crate = "rbxassetid://93656823461946",
	skill_flail_sweep = "rbxassetid://81009563615840",
	skill_iron_wall = "rbxassetid://89433846502826",
	skill_dash = "rbxassetid://135774125412355",
	skill_mark_target = "rbxassetid://70520446362233",
	skill_repair_pulse = "rbxassetid://77033438763458",
	skill_overcharge = "rbxassetid://100937203016341",
	skill_place_turret = "rbxassetid://83464147591707",
	skill_overclock = "rbxassetid://126974932623982",
	skill_cleave = "rbxassetid://76463841151849",
	skill_rage = "rbxassetid://91967528469182",
	skill_arcane_bolt = "rbxassetid://75087538941583",
	skill_frost_nova = "rbxassetid://129469923881332",
	skill_flame_sweep = "rbxassetid://121712263462907",
	skill_fire_wall = "rbxassetid://119296692733925",
	skill_piercing_shot = "rbxassetid://124565391912819",
	skill_overwatch = "rbxassetid://97302221172149",
	skill_frag_toss = "rbxassetid://107733009848917",
	skill_cluster_bomb = "rbxassetid://78032686647472",

	-- class emblems for the class panel cards
	class_Trooper = "rbxassetid://136051811133902",
	class_Tank = "rbxassetid://138738933904356",
	class_Scout = "rbxassetid://119193975838168",
	class_Medic = "rbxassetid://80065199363180",
	class_Engineer = "rbxassetid://121501499879891",
	class_Berserker = "rbxassetid://110814143150506",
	class_Mage = "rbxassetid://96523481749450",
	class_Pyro = "rbxassetid://121218896294012",
	class_Sniper = "rbxassetid://132670245486532",
	class_Demolisher = "rbxassetid://92946352174441",

	-- weapon icons for the weapon-slot buttons (Weapons.luau names)
	weapon_AssaultRifle = "rbxassetid://129462397216962",
	weapon_Shotgun = "rbxassetid://118605831880404",
	weapon_DualPistols = "rbxassetid://131781241228341",
	weapon_SMG = "rbxassetid://86273041052266",
	weapon_Flamethrower = "rbxassetid://100476003111078",
	weapon_BoltRifle = "rbxassetid://82106259425057",
	weapon_GrenadeLauncher = "rbxassetid://95429321090843",
	weapon_Flail = "rbxassetid://116616482495005",
	weapon_GreatAxe = "rbxassetid://138166515091405",
	weapon_Staff = "rbxassetid://94775707219776",
	weapon_CombatKnife = "rbxassetid://91317598397857",
	weapon_Karambit = "rbxassetid://109439579309447",
	weapon_Scalpel = "rbxassetid://93599633684335",
	weapon_Hammer = "rbxassetid://91138242050833",
	weapon_Sword = "rbxassetid://140390394846870",
	weapon_Dagger = "rbxassetid://118789424760395",
	weapon_Machete = "rbxassetid://136792605181883",
	weapon_Hatchet = "rbxassetid://91528257292807",
} :: { [string]: string }

-- "Arcane Bolt" -> "skill_arcane_bolt".
function Icons.skillKey(skillName: string): string
	return "skill_" .. (skillName:lower():gsub("%W+", "_"))
end

-- Asset id for `name`, or nil when the key is unknown or not filled in yet.
function Icons.get(name: string): string?
	local id = Icons.Ids[name]
	if type(id) ~= "string" or id == "" then
		return nil
	end
	return id
end

return Icons
