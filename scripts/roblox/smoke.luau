-- Cloud smoke test: runs server-side in the published place through the Open Cloud Luau Execution API
-- (scripts/roblox/cloud.py run scripts/roblox/smoke.luau). It must never need a player or the client.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local results = {}
local function check(name, ok, detail)
	table.insert(results, { name = name, ok = ok and true or false, detail = detail and tostring(detail) or nil })
	print((ok and "PASS " or "FAIL ") .. name .. (detail and (": " .. tostring(detail)) or ""))
end

local shared = ReplicatedStorage:FindFirstChild("Shared")
check("Shared folder synced", shared ~= nil)
local server = ServerScriptService:FindFirstChild("Server")
check("Server folder synced", server ~= nil)

if shared then
	for _, name in { "Config", "Dungeons", "Waves", "Classes", "Weapons", "Progression", "PadLogic", "Enemies" } do
		local mod = shared:FindFirstChild(name)
		if not mod then
			check("module " .. name, false, "missing")
		else
			local ok, err = pcall(require, mod)
			check("module " .. name, ok, ok and nil or err)
		end
	end
	local okD, Dungeons = pcall(require, shared.Dungeons)
	if okD then
		local n = 0
		for _ in Dungeons.List do
			n += 1
		end
		check("dungeons listed", n >= 10, n .. " dungeons")
	end
	local okC, Classes = pcall(require, shared.Classes)
	if okC then
		check("classes listed", #Classes.List == 10, #Classes.List .. " classes")
		local canUse, left = Classes.canUse(Classes.List[1].id, 1, {}, 0)
		check("class skill usable when fresh", canUse, left)
	end
	local okW, Waves = pcall(require, shared.Waves)
	if okW then
		check("wave scaling grows", Waves.healthMultiplier(10, "Solo") > Waves.healthMultiplier(1, "Solo"))
	end
end

-- Luau execution sessions do not start the place's own Scripts, so the lobby is never built here; check that the
-- builder is in the place and that the layout rules load instead.
local lobbyModule = server and server:FindFirstChild("Lobby")
check("lobby builder present", lobbyModule ~= nil)
local okLayout, layout = pcall(require, shared and shared:FindFirstChild("LobbyLayout"))
check("lobby layout loads", okLayout and type(layout) == "table", not okLayout and layout or nil)

local fails = 0
for _, r in results do
	if not r.ok then
		fails += 1
	end
end
print(("SMOKE %d checks, %d failed"):format(#results, fails))
return { checks = #results, failed = fails, results = results }
