local HealthBar = require("../src/shared/HealthBar")

local function eq(got, want, label)
	assert(got == want, `{label}: got {got}, want {want}`)
end

local function rgb(fraction: number, want: { number }, label)
	local r, g, b = HealthBar.color(fraction)
	eq(r, want[1], label .. " r")
	eq(g, want[2], label .. " g")
	eq(b, want[3], label .. " b")
end

-- fraction clamps and guards bad input
eq(HealthBar.fraction(50, 100), 0.5, "half")
eq(HealthBar.fraction(150, 100), 1, "overheal clamps to 1")
eq(HealthBar.fraction(-5, 100), 0, "negative clamps to 0")
eq(HealthBar.fraction(10, 0), 0, "zero max is empty")
eq(HealthBar.fraction(nil, 100), 0, "missing health is empty")
eq(HealthBar.fraction(10, nil), 0, "missing max is empty")
eq(HealthBar.fraction(0 / 0, 100), 0, "NaN health is empty")

-- colour stops
rgb(1, HealthBar.Green, "full is green")
rgb(0.5, HealthBar.Yellow, "half is yellow")
rgb(0, HealthBar.Red, "empty is red")
rgb(2, HealthBar.Green, "above 1 clamps to green")
rgb(-1, HealthBar.Red, "below 0 clamps to red")

-- colour moves monotonically: green channel falls from yellow to red, red channel rises from green to yellow
local _, gQuarter = HealthBar.color(0.25)
assert(gQuarter < HealthBar.Yellow[2] and gQuarter > HealthBar.Red[2], "quarter is between red and yellow")
local rThreeQ = HealthBar.color(0.75)
assert(rThreeQ < HealthBar.Yellow[1] and rThreeQ > HealthBar.Green[1], "three quarters is between yellow and green")

-- label
eq(HealthBar.label(1250, 2000), "1,250 / 2,000", "thousands separators")
eq(HealthBar.label(0.2, 100), "1 / 100", "a sliver rounds up")
eq(HealthBar.label(-3, 100), "0 / 100", "negative shows 0")
eq(HealthBar.label(nil, nil), "0 / 0", "missing values")
eq(HealthBar.label(1000000, 1000000), "1,000,000 / 1,000,000", "millions")
eq(HealthBar.label(999, 999), "999 / 999", "no separator under 1000")

-- visibility
eq(HealthBar.shouldShow(1, true), false, "full creature bar hides")
eq(HealthBar.shouldShow(0.99, true), true, "damaged creature bar shows")
eq(HealthBar.shouldShow(1, false), true, "always-on bar shows at full")

print("HealthBar: ok")
