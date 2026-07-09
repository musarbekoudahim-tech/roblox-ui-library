--!strict
--[[
	AetherUI • Components/EmptyState

	Centered empty/zero-data state with icon, title, description and optional action.

	props:
		Icon: string?          Title: string
		Description: string?   ActionText: string?    OnAction: (() -> ())?
		Size: UDim2?           LayoutOrder: number?   Parent: Instance?
]]

local Fusion = require(script.Parent.Parent.Core.Fusion)
local Theme = require(script.Parent.Parent.Core.Theme)
local Primitives = require(script.Parent.Primitives)
local Button = require(script.Parent.Button)

local New = Fusion.New
local Children = Fusion.Children
local Computed = Fusion.Computed

return function(props: { [string]: any }): Frame
	local content: { any } = {
		Primitives.List({
			Padding = 10,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Center,
		}),
		Primitives.Padding({ Y = 32, X = 24 }),
	}

	if props.Icon then
		table.insert(content, New("Frame")({
			Name = "IconHalo",
			Size = UDim2.fromOffset(56, 56),
			BackgroundColor3 = Computed(function()
				return Theme.Colors.SurfaceHigh:get()
			end),
			LayoutOrder = 1,
			[Children] = {
				Primitives.Corner("Full"),
				Primitives.Icon({
					Name = props.Icon,
					Size = 24,
					Color = Computed(function()
						return Theme.Colors.TextMuted:get()
					end),
					Position = UDim2.fromScale(0.5, 0.5),
					AnchorPoint = Vector2.new(0.5, 0.5),
				}),
			},
		}))
	end

	table.insert(content, Primitives.Text({
		Text = props.Title or "Nothing here yet",
		Size = 15,
		Bold = true,
		LayoutOrder = 2,
	}))

	if props.Description then
		table.insert(content, Primitives.Text({
			Text = props.Description,
			Size = 12,
			Muted = true,
			Wrapped = true,
			LayoutOrder = 3,
			Props = {
				Size = UDim2.new(0, 320, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				TextXAlignment = Enum.TextXAlignment.Center,
			},
		}))
	end

	if props.ActionText then
		table.insert(content, Button({
			Text = props.ActionText,
			Variant = "Primary",
			Size = "Sm",
			LayoutOrder = 4,
			OnClick = props.OnAction,
		}))
	end

	return New("Frame")({
		Name = "AetherEmptyState",
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = props.Size or UDim2.new(1, 0, 0, 0),
		BackgroundTransparency = 1,
		LayoutOrder = props.LayoutOrder,
		Parent = props.Parent,
		[Children] = content,
	})
end
