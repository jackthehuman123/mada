--!strict
-- A scene's base Lighting as pure data (Lune-testable). SceneLoader applies it; nothing else sets base Lighting.
-- clockTime is only the edit-mode starting value: during play GameStateService owns the time of day.
export type Atmosphere = {
	density: number,
	offset: number?,
	color: { number }?,
	decay: { number }?,
	glare: number?,
	haze: number?,
}

export type Mood = {
	clockTime: number?,
	brightness: number,
	fogStart: number,
	fogEnd: number,
	fogColor: { number },
	ambient: { number },
	outdoorAmbient: { number }?,
	exposure: number?,
	environmentDiffuse: number?,
	environmentSpecular: number?,
	globalShadows: boolean?,
	atmosphere: Atmosphere?,
}

local Mood = {}

local function badColour(c: any): boolean
	if type(c) ~= "table" or #c ~= 3 then
		return true
	end
	for _, x in c do
		if type(x) ~= "number" or x < 0 or x > 255 then
			return true
		end
	end
	return false
end

-- true when v is nil (optional) or a number in [lo, hi]
local function optionalIn(v: any, lo: number, hi: number): boolean
	return v == nil or (type(v) == "number" and v >= lo and v <= hi)
end

local function validateAtmosphere(a: any, errs: { string })
	if type(a) ~= "table" then
		table.insert(errs, "atmosphere: must be a table")
		return
	end
	if type(a.density) ~= "number" or a.density < 0 or a.density > 1 then
		table.insert(errs, "atmosphere.density: must be a number in [0, 1]")
	end
	if not optionalIn(a.offset, 0, 1) then
		table.insert(errs, "atmosphere.offset: must be a number in [0, 1]")
	end
	if a.color ~= nil and badColour(a.color) then
		table.insert(errs, "atmosphere.color: must be 3 numbers in 0-255")
	end
	if a.decay ~= nil and badColour(a.decay) then
		table.insert(errs, "atmosphere.decay: must be 3 numbers in 0-255")
	end
	if not optionalIn(a.glare, 0, 10) then
		table.insert(errs, "atmosphere.glare: must be a number in [0, 10]")
	end
	if not optionalIn(a.haze, 0, 10) then
		table.insert(errs, "atmosphere.haze: must be a number in [0, 10]")
	end
end

function Mood.validate(mood: Mood): { string }
	local errs: { string } = {}
	local t = mood.clockTime
	if t ~= nil and (type(t) ~= "number" or t < 0 or t >= 24) then
		table.insert(errs, "clockTime: must be a number in [0, 24)")
	end
	if type(mood.brightness) ~= "number" then
		table.insert(errs, "brightness: must be a number")
	end
	if type(mood.fogStart) ~= "number" then
		table.insert(errs, "fogStart: must be a number")
	end
	if type(mood.fogEnd) ~= "number" or (type(mood.fogStart) == "number" and mood.fogEnd <= mood.fogStart) then
		table.insert(errs, "fogEnd: must be a number greater than fogStart")
	end
	if badColour(mood.fogColor) then
		table.insert(errs, "fogColor: must be 3 numbers in 0-255")
	end
	if badColour(mood.ambient) then
		table.insert(errs, "ambient: must be 3 numbers in 0-255")
	end
	if mood.outdoorAmbient ~= nil and badColour(mood.outdoorAmbient) then
		table.insert(errs, "outdoorAmbient: must be 3 numbers in 0-255")
	end
	if not optionalIn(mood.exposure, -5, 5) then
		table.insert(errs, "exposure: must be a number in [-5, 5]")
	end
	if not optionalIn(mood.environmentDiffuse, 0, 1) then
		table.insert(errs, "environmentDiffuse: must be a number in [0, 1]")
	end
	if not optionalIn(mood.environmentSpecular, 0, 1) then
		table.insert(errs, "environmentSpecular: must be a number in [0, 1]")
	end
	if mood.globalShadows ~= nil and type(mood.globalShadows) ~= "boolean" then
		table.insert(errs, "globalShadows: must be a boolean")
	end
	if mood.atmosphere ~= nil then
		validateAtmosphere(mood.atmosphere, errs)
	end
	return errs
end

return Mood
