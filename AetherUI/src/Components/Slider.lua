--!strict
--[[
	AetherUI • Components/Slider
	Single-value and range slider with drag, step snapping, live tooltip and formatting.

	props:
		Min: number (default 0)      Max: number (default 100)     Step: number?
		Value: Fusion.Value<number>?           -- single mode
		RangeValue: Fusion.Value<{number}>?    -- {low, high} enables range mode
		Format: ((number) -> string)?          -- tooltip / label formatting
		Label: string?               ShowValue: boolean?           OnChanged: (any) -> ()?
		LayoutOrder
]]

local UserInputService = game:GetService("UserInputService")

local Fusion = require(script.Parent.Parent.Core.Fusion)
local Theme = require(script.Parent.Parent.Core.Theme)
local Animation = require(script.Parent.Parent.Core.Animation)
local Utils = require(script.Parent.Parent.Core.Utils)
local Primitives = require(script.Parent.Primitives)

local New = Fusion.New
local Children = Fusion.Children
local OnEvent = Fusion.OnEvent
local Computed = Fusion.Computed
local Tween = Fusion.Tween
local Value = Fusion.Value
local Ref = Fusion.Ref
local Spring = Fusion.Spring

local THUMB = 16
local TRACK = 5

return function(props: { [string]: any }): Frame
	local min = props.Min or 0
	local max = props.Max or 100
	local step = props.Step
	local format = props.Format or function(v: number)
		return Utils.FormatNumber(v, if step and step < 1 then 2 else 0)
	end

	local isRange = props.RangeValue ~= nil
	local single = props.Value or Value(min)
	local range = props.RangeValue or Value({ min, max })

	local trackRef = Value(nil :: Frame?)
	local draggingThumb = Value(nil :: string?) -- "single" | "low" | "high"
	local hoveringThumb = Value(false)

	local function snap(v: number): number
		v = Utils.Clamp(v, min, max)
		if step then
			v = Utils.Clamp(Utils.Round(v - min, step) + min, min, max)
		end
		return v
	end

	local function alphaOf(v: number): number
		return (v - min) / math.max(max - min, 1e-6)
	end

	local function setFromX(x: number, thumb: string)
		local track = trackRef:get()
		if not track then
			return
		end
		local alpha = Utils.Clamp((x - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
		local v = snap(min + alpha * (max - min))
		if isRange then
			local current = table.clone(range:get())
			if thumb == "low" then
				current[1] = math.min(v, current[2])
			else
				current[2] = math.max(v, current[1])
			end
			range:set(current)
			if props.OnChanged then
				props.OnChanged(current)
			end
		else
			single:set(v)
			if props.OnChanged then
				props.OnChanged(v)
			end
		end
	end

	-- Global drag tracking
	local moveConn: RBXScriptConnection? = nil
	local upConn: RBXScriptConnection? = nil

	local function endDrag()
		draggingThumb:set(nil)
		if moveConn then
			moveConn:Disconnect()
			moveConn = nil
		end
		if upConn then
			upConn:Disconnect()
			upConn = nil
		end
	end

	local function beginDrag(thumb: string)
		draggingThumb:set(thumb)
		moveConn = UserInputService.InputChanged:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
				setFromX(input.Position.X, thumb)
			end
		end)
		upConn = UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				endDrag()
			end
		end)
	end

	local function makeThumb(thumbId: string, alphaState: any): Instance
		local scale = Spring(
			Computed(function()
				return if draggingThumb:get() == thumbId then 1.25 elseif hoveringThumb:get() then 1.1 else 1
			end),
			Animation.Springs.Snappy.Speed,
			Animation.Springs.Snappy.Damping
		)
		return New("TextButton")({
			Name = "Thumb_" .. thumbId,
			Text = "",
			AutoButtonColor = false,
			BackgroundColor3 = Theme.Colors.Text,
			Size = UDim2.fromOffset(THUMB, THUMB),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = Computed(function()
				return UDim2.new(alphaState:get(), 0, 0.5, 0)
			end),
			ZIndex = 3,
			[OnEvent("MouseEnter")] = function()
				hoveringThumb:set(true)
			end,
			[OnEvent("MouseLeave")] = function()
				hoveringThumb:set(false)
			end,
			[OnEvent("MouseButton1Down")] = function()
				beginDrag(thumbId)
			end,
			[Children] = {
				New("UICorner")({ CornerRadius = UDim.new(1, 0) }),
				New("UIScale")({ Scale = scale }),
				Primitives.Stroke({ Color = Theme.Colors.Primary, Transparency = 0, Thickness = 2 }),
				-- Value tooltip while dragging
				New("Frame")({
					Name = "Tooltip",
					BackgroundColor3 = Theme.Colors.Elevated,
					AutomaticSize = Enum.AutomaticSize.XY,
					AnchorPoint = Vector2.new(0.5, 1),
					Position = UDim2.new(0.5, 0, 0, -8),
					Visible = Computed(function()
						return draggingThumb:get() == thumbId
					end),
					ZIndex = 5,
					[Children] = {
						Primitives.Corner("Sm"),
						Primitives.Stroke(),
						Primitives.Padding({ X = 8, Y = 4 }),
						Primitives.Text({
							Text = Computed(function()
								if isRange then
									local r = range:get()
									return format(if thumbId == "low" then r[1] else r[2])
								end
								return format(single:get())
							end),
							Size = "Xs",
							Font = "Mono",
						}),
					},
				}),
			},
		})
	end

	local lowAlpha = Computed(function()
		return if isRange then alphaOf(range:get()[1]) else 0
	end)
	local highAlpha = Computed(function()
		return if isRange then alphaOf(range:get()[2]) else alphaOf(single:get())
	end)

	local thumbs: { Instance } = {}
	if isRange then
		table.insert(thumbs, makeThumb("low", lowAlpha))
		table.insert(thumbs, makeThumb("high", highAlpha))
	else
		table.insert(thumbs, makeThumb("single", highAlpha))
	end

	local header: Instance? = nil
	if props.Label or props.ShowValue then
		header = New("Frame")({
			Name = "Header",
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 18),
			LayoutOrder = 0,
			[Children] = {
				Primitives.Text({ Text = props.Label or "", Size = "Sm" }),
				Primitives.Text({
					Text = Computed(function()
						if isRange then
							local r = range:get()
							return `{format(r[1])} – {format(r[2])}`
						end
						return format(single:get())
					end),
					Size = "Sm",
					Font = "Mono",
					Muted = true,
					Props = { Position = UDim2.fromScale(1, 0), AnchorPoint = Vector2.new(1, 0) },
				}),
			},
		})
	end

	return New("Frame")({
		Name = "AetherSlider",
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, 0),
		LayoutOrder = props.LayoutOrder or 0,
		[Children] = {
			Primitives.List({ Gap = 8 }),
			header,
			New("Frame")({
				Name = "TrackArea",
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, THUMB + 4),
				LayoutOrder = 1,
				[Children] = {
					New("TextButton")({
						Name = "Track",
						Text = "",
						AutoButtonColor = false,
						BackgroundColor3 = Theme.Colors.Secondary,
						Size = UDim2.new(1, 0, 0, TRACK),
						Position = UDim2.fromScale(0, 0.5),
						AnchorPoint = Vector2.new(0, 0.5),
						[Ref] = trackRef,
						[OnEvent("MouseButton1Down")] = function(x: number)
							-- click-to-seek then continue dragging nearest thumb
							local thumb = "single"
							if isRange then
								local track = trackRef:get()
								if track then
									local alpha = (x - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1)
									local r = range:get()
									thumb = if math.abs(alpha - alphaOf(r[1])) < math.abs(alpha - alphaOf(r[2]))
										then "low"
										else "high"
								end
							end
							setFromX(x, thumb)
							beginDrag(thumb)
						end,
						[Children] = {
							New("UICorner")({ CornerRadius = UDim.new(1, 0) }),
							-- Filled portion
							New("Frame")({
								Name = "Fill",
								BackgroundColor3 = Theme.Colors.Primary,
								Position = Tween(
									Computed(function()
										return UDim2.fromScale(lowAlpha:get(), 0)
									end),
									Animation.Presets.Fast
								),
								Size = Tween(
									Computed(function()
										return UDim2.fromScale(math.max(highAlpha:get() - lowAlpha:get(), 0), 1)
									end),
									Animation.Presets.Fast
								),
								[Children] = { New("UICorner")({ CornerRadius = UDim.new(1, 0) }) },
							}),
						},
					}),
					thumbs,
				},
			}),
		},
	}) :: Frame
end
