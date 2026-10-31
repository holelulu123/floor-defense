local Classes = require("../src/shared/Classes")
local Icons = require("../src/shared/Icons")

local function eq(got, want, label)
	assert(got == want, `{label}: got {got}, want {want}`)
end

eq(Icons.skillKey("Arcane Bolt"), "skill_arcane_bolt", "snake_case skill key")
eq(Icons.skillKey("Dash"), "skill_dash", "single word")

-- every key the UI asks for exists (values may still be empty)
for _, name in { "diamonds", "health", "ammo", "reload" } do
	assert(Icons.Ids[name] ~= nil, `missing icon key {name}`)
end
for _, c in Classes.List do
	assert(Icons.Ids["class_" .. c.id] ~= nil, `missing portrait key class_{c.id}`)
	for _, s in c.skills do
		assert(Icons.Ids[Icons.skillKey(s.name)] ~= nil, `missing skill icon key {Icons.skillKey(s.name)}`)
	end
end

-- get: nil for empty or unknown, the id otherwise
eq(Icons.get("nope"), nil, "unknown key")
local saved = Icons.Ids.diamonds
Icons.Ids.diamonds = ""
eq(Icons.get("diamonds"), nil, "empty id")
Icons.Ids.diamonds = "rbxassetid://123"
eq(Icons.get("diamonds"), "rbxassetid://123", "filled id")
Icons.Ids.diamonds = saved

print("Icons.spec: ok")
