return {
	GlobalShadows = true,
	Brightness = 3,
	DiffuseScale = 1,
	Exposure = 0,
	ShadowSoftness = 0.2,
	SpecularScale = 1,
	Atmosphere = {
		Density = 0.3,
		Glare = 0,
		Haze = 0,
		Offset = 0.25,
		Color = Color3.fromRGB(199, 199, 199),
		Decay = Color3.fromRGB(106, 112, 125),
	},
	Bloom = {
		Intensity = 1,
		Size = 24,
		Threshold = 2,
	},
	ColorShift = {
		Bottom = Color3.fromRGB(0, 0, 0),
		Top = Color3.fromRGB(0, 0, 0),
	},
	Sky = {
		CelestialBodies = true,
		StarCount = 3000,
		Back = "rbxassetid://6444884337",
		Bottom = "rbxassetid://6444884785",
		Front = "rbxassetid://6444884337",
		Left = "rbxassetid://6444884337",
		Right = "rbxassetid://6444884337",
		Top = "rbxassetid://6412503613",
		Moon = {
			Size = 11,
			Texture = "rbxassetid://6444320592",
		},
		Sun = {
			Size = 11,
			Texture = "rbxassetid://6196665106",
		},
		Orientation = Vector3.new(0, 0, 0),
	},
	SunRays = {
		Intensity = 0.009,
		Spread = 0.1,
	},
	Time = {
		Clock = 14.5,
		Latitude = 0,
	},
	Ambient = Color3.fromRGB(70, 70, 70),
	OutdoorAmbient = Color3.fromRGB(70, 70, 70),
}
