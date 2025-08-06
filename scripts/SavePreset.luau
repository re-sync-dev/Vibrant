print("Saved")

local ServerStorage = game:GetService("ServerStorage")

local PrettyPrint

do
	type ExistingOptions = {
		rawStrings: boolean?,
	}

	local isPrimitiveType = { string = true, number = true, boolean = true }

	local typeSortOrder: { [string]: number } = {
		["boolean"] = 1,
		["number"] = 2,
		["string"] = 3,
		["function"] = 4,
		["vector"] = 5,
		["buffer"] = 6,
		["thread"] = 7,
		["table"] = 8,
		["userdata"] = 9,
		["nil"] = 10,
		["Color3"] = 11,
		["Vector3"] = 12,
	}

	local function isPrimitiveArray(array: { [unknown]: unknown }): boolean
		local max, len = 0, #array

		for key, value in array do
			if type(key) ~= "number" then
				return false
			elseif key <= 0 then
				return false
			-- userdatas arent primitives
			elseif not isPrimitiveType[type(value)] then
				return false
			end

			max = math.max(key, max)
		end

		return len == max
	end

	local function getFormattedAdress(t: {}): string
		return `table<({t})>`
	end

	local function formatValue(value: unknown, options: ExistingOptions?): string
		if type(value) == "table" then
			return getFormattedAdress(value :: any) -- simple representation for table values
		elseif typeof(value) == "Color3" then
			return `Color3.fromRGB({math.floor(value.R * 255)}, {math.floor(value.G * 255)}, {math.floor(value.B * 255)})`
		elseif typeof(value) == "Vector3" then
			return `Vector3.new({value.X}, {value.Y}, {value.Z})`
		elseif type(value) ~= "string" then
			if type(value) == "number" then
				value *= 1000
				value = math.floor(value) / 1000
			end

			return tostring(value)
		end

		if options and options.rawStrings then
			return `"{value}"`
		end
		return string.format("%q", value)
	end

	local function formatKey(key: unknown, seq: boolean): string
		if seq then
			return ""
		end

		if type(key) == "table" then
			return `[{getFormattedAdress(key :: any)}] = ` -- TODO: handling for table keys
		end
		if type(key) ~= "string" then
			return `[{tostring(key)}] =`
		end

		-- key is a simple identifier
		if string.match(key, "^[%a_][%w_]-$") == key then
			return `{key} = `
		end

		return `[{string.format("%q", key)}] = `
	end

	local function isEmpty(t: { [unknown]: unknown }): boolean
		for _ in t do
			return false
		end
		return true
	end

	-- FIXME(luau): mark `dataTable` indexer as read-only
	local function traverseTable(
		dataTable: { [unknown]: unknown },
		seen: { [unknown]: boolean },
		indent: number,
		options: ExistingOptions?
	): string
		local output = ""
		local indentStr = string.rep("\t", indent)

		local keys = {}

		-- Collect all keys, not just primitives
		for key in dataTable do
			table.insert(keys, key)
		end

		table.sort(keys, function(a: string, b: string): boolean
			local typeofTableA, typeofTableB = typeof(dataTable[a]), typeof(dataTable[b])

			if typeofTableA ~= typeofTableB then
				return typeSortOrder[typeofTableA] < typeSortOrder[typeofTableB]
			end

			if type(a) == "number" and type(b) == "number" then
				return a < b
			end

			return tostring(a) < tostring(b)
		end)

		local inSequence = false
		local previousKey = 0

		for idx, key in keys do
			if type(key) == "number" and key > 0 and key - 1 == previousKey then
				previousKey = key
				inSequence = true
			else
				inSequence = false
			end

			local value = dataTable[key]

			if typeof(value) ~= "table" then
				output = `{output}{indentStr}{formatKey(key, inSequence)}{formatValue(value, options)},\n`
				continue
			end

			-- prevents self-referential tables from looping infinitely
			if seen[value] then
				output = `{output}{indentStr}{formatKey(key, inSequence)}[Circular Reference <({value})>],\n`
				continue
			else
				seen[value] = true
			end

			if isEmpty(value :: { [unknown]: unknown }) then
				output = string.format("%s%s%s{},\n", output, indentStr, formatKey(key, inSequence))
				continue
			end

			if isPrimitiveArray(value :: { [unknown]: unknown }) then -- collapse primitive arrays
				local outputConcatTbl = table.create(#value) :: { string }

				for valueIndex, valueInArray in value :: { unknown } do
					outputConcatTbl[valueIndex] = formatValue(valueInArray)
				end

				output = string.format(
					"%s%s%s{%*},\n",
					output,
					indentStr,
					formatKey(key, inSequence),
					table.concat(outputConcatTbl, ", ")
				)
				continue
			end

			output = string.format(
				"%s%s%s{\n%s%s},\n",
				output,
				indentStr,
				formatKey(key, inSequence),
				traverseTable(value :: any, seen, indent + 1, options),
				indentStr
			)

			seen[value] = nil
		end

		return output
	end

	PrettyPrint = function(data: unknown, options: ExistingOptions?): string
		options = options or {} :: ExistingOptions

		-- if it's not a primitive, we'll pretty print it as a value
		if type(data) ~= "table" then
			return formatValue(data, options)
		end

		return `\{\n{traverseTable(data :: { [unknown]: unknown }, { [data] = true }, 1, options)}\}`
	end
end

local PresetHelper = {}
do
	-- Services:
	local Lighting = game:GetService("Lighting")

	-- Types:
	type Preset = any

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
end

local Preset = ServerStorage:FindFirstChild("Preset") or Instance.new("ModuleScript")

Preset.Name = "Preset"
Preset.Parent = ServerStorage
Preset.Source = `return {PresetHelper.Save(PresetHelper.Create())}`

print("Saved to:", Preset)
