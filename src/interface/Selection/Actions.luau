-- Services:
local CoreGui = game:GetService("CoreGui")
local Lighting = game:GetService("Lighting")
local Selection = game:GetService("Selection")

-- Modules:
local Nebulight = require(script.Parent.Parent.Parent.Packages.Nebulight)

-- Types:
type SelectionWidget = {
	Widget: PluginGui & { Main: Frame & { Export: Frame } },

	AddPreset: (Name: string, Preset: Nebulight.Preset) -> (),
}

type PresetInfo = {
	Name: string,
	Preset: Nebulight.Preset,
}

-- Main Module:
return {
	Save = function(Widget: SelectionWidget)
		if CoreGui:FindFirstChild("_Vibrant_PresetInput") then
			CoreGui._Vibrant_PresetInput:Destroy()
		end

		local Container: ScreenGui & { Field: TextBox } = Instance.new("ScreenGui") :: any --> Because ScreenGui is complete unrelated :pepelaugh:
		Container.Name = "_Vibrant_PresetInput"
		Container.IgnoreGuiInset = true
		Container.ResetOnSpawn = false
		Container.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
		Container.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		Container.Parent = CoreGui

		local Field = Instance.new("TextBox")
		Field.Name = "Field"
		Field.AnchorPoint = Vector2.new(0.5, 0.5)
		Field.BackgroundColor3 = Color3.fromRGB(58, 58, 58)
		Field.CursorPosition = -1
		Field.FontFace = Font.new("rbxasset://fonts/families/Roboto.json")
		Field.PlaceholderText = "Enter preset name..."
		Field.Position = UDim2.fromScale(0.5, 0.5)
		Field.Size = UDim2.fromScale(0.135023, 0.0675114)
		Field.Text = ""
		Field.TextColor3 = Color3.new(1, 1, 1)
		Field.TextScaled = true

		local UIStroke = Instance.new("UIStroke")
		UIStroke.Name = "UIStroke"
		UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		UIStroke.Color = Color3.fromRGB(79, 79, 79)
		UIStroke.Thickness = 1.25
		UIStroke.Parent = Field

		local UICorner = Instance.new("UICorner")
		UICorner.Name = "UICorner"
		UICorner.CornerRadius = UDim.new(0, 4)
		UICorner.Parent = Field

		local UIPadding = Instance.new("UIPadding")
		UIPadding.Name = "UIPadding"
		UIPadding.PaddingLeft = UDim.new(0.0382514, 0)
		UIPadding.PaddingRight = UDim.new(0.0382514, 0)
		UIPadding.Parent = Field

		local UITextSizeConstraint = Instance.new("UITextSizeConstraint")
		UITextSizeConstraint.Name = "UITextSizeConstraint"
		UITextSizeConstraint.MaxTextSize = 18
		UITextSizeConstraint.Parent = Field

		Field.Parent = Container

		-- TODO: Animate the input field (Fade In)

		local InputField = Container.Field
		InputField:CaptureFocus()

		InputField.FocusLost:Connect(function(WasEnter: boolean)
			local Name = InputField.Text

			Container:Destroy()

			if Name == "" or not Name:match("[a-zA-Z0-9 _#]+") or #Name > 20 then
				return
			end

			-- TODO: Animate the input field's destruction (Fade Out)

			local Preset = Nebulight.CreatePreset()

			Widget.AddPreset(Name, Preset)
			Container:Destroy()
		end)
	end,

	Import = function(Widget: SelectionWidget)
		local PresetRef: (ModuleScript | Folder)? = Selection:Get()[1]

		if not PresetRef then
			warn("No preset selected")
			return
		end

		if PresetRef:IsA("ModuleScript") then
			local Clone = PresetRef:Clone()
			local Success, Result = pcall(require, Clone)

			if not Success then
				warn("Error while loading", PresetRef, `: {Result}`)
				Clone:Destroy()

				return
			end

			Widget.AddPreset(PresetRef.Name, Result)
			Clone:Destroy()
		elseif PresetRef:IsA("Folder") then
			local Preset, DidCreate = Nebulight.CreateFromConfig(PresetRef)

			if not DidCreate then
				warn(
					`Invalid preset config`,
					PresetRef,
					"(This could be caused by an invalid config or attempting to save an empty folder)"
				)
				return
			end

			Widget.AddPreset(PresetRef.Name, Preset)
		end
	end,

	Export = function(Widget: SelectionWidget)
		local ExportWindow = Widget.Widget.Main.Export

		ExportWindow.Visible = not ExportWindow.Visible
	end,

	ExportAsFolder = function(Info: PresetInfo)
		local ConfigRef = Nebulight.SaveAsConfig(Info.Preset)
		ConfigRef.Name = Info.Name
		ConfigRef.Parent = Lighting
	end,

	ExportAsModule = function(Info: PresetInfo)
		local Source = "return " .. Nebulight.SaveAsModule(Info.Preset)

		local ModuleScript = Instance.new("ModuleScript")
		ModuleScript.Name = Info.Name
		ModuleScript.Source = Source
		ModuleScript.Parent = Lighting
	end,
}
