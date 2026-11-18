--!strict
local fs = require("@lune/fs")
local process = require("@lune/process")
local roblox = require("@lune/roblox")

local TMP = "work/spec-extract"

local function contains(s: string, part: string): boolean
	return string.find(s, part, 1, true) ~= nil
end

-- Builds work/spec-extract/<placeName>.rbxl with Workspace.PrefabWorkshop holding the given children.
local function writePlace(placeName: string, children: { { class: string, name: string } }): string
	local game = roblox.Instance.new("DataModel")
	local workshop = roblox.Instance.new("Folder")
	workshop.Name = "PrefabWorkshop"
	workshop.Parent = game:GetService("Workspace")
	for _, c in children do
		local inst = roblox.Instance.new(c.class)
		inst.Name = c.name
		inst.Parent = workshop
	end
	local path = `{TMP}/{placeName}.rbxl`
	fs.writeFile(path, roblox.serializePlace(game))
	return path
end

local function extract(place: string, outDir: string)
	return process.exec("lune", { "run", "tools/extract-prefabs", place, "PrefabWorkshop", outDir })
end

local function files(dir: string): { string }
	local out = if fs.isDir(dir) then fs.readDir(dir) else {}
	table.sort(out)
	return out
end

return function(test: (name: string, fn: () -> ()) -> ())
	local function fresh()
		if fs.isDir(TMP) then
			fs.removeDir(TMP)
		end
		fs.writeDir(TMP)
	end

	test("writes one rbxm per Model and reports skipped children", function()
		fresh()
		local place = writePlace("ok", {
			{ class = "Model", name = "A" },
			{ class = "Model", name = "B" },
			{ class = "Part", name = "Loose" },
		})
		local out = `{TMP}/out-ok`
		local res = extract(place, out)
		assert(res.ok, `exit {res.code}: {res.stderr}{res.stdout}`)
		local got = files(out)
		assert(#got == 2 and got[1] == "A.rbxm" and got[2] == "B.rbxm", `got {table.concat(got, ",")}`)
		assert(contains(res.stdout, "wrote 2 prefabs"), res.stdout)
		assert(contains(res.stdout, "Loose"), `no skip line for Loose: {res.stdout}`)
		fs.removeDir(TMP)
	end)

	test("duplicate Model names write nothing and exit non-zero", function()
		fresh()
		local place = writePlace("dup", {
			{ class = "Model", name = "A" },
			{ class = "Model", name = "A" },
		})
		local out = `{TMP}/out-dup`
		local res = extract(place, out)
		assert(not res.ok, "expected non-zero exit")
		assert(#files(out) == 0, `files were written: {table.concat(files(out), ",")}`)
		assert(contains(res.stdout .. res.stderr, "duplicate"), res.stdout .. res.stderr)
		fs.removeDir(TMP)
	end)

	test("invalid Model names write nothing and exit non-zero", function()
		fresh()
		local place = writePlace("bad", {
			{ class = "Model", name = "Good" },
			{ class = "Model", name = "Old House" },
		})
		local out = `{TMP}/out-bad`
		local res = extract(place, out)
		assert(not res.ok, "expected non-zero exit")
		assert(#files(out) == 0, "files were written")
		assert(contains(res.stdout .. res.stderr, "Old House"), res.stdout .. res.stderr)
		fs.removeDir(TMP)
	end)
end
