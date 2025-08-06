-- Modules:
local Root = script.Parent.Parent

local Types = require(Root.Types)
local Fusion = require(Root.Packages.Fusion)
local Preview = require(script.Parent.Preview)

-- Types:
type WidgetUI = typeof(script.Parent.Widgets.Presets)

-- Constants:
local WINDOW_WIDTH = 310
local WINDOW_HEIGHT = 335

-- Variables:
local Value = Fusion.Value
local Computed = Fusion.Computed
local Hydrate = Fusion.Hydrate
local OnChange = Fusion.OnChange
local OnEvent = Fusion.OnEvent
local Tween = Fusion.Tween

-- Main Module:
local Selection = {}
Selection.Plugin = nil :: Plugin?
Selection.Widget = nil :: DockWidgetPluginGui?
Selection.Presets = {} :: { { Name: string, Preset: Types.Preset } }
Selection.Filter = {
	Query = Value(""),
	OnlyFavorites = false,
}

function Selection.Refresh()
	local Plugin = Selection.Plugin

	if not Plugin then
		return
	end

	local Widget = Selection.Widget
	local WidgetUI = Widget and Widget:FindFirstChild("Main") :: WidgetUI

	if not WidgetUI then
		return
	end

	Widget.Title = "Lighting Presets"

	local SearchQuery = Selection.Filter.Query

	for Index, PresetInfo in Selection.Presets do
		local Clone = script.Parent.Templates.PresetPreview:Clone()
		Clone.Name = Index
		Clone.Preset.Label.Text = PresetInfo.Name
		Clone.Preview.Image = PresetInfo.Preset.Sky.Front
		Clone.ZIndex = Index
		Clone.Parent = WidgetUI.List

		Hydrate(Clone)({
			Visible = Computed(function()
				if not PresetInfo.Name:gsub(" ", ""):lower():match(SearchQuery:get():gsub(" ", ""):lower()) then
					return false
				end

				return true
			end, Fusion.cleanup),
		})

		local ImageColor = Value(Color3.new(0.8, 0.8, 0.8))

		Hydrate(Clone.Preview)({
			Active = true,

			ImageColor3 = Tween(ImageColor, TweenInfo.new(0.1)),

			[OnEvent("MouseEnter")] = function()
				ImageColor:set(Color3.new(1, 1, 1))
				Plugin:GetMouse().Icon = "rbxasset://SystemCursors/PointingHand"
			end,

			[OnEvent("MouseLeave")] = function()
				ImageColor:set(Color3.new(0.8, 0.8, 0.8))
				Plugin:GetMouse().Icon = ""
			end,

			[OnEvent("Activated")] = function()
				Preview.Set(PresetInfo.Name, PresetInfo.Preset)
			end,
		})
	end
end

function Selection.Load(Plugin: Plugin)
	Selection.Plugin = Plugin

	local Widget = Plugin:CreateDockWidgetPluginGui(
		"Lighting Presets",
		DockWidgetPluginGuiInfo.new(
			Enum.InitialDockState.Right,
			false,
			false,
			WINDOW_WIDTH,
			WINDOW_HEIGHT,
			WINDOW_WIDTH,
			WINDOW_HEIGHT
		)
	)

	Widget.Title = "Lighting Presets"
	Widget.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	local WidgetUI = script.Parent.Widgets.Presets:Clone()
	WidgetUI.Name = "Main"
	WidgetUI.Parent = Widget

	Selection.Widget = Widget

	Selection.Refresh()

	Hydrate(WidgetUI.Search)({
		[OnChange("Text")] = function(NewText: string)
			Selection.Filter.Query:set(NewText)
		end,
	})
end

for _, Child in script.Presets:GetChildren() do
	table.insert(Selection.Presets, {
		Name = Child.Name,
		Preset = require(Child),
	})
end

return Selection
