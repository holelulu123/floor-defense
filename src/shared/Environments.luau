-- Sky and lighting moods, per zone. Pure data so Lune can test it; Environment.client.luau tweens Lighting,
-- the Atmosphere, Terrain Clouds, SunRays and a ColorCorrection to these values (lighting is per client).
-- The lobby is a bright clear day; each dungeon gets the mood of its Roster.Themes entry (the atmosphere
-- colours start from that theme's fog and sky). Colours are RGB 0-255.

export type RGB = { number }

export type Environment = {
	clockTime: number, -- 0-24
	brightness: number, -- Lighting.Brightness, 0-10
	ambient: RGB,
	outdoorAmbient: RGB,
	atmosphere: {
		density: number, -- 0-1
		offset: number, -- 0-1
		color: RGB,
		decay: RGB,
		glare: number, -- 0-10
		haze: number, -- 0-10
	},
	clouds: {
		cover: number, -- 0-1 (0 = clear sky)
		density: number, -- 0-1
		color: RGB,
	},
	sunRays: number, -- SunRays.Intensity, 0-1
	grade: { -- ColorCorrection
		brightness: number, -- -1..1
		contrast: number, -- -1..1
		saturation: number, -- -1..1
		tint: RGB,
	},
}

local Environments = {}

Environments.TweenSeconds = 1.5
-- Lighting.EnvironmentDiffuseScale / EnvironmentSpecularScale. At 1 the sky's light tints every surface (the grey Kenney
-- guns turned baby blue, reds turned pink); at a quarter models keep the colours they have in the showcase.
Environments.SkyLightDiffuse = 0.25
Environments.SkyLightSpecular = 0.3

Environments.Lobby = {
	clockTime = 14,
	brightness = 3,
	ambient = { 110, 110, 120 },
	outdoorAmbient = { 128, 128, 138 },
	atmosphere = {
		density = 0.35,
		offset = 0, -- 0 hazes the horizon itself, hiding where the ground ends (a dark line at offset 0.25)
		color = { 199, 210, 225 },
		decay = { 150, 170, 195 },
		glare = 0,
		haze = 1.6,
	},
	clouds = { cover = 0.5, density = 0.7, color = { 255, 255, 255 } },
	sunRays = 0.1,
	grade = { brightness = 0, contrast = 0.05, saturation = 0.05, tint = { 255, 255, 255 } },
} :: Environment

-- Dungeon id (Dungeons.List) -> mood. The mood lives in the sky, fog and clouds; ambient light and the grade tint stay
-- close to neutral (half way to grey / white) so creatures, props and weapons keep their own colours.
Environments.Dungeons = {
	-- dusk, purple fog
	Graveyard = {
		clockTime = 17.3,
		brightness = 2.2,
		ambient = { 126, 116, 148 },
		outdoorAmbient = { 140, 132, 165 },
		atmosphere = {
			density = 0.45,
			offset = 0.05,
			color = { 120, 90, 160 },
			decay = { 60, 40, 90 },
			glare = 0.2,
			haze = 1.5,
		},
		clouds = { cover = 0.7, density = 0.6, color = { 120, 100, 150 } },
		sunRays = 0.05,
		grade = { brightness = 0, contrast = 0.1, saturation = -0.15, tint = { 240, 232, 255 } },
	},
	-- golden late afternoon
	Farm = {
		clockTime = 17,
		brightness = 2.5,
		ambient = { 126, 118, 115 },
		outdoorAmbient = { 145, 134, 131 },
		atmosphere = {
			density = 0.3,
			offset = 0.05,
			color = { 230, 200, 170 },
			decay = { 160, 110, 120 },
			glare = 0.4,
			haze = 1,
		},
		clouds = { cover = 0.55, density = 0.6, color = { 255, 230, 210 } },
		sunRays = 0.15,
		grade = { brightness = 0, contrast = 0.05, saturation = 0.1, tint = { 255, 248, 240 } },
	},
	-- overcast green murk
	Swamp = {
		clockTime = 15,
		brightness = 2.2,
		ambient = { 116, 126, 116 },
		outdoorAmbient = { 131, 141, 131 },
		atmosphere = {
			density = 0.5,
			offset = 0.05,
			color = { 120, 150, 110 },
			decay = { 60, 80, 60 },
			glare = 0,
			haze = 2.5,
		},
		clouds = { cover = 0.85, density = 0.7, color = { 150, 170, 140 } },
		sunRays = 0,
		grade = { brightness = 0, contrast = 0.05, saturation = -0.1, tint = { 240, 250, 238 } },
	},
	-- dim, damp, close to night
	Sewer = {
		clockTime = 17.3,
		brightness = 2.2,
		ambient = { 117, 120, 114 },
		outdoorAmbient = { 132, 138, 130 },
		atmosphere = {
			density = 0.55,
			offset = 0.05,
			color = { 80, 100, 70 },
			decay = { 30, 36, 30 },
			glare = 0,
			haze = 2,
		},
		clouds = { cover = 0.9, density = 0.8, color = { 90, 95, 90 } },
		sunRays = 0,
		grade = { brightness = 0, contrast = 0.15, saturation = -0.25, tint = { 235, 245, 232 } },
	},
	-- warm morning
	Village = {
		clockTime = 9,
		brightness = 2.8,
		ambient = { 124, 120, 115 },
		outdoorAmbient = { 142, 137, 132 },
		atmosphere = {
			density = 0.28,
			offset = 0.05,
			color = { 220, 200, 180 },
			decay = { 140, 110, 100 },
			glare = 0.3,
			haze = 0.5,
		},
		clouds = { cover = 0.45, density = 0.6, color = { 255, 245, 235 } },
		sunRays = 0.12,
		grade = { brightness = 0, contrast = 0.05, saturation = 0.05, tint = { 255, 250, 244 } },
	},
	-- cold blue haze
	Frozen = {
		clockTime = 12,
		brightness = 2.2,
		ambient = { 128, 138, 154 },
		outdoorAmbient = { 144, 154, 168 },
		atmosphere = {
			density = 0.45,
			offset = 0.05,
			color = { 190, 215, 240 },
			decay = { 110, 140, 180 },
			glare = 0.5,
			haze = 2,
		},
		clouds = { cover = 0.75, density = 0.6, color = { 230, 240, 255 } },
		sunRays = 0.05,
		grade = { brightness = 0, contrast = 0.05, saturation = -0.1, tint = { 240, 246, 255 } },
	},
	-- humid green midday
	Jungle = {
		clockTime = 13,
		brightness = 2.4,
		ambient = { 123, 136, 120 },
		outdoorAmbient = { 138, 150, 134 },
		atmosphere = {
			density = 0.4,
			offset = 0.05,
			color = { 160, 200, 140 },
			decay = { 70, 110, 70 },
			glare = 0.2,
			haze = 1.5,
		},
		clouds = { cover = 0.6, density = 0.7, color = { 240, 250, 235 } },
		sunRays = 0.1,
		grade = { brightness = 0, contrast = 0.05, saturation = 0.15, tint = { 245, 255, 242 } },
	},
	-- sunny sea air
	Pirate = {
		clockTime = 16,
		brightness = 3,
		ambient = { 112, 115, 120 },
		outdoorAmbient = { 132, 135, 140 },
		atmosphere = {
			density = 0.25,
			offset = 0.05,
			color = { 200, 220, 240 },
			decay = { 90, 130, 170 },
			glare = 0.4,
			haze = 0.3,
		},
		clouds = { cover = 0.4, density = 0.6, color = { 255, 255, 255 } },
		sunRays = 0.15,
		grade = { brightness = 0, contrast = 0.05, saturation = 0.1, tint = { 255, 255, 255 } },
	},
	-- smoggy orange
	Factory = {
		clockTime = 17.3,
		brightness = 2.2,
		ambient = { 153, 138, 126 },
		outdoorAmbient = { 172, 152, 141 },
		atmosphere = {
			density = 0.55,
			offset = 0.05,
			color = { 210, 140, 80 },
			decay = { 110, 60, 30 },
			glare = 0.3,
			haze = 2.5,
		},
		clouds = { cover = 0.8, density = 0.8, color = { 160, 120, 90 } },
		sunRays = 0.05,
		grade = { brightness = 0, contrast = 0.1, saturation = -0.1, tint = { 255, 240, 222 } },
	},
	-- dark space: midnight, thin red haze, no clouds so the default sky's stars show
	Station = {
		clockTime = 0,
		brightness = 2.2,
		ambient = { 126, 114, 121 },
		outdoorAmbient = { 146, 130, 130 },
		atmosphere = {
			density = 0.1,
			offset = 0,
			color = { 120, 60, 50 },
			decay = { 20, 10, 24 },
			glare = 0,
			haze = 0,
		},
		clouds = { cover = 0, density = 0, color = { 60, 40, 50 } },
		sunRays = 0,
		grade = { brightness = 0, contrast = 0.1, saturation = 0, tint = { 255, 242, 236 } },
	},
} :: { [string]: Environment }

-- Mood for a player: the dungeon's while in a run, otherwise (or for an unknown id) the lobby's.
function Environments.forZone(inRun: any, dungeonId: any): Environment
	if inRun == true and type(dungeonId) == "string" then
		local env = Environments.Dungeons[dungeonId]
		if env then
			return env
		end
	end
	return Environments.Lobby
end

return Environments
