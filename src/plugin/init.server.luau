local CoreGui = game:GetService("CoreGui")

-- Modules:
local Interface = require(script.Interface)

local Nebulight = require(script.Packages.Nebulight)

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

--local CreateButton =
--	Toolbar:CreateButton("create-preset", "Create Preset", "rbxassetid://80654736002793", "Create Preset")

--CreateButton.Click:Connect(function()
	
--end)

local DumpButton = Toolbar:CreateButton("dump-presets", "Dump Presets", "rbxassetid://80654736002793", "Dump Presets")

DumpButton.Click:Connect(function()
	local DumpedScript = game:GetService("ServerStorage"):FindFirstChild("Presets") or Instance.new("ModuleScript")
	DumpedScript.Name = "Presets"
	DumpedScript.Source = "return" .. Nebulight.SaveAsModule(Interface.Selection.CustomPresets, false)
	DumpedScript.Parent = game:GetService("ServerStorage")
end)

local ClearPresets =
	Toolbar:CreateButton("clear-presets", "Clear Presets", "rbxassetid://80654736002793", "Clear Presets")

ClearPresets.Click:Connect(function()
	plugin:SetSetting("Presets", "[]")

	Interface.Selection.CustomPresets = {}
	Interface.Selection.Refresh()

	ClearPresets:SetActive(false)
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

	if CoreGui:FindFirstChild("_Vibrant_PresetInput") then
		(CoreGui._Vibrant_PresetInput :: ScreenGui):Destroy()
	end
end)
