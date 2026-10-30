local PadLogic = require("../src/shared/PadLogic")

local function eq(got, want, label)
	assert(got == want, `{label}: got {got}, want {want}`)
end

local pad = PadLogic.new(2, 10)

eq(pad:update(0, 0), "waiting", "empty pad waits")
eq(pad:update(1, 1), "waiting", "one of two waits")

local state, left = pad:update(2, 5)
eq(state, "counting", "full pad counts")
eq(left, 10, "full countdown at start")

state, left = pad:update(2, 9)
eq(state, "counting", "still counting")
eq(left, 6, "4 s elapsed leaves 6")

-- stepping off cancels and the next fill restarts from the top
eq(pad:update(1, 10), "waiting", "step off cancels")
state, left = pad:update(2, 20)
eq(state, "counting", "refilled pad counts again")
eq(left, 10, "countdown restarted")

state, left = pad:update(2, 30)
eq(state, "launch", "countdown reached zero launches")
eq(left, 0, "no time left on launch")

-- after launch the pad is idle until refilled
eq(pad:update(2, 31), "counting", "pad counts again after launch if still full")

-- more occupants than capacity still counts as full
local solo = PadLogic.new(1, 5)
eq(solo:update(3, 0), "counting", "overfull pad still counts")

-- every generated lobby pad produces a working countdown with its own capacity and countdown
local LobbyLayout = require("../src/shared/LobbyLayout")
for _, def in LobbyLayout.pads() do
	local p = PadLogic.new(def.capacity, def.countdown)
	eq(p:update(def.capacity - 1, 0), "waiting", `{def.dungeonId}/{def.mode} short one waits`)
	local s, l = p:update(def.capacity, 0)
	eq(s, "counting", `{def.dungeonId}/{def.mode} full counts`)
	eq(l, def.countdown, `{def.dungeonId}/{def.mode} full countdown`)
	eq(p:update(def.capacity, def.countdown), "launch", `{def.dungeonId}/{def.mode} launches on time`)
end
print("PadLogic.spec: ok")
