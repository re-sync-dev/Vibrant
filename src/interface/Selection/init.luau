-- Services:
local HttpService = game:GetService("HttpService")

-- Modules:
local Root = script.Parent.Parent

local Actions = require(script.Actions)
local Preview = require(script.Parent.Preview)
local Util = require(script.Parent.Util)

local Fusion = require(Root.Packages.Fusion)
local Nebulight = require(Root.Packages.Nebulight)

-- Types:
type WidgetUI = typeof(script.Parent.Widgets.Presets)
type PresetInfo = {
	Name: string,
	Preset: Nebulight.Preset,
}

-- Constants:
local WINDOW_WIDTH = 310
local WINDOW_HEIGHT = 335

-- Variables:
local Children = Fusion.Children
local Value = Fusion.Value
local Computed = Fusion.Computed
local Hydrate = Fusion.Hydrate
local ForValues = Fusion.ForValues
local OnChange = Fusion.OnChange
local OnEvent = Fusion.OnEvent
local Tween = Fusion.Tween

-- Functions:
local function RecursiveEncode(T: any)
	for Key, Value in T do
		if typeof(Value) == "table" then
			RecursiveEncode(Value)
		elseif typeof(Value) == "Color3" then
			T[Key] = { _Type = "Color3", R = Value.R, G = Value.G, B = Value.B }
		elseif typeof(Value) == "Vector3" then
			T[Key] = { _Type = "Vector3", X = Value.X, Y = Value.Y, Z = Value.Z }
		elseif typeof(Value) == "EnumItem" then
			T[Key] = { _Type = "Enum", Category = Value.EnumType, Name = Value.Name }
		end
	end
end

local function RecursiveDecode(T: any)
	for Key, Value in T do
		if type(Value) ~= "table" then
			continue
		end

		if not Value._Type then
			RecursiveDecode(Value)
			continue
		end

		if Value._Type == "Color3" then
			T[Key] = Color3.new(Value.R, Value.G, Value.B)
		elseif Value._Type == "Vector3" then
			T[Key] = Vector3.new(Value.X, Value.Y, Value.Z)
		elseif Value._Type == "Enum" then
			T[Key] = Enum[Value.Category][Value.Name]
		end
	end
end

-- Main Module:
local Selection = {}
Selection.Plugin = nil :: Plugin?
Selection.Widget = nil :: DockWidgetPluginGui?
Selection.Presets = {} :: { PresetInfo }
Selection.CustomPresets = {} :: { PresetInfo }
Selection.Filter = {
	Query = Value(""),
	OnlyFavorites = false,
}

function Selection.AddPreset(Name: string, Preset: Nebulight.Preset)
	table.insert(Selection.CustomPresets, {
		Name = Name,
		Preset = Preset,
	})

	local CustomPresets = Util.Copy(Selection.CustomPresets, true)
	RecursiveEncode(CustomPresets)

	Selection.Plugin:SetSetting("Presets", HttpService:JSONEncode(CustomPresets))

	Selection.Refresh()
end

function Selection.RemovePreset(Preset: PresetInfo)
	local Index = table.find(Selection.CustomPresets, Preset)

	if not Index then
		return
	end

	table.remove(Selection.CustomPresets, Index)

	local CustomPresets = Util.Copy(Selection.CustomPresets, true)
	RecursiveEncode(CustomPresets)

	Selection.Plugin:SetSetting("Presets", HttpService:JSONEncode(CustomPresets))

	Selection.Refresh()
end

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

	-- Clear list:
	for _, Child in WidgetUI.List:GetChildren() do
		if Child:IsA("UIGridLayout") then
			continue
		end

		Child:Destroy()
	end

	local SearchQuery = Selection.Filter.Query

	local function CreateEntry(Index: number, PresetInfo: PresetInfo, IsCustom: boolean?)
		local Clone = script.Parent.Templates.PresetPreview:Clone()
		Clone.Name = PresetInfo.Name
		Clone.Preset.Label.Text = PresetInfo.Name
		Clone.Preview.Image = PresetInfo.Preset.Sky and PresetInfo.Preset.Sky.Front or "" -- TODO: Add no skybox image
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

		local TrashColor = Value(Color3.new(0.5, 0, 0))
		local TrashConfirmed = false

		Hydrate(Clone.Trash)({
			Active = true,
			Visible = IsCustom or false,

			ImageColor3 = Tween(TrashColor, TweenInfo.new(0.1)),

			[OnEvent("MouseLeave")] = function()
				TrashConfirmed = false
				TrashColor:set(Color3.new(0.5, 0, 0))
			end,

			[OnEvent("Activated")] = function()
				if TrashConfirmed then
					-- TODO: Add delete logic
					Selection.RemovePreset(PresetInfo)
				else
					TrashColor:set(Color3.new(1, 0, 0))
					TrashConfirmed = true
				end
			end,
		})
	end

	for Index, PresetInfo in Selection.Presets do
		CreateEntry(Index, PresetInfo)
	end

	for Index, PresetInfo in Selection.CustomPresets do
		print(Index, PresetInfo.Name)

		Index += #Selection.Presets --> Custom preset will always come after default ones

		CreateEntry(Index, PresetInfo, true)
	end
end

function Selection.Load(Plugin: Plugin)
	Selection.Plugin = Plugin

	do -- Load custom presets:
		local JSONString = Plugin:GetSetting("Presets")

		if JSONString then
			Selection.CustomPresets = HttpService:JSONDecode(JSONString) or {}

			RecursiveDecode(Selection.CustomPresets)
		end
	end

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

	Hydrate(WidgetUI.Buttons)({
		[Children] = {
			ForValues({ "Save", "Import", "Export" }, function(Action: string)
				local ButtonRef = WidgetUI.Buttons[Action] :: ImageButton

				return Hydrate(ButtonRef)({
					[OnEvent("MouseEnter")] = function()
						Plugin:GetMouse().Icon = "rbxasset://SystemCursors/PointingHand"
					end,

					[OnEvent("MouseLeave")] = function()
						Plugin:GetMouse().Icon = ""
					end,

					[OnEvent("Activated")] = function()
						local Handler = Actions[Action]

						if not Handler then
							warn(`[Selection] Action '{Action}' does not have a handler`)
							return
						end

						Handler(Selection)
					end,
				})
			end, Fusion.cleanup),
		},
	})
end

for _, Child in script.Presets:GetChildren() do
	table.insert(Selection.Presets, {
		Name = Child.Name,
		Preset = require(Child),
	})
end

return Selection
