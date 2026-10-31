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

-- The Studio template's Baseplate (2048 x 16 x 2048, top at y = 0) sits exactly at the lobby grass field's height
-- and z-fights with it: the flickering grey-and-green floor seen in Studio. The lobby builds its own ground.
local baseplate = workspace:FindFirstChild("Baseplate")
if baseplate and baseplate:IsA("BasePart") and baseplate.Size.X >= 1000 and baseplate:GetAttribute(OURS) ~= true then
	warn("Environment: removing the template Baseplate (z-fights with the lobby field)")
	baseplate:Destroy()
end

-- Ground to the horizon: beyond the lobby field (radius ~588) the void showed as a black band under the sky. Planes
-- 0.6 studs below the field's top fill it without touching any surface the game builds at y = 0. A Part is capped
-- at 2048 studs a side, so tile a 7 x 7 grid (about 14,000 studs across, past where the atmosphere hides it).
if not workspace:FindFirstChild("HorizonGround") then
	local folder = Instance.new("Folder")
	folder.Name = "HorizonGround"
	for gx = -3, 3 do
		for gz = -3, 3 do
			local ground = Instance.new("Part")
			ground.Name = `Ground{gx}_{gz}`
			ground.Anchored = true
			ground.CanQuery = false
			ground.CanTouch = false
			ground.Size = Vector3.new(2048, 1, 2048)
			ground.Position = Vector3.new(gx * 2048, -1.1, gz * 2048)
			ground.Material = Enum.Material.Grass
			ground.Color = Color3.fromRGB(86, 140, 70)
			ground.TopSurface = Enum.SurfaceType.Smooth
			ground.Parent = folder
		end
	end
	folder:SetAttribute(OURS, true)
	folder.Parent = workspace
end
