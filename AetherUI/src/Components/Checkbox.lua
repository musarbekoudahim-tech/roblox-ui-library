--!strict
--[[
	AetherUI • Components/Checkbox
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

return function(props: { [string]: any }): TextButton
	local checked = props.Value or Value(false)
	local hovering = Value(false)

	local checkScale = Spring(
		Computed(function()
			return if checked:get() then 1 else 0
		end),
		Animation.Springs.Wobbly.Speed,
		Animation.Springs.Wobbly.Damping
	)

	local function toggle()
		if props.Disabled then
			return
		end
		checked:set(not checked:get())
		Sound.Play("Toggle")
		if props.OnChanged then
			props.OnChanged(checked:get())
		end
	end

	return New("TextButton")({
		Name = "AetherCheckbox",
		Text = "",
		AutoButtonColor = false,
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.XY,
		LayoutOrder = props.LayoutOrder or 0,
		[OnEvent("MouseEnter")] = function()
			hovering:set(true)
		end,
		[OnEvent("MouseLeave")] = function()
			hovering:set(false)
		end,
		[OnEvent("Activated")] = toggle,
		[Children] = {
			Primitives.List({
				Direction = Enum.FillDirection.Horizontal,
				Gap = 10,
				VerticalAlignment = Enum.VerticalAlignment.Top,
			}),

			New("Frame")({
				Name = "Box",
				BackgroundColor3 = Tween(
					Computed(function()
						return if checked:get() then Theme.Colors.Primary:get() else Theme.Colors.Surface:get()
					end),
					Animation.Presets.Fast
				),
				Size = UDim2.fromOffset(18, 18),
				LayoutOrder = 0,
				[Children] = {
					Primitives.Corner(5),
					Primitives.Stroke({
						Color = Tween(
							Computed(function()
								if checked:get() then
									return Theme.Colors.Primary:get()
								end
								return if hovering:get() then Theme.Colors.BorderStrong:get() else Theme.Colors.Border:get()
							end),
							Animation.Presets.Fast
						),
						Transparency = 0,
					}),
					New("Frame")({
						BackgroundTransparency = 1,
						Size = UDim2.fromScale(1, 1),
						[Children] = {
							New("UIScale")({ Scale = checkScale }),
							Primitives.Icon({
								Name = "check",
								Size = 12,
								Color = Theme.Colors.PrimaryText,
								Position = UDim2.fromScale(0.5, 0.5),
								AnchorPoint = Vector2.new(0.5, 0.5),
							}),
						},
					}),
				},
			}),

			if props.Label
				then New("Frame")({
					Name = "Copy",
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
