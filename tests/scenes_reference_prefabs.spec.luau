--!strict
local fs = require("@lune/fs")

local Layout = require("../src/shared/Scene/Layout")
local Mood = require("../src/shared/Scene/Mood")

local function prefabNames(): { [string]: boolean }
	local names: { [string]: boolean } = {}
	if fs.isDir("assets/prefabs") then
		for _, file in fs.readDir("assets/prefabs") do
			local stem = file:match("^(.+)%.[^.]+$")
			if stem and not file:match("^%.") then
				names[stem] = true
			end
		end
	end
	return names
end

return function(test)
	test("every scene's layout and mood validate", function()
		local names = prefabNames()
		for _, scene in fs.readDir("src/server/Scenes") do
			if not fs.isDir(`src/server/Scenes/{scene}`) then
				continue
			end
			local layout = require(`../src/server/Scenes/{scene}/layout`)
			local mood = require(`../src/server/Scenes/{scene}/mood`)
			local errs = Layout.validate(layout, names)
			for _, e in Mood.validate(mood) do
				table.insert(errs, e)
			end
			assert(#errs == 0, `scene '{scene}': {table.concat(errs, "; ")}`)
		end
	end)
end
