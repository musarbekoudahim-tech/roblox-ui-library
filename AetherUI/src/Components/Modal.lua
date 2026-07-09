--!strict
--[=[
	AetherUI · Modal / Dialog
	Backdrop blur + dim, scale/fade entrance, ESC to close, optional
	dragging by header, variants (default, danger, success).
]=]

local Fusion = require(script.Parent.Parent.Core.Fusion)
local Theme = require(script.Parent.Parent.Core.Theme)
local Icons = require(script.Parent.Parent.Core.Icons)
local Sound = require(script.Parent.Parent.Core.Sound)
local Overlay = require(script.Parent.Parent.Core.Overlay)
local Keybinds = require(script.Parent.Parent.Core.Keybinds)
local Button = require(script.Parent.Parent.Components.Button)

local New = Fusion.New
local Children = Fusion.Children
local Value = Fusion.Value
local Computed = Fusion.Computed
local OnEvent = Fusion.OnEvent
local Spring = Fusion.Spring

local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")

export type ModalAction = {
	Label: string,
	Variant: string?,
	OnClick: (() -> ())?,
	CloseOnClick: boolean?,
}

export type ModalProps = {
	Title: string,
	Description: string?,
	Icon: string?,
	Variant: ("default" | "danger" | "success")?,
	Size: UDim2?,
	Draggable: boolean?,
	CloseOnBackdrop: boolean?,
	BlurBackground: boolean?,
	Content: (() -> Instance)?,
	Actions: { ModalAction }?,
	OnClose: (() -> ())?,
}

export type ModalHandle = {
	Close: () -> (),
	Instance: Frame,
}

local activeBlur: BlurEffect? = nil
local openCount = 0

local function Modal(props: ModalProps): ModalHandle
	local theme = Theme.Current
	local layer = Overlay.getLayer("Modals", 100)

	local visible = Value(false)
	local closed = false

	openCount += 1

	-- world blur
	if props.BlurBackground ~= false then
		if not activeBlur then
			local blur = Instance.new("BlurEffect")
			blur.Name = "AetherUI_ModalBlur"
			blur.Size = 0
			blur.Parent = Lighting
			activeBlur = blur
		end
		task.spawn(function()
			local blur = activeBlur
			if blur then
				for i = blur.Size, 12, 2 do
					blur.Size = i
					task.wait()
				end
			end
		end)
	end

	local backdrop: Frame? = nil
	local escUnbind: (() -> ())? = nil
	local dragConn: RBXScriptConnection? = nil

	local function close()
		if closed then
			return
		end
		closed = true
		openCount = math.max(0, openCount - 1)
		visible:set(false)
		Sound.play("Close")
		if escUnbind then
			escUnbind()
		end
		if dragConn then
			dragConn:Disconnect()
		end

		if openCount == 0 and activeBlur then
			local blur = activeBlur
			activeBlur = nil
			task.spawn(function()
				for i = blur.Size, 0, -2 do
					blur.Size = i
					task.wait()
				end
				blur:Destroy()
			end)
		end

		task.delay(0.25, function()
			if backdrop then
				backdrop:Destroy()
			end
		end)
		if props.OnClose then
			props.OnClose()
		end
	end

	-- Header ------------------------------------------------------------
	local headerChildren: { Instance } = {
		New("UIListLayout")({
			FillDirection = Enum.FillDirection.Horizontal,
			Padding = UDim.new(0, 10),
			VerticalAlignment = Enum.VerticalAlignment.Center,
		}),
	}

	if props.Icon then
		table.insert(headerChildren, New("Frame")({
			Size = UDim2.fromOffset(34, 34),
			LayoutOrder = 1,
			BackgroundColor3 = Computed(function()
				local t = theme:get()
				if props.Variant == "danger" then
					return t.Danger
				elseif props.Variant == "success" then
					return t.Success
				end
				return t.Primary
			end),
			BackgroundTransparency = 0.85,
			[Children] = {
				New("UICorner")({ CornerRadius = UDim.new(0, 10) }),
				Icons.render(props.Icon, {
					Size = UDim2.fromOffset(17, 17),
					Position = UDim2.fromScale(0.5, 0.5),
					AnchorPoint = Vector2.new(0.5, 0.5),
					Color = Computed(function()
						local t = theme:get()
						if props.Variant == "danger" then
							return t.Danger
						elseif props.Variant == "success" then
							return t.Success
						end
						return t.Primary
					end),
				}),
			},
		}))
	end

	table.insert(headerChildren, New("Frame")({
		AutomaticSize = Enum.AutomaticSize.XY,
		BackgroundTransparency = 1,
		LayoutOrder = 2,
		[Children] = {
			New("UIListLayout")({ FillDirection = Enum.FillDirection.Vertical, Padding = UDim.new(0, 2) }),
			New("TextLabel")({
				AutomaticSize = Enum.AutomaticSize.XY,
				BackgroundTransparency = 1,
				Text = props.Title,
				Font = Enum.Font.GothamBold,
				TextSize = 15,
				TextColor3 = Computed(function()
					return theme:get().Text
				end),
				TextXAlignment = Enum.TextXAlignment.Left,
			}),
			props.Description and New("TextLabel")({
				AutomaticSize = Enum.AutomaticSize.XY,
				BackgroundTransparency = 1,
				Text = props.Description,
				Font = Enum.Font.Gotham,
				TextSize = 12,
				TextColor3 = Computed(function()
					return theme:get().TextMuted
				end),
				TextXAlignment = Enum.TextXAlignment.Left,
				TextWrapped = true,
			}) or nil,
		},
	}))

	-- Body assembly -------------------------------------------------------
	local bodyChildren: { Instance } = {
		New("UIListLayout")({
			FillDirection = Enum.FillDirection.Vertical,
			Padding = UDim.new(0, 14),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
		New("UIPadding")({
			PaddingLeft = UDim.new(0, 20),
			PaddingRight = UDim.new(0, 20),
			PaddingTop = UDim.new(0, 20),
			PaddingBottom = UDim.new(0, 20),
		}),
		New("Frame")({
			Name = "Header",
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			LayoutOrder = 1,
			[Children] = headerChildren,
		}),
	}

	if props.Content then
		local content = props.Content()
		if content:IsA("GuiObject") then
			content.LayoutOrder = 2
		end
		table.insert(bodyChildren, content)
	end

	if props.Actions then
		local actionButtons: { Instance } = {
			New("UIListLayout")({
				FillDirection = Enum.FillDirection.Horizontal,
				Padding = UDim.new(0, 8),
				HorizontalAlignment = Enum.HorizontalAlignment.Right,
			}),
		}
		for i, action in ipairs(props.Actions) do
			table.insert(actionButtons, Button({
				Text = action.Label,
				Variant = (action.Variant or "secondary") :: any,
				LayoutOrder = i,
				OnClick = function()
					if action.OnClick then
						action.OnClick()
					end
					if action.CloseOnClick ~= false then
						close()
					end
				end,
			}))
		end
		table.insert(bodyChildren, New("Frame")({
			Name = "Actions",
			Size = UDim2.new(1, 0, 0, 36),
			BackgroundTransparency = 1,
			LayoutOrder = 3,
			[Children] = actionButtons,
		}))
	end

	-- Dialog window -------------------------------------------------------
	local dialogPosition = Value(UDim2.fromScale(0.5, 0.5))

	local dialog = New("Frame")({
		Name = "Dialog",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = Spring(Computed(function()
			local base = Fusion.peek(dialogPosition)
			if not Fusion.peek(visible) then
				return base + UDim2.fromOffset(0, 24)
			end
			return base
		end), 26, 0.9),
		Size = props.Size or UDim2.fromOffset(420, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Computed(function()
			return theme:get().Surface
		end),
		BackgroundTransparency = Spring(Computed(function()
			return Fusion.peek(visible) and 0 or 1
		end), 26, 1),
		ZIndex = 102,
		[Children] = {
			New("UICorner")({ CornerRadius = Computed(function()
				return UDim.new(0, theme:get().RadiusLg)
			end) }),
			New("UIStroke")({
				Color = Computed(function()
					return theme:get().Border
				end),
				Thickness = 1,
				Transparency = Spring(Computed(function()
					return Fusion.peek(visible) and 0 or 1
				end), 26, 1),
			}),
			New("Frame")({
				Name = "Body",
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				[Children] = bodyChildren,
			}),
		},
	}) :: Frame

	-- Dragging ------------------------------------------------------------
	if props.Draggable then
		local dragging = false
		local dragStart = Vector2.zero
		local startPos = UDim2.new()
		dialog.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				local rel = input.Position.Y - dialog.AbsolutePosition.Y
				if rel <= 60 then -- header zone
					dragging = true
					dragStart = Vector2.new(input.Position.X, input.Position.Y)
					startPos = Fusion.peek(dialogPosition)
				end
			end
		end)
		dragConn = UserInputService.InputChanged:Connect(function(input)
			if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
				local delta = Vector2.new(input.Position.X, input.Position.Y) - dragStart
				dialogPosition:set(UDim2.new(
					startPos.X.Scale, startPos.X.Offset + delta.X,
					startPos.Y.Scale, startPos.Y.Offset + delta.Y
				))
			end
		end)
		UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				dragging = false
			end
		end)
	end

	-- Backdrop --------------------------------------------------------------
	backdrop = New("TextButton")({
		Name = "AetherModalBackdrop",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = Spring(Computed(function()
			return Fusion.peek(visible) and 0.45 or 1
		end), 26, 1),
		Text = "",
		AutoButtonColor = false,
		ZIndex = 101,
		Parent = layer,
		[OnEvent("Activated")] = function()
			if props.CloseOnBackdrop ~= false then
				close()
			end
		end,
		[Children] = { dialog },
	}) :: Frame

	-- ESC to close
	escUnbind = Keybinds.bindTransient(Enum.KeyCode.Escape, close)

	Sound.play("Open")
	task.defer(function()
		visible:set(true)
	end)

	return {
		Close = close,
		Instance = backdrop :: Frame,
	}
end

return Modal
