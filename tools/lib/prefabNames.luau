--!strict
local prefabNames = {}

-- Returns one error string per invalid or duplicated prefab name; empty when all are fine.
function prefabNames.check(names: { string }): { string }
	local errors: { string } = {}
	local seen: { [string]: boolean } = {}
	local reported: { [string]: boolean } = {}
	for _, name in names do
		if not string.match(name, "^[A-Za-z][A-Za-z0-9_]*$") then
			table.insert(errors, `invalid prefab name '{name}' (use letters, digits, _; start with a letter)`)
		elseif seen[name] then
			if not reported[name] then
				reported[name] = true
				table.insert(errors, `duplicate prefab name '{name}'`)
			end
		end
		seen[name] = true
	end
	return errors
end

return prefabNames
