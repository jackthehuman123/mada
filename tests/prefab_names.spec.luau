--!strict
local prefabNames = require("../tools/lib/prefabNames")

local function contains(s: string, part: string): boolean
	return string.find(s, part, 1, true) ~= nil
end

return function(test: (name: string, fn: () -> ()) -> ())
	test("valid unique names give no errors", function()
		assert(#prefabNames.check({ "StiltHouse_A", "Shrine" }) == 0, "expected no errors")
	end)

	test("duplicate names are reported", function()
		local errs = prefabNames.check({ "Shrine", "Shrine" })
		assert(#errs == 1, `expected 1 error, got {#errs}`)
		assert(contains(errs[1], "duplicate") and contains(errs[1], "Shrine"), errs[1])
	end)

	test("invalid names are each reported with the name", function()
		local errs = prefabNames.check({ "2Lantern", "Old House" })
		assert(#errs == 2, `expected 2 errors, got {#errs}`)
		assert(contains(errs[1], "2Lantern"), errs[1])
		assert(contains(errs[2], "Old House"), errs[2])
	end)

	test("names differing only by case are duplicates", function()
		local errs = prefabNames.check({ "Lantern", "lantern" })
		assert(#errs == 1, `expected 1 error, got {#errs}`)
		assert(
			contains(errs[1], "duplicate") and contains(errs[1], "lantern") and contains(errs[1], "Lantern"),
			errs[1]
		)
	end)
end
