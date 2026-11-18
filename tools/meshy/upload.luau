--!strict
-- Upload checked models to Roblox as Model assets through Open Cloud (docs/MESHY.md step 5), so world-builder can
-- insert them by id in Studio. A human step (CLAUDE.md, docs/GAME.md): it uses Catlyn's account through her API key.
--   setup once: create an Open Cloud API key with Assets read+write (create.roblox.com > Open Cloud > API Keys),
--               then in the shell: ROBLOX_API_KEY=... ROBLOX_CREATOR_USER_ID=<her user id>  (never commit the key)
--   lune run tools/meshy/upload.luau thu_seated [more names...]     (names from art/meshy/manifest.json, status "checked")
-- Writes each asset id into the manifest (status "uploaded"). No key? Use Studio's 3D Importer instead and type the id
-- into the manifest by hand.

local fs = require("@lune/fs")
local net = require("@lune/net")
local process = require("@lune/process")
local serde = require("@lune/serde")
local task = require("@lune/task")

local MANIFEST = "art/meshy/manifest.json"
local KEY = process.env.ROBLOX_API_KEY
local USER = process.env.ROBLOX_CREATOR_USER_ID
assert(KEY and KEY ~= "", "set ROBLOX_API_KEY (Open Cloud key with Assets read+write)")
assert(USER and USER ~= "", "set ROBLOX_CREATOR_USER_ID (the Roblox user id that will own the assets)")

local manifest = serde.decode("json", fs.readFile(MANIFEST)) :: any

local function find(name: string): any
	for _, e in manifest.assets do
		if e.name == name then
			return e
		end
	end
	error(`no "{name}" in {MANIFEST}`)
end

local function upload(e: any): string
	assert(e.status == "checked", `{e.name}: status is "{e.status}", run tools/meshy/check.luau first`)
	local file = fs.readFile(e.file)
	local boundary = "----LangVong" .. tostring(os.time())
	local request = serde.encode("json", {
		assetType = "Model",
		displayName = "LV_" .. e.name,
		description = `Làng Vọng: {e.what}. Generated with Meshy (meshy.ai), CC BY 4.0.`,
		creationContext = { creator = { userId = USER } },
	})
	local body = table.concat({
		`--{boundary}\r\nContent-Disposition: form-data; name="request"\r\nContent-Type: application/json\r\n\r\n{request}\r\n`,
		`--{boundary}\r\nContent-Disposition: form-data; name="fileContent"; filename="{e.name}.glb"\r\nContent-Type: model/gltf-binary\r\n\r\n`,
		file,
		`\r\n--{boundary}--\r\n`,
	})
	local res = net.request({
		url = "https://apis.roblox.com/assets/v1/assets",
		method = "POST",
		headers = { ["x-api-key"] = KEY :: string, ["content-type"] = `multipart/form-data; boundary={boundary}` },
		body = body,
	})
	assert(res.ok, `{e.name}: upload refused ({res.statusCode}): {res.body}`)
	local op = serde.decode("json", res.body) :: any
	local path = op.path or ("operations/" .. tostring(op.operationId))
	for _ = 1, 30 do
		if op.done and op.response and op.response.assetId then
			return tostring(op.response.assetId)
		end
		task.wait(2)
		local poll = net.request({
			url = "https://apis.roblox.com/assets/v1/" .. path,
			headers = { ["x-api-key"] = KEY :: string },
		})
		assert(poll.ok, `{e.name}: polling failed ({poll.statusCode}): {poll.body}`)
		op = serde.decode("json", poll.body)
	end
	error(`{e.name}: Roblox didn't finish processing in 60 s (check create.roblox.com > Creations)`)
end

for _, name in process.args do
	local e = find(name)
	local ok, id = pcall(upload, e)
	if ok then
		e.robloxAssetId = id
		e.status = "uploaded"
		print(`✓ {name} → {id}`)
		fs.writeFile(MANIFEST, serde.encode("json", manifest, true))
	else
		print(`✗ {id}`)
	end
end
