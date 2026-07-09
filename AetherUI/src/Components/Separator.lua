--!strict
--[=[
	AetherUI · Separator / Divider
	Horizontal or vertical hairline, optional centered label.
]=]

local Fusion = require(script.Parent.Parent.Core.Fusion)
local Theme = require(script.Parent.Parent.Core.Theme)

local New = Fusion.New
local Children = Fusion.Children
local Computed = Fusion.Computed

export type SeparatorProps = {
	Vertical: boolean?,
	Label: string?,
	LayoutOrder: number?,
	Parent: Instance?,
}

local function line(theme: any, size: UDim2): Frame
	return New("Frame")({
		Size = size,
		BackgroundColor3 = Computed(function()
			return Fusion.peek(theme).Border
		end),
		BorderSizePixel = 0,
	}) :: Frame
end

local function Separator(props: SeparatorProps): Frame
	local theme = Theme.Current

	if props.Vertical then
		return New("Frame")({
			Name = "AetherSeparator",
			Size = UDim2.new(0, 1, 1, 0),
			BackgroundColor3 = Computed(function()
				return Fusion.peek(theme).Border
			end),
			BorderSizePixel = 0,
			LayoutOrder = props.LayoutOrder,
			Parent = props.Parent,
		}) :: Frame
	end

	if props.Label then
		return New("Frame")({
			Name = "AetherSeparator",
			Size = UDim2.new(1, 0, 0, 16),
			BackgroundTransparency = 1,
			LayoutOrder = props.LayoutOrder,
			Parent = props.Parent,
			[Children] = {
				New("UIListLayout")({
					FillDirection = Enum.FillDirection.Horizontal,
					Padding = UDim.new(0, 10),
					VerticalAlignment = Enum.VerticalAlignment.Center,
				}),
				New("Frame")({
					Size = UDim2.new(0.5, -40, 0, 1),
					BackgroundColor3 = Computed(function()
						return Fusion.peek(theme).Border
					end),
					BorderSizePixel = 0,
					LayoutOrder = 1,
				}),
				New("TextLabel")({
					AutomaticSize = Enum.AutomaticSize.XY,
					BackgroundTransparency = 1,
					Text = props.Label,
					Font = Enum.Font.GothamMedium,
					TextSize = 11,
					TextColor3 = Computed(function()
						return Fusion.peek(theme).TextMuted
					end),
					LayoutOrder = 2,
				}),
				New("Frame")({
					Size = UDim2.new(0.5, -40, 0, 1),
					BackgroundColor3 = Computed(function()
						return Fusion.peek(theme).Border
					end),
					BorderSizePixel = 0,
					LayoutOrder = 3,
				}),
			},
		}) :: Frame
	end

	local _ = line
	return New("Frame")({
		Name = "AetherSeparator",
		Size = UDim2.new(1, 0, 0, 1),
		BackgroundColor3 = Computed(function()
			return Fusion.peek(theme).Border
		end),
		BorderSizePixel = 0,
		LayoutOrder = props.LayoutOrder,
		Parent = props.Parent,
	}) :: Frame
end

return Separator
