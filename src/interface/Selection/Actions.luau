-- Services:
local CoreGui = game:GetService("CoreGui")

-- Modules:
local Nebulight = require(script.Parent.Parent.Parent.Packages.Nebulight)

-- Types:
type SelectionWidget = {
	AddPreset: (Name: string, Preset: Nebulight.Preset) -> (),
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
		end)
	end,
}
