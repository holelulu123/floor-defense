local SaveData = require("../src/shared/SaveData")

local function eq(got, want, label)
	assert(got == want, `{label}: got {got}, want {want}`)
end

local defaults = { Diamonds = 0, Level = 1, XP = 0, BestScoreSolo = 0, OwnedClasses = {}, Mastery = {} }

-- new player
local fresh = SaveData.migrate(nil, defaults)
eq(fresh.Diamonds, 0, "new player diamonds")
eq(fresh.Level, 1, "new player level")
eq(fresh.XP, 0, "new player xp")
assert(type(fresh.ProcessedReceipts) == "table", "receipts table")
table.insert(fresh.OwnedClasses, "Mage")
eq(#defaults.OwnedClasses, 0, "defaults are copied, not shared between players")
eq(#SaveData.migrate(nil, defaults).OwnedClasses, 0, "next new player starts with no classes")

-- Gems -> Diamonds, no loss
local old = SaveData.migrate({ Gems = 1250, Level = 4, OwnedClasses = { "Pyro" }, BestScoreSolo = 900 }, defaults)
eq(old.Diamonds, 1250, "old gems become diamonds")
eq(old.Gems, nil, "gems field removed")
eq(old.Level, 4, "level kept")
eq(old.XP, 0, "xp defaults to 0")
eq(old.OwnedClasses[1], "Pyro", "owned classes kept")
eq(old.BestScoreSolo, 900, "scores kept")
eq(SaveData.migrate({ gems = 30 }, defaults).Diamonds, 30, "lowercase gems too")
eq(SaveData.migrate({ Gems = 30, Diamonds = 12 }, defaults).Diamonds, 42, "both fields are added")
eq(SaveData.migrate({ Diamonds = 77 }, defaults).Diamonds, 77, "already migrated data is unchanged")
local again = SaveData.migrate(SaveData.migrate({ Gems = 5 }, defaults), defaults)
eq(again.Diamonds, 5, "migrating twice does not double")

-- bad or out-of-range values
local bad = SaveData.migrate({ Level = 99, XP = -4, Gems = "lots", OwnedClasses = "x" }, defaults)
eq(bad.Level, 20, "level clamped to the max")
eq(bad.XP, 0, "negative xp clamped")
eq(bad.Diamonds, 0, "non-number gems ignored")
eq(type(bad.OwnedClasses), "table", "owned classes repaired")
local over = SaveData.migrate({ Level = 1, XP = 150 }, defaults)
eq(over.Level, 2, "over-full xp rolls into a level")
eq(over.XP, 50, "remaining xp")

print("SaveData.spec: ok")
