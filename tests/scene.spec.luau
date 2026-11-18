--!strict
local Layout = require("../src/shared/Scene/Layout")
local Mood = require("../src/shared/Scene/Mood")
local names = { StiltHouse_A = true, Shrine = true }

return function(test)
	test("valid layout has no errors", function()
		local errs = Layout.validate({ { prefab = "Shrine", at = { 0, 4, 30 } } }, names)
		assert(#errs == 0, table.concat(errs, "; "))
	end)
	test("unknown prefab is reported with index and name", function()
		local errs =
			Layout.validate({ { prefab = "Shrine", at = { 0, 0, 0 } }, { prefab = "Shrin", at = { 0, 0, 0 } } }, names)
		assert(#errs == 1 and errs[1]:find("entry 2") and errs[1]:find("Shrin"), errs[1])
	end)
	test("'at' must be exactly 3 numbers", function()
		local errs = Layout.validate({ { prefab = "Shrine", at = { 1, 2 } } }, names)
		assert(#errs == 1 and errs[1]:find("entry 1"), "expected at error")
	end)
	test("mood rejects fogEnd below fogStart and colour over 255", function()
		local errs = Mood.validate({
			clockTime = 2,
			brightness = 1,
			fogStart = 100,
			fogEnd = 50,
			fogColor = { 300, 0, 0 },
			ambient = { 0, 0, 0 },
		})
		assert(#errs == 2, `expected 2 errors, got {#errs}`)
	end)
	test("mood rejects clockTime outside [0, 24)", function()
		local errs = Mood.validate({
			clockTime = 24,
			brightness = 1,
			fogStart = 0,
			fogEnd = 100,
			fogColor = { 0, 0, 0 },
			ambient = { 0, 0, 0 },
		})
		assert(#errs == 1 and errs[1]:find("clockTime"), "expected clockTime error")
	end)
	test("mood clockTime is optional (GameStateService owns time of day in play)", function()
		local errs = Mood.validate({
			brightness = 1,
			fogStart = 0,
			fogEnd = 100,
			fogColor = { 0, 0, 0 },
			ambient = { 0, 0, 0 },
		})
		assert(#errs == 0, table.concat(errs, "; "))
	end)
	test("mood checks optional lighting and atmosphere fields", function()
		local errs = Mood.validate({
			brightness = 1,
			fogStart = 0,
			fogEnd = 100,
			fogColor = { 0, 0, 0 },
			ambient = { 0, 0, 0 },
			outdoorAmbient = { 0, 0, 999 },
			environmentDiffuse = 2,
			atmosphere = { density = 1.5, color = { 1, 2 } },
		} :: any)
		local all = table.concat(errs, "; ")
		assert(#errs == 4, `expected 4 errors, got {#errs}: {all}`)
		assert(all:find("outdoorAmbient") and all:find("environmentDiffuse"), all)
		assert(all:find("atmosphere.density") and all:find("atmosphere.color"), all)
	end)
end
