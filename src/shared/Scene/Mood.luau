--!strict
export type Mood = {
	clockTime: number,
	brightness: number,
	fogStart: number,
	fogEnd: number,
	fogColor: { number },
	ambient: { number },
	atmosphereDensity: number?,
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

function Mood.validate(mood: Mood): { string }
	local errs: { string } = {}
	if type(mood.clockTime) ~= "number" or mood.clockTime < 0 or mood.clockTime >= 24 then
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
	local d = mood.atmosphereDensity
	if d ~= nil and (type(d) ~= "number" or d < 0 or d > 1) then
		table.insert(errs, "atmosphereDensity: must be a number in [0, 1]")
	end
	return errs
end

return Mood
