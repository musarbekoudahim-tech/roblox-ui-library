--!strict
--[=[
	AetherUI · Window
	Top-level draggable, resizable app window with title bar, traffic-light
	controls, minimize-to-bubble, and a global toggle keybind.
]=]

local Fusion = require(script.Parent.Parent.Core.Fusion)
local Theme = require(script.Parent.Parent.Core.Theme)
local Icons = require(script.Parent.Parent.Core.Icons)
local Sound = require(script.Parent.Parent.Core.Sound)
local Overlay = require(script.Parent.Parent.Core.Overlay)
local Keybinds = require(script.Parent.Parent.Core.Keybinds)

local New = Fusion.New
local Children = Fusion.Children
local Value = Fusion.Value
local Computed = Fusion.Computed
local OnEvent = Fusion.OnEvent
local Spring = Fusion.Spring

local UserInputService = game:GetService("UserInputService")

export type WindowProps = {
	Title: string,
	Subtitle: string?,
	Icon: string?,
	Size: UDim2?,
	MinSize: Vector2?,
	ToggleKey: Enum.KeyCode?,
	Resizable: boolean?,
	OnClose: (() -> ())?,
}

export type WindowHandle = {
	Instance: Frame,
	Content: Frame,
	Toggle: () -> (),
	Show: () -> (),
	Hide: () -> (),
	Close: () -> (),
}

local function Window(props: WindowProps): WindowHandle
	local theme = Theme.Current
	local layer = Overlay.getLayer("Windows", 50)

	--- Current usable viewport (safe-area) in pixels, with a sane fallback.
	local function viewportSize(): Vector2
		local camera = workspace.CurrentCamera
		if camera and camera.ViewportSize.X > 0 then
			return camera.ViewportSize
		end
		return Vector2.new(1280, 720)
	end

	--- Clamps a pixel size so the window always fits on screen (phones!).
	--- Also guards against degenerate (zero/negative) sizes.
	local function clampToViewport(w: number, h: number): (number, number)
		local vp = viewportSize()
		local maxW = math.floor(vp.X * 0.92)
		local maxH = math.floor(vp.Y * 0.88)
		w = math.clamp(w, 120, maxW)
		h = math.clamp(h, 100, maxH)
		return w, h
	end

	--- Resolves a UDim2 (scale AND offset) into absolute pixels, so
	--- scale-based sizes like UDim2.fromScale(0.9, 0.8) work correctly.
	local function resolvePixels(udim: UDim2): (number, number)
		local vp = viewportSize()
		return math.floor(udim.X.Scale * vp.X + udim.X.Offset), math.floor(udim.Y.Scale * vp.Y + udim.Y.Offset)
	end

	local visible = Value(false)
	local position = Value(UDim2.fromScale(0.5, 0.5))

	local requested = props.Size or UDim2.fromOffset(680, 460)
	local initialW, initialH = clampToViewport(resolvePixels(requested))
	local size = Value(UDim2.fromOffset(initialW, initialH))

	-- The minimum can never exceed what fits on screen either.
	local requestedMin = props.MinSize or Vector2.new(420, 300)
	local minW, minH = clampToViewport(requestedMin.X, requestedMin.Y)
	local minSize = Vector2.new(minW, minH)

	-- Re-clamp when the viewport changes (rotation, resolution change).
	do
		local camera = workspace.CurrentCamera
		if camera then
			camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
				local current = Fusion.peek(size)
				local w, h = clampToViewport(current.X.Offset, current.Y.Offset)
				if w ~= current.X.Offset or h ~= current.Y.Offset then
					size:set(UDim2.fromOffset(w, h))
					position:set(UDim2.fromScale(0.5, 0.5))
				end
			end)
		end
	end

	local windowFrame: Frame
	local contentFrame: Frame

	local function show()
		visible:set(true)
		Sound.play("Open")
	end
	local function hide()
		visible:set(false)
		Sound.play("Close")
	end
	local function toggle()
		if Fusion.peek(visible) then
			hide()
		else
			show()
		end
	end

	-- Traffic light controls -----------------------------------------------
	local function controlDot(color: Color3, icon: string, onClick: () -> (), order: number): Instance
		local hovered = Value(false)
		return New("TextButton")({
			Size = UDim2.fromOffset(14, 14),
			BackgroundColor3 = color,
			Text = "",
			AutoButtonColor = false,
			LayoutOrder = order,
			[OnEvent("Activated")] = onClick,
			[OnEvent("MouseEnter")] = function()
				hovered:set(true)
			end,
			[OnEvent("MouseLeave")] = function()
				hovered:set(false)
			end,
			[Children] = {
				New("UICorner")({ CornerRadius = UDim.new(1, 0) }),
				Icons.render(icon, {
					Size = UDim2.fromOffset(8, 8),
					Position = UDim2.fromScale(0.5, 0.5),
					AnchorPoint = Vector2.new(0.5, 0.5),
					Color = Color3.new(0, 0, 0),
					Transparency = Computed(function()
						return Fusion.peek(hovered) and 0.2 or 1
					end),
				}),
			},
		})
	end

	-- Title bar --------------------------------------------------------------
	local titleBar = New("Frame")({
		Name = "TitleBar",
		Size = UDim2.new(1, 0, 0, 44),
		BackgroundTransparency = 1,
		[Children] = {
			New("UIPadding")({ PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14) }),
			New("UIListLayout")({
				FillDirection = Enum.FillDirection.Horizontal,
				Padding = UDim.new(0, 8),
				VerticalAlignment = Enum.VerticalAlignment.Center,
			}),
			New("Frame")({
				Name = "Controls",
				AutomaticSize = Enum.AutomaticSize.XY,
				BackgroundTransparency = 1,
				LayoutOrder = 1,
				[Children] = {
					New("UIListLayout")({
						FillDirection = Enum.FillDirection.Horizontal,
						Padding = UDim.new(0, 7),
						VerticalAlignment = Enum.VerticalAlignment.Center,
					}),
					controlDot(Color3.fromRGB(255, 95, 87), "x", function()
						hide()
						if props.OnClose then
							props.OnClose()
						end
					end, 1),
					controlDot(Color3.fromRGB(255, 189, 46), "minus", hide, 2),
					controlDot(Color3.fromRGB(40, 201, 64), "maximize-2", function()
						local vp = viewportSize()
						local w, h = clampToViewport(math.floor(vp.X * 0.85), math.floor(vp.Y * 0.85))
						size:set(UDim2.fromOffset(w, h))
						position:set(UDim2.fromScale(0.5, 0.5))
					end, 3),
				},
			}),
			props.Icon and Icons.render(props.Icon, {
				Size = UDim2.fromOffset(16, 16),
				LayoutOrder = 2,
				Color = Computed(function()
					return theme:get().Primary
				end),
			}) or nil,
			New("TextLabel")({
				AutomaticSize = Enum.AutomaticSize.XY,
				BackgroundTransparency = 1,
				Text = props.Title,
				Font = Enum.Font.GothamBold,
				TextSize = 14,
				TextColor3 = Computed(function()
					return theme:get().Text
				end),
				LayoutOrder = 3,
			}),
			props.Subtitle and New("TextLabel")({
				AutomaticSize = Enum.AutomaticSize.XY,
				BackgroundTransparency = 1,
				Text = props.Subtitle,
				Font = Enum.Font.Gotham,
				TextSize = 12,
				TextColor3 = Computed(function()
					return theme:get().TextMuted
				end),
				LayoutOrder = 4,
			}) or nil,
		},
	}) :: Frame

	-- Content ------------------------------------------------------------------
	contentFrame = New("Frame")({
		Name = "Content",
		Position = UDim2.fromOffset(0, 44),
		Size = UDim2.new(1, 0, 1, -44),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
	}) :: Frame

	-- Resize grip ----------------------------------------------------------------
	local resizing = false
	local resizeStart = Vector2.zero
	local startSize = Vector2.zero

	local resizeGrip = props.Resizable ~= false and New("TextButton")({
		Name = "ResizeGrip",
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -2, 1, -2),
		Size = UDim2.fromOffset(18, 18),
		BackgroundTransparency = 1,
		Text = "",
		ZIndex = 5,
		[Children] = {
			Icons.render("move-diagonal-2", {
				Size = UDim2.fromOffset(12, 12),
				Position = UDim2.fromScale(0.5, 0.5),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Color = Computed(function()
					return theme:get().TextDisabled
				end),
			}),
		},
	}) or nil

	if resizeGrip then
		(resizeGrip :: TextButton).InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				resizing = true
				resizeStart = Vector2.new(input.Position.X, input.Position.Y)
				local current = Fusion.peek(size)
				startSize = Vector2.new(current.X.Offset, current.Y.Offset)
			end
		end)
	end

	-- Window frame -----------------------------------------------------------------
	windowFrame = New("Frame")({
		Name = "AetherWindow",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = Spring(Computed(function()
			local base = Fusion.peek(position)
			if not Fusion.peek(visible) then
				return base + UDim2.fromOffset(0, 30)
			end
			return base
		end), 24, 0.85),
		Size = Spring(size, 30, 1),
		BackgroundColor3 = Computed(function()
			return theme:get().Background
		end),
		BackgroundTransparency = Spring(Computed(function()
			return Fusion.peek(visible) and 0 or 1
		end), 24, 1),
		Visible = Computed(function()
			return Fusion.peek(visible)
		end),
		Parent = layer,
		[Children] = {
			New("UICorner")({ CornerRadius = Computed(function()
				return UDim.new(0, theme:get().RadiusLg)
			end) }),
			New("UIStroke")({
				Color = Computed(function()
					return theme:get().Border
				end),
				Thickness = 1,
			}),
			titleBar,
			contentFrame,
			resizeGrip :: any,
		},
	}) :: Frame

	-- Dragging by title bar ------------------------------------------------------
	local dragging = false
	local dragStart = Vector2.zero
	local startPos = UDim2.new()

	titleBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = Vector2.new(input.Position.X, input.Position.Y)
			startPos = Fusion.peek(position)
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end
		local point = Vector2.new(input.Position.X, input.Position.Y)
		if dragging then
			local delta = point - dragStart
			position:set(UDim2.new(
				startPos.X.Scale, startPos.X.Offset + delta.X,
				startPos.Y.Scale, startPos.Y.Offset + delta.Y
			))
		elseif resizing then
			local delta = point - resizeStart
			local w, h = clampToViewport(startSize.X + delta.X, startSize.Y + delta.Y)
			size:set(UDim2.fromOffset(
				math.max(minSize.X, w),
				math.max(minSize.Y, h)
			))
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
			resizing = false
		end
	end)

	-- Global toggle keybind --------------------------------------------------------
	if props.ToggleKey then
		Keybinds.Register("window-toggle-" .. props.Title, {
			Key = props.ToggleKey,
			Description = "Toggle " .. props.Title,
			Callback = toggle,
		})
	end

	task.defer(show)

	return {
		Instance = windowFrame,
		Root = windowFrame,
		Content = contentFrame,
		Toggle = toggle,
		Show = show,
		Hide = hide,
		Close = function()
			hide()
			task.delay(0.3, function()
				windowFrame:Destroy()
			end)
		end,
	}
end

return Window
