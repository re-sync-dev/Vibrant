local CoreGui = game:GetService("CoreGui")
local TestService = game:GetService("TestService")
local ScriptEditorService = game:GetService("ScriptEditorService")

-- Modules:
local Interface = require(script.Interface)
local DefaultSettings = require(script.Settings)

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

local SettingsButton = Toolbar:CreateButton("settings", "Openn Settings", "rbxassetid://92152739729044", "Settings")

SettingsButton.Click:Connect(function()
	local CurrentSettings = plugin:GetSetting("Settings") or DefaultSettings

	local ModuleScript = TestService:FindFirstChild("VibrantSettings") or Instance.new("ModuleScript")
	ModuleScript.Name = "VibrantSettings"
	ModuleScript.Parent = TestService

	local Source = "return {\n"

	for Key, Value in CurrentSettings do
		Source ..= `\t{Key} = {Value},\n`
	end

	Source ..= "}"

	ModuleScript.Source = Source

	plugin:OpenScript(ModuleScript)

	local Connection
	Connection = ScriptEditorService.TextDocumentDidClose:Connect(function(Document)
		if Document:GetFullName() ~= ModuleScript:GetFullName() then
			return
		end

		Connection:Disconnect()

		local Success, Result = pcall(require, ModuleScript)

		if not Success then
			warn(`[Vibrant] Failed to load new settings: {Result}`)
			return
		end

		plugin:SetSetting("Settings", Result)

		ModuleScript:Destroy()
	end)

	ModuleScript.Destroying:Once(function()
		Connection:Disconnect()
	end)
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
