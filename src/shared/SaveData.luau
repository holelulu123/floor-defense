-- Turns a saved DataStore table (any older shape, or nil for a new player) into the current player data.
-- Pure so Lune can test the migrations; PlayerData.load calls it and adds the class checks.
--
-- Migrations:
--   * Gems -> Diamonds: the old `Gems` (or `gems`) balance is added to `Diamonds`, nothing is lost.
--   * Level/XP: Level is clamped to 1..Progression.MaxLevel and XP is progress toward the next level,
--     rolled over if a curve change left it above the new requirement.

local Progression = require(script and script.Parent.Progression or "./Progression")

local SaveData = {}

local function deepCopy<T>(value: T): T
	if type(value) ~= "table" then
		return value
	end
	local out = {}
	for k, v in value :: any do
		out[k] = deepCopy(v)
	end
	return out :: any
end

local function number(value: any, fallback: number): number
	return if type(value) == "number" and value == value then value else fallback
end

function SaveData.migrate(saved: any, defaults: { [string]: any }): { [string]: any }
	local data = deepCopy(defaults) -- deep: defaults hold tables (OwnedClasses) that must not be shared
	if type(saved) == "table" then
		for field, value in saved do
			data[field] = deepCopy(value)
		end
	end

	local diamonds = math.max(0, number(data.Diamonds, 0))
	for _, old in { "Gems", "gems" } do
		diamonds += math.max(0, number(data[old], 0))
		data[old] = nil
	end
	data.Diamonds = math.floor(diamonds)

	local level, xp = Progression.addXp(number(data.Level, 1), number(data.XP, 0), 0)
	data.Level = level
	data.XP = xp

	if type(data.ProcessedReceipts) ~= "table" then
		data.ProcessedReceipts = {}
	end
	if type(data.OwnedClasses) ~= "table" then
		data.OwnedClasses = {}
	end
	return data
end

return SaveData
