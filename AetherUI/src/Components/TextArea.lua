--!strict
--[[
	AetherUI • Components/TextArea
	Multiline text field with counter and focus ring.

	props: Value?, Placeholder?, Rows?, MaxLength?, ShowCounter?, OnChanged?, Disabled?, LayoutOrder
]]

local Fusion = require(script.Parent.Parent.Core.Fusion)
local Theme = require(script.Parent.Parent.Core.Theme)
local Animation = require(script.Parent.Parent.Core.Animation)
local Primitives = require(script.Parent.Primitives)

local New = Fusion.New
local Children = Fusion.Children
local OnEvent = Fusion.OnEvent
local OnChange = Fusion.OnChange
local Computed = Fusion.Computed
local Tween = Fusion.Tween
local Value = Fusion.Value
local Ref = Fusion.Ref

return function(props: { [string]: any }): Frame
	local text = props.Value or Value("")
	local focused = Value(false)
	local boxRef = Value(nil :: TextBox?)

	local rows = props.Rows or 4
	local height = rows * 20 + 20

	return New("Frame")({
		Name = "AetherTextArea",
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, 0),
		LayoutOrder = props.LayoutOrder or 0,
		[Children] = {
			Primitives.List({ Gap = 4 }),
			New("Frame")({
				Name = "Field",
				BackgroundColor3 = Theme.Colors.Surface,
				Size = UDim2.new(1, 0, 0, height),
				LayoutOrder = 0,
				[Children] = {
					Primitives.Corner("Md"),
					Primitives.Stroke({
						Color = Tween(
							Computed(function()
								return if focused:get() then Theme.Colors.Primary:get() else Theme.Colors.Border:get()
							end),
							Animation.Presets.Fast
						),
						Transparency = Tween(
							Computed(function()
								return if focused:get() then 0 else 0.35
							end),
							Animation.Presets.Fast
						),
					}),
					Primitives.Padding(10),
					New("TextBox")({
						Name = "Input",
						BackgroundTransparency = 1,
						Text = text:get(),
						PlaceholderText = props.Placeholder or "",
						PlaceholderColor3 = Theme.Colors.TextDisabled,
						TextColor3 = Theme.Colors.Text,
						FontFace = Theme.Fonts.Body,
						TextSize = Theme.TextSizes.Md,
						TextXAlignment = Enum.TextXAlignment.Left,
						TextYAlignment = Enum.TextYAlignment.Top,
						TextWrapped = true,
						MultiLine = true,
						ClearTextOnFocus = false,
						TextEditable = not props.Disabled,
						Size = UDim2.fromScale(1, 1),
						ClipsDescendants = true,
						[Ref] = boxRef,
						[OnChange("Text")] = function(newText: string)
							local truncated = newText
							if props.MaxLength and #truncated > props.MaxLength then
								truncated = truncated:sub(1, props.MaxLength)
								local box = boxRef:get()
								if box then
									box.Text = truncated
								end
							end
							text:set(truncated)
							if props.OnChanged then
								props.OnChanged(truncated)
							end
						end,
						[OnEvent("Focused")] = function()
							focused:set(true)
						end,
						[OnEvent("FocusLost")] = function()
							focused:set(false)
						end,
					}),
				},
			}),
			Primitives.Text({
				Name = "Counter",
				Text = Computed(function()
					local max = props.MaxLength
					return if max then `{#text:get()}/{max}` else ""
				end),
				Size = "Xs",
				Muted = true,
				LayoutOrder = 1,
				Props = {
					Visible = props.ShowCounter == true and props.MaxLength ~= nil,
				},
			}),
		},
	}) :: Frame
end
