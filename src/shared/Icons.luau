-- UI icon asset ids, keyed by name. Fill the values with "rbxassetid://<id>" after uploading the PNGs
-- from assets/ui/icons/ (drawn by scripts/make-icons.py). An empty string means "no icon yet": the UI
-- then keeps its text-only look. Keys: currency and stats, skill_<snake_case skill name>, class_<ClassId>.

local Icons = {}

Icons.Ids = {
	diamonds = "rbxassetid://70824592917420",
	health = "rbxassetid://106034030060762",
	ammo = "rbxassetid://137845073299116",
	reload = "rbxassetid://78345908581049",

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

	-- class portraits for the class panel cards
	class_Trooper = "rbxassetid://76869255899252",
	class_Tank = "rbxassetid://82050586769837",
	class_Scout = "rbxassetid://115595999237805",
	class_Medic = "rbxassetid://100478320013051",
	class_Engineer = "rbxassetid://111812228402961",
	class_Berserker = "rbxassetid://95039017655402",
	class_Mage = "rbxassetid://137927440614076",
	class_Pyro = "rbxassetid://94899626630309",
	class_Sniper = "rbxassetid://78604487191719",
	class_Demolisher = "rbxassetid://84069399876006",
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
