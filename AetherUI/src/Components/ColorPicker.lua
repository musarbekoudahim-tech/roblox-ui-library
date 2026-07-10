--!strict
--[=[
	AetherUI · ColorPicker
	Advanced color picker: SV square + Hue bar, RGB/HEX inputs,
	preset swatches, copy-to-clipboard button, live preview.
]=]

local Fusion = require(script.Parent.Parent.Core.Fusion)
local Theme = require(script.Parent.Parent.Core.Theme)
local Icons = require(script.Parent.Parent.Core.Icons)
local Sound = require(script.Parent.Parent.Core.Sound)
local Utils = require(script.Parent.Parent.Core.Utils)
local Primitives = require(script.Parent.Parent.Components.Primitives)

local New = Fusion.New
local Children = Fusion.Children
local Value = Fusion.Value
local Computed = Fusion.Computed
local OnEvent = Fusion.OnEvent
local Spring = Fusion.Spring

local UserInputService = game:GetService("UserInputService")

export type ColorPickerProps = {
	Value: Color3?,
	Presets: { Color3 }?,
	ShowHex: boolean?,
	ShowRGB: boolean?,
	OnChanged: ((color: Color3) -> ())?,
	Size: UDim2?,
	LayoutOrder: number?,
	Parent: Instance?,
}

local DEFAULT_PRESETS: { Color3 } = {
	Color3.fromRGB(99, 102, 241),
	Color3.fromRGB(59, 130, 246),
	Color3.fromRGB(16, 185, 129),
	Color3.fromRGB(245, 158, 11),
	Color3.fromRGB(239, 68, 68),
	Color3.fromRGB(236, 72, 153),
	Color3.fromRGB(255, 255, 255),
	Color3.fromRGB(23, 23, 23),
}

local function ColorPicker(props: ColorPickerProps): Frame
	local theme = Theme.Current

	local initH, initS, initV = (props.Value or Color3.fromRGB(99, 102, 241)):ToHSV()
	local hue = Value(initH)
	local sat = Value(initS)
	local val = Value(initV)

	local draggingSV = Value(false)
	local draggingHue = Value(false)
	local copied = Value(false)

	local color = Computed(function()
		return Color3.fromHSV(Fusion.peek(hue), Fusion.peek(sat), Fusion.peek(val))
	end)

	local function emit()
		if props.OnChanged then
			props.OnChanged(Fusion.peek(color))
		end
	end

	local function setFromColor(c: Color3)
		local h, s, v = c:ToHSV()
		hue:set(h)
		sat:set(s)
		val:set(v)
		emit()
	end

	local hexText = Computed(function()
		return Utils.ToHex(Fusion.peek(color))
	end)

	-- SV square ---------------------------------------------------------
	local svSquare = New("ImageButton")({
		Name = "SVSquare",
		Size = UDim2.new(1, 0, 0, 140),
		BackgroundColor3 = Computed(function()
			return Color3.fromHSV(Fusion.peek(hue), 1, 1)
		end),
		AutoButtonColor = false,
		[Children] = {
			New("UICorner")({ CornerRadius = Computed(function()
				return UDim.new(0, theme:get().RadiusSm)
			end) }),
			-- white → transparent horizontal
			New("Frame")({
				Size = UDim2.fromScale(1, 1),
				BackgroundColor3 = Color3.new(1, 1, 1),
				[Children] = {
					New("UIGradient")({
						Transparency = NumberSequence.new({
							NumberSequenceKeypoint.new(0, 0),
							NumberSequenceKeypoint.new(1, 1),
						}),
					}),
					New("UICorner")({ CornerRadius = UDim.new(0, 8) }),
				},
			}),
			-- transparent → black vertical
			New("Frame")({
				Size = UDim2.fromScale(1, 1),
				BackgroundColor3 = Color3.new(0, 0, 0),
				[Children] = {
					New("UIGradient")({
						Rotation = 90,
						Transparency = NumberSequence.new({
							NumberSequenceKeypoint.new(0, 1),
							NumberSequenceKeypoint.new(1, 0),
						}),
					}),
					New("UICorner")({ CornerRadius = UDim.new(0, 8) }),
				},
			}),
			-- Thumb
			New("Frame")({
				Name = "Thumb",
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = Spring(Computed(function()
					return UDim2.fromScale(Fusion.peek(sat), 1 - Fusion.peek(val))
				end), 40, 1),
				Size = Computed(function()
					return Fusion.peek(draggingSV) and UDim2.fromOffset(18, 18) or UDim2.fromOffset(14, 14)
				end),
				BackgroundColor3 = color,
				ZIndex = 3,
				[Children] = {
					New("UICorner")({ CornerRadius = UDim.new(1, 0) }),
					New("UIStroke")({ Color = Color3.new(1, 1, 1), Thickness = 2 }),
				},
			}),
		},
	}) :: ImageButton

	local function updateSV(input: InputObject)
		local pos = svSquare.AbsolutePosition
		local size = svSquare.AbsoluteSize
		local x = math.clamp((input.Position.X - pos.X) / size.X, 0, 1)
		local y = math.clamp((input.Position.Y - pos.Y) / size.Y, 0, 1)
		sat:set(x)
		val:set(1 - y)
		emit()
	end

	svSquare.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			draggingSV:set(true)
			updateSV(input)
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if Fusion.peek(draggingSV) and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			updateSV(input)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			draggingSV:set(false)
			draggingHue:set(false)
		end
	end)

	-- Hue bar -----------------------------------------------------------
	local hueKeypoints = {}
	for i = 0, 6 do
		table.insert(hueKeypoints, ColorSequenceKeypoint.new(i / 6, Color3.fromHSV(i / 6, 1, 1)))
	end

	local hueBar = New("ImageButton")({
		Name = "HueBar",
		Size = UDim2.new(1, 0, 0, 14),
		BackgroundColor3 = Color3.new(1, 1, 1),
		AutoButtonColor = false,
		[Children] = {
			New("UIGradient")({ Color = ColorSequence.new(hueKeypoints) }),
			New("UICorner")({ CornerRadius = UDim.new(1, 0) }),
			New("Frame")({
				Name = "Thumb",
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = Spring(Computed(function()
					return UDim2.fromScale(Fusion.peek(hue), 0.5)
				end), 40, 1),
				Size = UDim2.fromOffset(18, 18),
				BackgroundColor3 = Computed(function()
					return Color3.fromHSV(Fusion.peek(hue), 1, 1)
				end),
				ZIndex = 3,
				[Children] = {
					New("UICorner")({ CornerRadius = UDim.new(1, 0) }),
					New("UIStroke")({ Color = Color3.new(1, 1, 1), Thickness = 2 }),
				},
			}),
		},
	}) :: ImageButton

	local function updateHue(input: InputObject)
		local pos = hueBar.AbsolutePosition
		local size = hueBar.AbsoluteSize
		local x = math.clamp((input.Position.X - pos.X) / size.X, 0, 1)
		hue:set(x)
		emit()
	end

	hueBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			draggingHue:set(true)
			updateHue(input)
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if Fusion.peek(draggingHue) and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			updateHue(input)
		end
	end)

	-- HEX row -----------------------------------------------------------
	local hexBox = New("TextBox")({
		Name = "HexInput",
		Size = UDim2.new(1, -76, 1, 0),
		BackgroundColor3 = Computed(function()
			return theme:get().SurfaceHigh
		end),
		Text = hexText,
		TextColor3 = Computed(function()
			return theme:get().Text
		end),
		Font = Enum.Font.RobotoMono,
		TextSize = 13,
		ClearTextOnFocus = false,
		[Children] = {
			New("UICorner")({ CornerRadius = UDim.new(0, 8) }),
			New("UIStroke")({
				Color = Computed(function()
					return theme:get().Border
				end),
				Thickness = 1,
			}),
		},
	}) :: TextBox

	hexBox.FocusLost:Connect(function(enterPressed)
		if enterPressed then
			local parsed = Utils.FromHex(hexBox.Text)
			if parsed then
				setFromColor(parsed)
				Sound.play("Success")
			else
				hexBox.Text = Fusion.peek(hexText)
			end
		end
	end)

	local copyButton = New("TextButton")({
		Name = "CopyButton",
		Size = UDim2.fromOffset(32, 32),
		BackgroundColor3 = Computed(function()
			return theme:get().SurfaceHigh
		end),
		Text = "",
		AutoButtonColor = false,
		[OnEvent("Activated")] = function()
			-- setclipboard is exploit-env only; fall back to selecting text
			local ok = pcall(function()
				(getfenv() :: any).setclipboard(Fusion.peek(hexText))
			end)
			if not ok then
				hexBox:CaptureFocus()
			end
			copied:set(true)
			Sound.play("Click")
			task.delay(1.2, function()
				copied:set(false)
			end)
		end,
		[Children] = {
			New("UICorner")({ CornerRadius = UDim.new(0, 8) }),
			New("UIStroke")({
				Color = Computed(function()
					return theme:get().Border
				end),
				Thickness = 1,
			}),
			Icons.render(Computed(function()
				return Fusion.peek(copied) and "check" or "copy"
			end), {
				Size = UDim2.fromOffset(14, 14),
				Position = UDim2.fromScale(0.5, 0.5),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Color = Computed(function()
					local t = theme:get()
					return Fusion.peek(copied) and t.Success or t.TextMuted
				end),
			}),
		},
	})

	-- Preview swatch
	local preview = New("Frame")({
		Name = "Preview",
		Size = UDim2.fromOffset(32, 32),
		BackgroundColor3 = Spring(color, 30, 1),
		[Children] = {
			New("UICorner")({ CornerRadius = UDim.new(0, 8) }),
			New("UIStroke")({
				Color = Computed(function()
					return theme:get().Border
				end),
				Thickness = 1,
			}),
		},
	})

	-- Presets row -------------------------------------------------------
	local presetChildren: { Instance } = {
		New("UIListLayout")({
			FillDirection = Enum.FillDirection.Horizontal,
			Padding = UDim.new(0, 6),
			VerticalAlignment = Enum.VerticalAlignment.Center,
		}),
	}
	for i, presetColor in ipairs(props.Presets or DEFAULT_PRESETS) do
		table.insert(presetChildren, New("TextButton")({
			Name = "Preset" .. i,
			Size = UDim2.fromOffset(22, 22),
			BackgroundColor3 = presetColor,
			Text = "",
			AutoButtonColor = false,
			LayoutOrder = i,
			[OnEvent("Activated")] = function()
				setFromColor(presetColor)
				Sound.play("Click")
			end,
			[Children] = {
				New("UICorner")({ CornerRadius = UDim.new(1, 0) }),
				New("UIStroke")({
					Color = Computed(function()
						return theme:get().Border
					end),
					Thickness = 1,
					Transparency = 0.4,
				}),
			},
		}))
	end

	return Primitives.Surface({
		Name = "AetherColorPicker",
		Size = props.Size or UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = props.LayoutOrder,
		Parent = props.Parent,
		Padding = 12,
		[Children] = {
			New("UIListLayout")({
				FillDirection = Enum.FillDirection.Vertical,
				Padding = UDim.new(0, 10),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
			svSquare,
			hueBar,
			New("Frame")({
				Name = "HexRow",
				Size = UDim2.new(1, 0, 0, 32),
				BackgroundTransparency = 1,
				LayoutOrder = 3,
				[Children] = {
					New("UIListLayout")({
						FillDirection = Enum.FillDirection.Horizontal,
						Padding = UDim.new(0, 6),
						VerticalAlignment = Enum.VerticalAlignment.Center,
					}),
					preview,
					hexBox,
					copyButton,
				},
			}),
			New("Frame")({
				Name = "Presets",
				Size = UDim2.new(1, 0, 0, 24),
				BackgroundTransparency = 1,
				LayoutOrder = 4,
				[Children] = presetChildren,
			}),
		},
	}) :: Frame
end

return ColorPicker
