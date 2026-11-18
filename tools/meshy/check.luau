--!strict
-- Check a generated model before it goes to Roblox (docs/MESHY.md step 4). Reads a .glb, prints triangles, meshes,
-- size and textures, and says whether Roblox will take it.
--   lune run tools/meshy/check.luau art/meshy/in/thu_seated.glb [more.glb ...]
-- With the manifest entry's name as the file name (art/meshy/manifest.json), it also writes tris/size into it.
-- Limits: Roblox refuses meshes over ~20k triangles per MeshPart (aim for under 10k), Open Cloud uploads up to 20 MB.

local fs = require("@lune/fs")
local process = require("@lune/process")
local serde = require("@lune/serde")

local MAX_TRIS, GOOD_TRIS, MAX_BYTES = 20000, 10000, 20 * 1024 * 1024
local MANIFEST = "art/meshy/manifest.json"

type Report = { ok: boolean, tris: number, meshes: number, size: { number }, images: { string }, notes: { string } }

local function u32(b: buffer, at: number): number
	return buffer.readu32(b, at)
end

local function check(path: string): Report
	local raw = fs.readFile(path)
	local b = buffer.fromstring(raw)
	local notes = {}
	assert(buffer.len(b) >= 20 and buffer.readstring(b, 0, 4) == "glTF", `{path}: not a .glb (binary glTF)`)
	local jsonLen = u32(b, 12)
	assert(buffer.readstring(b, 16, 4) == "JSON", `{path}: first chunk isn't JSON`)
	local gltf = serde.decode("json", buffer.readstring(b, 20, jsonLen)) :: any
	local binStart = 20 + jsonLen + 8 -- the BIN chunk's data, after its 8-byte header

	local tris, meshes = 0, 0
	local lo, hi = { math.huge, math.huge, math.huge }, { -math.huge, -math.huge, -math.huge }
	for _, mesh in gltf.meshes or {} do
		meshes += 1
		for _, prim in mesh.primitives or {} do
			local mode = prim.mode or 4
			local acc = if prim.indices ~= nil
				then gltf.accessors[prim.indices + 1]
				else gltf.accessors[prim.attributes.POSITION + 1]
			if mode == 4 then
				tris += math.floor(acc.count / 3)
			elseif mode == 5 or mode == 6 then
				tris += acc.count - 2
			else
				table.insert(notes, "a primitive that isn't triangles (lines/points)")
			end
			local pos = gltf.accessors[prim.attributes.POSITION + 1]
			if pos.min and pos.max then
				for i = 1, 3 do
					lo[i] = math.min(lo[i], pos.min[i])
					hi[i] = math.max(hi[i], pos.max[i])
				end
			end
		end
	end
	local size = { 0, 0, 0 }
	for i = 1, 3 do
		size[i] = if hi[i] > lo[i] then math.floor((hi[i] - lo[i]) * 100 + 0.5) / 100 else 0
	end

	local images = {}
	for _, img in gltf.images or {} do
		local kind = img.mimeType or "?"
		if img.bufferView ~= nil and kind == "image/png" then
			local view = gltf.bufferViews[img.bufferView + 1]
			local at = binStart + (view.byteOffset or 0)
			local w = bit32.byteswap(u32(b, at + 16))
			local h = bit32.byteswap(u32(b, at + 20))
			kind = `png {w}x{h}`
			if w > 1024 or h > 1024 then
				table.insert(notes, `texture {w}x{h}: Roblox shows it at 1024 at most`)
			end
		end
		table.insert(images, kind)
	end

	local ok = true
	if tris > MAX_TRIS then
		ok = false
		table.insert(
			notes,
			`{tris} triangles: over Roblox's ~{MAX_TRIS} per mesh. Decimate it (docs/MESHY.md) or split it`
		)
	elseif tris > GOOD_TRIS then
		table.insert(notes, `{tris} triangles: imports, but heavy for a prop used many times`)
	end
	if #raw > MAX_BYTES then
		ok = false
		table.insert(notes, `{#raw // 1048576} MB: over Open Cloud's 20 MB (use Studio's 3D Importer, or shrink it)`)
	end
	if #(gltf.nodes or {}) > 0 then
		for _, n in gltf.nodes do
			if n.scale or n.matrix then
				table.insert(notes, "a node has its own transform (scale/rotation): the size above is before it")
				break
			end
		end
	end
	return { ok = ok, tris = tris, meshes = meshes, size = size, images = images, notes = notes }
end

local manifest: any = nil
if fs.isFile(MANIFEST) then
	manifest = serde.decode("json", fs.readFile(MANIFEST))
end
local changed = false
local failed = false

for _, path in process.args do
	local ok, r = pcall(check, path)
	if not ok then
		print(`✗ {path}: {r}`)
		failed = true
		continue
	end
	local rep = r :: Report
	local name = string.match(path, "([^/\\]+)%.glb$") or path
	print(
		`{if rep.ok then "✓" else "✗"} {name}: {rep.tris} tris in {rep.meshes} mesh(es), size {rep.size[1]} x {rep.size[2]} x {rep.size[3]} (file units, usually metres), textures: {if #rep.images
				> 0
			then table.concat(rep.images, ", ")
			else "none"}`
	)
	for _, n in rep.notes do
		print("    - " .. n)
	end
	failed = failed or not rep.ok
	if manifest then
		for _, entry in manifest.assets do
			if entry.name == name then
				entry.tris = rep.tris
				entry.fileSize = rep.size
				entry.file = path
				if entry.status == "generated" or entry.status == "queued" then
					entry.status = if rep.ok then "checked" else "too heavy"
				end
				changed = true
			end
		end
	end
end
if changed then
	fs.writeFile(MANIFEST, serde.encode("json", manifest, true))
	print(`updated {MANIFEST}`)
end
process.exit(if failed then 1 else 0)
