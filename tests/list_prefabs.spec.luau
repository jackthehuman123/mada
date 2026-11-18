--!strict
local fs = require("@lune/fs")
local process = require("@lune/process")

local TMP = "work/spec-list-prefabs"

return function(test: (name: string, fn: () -> ()) -> ())
	test("prints prefab names one per line, sorted, ignoring other files", function()
		if fs.isDir(TMP) then
			fs.removeDir(TMP)
		end
		fs.writeDir(TMP)
		for _, file in { "Shrine.rbxm", "Dock_A.rbxm", ".gitkeep", "notes.txt" } do
			fs.writeFile(`{TMP}/{file}`, "")
		end
		local res = process.exec("lune", { "run", "tools/list-prefabs", TMP })
		fs.removeDir(TMP)
		assert(res.ok, `exit {res.code}: {res.stderr}`)
		assert(res.stdout == "Dock_A\nShrine\n", `got {res.stdout}`)
	end)
end
