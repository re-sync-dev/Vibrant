--!strict
-- Modules:
local Root = script.Parent.Parent

local Fusion = require(Root.Packages.Fusion)
local Nebulight = require(Root.Packages.Nebulight)

-- Types:
type WidgetUI = typeof(script.Parent.Widgets.Preview)

type PreviewWidget = {
	-- Fields --
	Plugin: Plugin?,
	Widget: DockWidgetPluginGui?,
	Orientation: Fusion.Computed<CFrame>,
	Dragging: boolean,
	_UpdateThread: thread?,
	_Preset: Nebulight.Preset?,

	-- Methods --
	Set: (self: PreviewWidget, Name: string, Preset: Nebulight.Preset) -> (),
	Load: (self: PreviewWidget, Plugin: Plugin) -> (),
}

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
local Preview = {} :: PreviewWidget
Preview.Orientation = Computed(function()
	return CFrame.fromOrientation(math.rad(AngleX:get()), math.rad(AngleY:get()), 0)
end, Fusion.cleanup)
Preview.Dragging = false

function Preview:Set(Name: string, Preset: Nebulight.Preset)
	local Widget = self.Widget

	if not Widget then
		return
	end

	self._Preset = Preset

	local WidgetUI = Widget:FindFirstChild("Main") :: WidgetUI
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

	if self._UpdateThread then
		task.cancel(self._UpdateThread)
		self._UpdateThread = nil
	end

	self._UpdateThread = task.defer(function()
		local Camera = WidgetUI.Viewport.CurrentCamera

		while Widget.Enabled and Camera do
			Camera.CFrame = Camera.CFrame:Lerp(self.Orientation:get(), 0.7)

			task.wait(FPS)
		end

		self.Dragging = false
		self._UpdateThread = nil
	end)
end

function Preview:Load(Plugin: Plugin)
	self.Plugin = Plugin

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

	self.Widget = Widget

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
			self.Dragging = true
			Mouse.Icon = "rbxasset://SystemCursors/ClosedHand"
		end,
		[OnEvent("MouseButton1Up")] = function()
			Mouse.Icon = "rbxasset://SystemCursors/OpenHand"
			self.Dragging = false
		end,
		[OnEvent("MouseEnter")] = function()
			InDetector = true
			Mouse.Icon = "rbxasset://SystemCursors/OpenHand"
		end,
		[OnEvent("MouseLeave")] = function()
			self.Dragging = false
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
			if not self.Dragging then
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
			if not self._Preset then
				return
			end

			Widget.Enabled = false

			Nebulight.UsePreset(self._Preset)
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
			if not self._Preset then
				return
			end

			Widget.Enabled = false

			Nebulight.UsePreset(self._Preset, true)
		end,
	})
end

return Preview
