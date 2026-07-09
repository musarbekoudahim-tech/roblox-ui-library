--!strict
--[[
	AetherUI • Components/RadioGroup
	props:
		Items: { { Label: string, Value: any, Description: string? } }
		Value: Fusion.Value<any>?
		Direction: Enum.FillDirection?   OnChanged?, LayoutOrder
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
local Spring = Fusion.Spring
local Tween = Fusion.Tween
local Value = Fusion.Value
local ForValues = Fusion.ForValues

return function(props: { [string]: any }): Frame
	local selected = props.Value or Value(nil)

	local function makeOption(item: any): Instance
		local hovering = Value(false)
		local isSelected = Computed(function()
			return selected:get() == item.Value
		end)
		local dotScale = Spring(
			Computed(function()
				return if isSelected:get() then 1 else 0
			end),
			Animation.Springs.Wobbly.Speed,
			Animation.Springs.Wobbly.Damping
		)

		return New("TextButton")({
			Name = "Radio",
			Text = "",
			AutoButtonColor = false,
			BackgroundTransparency = 1,
			AutomaticSize = Enum.AutomaticSize.XY,
			[OnEvent("MouseEnter")] = function()
				hovering:set(true)
			end,
			[OnEvent("MouseLeave")] = function()
				hovering:set(false)
			end,
			[OnEvent("Activated")] = function()
				selected:set(item.Value)
				Sound.Play("Click")
				if props.OnChanged then
					props.OnChanged(item.Value)
				end
			end,
			[Children] = {
				Primitives.List({
					Direction = Enum.FillDirection.Horizontal,
					Gap = 10,
					VerticalAlignment = Enum.VerticalAlignment.Top,
				}),
				New("Frame")({
					Name = "Circle",
					BackgroundColor3 = Theme.Colors.Surface,
					Size = UDim2.fromOffset(18, 18),
					LayoutOrder = 0,
					[Children] = {
						New("UICorner")({ CornerRadius = UDim.new(1, 0) }),
						Primitives.Stroke({
							Color = Tween(
								Computed(function()
									if isSelected:get() then
										return Theme.Colors.Primary:get()
									end
									return if hovering:get() then Theme.Colors.BorderStrong:get() else Theme.Colors.Border:get()
								end),
								Animation.Presets.Fast
							),
							Transparency = 0,
							Thickness = Computed(function()
								return if isSelected:get() then 1.5 else 1
							end),
						}),
						New("Frame")({
							Name = "Dot",
							BackgroundColor3 = Theme.Colors.Primary,
							Size = UDim2.fromOffset(8, 8),
							Position = UDim2.fromScale(0.5, 0.5),
							AnchorPoint = Vector2.new(0.5, 0.5),
							[Children] = {
								New("UICorner")({ CornerRadius = UDim.new(1, 0) }),
								New("UIScale")({ Scale = dotScale }),
							},
						}),
					},
				}),
				New("Frame")({
					BackgroundTransparency = 1,
					AutomaticSize = Enum.AutomaticSize.XY,
					LayoutOrder = 1,
					[Children] = {
						Primitives.List({ Gap = 2 }),
						Primitives.Text({ Text = item.Label, Size = "Sm" }),
						if item.Description
							then Primitives.Text({ Text = item.Description, Size = "Xs", Muted = true, Wrapped = true })
							else nil,
					},
				}),
			},
		})
	end

	return New("Frame")({
		Name = "AetherRadioGroup",
		Parent = props.Parent,
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.XY,
		LayoutOrder = props.LayoutOrder or 0,
		[Children] = {
			Primitives.List({
				Direction = props.Direction or Enum.FillDirection.Vertical,
				Gap = 10,
			}),
			ForValues(props.Items or {}, function(item: any)
				return makeOption(item)
			end, Fusion.cleanup),
		},
	}) :: Frame
end
