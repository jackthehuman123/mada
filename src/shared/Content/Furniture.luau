-- Raumania's Blender furniture (tools/blender/furniture.py in the raumania repo; the meshes belong to the Raumania group, like this
-- place): copied from Lotus Valley's Shared/FurnitureMeshes.lua. Per item, its pieces: mesh id, size, centre offset from the foot, colour.
return {
	Altar = {
		{ part = "Fruit", id = "rbxassetid://132188580114509", size = Vector3.new(0.450, 0.340, 0.453), at = Vector3.new(-0.763, 3.080, -0.100), color = Color3.fromRGB(255, 150, 40) },
		{ part = "Gold", id = "rbxassetid://128633682753018", size = Vector3.new(1.375, 0.951, 0.632), at = Vector3.new(-0.372, 3.326, -0.100), color = Color3.fromRGB(226, 184, 72) },
		{ part = "Wood", id = "rbxassetid://137115554490196", size = Vector3.new(2.600, 4.300, 1.400), at = Vector3.new(0.000, 2.150, 0.000), color = Color3.fromRGB(178, 40, 36) },
	},
	Bed = {
		{ part = "Mat", id = "rbxassetid://93977266638856", size = Vector3.new(2.400, 0.400, 3.000), at = Vector3.new(0.000, 1.350, 0.000), color = Color3.fromRGB(214, 190, 120) },
		{ part = "Wood", id = "rbxassetid://136280406839961", size = Vector3.new(2.700, 1.150, 3.300), at = Vector3.new(0.000, 0.575, 0.000), color = Color3.fromRGB(150, 98, 58) },
	},
	Bonsai = {
		{ part = "Leaf", id = "rbxassetid://124727313646104", size = Vector3.new(1.754, 1.085, 1.058), at = Vector3.new(-0.011, 1.732, -0.030), color = Color3.fromRGB(70, 140, 70) },
		{ part = "Pot", id = "rbxassetid://114709099995368", size = Vector3.new(1.400, 0.600, 1.400), at = Vector3.new(0.000, 0.300, 0.000), color = Color3.fromRGB(60, 110, 150) },
		{ part = "Trunk", id = "rbxassetid://109537557846097", size = Vector3.new(0.674, 1.475, 0.386), at = Vector3.new(-0.038, 1.210, 0.028), color = Color3.fromRGB(96, 70, 50) },
	},
	Cabinet = {
		{ part = "Gold", id = "rbxassetid://90346011726284", size = Vector3.new(0.476, 0.400, 0.116), at = Vector3.new(-0.000, 1.900, -0.680), color = Color3.fromRGB(226, 184, 72) },
		{ part = "Wood", id = "rbxassetid://99835443548105", size = Vector3.new(2.600, 3.800, 1.400), at = Vector3.new(0.000, 1.900, 0.000), color = Color3.fromRGB(150, 98, 58) },
	},
	Fan = {
		{ part = "Blades", id = "rbxassetid://138759978134763", size = Vector3.new(1.050, 1.212, 0.400), at = Vector3.new(-0.175, 3.200, -0.300), color = Color3.fromRGB(200, 230, 220) },
		{ part = "Metal", id = "rbxassetid://119465329075138", size = Vector3.new(1.654, 4.024, 1.086), at = Vector3.new(-0.001, 2.012, 0.000), color = Color3.fromRGB(90, 150, 140) },
	},
	FishTank = {
		{ part = "Fish", id = "rbxassetid://79875721526235", size = Vector3.new(1.547, 0.520, 0.374), at = Vector3.new(0.077, 2.250, 0.000), color = Color3.fromRGB(240, 120, 50) },
		{ part = "Glass", id = "rbxassetid://111279461860794", size = Vector3.new(2.300, 1.350, 1.100), at = Vector3.new(0.000, 2.225, 0.000), color = Color3.fromRGB(150, 200, 220) },
		{ part = "Wood", id = "rbxassetid://88106137417281", size = Vector3.new(2.500, 1.550, 1.300), at = Vector3.new(0.000, 0.775, 0.000), color = Color3.fromRGB(96, 58, 34) },
	},
	Lantern = {
		{ part = "Paper", id = "rbxassetid://114447350035466", size = Vector3.new(0.856, 1.215, 0.900), at = Vector3.new(-0.700, 3.050, 0.000), color = Color3.fromRGB(246, 150, 76) },
		{ part = "Wood", id = "rbxassetid://75572979235583", size = Vector3.new(1.420, 3.800, 1.000), at = Vector3.new(-0.210, 1.900, 0.000), color = Color3.fromRGB(96, 58, 34) },
	},
	Radio = {
		{ part = "Front", id = "rbxassetid://99593741918065", size = Vector3.new(0.880, 0.450, 0.160), at = Vector3.new(0.010, 1.675, -0.360), color = Color3.fromRGB(214, 196, 150) },
		{ part = "Wood", id = "rbxassetid://78151286291403", size = Vector3.new(1.200, 2.050, 0.900), at = Vector3.new(0.000, 1.025, 0.000), color = Color3.fromRGB(120, 72, 40) },
	},
	Rug = {
		{ part = "Border", id = "rbxassetid://124275755706346", size = Vector3.new(3.040, 0.030, 3.040), at = Vector3.new(0.000, 0.075, 0.000), color = Color3.fromRGB(178, 40, 36) },
		{ part = "Mat", id = "rbxassetid://76279326947976", size = Vector3.new(2.800, 0.060, 2.800), at = Vector3.new(0.000, 0.030, 0.000), color = Color3.fromRGB(226, 196, 120) },
	},
	TeaTable = {
		{ part = "Ware", id = "rbxassetid://133040164588451", size = Vector3.new(1.159, 0.474, 0.947), at = Vector3.new(0.000, 1.287, 0.000), color = Color3.fromRGB(230, 236, 226) },
		{ part = "Wood", id = "rbxassetid://99371853282749", size = Vector3.new(2.300, 1.050, 1.700), at = Vector3.new(0.000, 0.525, 0.000), color = Color3.fromRGB(96, 58, 34) },
	},
}
