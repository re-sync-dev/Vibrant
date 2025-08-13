-- Modules:
local Root = script.Parent.Parent

local Fusion = require(Root.Packages.Fusion)
local Nebulight = require(Root.Packages.Nebulight)

-- Types:
type WidgetUI = typeof(script.Parent.Widgets.Preview)

-- Constants:
local WINDOW_WIDTH = 730
local WINDOW_HEIGHT = 450

local FPS = 1 / 60
local SPEED = 15
local MAX_ANGLE = 45

-- Variables:
local Value = Fusion.Value
local Computed = Fusion.Computed
local Hydrate = Fusion.Hydrate
local OnEvent = Fusion.OnEvent

local AngleX, AngleY = Value(0), Value(0)

-- Main Module:
local Preview = {}
Preview.Widget = nil :: DockWidgetPluginGui?
Preview.Orientation = Computed(function()
	return CFrame.fromOrientation(math.rad(AngleX:get()), math.rad(AngleY:get()), 0)
end, Fusion.cleanup)
Preview.Dragging = false
Preview._UpdateThread = nil :: thread?
Preview._Preset = nil :: Nebulight.Preset?

function Preview.Set(Name: string, Preset: Nebulight.Preset)
	local Widget = Preview.Widget
	local WidgetUI = Widget and Widget:FindFirstChild("Main") :: WidgetUI

	if not WidgetUI then
		return
	end

	Preview._Preset = Preset

	Widget.Enabled = true
	WidgetUI.Notice.Visible = true
	WidgetUI.Preset.Text = Name

	for _, Child in WidgetUI.Viewport:GetChildren() do
		if not Child:IsA("BasePart") then
			continue
		end

		local Sky = Preset.Sky or {}
		local FaceTexture = Sky[Child.Name]

		if not FaceTexture then
			continue
		end

		Child.Decal.Texture = FaceTexture
	end

	if Preview._UpdateThread then
		task.cancel(Preview._UpdateThread)
		Preview._UpdateThread = nil
	end

	Preview._UpdateThread = task.defer(function()
		local Camera = WidgetUI.Viewport.CurrentCamera

		while Widget.Enabled and Camera do
			Camera.CFrame = Camera.CFrame:Lerp(Preview.Orientation:get(), 0.7)

			task.wait(FPS)
		end

		Preview.Dragging = false
		Preview._UpdateThread = nil
	end)
end

function Preview.Load(Plugin: Plugin)
	Preview.Plugin = Plugin

	local Widget = Plugin:CreateDockWidgetPluginGui(
		"Preview",
		DockWidgetPluginGuiInfo.new(
			Enum.InitialDockState.Float,
			false,
			false,
			WINDOW_WIDTH,
			WINDOW_HEIGHT,
			WINDOW_WIDTH,
			WINDOW_HEIGHT
		)
	)

	Widget.Title = "Preview"
	Widget.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	local WidgetUI = script.Parent.Widgets.Preview:Clone()
	WidgetUI.Name = "Main"
	WidgetUI.Parent = Widget

	Preview.Widget = Widget

	local Mouse = Plugin:GetMouse()

	WidgetUI.Viewport.CurrentCamera = WidgetUI.Viewport.Camera

	local InDetector = false

	Widget.WindowFocusReleased:Connect(function()
		Mouse.Icon = ""
	end)

	local function Update(Position: Vector3, Delta: Vector3)
		WidgetUI.Notice.Visible = false

		local YAlpha = ((Position.Y / WidgetUI.Detector.AbsoluteSize.Y) - 0.5) * 2

		AngleX:set(-YAlpha * MAX_ANGLE)
		AngleY:set(math.max((AngleY:get() + (-Delta.X * SPEED) * FPS) % 360, 0))
	end

	Hydrate(WidgetUI.Detector)({
		[OnEvent("MouseButton1Down")] = function()
			Preview.Dragging = true
			Mouse.Icon = "rbxasset://SystemCursors/ClosedHand"
		end,
		[OnEvent("MouseButton1Up")] = function()
			Mouse.Icon = "rbxasset://SystemCursors/OpenHand"
			Preview.Dragging = false
		end,
		[OnEvent("MouseEnter")] = function()
			InDetector = true
			Mouse.Icon = "rbxasset://SystemCursors/OpenHand"
		end,
		[OnEvent("MouseLeave")] = function()
			Preview.Dragging = false
			InDetector = false
			Mouse.Icon = ""
		end,
		[OnEvent("InputBegan")] = function(Input: InputObject)
			if Input.UserInputType ~= Enum.UserInputType.MouseButton1 then
				return
			end

			Update(Input.Position, Vector3.zero)
		end,
		[OnEvent("InputChanged")] = function(Input: InputObject)
			if not Preview.Dragging then
				return
			end

			if Input.UserInputType ~= Enum.UserInputType.MouseMovement then
				return
			end

			Update(Input.Position, Input.Delta)
		end,
	})

	Hydrate(WidgetUI.Apply)({
		[OnEvent("MouseEnter")] = function()
			Mouse.Icon = "rbxasset://SystemCursors/PointingHand"
		end,

		[OnEvent("MouseLeave")] = function()
			Mouse.Icon = InDetector and "rbxasset://SystemCursors/OpenHand" or ""
		end,

		[OnEvent("Activated")] = function()
			if not Preview._Preset then
				return
			end

			Widget.Enabled = false

			Nebulight.UsePreset(Preview._Preset)
		end,
	})

	Hydrate(WidgetUI.NoLighting)({
		[OnEvent("MouseEnter")] = function()
			Mouse.Icon = "rbxasset://SystemCursors/PointingHand"
		end,

		[OnEvent("MouseLeave")] = function()
			Mouse.Icon = InDetector and "rbxasset://SystemCursors/OpenHand" or ""
		end,

		[OnEvent("Activated")] = function()
			if not Preview._Preset then
				return
			end

			Widget.Enabled = false

			Nebulight.UsePreset(Preview._Preset, true)
		end,
	})
end

return Preview
