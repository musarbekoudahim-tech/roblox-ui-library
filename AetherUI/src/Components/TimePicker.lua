--!strict
--[[
	AetherUI • Components/TimePicker

	Hour / minute spinner with 12h/24h support.

	props:
		Value: { Hour: number, Minute: number }?    (24h internally; defaults to now)
		Use24Hour: boolean?                          (default false)
		MinuteStep: number?                          (default 5)
		OnChanged: ((time: { Hour: number, Minute: number }) -> ())?
		LayoutOrder: number?    Parent: Instance?
]]

local Fusion = require(script.Parent.Parent.Core.Fusion)
local Theme = require(script.Parent.Parent.Core.Theme)
local Utils = require(script.Parent.Parent.Core.Utils)
local Primitives = require(script.Parent.Primitives)
local Button = require(script.Parent.Button)

local New = Fusion.New
local Children = Fusion.Children
local Computed = Fusion.Computed
local Value = Fusion.Value

return function(props: { [string]: any }): Frame
	local now = os.date("*t")
	local initial = props.Value or { Hour = now.hour, Minute = now.min }
	local use24 = props.Use24Hour == true
	local minuteStep: number = props.MinuteStep or 5

	local hour = Value(initial.Hour) -- always 0-23
	local minute = Value(initial.Minute)

	local function emit()
		if props.OnChanged then
			props.OnChanged({ Hour = hour:get(), Minute = minute:get() })
		end
	end

	local function shiftHour(delta: number)
		hour:set((hour:get() + delta) % 24)
		emit()
	end

	local function shiftMinute(delta: number)
		local m = minute:get() + delta * minuteStep
		if m >= 60 then
			m -= 60
			shiftHour(1)
		elseif m < 0 then
			m += 60
			shiftHour(-1)
		end
		minute:set(m)
		emit()
	end

	local function spinner(labelState: any, onUp: () -> (), onDown: () -> (), order: number): Frame
		return New("Frame")({
			Name = "Spinner",
			Size = UDim2.fromOffset(64, 118),
			BackgroundTransparency = 1,
			LayoutOrder = order,
			[Children] = {
				Primitives.List({ Padding = 4, HorizontalAlignment = Enum.HorizontalAlignment.Center }),
				Button({
					Icon = "chevron-up",
					Variant = "Ghost",
					Size = "Sm",
					LayoutOrder = 1,
					OnClick = onUp,
				}),
				New("Frame")({
					Name = "Display",
					Size = UDim2.fromOffset(56, 44),
					BackgroundColor3 = Computed(function()
						return Theme.Colors.SurfaceHigh:get()
					end),
					LayoutOrder = 2,
					[Children] = {
						Primitives.Corner("Md"),
						Primitives.Stroke(),
						Primitives.Text({
							Text = labelState,
							Size = 20,
							Bold = true,
							Font = "Mono",
							Props = {
								Size = UDim2.fromScale(1, 1),
								TextXAlignment = Enum.TextXAlignment.Center,
							},
						}),
					},
				}),
				Button({
					Icon = "chevron-down",
					Variant = "Ghost",
					Size = "Sm",
					LayoutOrder = 3,
					OnClick = onDown,
				}),
			},
		})
	end

	local hourLabel = Computed(function()
		local h = hour:get()
		if use24 then
			return Utils.PadZero(h)
		end
		local display = h % 12
		if display == 0 then
			display = 12
		end
		return Utils.PadZero(display)
	end)

	local minuteLabel = Computed(function()
		return Utils.PadZero(minute:get())
	end)

	local content: { any } = {
		Primitives.Corner("Lg"),
		Primitives.Stroke(),
		Primitives.Padding(12),
		Primitives.List({ Direction = "Horizontal", Padding = 8, VerticalAlignment = Enum.VerticalAlignment.Center }),
		spinner(hourLabel, function()
			shiftHour(1)
		end, function()
			shiftHour(-1)
		end, 1),
		Primitives.Text({
			Text = ":",
			Size = 20,
			Bold = true,
			LayoutOrder = 2,
		}),
		spinner(minuteLabel, function()
			shiftMinute(1)
		end, function()
			shiftMinute(-1)
		end, 3),
	}

	if not use24 then
		table.insert(content, Button({
			Text = Computed(function()
				return if hour:get() < 12 then "AM" else "PM"
			end),
			Variant = "Outline",
			Size = "Sm",
			LayoutOrder = 4,
			OnClick = function()
				shiftHour(12)
			end,
		}))
	end

	return New("Frame")({
		Name = "AetherTimePicker",
		AutomaticSize = Enum.AutomaticSize.XY,
		BackgroundColor3 = Computed(function()
			return Theme.Colors.Surface:get()
		end),
		LayoutOrder = props.LayoutOrder,
		Parent = props.Parent,
		[Children] = content,
	})
end
