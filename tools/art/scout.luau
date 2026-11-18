--!strict
-- Scout the Creator Store from any computer, no Studio needed: search free models (or audio) by keyword, list what
-- each one is and save model thumbnails, so assets can be picked before a Studio session inserts them.
--   lune run tools/art/scout.luau <out-dir> <how-many-per-keyword> "vietnamese house" "old lady" ...
--   lune run tools/art/scout.luau <out-dir> <how-many-per-keyword> --audio "horror chase music" ...
-- Models: writes <out-dir>/<id>.png and prints id, name, creator, triangles, scripts, votes.
-- Audio: prints id, title, artist, album, seconds, type, creator (verified licensed uploaders: APM Music,
-- DistrokidOfficial, Monstercat... are usable in any experience). Paste the good rows into docs/ASSETS.md.
-- Uses the public search the Creator Store website uses; it may change without notice.

local fs = require("@lune/fs")
local net = require("@lune/net")
local process = require("@lune/process")
local serde = require("@lune/serde")
local task = require("@lune/task")

local args = process.args
local out = args[1] or "scout"
local per = tonumber(args[2]) or 10
local first = 3
local audio = args[3] == "--audio"
if audio then
	first = 4
end
if not audio and not fs.isDir(out) then
	fs.writeDir(out)
end

local function get(url: string): any?
	local ok, res = pcall(net.request, { url = url, method = "GET" })
	if not ok or not res.ok then
		return nil
	end
	local decoded, data = pcall(serde.decode, "json" :: any, res.body)
	return if decoded then data else nil
end

local function url(s: string): string
	return (string.gsub(s, "[^%w]", function(c)
		return string.format("%%%02X", string.byte(c))
	end))
end

local function clean(s: any): string
	return (string.gsub(tostring(s or ""), "|", "/"))
end

if audio then
	print("| keyword | id | title | artist | album | s | type | creator |")
	print("| --- | --- | --- | --- | --- | --- | --- | --- |")
else
	print("| keyword | id | name | creator | tris | scripts | votes (up/down) | thumb |")
	print("| --- | --- | --- | --- | --- | --- | --- | --- |")
end
for i = first, #args do
	local keyword = args[i]
	local category = if audio then "Audio" else "Model"
	local data = get(
		`https://apis.roblox.com/toolbox-service/v2/assets:search?searchCategoryType={category}&query={url(keyword)}&maxPageSize={per}`
	)
	local rows = if data then data.creatorStoreAssets or {} else {}
	if audio then
		for _, r in rows do
			local a = r.asset
			local who = r.creator and r.creator.name or "?"
			if r.creator and r.creator.verified then
				who ..= " ✓"
			end
			print(
				`| {keyword} | {a.id} | {clean(a.title or a.name)} | {clean(a.artist)} | {clean(a.album)} | {a.durationSeconds or "?"} | {clean(
					a.audioType
				)} | {who} |`
			)
		end
	else
		local ids = {}
		for _, r in rows do
			table.insert(ids, tostring(r.asset.id))
		end
		local thumbs = {}
		if #ids > 0 then
			local t =
				get(`https://thumbnails.roblox.com/v1/assets?assetIds={table.concat(ids, ",")}&size=420x420&format=Png`)
			for _, d in (if t then t.data else {}) do
				if d.state == "Completed" and d.imageUrl then
					thumbs[tostring(d.targetId)] = d.imageUrl
				end
			end
		end
		for _, r in rows do
			local a = r.asset
			local id = tostring(a.id)
			local tris = a.objectMeshSummary and a.objectMeshSummary.triangles or 0
			local v = r.voting or {}
			local thumb = ""
			if thumbs[id] then
				local ok, res = pcall(net.request, thumbs[id])
				if ok and res.ok then
					fs.writeFile(`{out}/{id}.png`, res.body)
					thumb = `{id}.png`
				end
			end
			print(
				`| {keyword} | {id} | {clean(a.name)} | {r.creator and r.creator.name or "?"} | {tris} | {a.scriptCount or 0} | {v.upVotes or 0}/{v.downVotes or 0} | {thumb} |`
			)
		end
	end
	task.wait(0.5)
end
