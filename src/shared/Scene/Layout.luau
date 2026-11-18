--!strict
export type Entry = { prefab: string, at: { number }, rot: number?, tags: { string }? }

local Layout = {}

local function isNumberList(v: any, n: number?): boolean
	if type(v) ~= "table" then
		return false
	end
	local count = 0
	for _ in v do
		count += 1
	end
	if count ~= #v or (n ~= nil and count ~= n) then
		return false
	end
	for _, x in v do
		if type(x) ~= "number" then
			return false
		end
	end
	return true
end

function Layout.validate(entries: { Entry }, prefabNames: { [string]: boolean }): { string }
	local errs: { string } = {}
	for i, e in entries do
		if type(e.prefab) ~= "string" or not prefabNames[e.prefab] then
			table.insert(errs, `entry {i}: unknown prefab '{tostring(e.prefab)}'`)
		end
		if not isNumberList(e.at, 3) then
			table.insert(errs, `entry {i}: 'at' must be exactly 3 numbers`)
		end
		if e.rot ~= nil and type(e.rot) ~= "number" then
			table.insert(errs, `entry {i}: 'rot' must be a number (degrees)`)
		end
		if e.tags ~= nil then
			local ok = type(e.tags) == "table"
			if ok then
				for _, t in e.tags do
					if type(t) ~= "string" then
						ok = false
					end
				end
			end
			if not ok then
				table.insert(errs, `entry {i}: 'tags' must be a list of strings`)
			end
		end
	end
	return errs
end

return Layout
