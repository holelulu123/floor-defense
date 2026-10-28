-- The objective. Creatures damage it; players repair it; at 0 the run ends.
-- Health is mirrored to a "Health" attribute on the part so the client can read it directly.

local TownHall = {}
TownHall.__index = TownHall

export type TownHall = typeof(setmetatable(
	{} :: { part: Part, health: number, maxHealth: number, destroyed: BindableEvent },
	TownHall
))

function TownHall.new(part: Part, maxHealth: number): TownHall
	local self = setmetatable({
		part = part,
		health = maxHealth,
		maxHealth = maxHealth,
		destroyed = Instance.new("BindableEvent"),
	}, TownHall)
	part:SetAttribute("Health", maxHealth)
	part:SetAttribute("MaxHealth", maxHealth)
	return self
end

function TownHall.isAlive(self: TownHall): boolean
	return self.health > 0
end

function TownHall.takeDamage(self: TownHall, amount: number)
	if not self:isAlive() then
		return
	end
	self.health = math.max(0, self.health - amount)
	self.part:SetAttribute("Health", self.health)
	if self.health == 0 then
		self.part.Color = Color3.fromRGB(60, 50, 40)
		self.destroyed:Fire()
	end
end

function TownHall.repair(self: TownHall, amount: number)
	if not self:isAlive() then
		return
	end
	self.health = math.min(self.maxHealth, self.health + amount)
	self.part:SetAttribute("Health", self.health)
end

function TownHall.destroy(self: TownHall)
	self.destroyed:Destroy()
end

return TownHall
