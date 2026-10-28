-- Countdown state for one floor pad. Pure: the caller feeds it occupant counts and a clock.
-- Stepping off (occupants < capacity) cancels the countdown.

local PadLogic = {}
PadLogic.__index = PadLogic

export type State = "waiting" | "counting" | "launch"

export type Pad = typeof(setmetatable(
	{} :: { capacity: number, countdown: number, occupants: number, startedAt: number? },
	PadLogic
))

function PadLogic.new(capacity: number, countdown: number): Pad
	assert(capacity >= 1, "capacity must be at least 1")
	return setmetatable({
		capacity = capacity,
		countdown = countdown,
		occupants = 0,
		startedAt = nil,
	}, PadLogic)
end

-- Returns the state and, while counting, the seconds left.
function PadLogic.update(self: Pad, occupants: number, now: number): (State, number?)
	self.occupants = occupants

	if occupants < self.capacity then
		self.startedAt = nil
		return "waiting", nil
	end

	local startedAt = self.startedAt or now
	self.startedAt = startedAt

	local left = self.countdown - (now - startedAt)
	if left <= 0 then
		self.startedAt = nil
		return "launch", 0
	end
	return "counting", left
end

function PadLogic.reset(self: Pad)
	self.startedAt = nil
	self.occupants = 0
end

return PadLogic
