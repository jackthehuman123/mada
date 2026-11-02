--!strict
-- Scout the Creator Store from any computer, no Studio needed: search free models by keyword, list what each one is
-- (triangles, scripts, votes) and save its thumbnail, so assets can be picked before a Studio session inserts them.
--   lune run tools/art/scout.luau <out-dir> <how-many-per-keyword> "vietnamese house" "old lady" ...
-- Writes <out-dir>/<id>.png and prints a markdown table (paste the good rows into docs/ASSETS.md's shortlist).
-- Uses the public search the Creator Store website uses; it may change without notice.

local fs = require("@lune/fs")
local net = require("@lune/net")
local process = require("@lune/process")
local serde = require("@lune/serde")
local task = require("@lune/task")

local args = process.args
local out = args[1] or "scout"
local per = tonumber(args[2]) or 10
if not fs.isDir(out) then
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

print("| keyword | id | name | creator | tris | scripts | votes (up/down) | thumb |")
print("| --- | --- | --- | --- | --- | --- | --- | --- |")
for i = 3, #args do
	local keyword = args[i]
	local data = get(`https://apis.roblox.com/toolbox-service/v2/assets:search?searchCategoryType=Model&query={url(keyword)}&maxPageSize={per}`)
	local rows = if data then data.creatorStoreAssets or {} else {}
	local ids = {}
	for _, r in rows do
		table.insert(ids, tostring(r.asset.id))
	end
	local thumbs = {}
	if #ids > 0 then
		local t = get(`https://thumbnails.roblox.com/v1/assets?assetIds={table.concat(ids, ",")}&size=420x420&format=Png`)
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
		local name = string.gsub(a.name or "?", "|", "/")
		print(`| {keyword} | {id} | {name} | {r.creator and r.creator.name or "?"} | {tris} | {a.scriptCount or 0} | {v.upVotes or 0}/{v.downVotes or 0} | {thumb} |`)
	end
	task.wait(0.5)
end
