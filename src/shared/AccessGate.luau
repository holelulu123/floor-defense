-- Password gate rules (pure, tested by Lune). The server (src/server/AccessGate.server.luau) holds every new player
-- behind a password box until they type the password kept in the "Access" DataStore; see docs/ROBLOX.md.

local AccessGate = {}

AccessGate.MaxTries = 3 -- wrong answers before the player is kicked
AccessGate.TimeoutSeconds = 120 -- kicked if no right answer by then
AccessGate.MinSecondsBetweenTries = 1
AccessGate.MaxLength = 64
AccessGate.StoreName = "Access"
AccessGate.StoreKey = "password"

-- What the player typed, trimmed; nil for anything that is not a short string.
function AccessGate.clean(input: any): string?
	if type(input) ~= "string" or #input > AccessGate.MaxLength then
		return nil
	end
	local trimmed = input:match("^%s*(.-)%s*$")
	return if trimmed and trimmed ~= "" then trimmed else nil
end

-- Whether `input` matches `password` (case-sensitive, surrounding spaces ignored on both).
function AccessGate.matches(input: any, password: any): boolean
	local a, b = AccessGate.clean(input), AccessGate.clean(password)
	return a ~= nil and b ~= nil and a == b
end

return AccessGate
