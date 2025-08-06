export type Preset = {
	-- Lighting --
	Brightness: number?,
	Ambient: Color3?,
	OutdoorAmbient: Color3?,
	ColorShift: {
		Top: Color3?,
		Bottom: Color3?,
	}?,
	DiffuseScale: number?,
	SpecularScale: number?,
	ShadowSoftness: number?,
	Exposure: number?,
	GlobalShadows: boolean?,
	Time: {
		Clock: number?, -- ClockTime
		Latitude: number?, -- GeographicalLatitude
	}?,
	Fog: {
		Color: Color3?,
		Start: number?,
		End: number?,
	}?,

	-- Sky --
	Sky: {
		Top: string,
		Bottom: string,
		Left: string,
		Right: string,
		Front: string,
		Back: string,
		CelestialBodies: boolean?,
		StarCount: number?,

		Orientation: Vector3,

		Moon: {
			Texture: string?,
			Size: number?,
		}?,
		Sun: {
			Texture: string?,
			Size: number?,
		}?,
	}?,

	-- Atmosphere --
	Atmosphere: {
		Density: number?,
		Offset: number?,
		Color: Color3?,
		Decay: Color3?,
		Glare: number?,
		Haze: number?,
	}?,

	-- Bloom --
	Bloom: {
		Intensity: number?,
		Size: number?,
		Threshold: number?,
	}?,

	-- Depth of Field --
	DepthOfField: {
		FarIntensity: number?,
		FocusDistance: number?,
		InFocusRadius: number?,
		NearIntensity: number?,
	}?,

	-- SunRays --
	SunRays: {
		Intensity: number?,
		Spread: number?,
	}?,

	-- Blur --
	Blur: number?,

	-- Color Correction --
	ColorCorrection: {
		Brightness: number?,
		Contrast: number?,
		Saturation: number?,
		TintColor: Color3?,
	}?,

	ColorGrading: Enum.TonemapperPreset?,
}

return 0
