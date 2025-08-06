-- Modules:
local Interface = require(script.Interface)

-- Main:
plugin:Activate(true)
Interface.Load(plugin)

local Toolbar = plugin:CreateToolbar("Vibrant")

local SelectionButton =
	Toolbar:CreateButton("preset-selection", "Open preset menu", "rbxassetid://80654736002793", "Presets")

SelectionButton.Click:Connect(function()
	local Widget = Interface.Selection.Widget

	if not Widget then
		return
	end

	Widget.Enabled = not Widget.Enabled
end)

plugin.Deactivation:Connect(function()
	local SelectionWidget = Interface.Selection.Widget
	local PreviewWidget = Interface.Preview.Widget

	if SelectionWidget then
		SelectionWidget.Enabled = false
	end

	if PreviewWidget then
		PreviewWidget.Enabled = false
	end
end)
