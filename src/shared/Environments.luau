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

Environments.Lobby = {
	clockTime = 14,
	brightness = 3,
	ambient = { 110, 110, 120 },
	outdoorAmbient = { 128, 128, 138 },
	atmosphere = {
		density = 0.3,
		offset = 0.25,
		color = { 199, 210, 225 },
		decay = { 106, 125, 150 },
		glare = 0,
		haze = 0,
	},
	clouds = { cover = 0.5, density = 0.7, color = { 255, 255, 255 } },
	sunRays = 0.1,
	grade = { brightness = 0, contrast = 0.05, saturation = 0.05, tint = { 255, 255, 255 } },
} :: Environment

-- Dungeon id (Dungeons.List) -> mood.
Environments.Dungeons = {
	-- dusk, purple fog
	Graveyard = {
		clockTime = 17.3,
		brightness = 2.2,
		ambient = { 128, 110, 174 },
		outdoorAmbient = { 142, 125, 192 },
		atmosphere = {
			density = 0.45,
			offset = 0.1,
			color = { 120, 90, 160 },
			decay = { 60, 40, 90 },
			glare = 0.2,
			haze = 1.5,
		},
		clouds = { cover = 0.7, density = 0.6, color = { 120, 100, 150 } },
		sunRays = 0.05,
		grade = { brightness = 0, contrast = 0.1, saturation = -0.15, tint = { 225, 210, 255 } },
	},
	-- golden late afternoon
	Farm = {
		clockTime = 17,
		brightness = 2.5,
		ambient = { 133, 116, 110 },
		outdoorAmbient = { 153, 131, 125 },
		atmosphere = {
			density = 0.3,
			offset = 0.2,
			color = { 230, 200, 170 },
			decay = { 160, 110, 120 },
			glare = 0.4,
			haze = 1,
		},
		clouds = { cover = 0.55, density = 0.6, color = { 255, 230, 210 } },
		sunRays = 0.15,
		grade = { brightness = 0, contrast = 0.05, saturation = 0.1, tint = { 255, 240, 225 } },
	},
	-- overcast green murk
	Swamp = {
		clockTime = 15,
		brightness = 2.2,
		ambient = { 110, 131, 110 },
		outdoorAmbient = { 125, 145, 125 },
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
		grade = { brightness = 0, contrast = 0.05, saturation = -0.1, tint = { 225, 245, 220 } },
	},
	-- dim, damp, close to night
	Sewer = {
		clockTime = 17.3,
		brightness = 2.2,
		ambient = { 115, 122, 110 },
		outdoorAmbient = { 130, 140, 125 },
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
		grade = { brightness = 0, contrast = 0.15, saturation = -0.25, tint = { 215, 235, 210 } },
	},
	-- warm morning
	Village = {
		clockTime = 9,
		brightness = 2.8,
		ambient = { 127, 119, 110 },
		outdoorAmbient = { 147, 136, 125 },
		atmosphere = {
			density = 0.28,
			offset = 0.2,
			color = { 220, 200, 180 },
			decay = { 140, 110, 100 },
			glare = 0.3,
			haze = 0.5,
		},
		clouds = { cover = 0.45, density = 0.6, color = { 255, 245, 235 } },
		sunRays = 0.12,
		grade = { brightness = 0, contrast = 0.05, saturation = 0.05, tint = { 255, 245, 232 } },
	},
	-- cold blue haze
	Frozen = {
		clockTime = 12,
		brightness = 2.2,
		ambient = { 120, 140, 170 },
		outdoorAmbient = { 135, 155, 185 },
		atmosphere = {
			density = 0.45,
			offset = 0.15,
			color = { 190, 215, 240 },
			decay = { 110, 140, 180 },
			glare = 0.5,
			haze = 2,
		},
		clouds = { cover = 0.75, density = 0.6, color = { 230, 240, 255 } },
		sunRays = 0.05,
		grade = { brightness = 0, contrast = 0.05, saturation = -0.1, tint = { 225, 238, 255 } },
	},
	-- humid green midday
	Jungle = {
		clockTime = 13,
		brightness = 2.4,
		ambient = { 116, 141, 110 },
		outdoorAmbient = { 131, 155, 125 },
		atmosphere = {
			density = 0.4,
			offset = 0.15,
			color = { 160, 200, 140 },
			decay = { 70, 110, 70 },
			glare = 0.2,
			haze = 1.5,
		},
		clouds = { cover = 0.6, density = 0.7, color = { 240, 250, 235 } },
		sunRays = 0.1,
		grade = { brightness = 0, contrast = 0.05, saturation = 0.15, tint = { 235, 255, 230 } },
	},
	-- sunny sea air
	Pirate = {
		clockTime = 16,
		brightness = 3,
		ambient = { 110, 115, 125 },
		outdoorAmbient = { 130, 135, 145 },
		atmosphere = {
			density = 0.25,
			offset = 0.25,
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
		ambient = { 165, 134, 110 },
		outdoorAmbient = { 188, 148, 125 },
		atmosphere = {
			density = 0.55,
			offset = 0.2,
			color = { 210, 140, 80 },
			decay = { 110, 60, 30 },
			glare = 0.3,
			haze = 2.5,
		},
		clouds = { cover = 0.8, density = 0.8, color = { 160, 120, 90 } },
		sunRays = 0.05,
		grade = { brightness = 0, contrast = 0.1, saturation = -0.1, tint = { 255, 225, 190 } },
	},
	-- dark space: midnight, thin red haze, no clouds so the default sky's stars show
	Station = {
		clockTime = 0,
		brightness = 2.2,
		ambient = { 133, 110, 124 },
		outdoorAmbient = { 158, 125, 125 },
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
		grade = { brightness = 0, contrast = 0.1, saturation = 0, tint = { 255, 228, 218 } },
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
