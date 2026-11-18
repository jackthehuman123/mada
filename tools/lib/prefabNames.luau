--!strict
local prefabNames = {}

-- Returns one error string per invalid or duplicated prefab name; empty when all are fine.
-- Names that differ only by case are duplicates: on macOS/Windows they would write the same .rbxm file.
function prefabNames.check(names: { string }): { string }
	local errors: { string } = {}
	local seen: { [string]: string } = {} -- lower-cased name -> first spelling
	local reported: { [string]: boolean } = {}
	for _, name in names do
		local key = string.lower(name)
		if not string.match(name, "^[A-Za-z][A-Za-z0-9_]*$") then
			table.insert(errors, `invalid prefab name '{name}' (use letters, digits, _; start with a letter)`)
		elseif seen[key] then
			if not reported[key] then
				reported[key] = true
				local first = seen[key]
				local detail = if first == name then "" else ` (same as '{first}' ignoring case)`
				table.insert(errors, `duplicate prefab name '{name}'{detail}`)
			end
		else
			seen[key] = name
		end
	end
	return errors
end

return prefabNames
