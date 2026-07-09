--!strict
--[[
	AetherUI • Components/Toggle (Switch)
	props: Label?, Description?, Value: Fusion.Value<boolean>?, Disabled?, OnChanged?, LayoutOrder
]]

local Fusion = require(script.Parent.Parent.Core.Fusion)
local Theme = require(script.Parent.Parent.Core.Theme)
local Animation = require(script.Parent.Parent.Core.Animation)
local Sound = require(script.Parent.Parent.Core.Sound)
local Primitives = require(script.Parent.Primitives)

local New = Fusion.New
local Children = Fusion.Children
local OnEvent = Fusion.OnEvent
local Computed = Fusion.Computed
local Tween = Fusion.Tween
local Spring = Fusion.Spring
local Value = Fusion.Value

local TRACK_W, TRACK_H, KNOB = 38, 22, 16

return function(props: { [string]: any }): TextButton
	local on = props.Value or Value(false)

	local knobAlpha = Spring(
		Computed(function()
			return if on:get() then 1 else 0
		end),
		Animation.Springs.Snappy.Speed,
		Animation.Springs.Snappy.Damping
	)

	local function toggle()
		if props.Disabled then
			return
		end
		on:set(not on:get())
		Sound.Play("Toggle")
		if props.OnChanged then
			props.OnChanged(on:get())
		end
	end

	return New("TextButton")({
		Name = "AetherToggle",
		Text = "",
		AutoButtonColor = false,
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.XY,
		LayoutOrder = props.LayoutOrder or 0,
		[OnEvent("Activated")] = toggle,
		[Children] = {
			Primitives.List({
				Direction = Enum.FillDirection.Horizontal,
				Gap = 10,
				VerticalAlignment = Enum.VerticalAlignment.Center,
			}),

			New("Frame")({
				Name = "Track",
				BackgroundColor3 = Tween(
					Computed(function()
						return if on:get() then Theme.Colors.Primary:get() else Theme.Colors.Secondary:get()
					end),
					Animation.Presets.Normal
				),
				BackgroundTransparency = if props.Disabled then 0.5 else 0,
				Size = UDim2.fromOffset(TRACK_W, TRACK_H),
				LayoutOrder = 0,
				[Children] = {
					New("UICorner")({ CornerRadius = UDim.new(1, 0) }),
					Primitives.Stroke({ Transparency = 0.6 }),
					New("Frame")({
						Name = "Knob",
						BackgroundColor3 = Color3.new(1, 1, 1),
						Size = UDim2.fromOffset(KNOB, KNOB),
						AnchorPoint = Vector2.new(0, 0.5),
						Position = Computed(function()
							local pad = (TRACK_H - KNOB) / 2
							local travel = TRACK_W - KNOB - pad * 2
							return UDim2.new(0, pad + knobAlpha:get() * travel, 0.5, 0)
						end),
						[Children] = {
							New("UICorner")({ CornerRadius = UDim.new(1, 0) }),
							Primitives.Shadow({ Size = 10, Transparency = 0.8 }),
						},
					}),
				},
			}),

			if props.Label
				then New("Frame")({
					BackgroundTransparency = 1,
					AutomaticSize = Enum.AutomaticSize.XY,
					LayoutOrder = 1,
					[Children] = {
						Primitives.List({ Gap = 2 }),
						Primitives.Text({
							Text = props.Label,
							Size = "Sm",
							Color = if props.Disabled then Theme.Colors.TextDisabled else Theme.Colors.Text,
						}),
						if props.Description
							then Primitives.Text({ Text = props.Description, Size = "Xs", Muted = true, Wrapped = true })
							else nil,
					},
				})
				else nil,
		},
	}) :: TextButton
end
