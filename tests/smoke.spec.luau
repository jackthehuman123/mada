--!strict
return function(test: (name: string, fn: () -> ()) -> ())
	test("arithmetic works", function()
		assert(1 + 1 == 2, "expected 2")
	end)
end
