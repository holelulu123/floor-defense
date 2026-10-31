-- Server-side sky clean-up. Lighting properties, Atmosphere, Bloom and SunRays are defined in default.project.json;
-- the per-zone mood is tweened by Environment.client.luau. Here we only make sure the place file cannot override
-- that: the Studio template's Sky (SkyboxBk rbxassetid://6444884337 and friends) fails to load and paints the sky
-- black, and its DepthOfField blurs the HUD camera view. Any Sky or DepthOfField not marked as ours is removed, and
-- Terrain gets the Clouds the lobby sky uses (the client tweens their cover per zone).

local Lighting = game:GetService("Lighting")

local OURS = "FloorDefense" -- attribute that marks a Sky we created on purpose

local function prune(child: Instance)
	if (child:IsA("Sky") or child:IsA("DepthOfFieldEffect")) and child:GetAttribute(OURS) ~= true then
		warn(`Environment: removing {child.ClassName} "{child.Name}" from Lighting (template leftover)`)
		child:Destroy()
	end
end

for _, child in Lighting:GetChildren() do
	prune(child)
end
Lighting.ChildAdded:Connect(function(child)
	task.defer(prune, child) -- cannot reparent/destroy during the ChildAdded event itself
end)

local terrain = workspace:FindFirstChildOfClass("Terrain")
if terrain and not terrain:FindFirstChildOfClass("Clouds") then
	local clouds = Instance.new("Clouds")
	clouds.Cover = 0.5
	clouds.Density = 0.7
	clouds.Color = Color3.new(1, 1, 1)
	clouds.Parent = terrain
end
