-- Services:
local Lighting = game:GetService("Lighting")

-- Modules:
local Types = require(script.Parent.Parent.Types)
local PrettyPrint = require(script.Parent.PrettyPrint)

-- Types:
type Preset = Types.Preset

-- Variables:
local Deserializers = {
	Lighting = function(Ref: Lighting, Preset: Preset)
		Preset.Brightness = Ref.Brightness
		Preset.Ambient = Ref.Ambient
		Preset.OutdoorAmbient = Ref.OutdoorAmbient
		Preset.ColorShift = {
			Top = Ref.ColorShift_Top,
			Bottom = Ref.ColorShift_Bottom,
		}
		Preset.DiffuseScale = Ref.EnvironmentDiffuseScale
		Preset.SpecularScale = Ref.EnvironmentSpecularScale
		Preset.ShadowSoftness = Ref.ShadowSoftness
		Preset.Exposure = Ref.ExposureCompensation
		Preset.GlobalShadows = Ref.GlobalShadows
		Preset.Time = {
			Clock = Ref.ClockTime,
			Latitude = Ref.GeographicLatitude,
		}
		Preset.Fog = {
			Color = Ref.FogColor,
			Start = Ref.FogStart,
			End = Ref.FogEnd,
		}
	end,
	Sky = function(Ref: Sky, Preset: Preset)
		Preset.Sky = {
			Top = Ref.SkyboxUp,
			Bottom = Ref.SkyboxDn,
			Left = Ref.SkyboxLf,
			Right = Ref.SkyboxRt,
			Front = Ref.SkyboxFt,
			Back = Ref.SkyboxBk,
			CelestialBodies = Ref.CelestialBodiesShown,
			StarCount = Ref.StarCount,

			Orientation = Ref.SkyboxOrientation,

			Moon = Ref.CelestialBodiesShown and {
				Texture = Ref.MoonTextureId,
				Size = Ref.MoonAngularSize,
			} or nil,

			Sun = Ref.CelestialBodiesShown and {
				Texture = Ref.SunTextureId,
				Size = Ref.SunAngularSize,
			} or nil,
		}
	end,
	Atmosphere = function(Ref: Atmosphere, Preset: Preset)
		Preset.Atmosphere = {
			Density = Ref.Density,
			Offset = Ref.Offset,
			Color = Ref.Color,
			Decay = Ref.Decay,
			Glare = Ref.Glare,
			Haze = Ref.Haze,
		}

		Preset.Fog = nil --> Atmosphere 'cancels out' fog to my knowledge
	end,
	Bloom = function(Ref: BloomEffect, Preset: Preset)
		if not Ref.Enabled then
			return
		end

		Preset.Bloom = {
			Intensity = Ref.Intensity,
			Size = Ref.Size,
			Threshold = Ref.Threshold,
		}
	end,
	DepthOfField = function(Ref: DepthOfFieldEffect, Preset: Preset)
		if not Ref.Enabled then
			return
		end

		Preset.DepthOfField = {
			FarIntensity = Ref.FarIntensity,
			FocusDistance = Ref.FocusDistance,
			InFocusRadius = Ref.InFocusRadius,
			NearIntensity = Ref.NearIntensity,
		}
	end,
	SunRays = function(Ref: SunRaysEffect, Preset: Preset)
		if not Ref.Enabled then
			return
		end

		Preset.SunRays = {
			Intensity = Ref.Intensity,
			Spread = Ref.Spread,
		}
	end,
	Blur = function(Ref: BlurEffect, Preset: Preset)
		if not Ref.Enabled then
			return
		end

		Preset.Blur = Ref.Size
	end,
	ColorCorrection = function(Ref: ColorCorrectionEffect, Preset: Preset)
		if not Ref.Enabled then
			return
		end

		Preset.ColorCorrection = {
			Brightness = Ref.Brightness,
			Contrast = Ref.Contrast,
			Saturation = Ref.Saturation,
			TintColor = Ref.TintColor,
		}
	end,
	ColorGrading = function(Ref: ColorGradingEffect, Preset: Preset)
		if not Ref.Enabled then
			return
		end

		Preset.ColorGrading = Ref.TonemapperPreset
	end,
}

-- Main Module:
local PresetHelper = {}

function PresetHelper.Create()
	local Preset: Preset = {}

	Deserializers.Lighting(Lighting, Preset)

	for _, Child in Lighting:GetChildren() do
		local ClassName = Child.ClassName

		if ClassName:match("Effect$") then
			ClassName = ClassName:sub(1, -7) --> Imo having this in the code would be dumb
		end

		if not Deserializers[ClassName] then
			warn(`[Preset.Create]: {ClassName} is not parseable`)
			continue
		end

		Deserializers[ClassName](Child, Preset)
	end

	return Preset
end

function PresetHelper.Apply(Preset: Preset, SkyOnly: boolean?)
	do -- Skybox:
		local Skybox = Preset.Sky
		local SkyboxRef = Lighting:FindFirstChild("Sky") :: Sky?

		if Skybox then
			if not SkyboxRef then
				SkyboxRef = Instance.new("Sky")
				SkyboxRef.Parent = Lighting
			end

			-- Skybox texture:
			for Key, Prop in
				{
					Top = "SkyboxUp",
					Bottom = "SkyboxDn",
					Left = "SkyboxLf",
					Right = "SkyboxRt",
					Front = "SkyboxFt",
					Back = "SkyboxBk",
				} :: { [string]: string }
			do
				SkyboxRef[Prop] = Skybox[Key]
			end

			if Skybox.CelestialBodies ~= nil then
				SkyboxRef.CelestialBodiesShown = Skybox.CelestialBodies
			end

			if Skybox.Moon then
				if Skybox.Moon.Size then
					SkyboxRef.MoonAngularSize = Skybox.Moon.Size
				end

				if Skybox.Moon.Texture then
					SkyboxRef.MoonTextureId = Skybox.Moon.Texture
				end
			end

			if Skybox.Sun then
				if Skybox.Sun.Size then
					SkyboxRef.SunAngularSize = Skybox.Sun.Size
				end

				if Skybox.Sun.Texture then
					SkyboxRef.SunTextureId = Skybox.Sun.Texture
				end
			end

			if Skybox.StarCount then
				SkyboxRef.StarCount = Skybox.StarCount
			end
		else
			if SkyboxRef then
				SkyboxRef:Destroy()
			end
		end
	end

	if SkyOnly then
		return
	end

	do -- Lighting:
		if Preset.Brightness then
			Lighting.Brightness = Preset.Brightness
		end

		if Preset.Ambient then
			Lighting.Ambient = Preset.Ambient
		end

		if Preset.OutdoorAmbient then
			Lighting.OutdoorAmbient = Preset.OutdoorAmbient
		end

		if Preset.DiffuseScale then
			Lighting.EnvironmentDiffuseScale = Preset.DiffuseScale
		end

		if Preset.SpecularScale then
			Lighting.EnvironmentSpecularScale = Preset.SpecularScale
		end

		if Preset.ShadowSoftness then
			Lighting.ShadowSoftness = Preset.ShadowSoftness
		end

		if Preset.Exposure then
			Lighting.ExposureCompensation = Preset.Exposure
		end

		if Preset.GlobalShadows then
			Lighting.GlobalShadows = Preset.GlobalShadows
		end

		if Preset.ColorShift then
			if Preset.ColorShift.Top then
				Lighting.ColorShift_Top = Preset.ColorShift.Top
			end

			if Preset.ColorShift.Bottom then
				Lighting.ColorShift_Bottom = Preset.ColorShift.Bottom
			end
		end

		if Preset.Time then
			if Preset.Time.Clock then
				Lighting.ClockTime = Preset.Time.Clock
			end

			if Preset.Time.Latitude then
				Lighting.GeographicLatitude = Preset.Time.Latitude
			end
		end

		if Preset.Fog then
			if Preset.Fog.Color then
				Lighting.FogColor = Preset.Fog.Color
			end

			if Preset.Fog.Start then
				Lighting.FogStart = Preset.Fog.Start
			end

			if Preset.Fog.End then
				Lighting.FogEnd = Preset.Fog.End
			end
		end
	end

	do -- Atmosphere:
		local Atmosphere = Preset.Atmosphere
		local AtmosphereRef = Lighting:FindFirstChild("Atmosphere") :: Atmosphere?

		if Atmosphere then
			if not AtmosphereRef then
				AtmosphereRef = Instance.new("Atmosphere")
				AtmosphereRef.Parent = Lighting
			end

			if Atmosphere.Density then
				AtmosphereRef.Density = Atmosphere.Density
			end

			if Atmosphere.Offset then
				AtmosphereRef.Offset = Atmosphere.Offset
			end

			if Atmosphere.Color then
				AtmosphereRef.Color = Atmosphere.Color
			end

			if Atmosphere.Decay then
				AtmosphereRef.Decay = Atmosphere.Decay
			end

			if Atmosphere.Glare then
				AtmosphereRef.Glare = Atmosphere.Glare
			end

			if Atmosphere.Haze then
				AtmosphereRef.Haze = Atmosphere.Haze
			end
		else
			if AtmosphereRef then
				AtmosphereRef:Destroy()
			end
		end
	end

	do -- Bloom:
		local Bloom = Preset.Bloom
		local BloomRef = Lighting:FindFirstChild("Bloom") :: BloomEffect?

		if Bloom then
			if not BloomRef then
				BloomRef = Instance.new("BloomEffect")
				BloomRef.Parent = Lighting
			end

			if Bloom.Intensity then
				BloomRef.Intensity = Bloom.Intensity
			end

			if Bloom.Size then
				BloomRef.Size = Bloom.Size
			end

			if Bloom.Threshold then
				BloomRef.Threshold = Bloom.Threshold
			end
		else
			if BloomRef then
				BloomRef:Destroy()
			end
		end
	end

	do -- Depth of Field:
		local DepthOfField = Preset.DepthOfField
		local DepthOfFieldRef = Lighting:FindFirstChild("DepthOfField") :: DepthOfFieldEffect?

		if DepthOfField then
			if not DepthOfFieldRef then
				DepthOfFieldRef = Instance.new("DepthOfFieldEffect")
				DepthOfFieldRef.Parent = Lighting
			end

			if DepthOfField.FarIntensity then
				DepthOfFieldRef.FarIntensity = DepthOfField.FarIntensity
			end

			if DepthOfField.FocusDistance then
				DepthOfFieldRef.FocusDistance = DepthOfField.FocusDistance
			end

			if DepthOfField.InFocusRadius then
				DepthOfFieldRef.InFocusRadius = DepthOfField.InFocusRadius
			end

			if DepthOfField.NearIntensity then
				DepthOfFieldRef.NearIntensity = DepthOfField.NearIntensity
			end
		else
			if DepthOfFieldRef then
				DepthOfFieldRef:Destroy()
			end
		end
	end

	do -- SunRays:
		local SunRays = Preset.SunRays
		local SunRaysRef = Lighting:FindFirstChild("SunRays") :: SunRaysEffect?

		if SunRays then
			if not SunRaysRef then
				SunRaysRef = Instance.new("SunRaysEffect")
				SunRaysRef.Parent = Lighting
			end

			if SunRays.Intensity then
				SunRaysRef.Intensity = SunRays.Intensity
			end

			if SunRays.Spread then
				SunRaysRef.Spread = SunRays.Spread
			end
		else
			if SunRaysRef then
				SunRaysRef:Destroy()
			end
		end
	end

	do -- Blur:
		local Blur = Preset.Blur
		local BlurRef = Lighting:FindFirstChild("Blur") :: BlurEffect?

		if Blur then
			if not BlurRef then
				BlurRef = Instance.new("BlurEffect")
				BlurRef.Parent = Lighting
			end

			BlurRef.Enabled = true
			BlurRef.Blur = Blur
		else
			if BlurRef then
				BlurRef:Destroy()
			end
		end
	end

	do -- Color Correction:
		local ColorCorrection = Preset.ColorCorrection
		local ColorCorrectionRef = Lighting:FindFirstChild("ColorCorrection") :: ColorCorrectionEffect?

		if ColorCorrection then
			if not ColorCorrectionRef then
				ColorCorrectionRef = Instance.new("ColorCorrectionEffect")
				ColorCorrectionRef.Parent = Lighting
			end

			if ColorCorrection.Brightness then
				ColorCorrectionRef.Brightness = ColorCorrection.Brightness
			end

			if ColorCorrection.Contrast then
				ColorCorrectionRef.Contrast = ColorCorrection.Contrast
			end

			if ColorCorrection.Saturation then
				ColorCorrectionRef.Saturation = ColorCorrection.Saturation
			end

			if ColorCorrection.TintColor then
				ColorCorrectionRef.TintColor = ColorCorrection.TintColor
			end
		else
			if ColorCorrectionRef then
				ColorCorrectionRef:Destroy()
			end
		end
	end

	do -- Color Grading:
		local ColorGrading = Preset.ColorGrading
		local ColorGradingRef = Lighting:FindFirstChild("ColorGrading") :: ColorGradingEffect?

		if ColorGrading then
			if not ColorGradingRef then
				ColorGradingRef = Instance.new("BlurEffect")
				ColorGradingRef.Parent = Lighting
			end

			ColorGradingRef.TonemapperPreset = ColorGrading
		else
			if ColorGradingRef then
				ColorGradingRef:Destroy()
			end
		end
	end
end

function PresetHelper.Save(Preset: Preset)
	return PrettyPrint(Preset)
end

return PresetHelper
