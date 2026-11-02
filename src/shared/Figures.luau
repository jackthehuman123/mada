--!strict
-- Graybox figures built from parts, used both on Bin's tape (client, local only) and in the finale (server).
-- Sen: a small girl in a faded áo bà ba, her hair hiding her face (characters.md: her face is never shown).
-- The lost children: dark silhouettes, as in the drowned festival. Nothing gory, nobody hurt.

local Figures = {}

local rgb = Color3.fromRGB

local function piece(m: Model, name: string, size: Vector3, cf: CFrame, color: Color3, ball: boolean?): BasePart
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored, p.CanCollide, p.CanQuery, p.CastShadow = true, false, false, false
	p.Size = size
	p.Shape = if ball then Enum.PartType.Ball else Enum.PartType.Block
	p.Color = color
	p.Material = Enum.Material.SmoothPlastic
	p.CFrame = cf
	p.Parent = m
	return p
end

-- cf: where she stands, at about the height of the water, facing the way she looks; lookUp tips her head back
function Figures.Sen(cf: CFrame, parent: Instance?, lookUp: number?): Model
	local m = Instance.new("Model")
	m.Name = "Sen"
	local cloth, skin, hair = rgb(86, 96, 100), rgb(150, 150, 146), rgb(12, 12, 14)
	local body = piece(m, "Body", Vector3.new(1.2, 2.2, 0.7), cf * CFrame.new(0, -0.4, 0), cloth)
	piece(m, "ArmL", Vector3.new(0.35, 1.6, 0.35), cf * CFrame.new(-0.8, -0.2, 0), cloth)
	piece(m, "ArmR", Vector3.new(0.35, 1.6, 0.35), cf * CFrame.new(0.8, -0.2, 0), cloth)
	local up = cf * CFrame.new(0, 1.25, 0) * CFrame.Angles(math.rad(lookUp or 18), 0, 0)
	piece(m, "Head", Vector3.new(1, 1, 1), up, skin, true)
	piece(m, "Hair", Vector3.new(1.15, 1.5, 1.1), up * CFrame.new(0, -0.15, -0.05), hair)
	m.PrimaryPart = body
	m.Parent = parent
	return m
end

-- Sen's hand, small and wet, reaching up (Bin's tape); cf: the wrist, pointing the way it reaches
function Figures.Hand(cf: CFrame, parent: Instance?): Model
	local m = Instance.new("Model")
	m.Name = "Hand"
	local skin = rgb(150, 150, 146)
	local palm = piece(m, "Palm", Vector3.new(0.32, 0.4, 0.12), cf * CFrame.new(0, 0.2, 0), skin)
	piece(m, "Wrist", Vector3.new(0.24, 0.7, 0.2), cf * CFrame.new(0, -0.35, 0), rgb(86, 96, 100)) -- her sleeve
	for i = -1, 1 do
		piece(m, "Finger", Vector3.new(0.07, 0.26, 0.07), cf * CFrame.new(i * 0.1, 0.52, 0), skin)
	end
	m.PrimaryPart = palm
	m.Parent = parent
	return m
end

-- one of the lost children (or Bin), a dark silhouette; height in studs (6-12 year olds: 3.4-4.4)
function Figures.Child(cf: CFrame, name: string, height: number, parent: Instance?): Model
	local m = Instance.new("Model")
	m.Name = name
	local dark = rgb(14, 16, 22)
	local body = piece(m, "Body", Vector3.new(1.3, height * 0.62, 0.8), cf * CFrame.new(0, -height * 0.19, 0), dark)
	piece(m, "Head", Vector3.new(height * 0.27, height * 0.27, height * 0.27), cf * CFrame.new(0, height * 0.27, 0), dark, true)
	m.PrimaryPart = body
	m.Parent = parent
	return m
end

return Figures
