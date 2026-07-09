--!strict
--[=[
	AetherUI · Card / Section / GroupBox
	Elevated surfaces with optional header (title, description, icon, actions).
]=]

local Fusion = require(script.Parent.Parent.Core.Fusion)
local Theme = require(script.Parent.Parent.Core.Theme)
local Icons = require(script.Parent.Parent.Core.Icons)
local Primitives = require(script.Parent.Parent.Components.Primitives)

local New = Fusion.New
local Children = Fusion.Children
local Computed = Fusion.Computed

local Card = {}

export type CardProps = {
	Title: string?,
	Description: string?,
	Icon: string?,
	Glass: boolean?,
	Padding: number?,
	Size: UDim2?,
	AutomaticSize: Enum.AutomaticSize?,
	LayoutOrder: number?,
	Parent: Instance?,
	Children: { Instance }?,
	HeaderActions: { Instance }?,
}

function Card.Card(props: CardProps): Frame
	local theme = Theme.Current
	local body: { Instance } = {
		New("UIListLayout")({
			FillDirection = Enum.FillDirection.Vertical,
			Padding = UDim.new(0, 12),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	}

	if props.Title then
		local headerRow: { Instance } = {
			New("UIListLayout")({
				FillDirection = Enum.FillDirection.Horizontal,
				Padding = UDim.new(0, 8),
				VerticalAlignment = Enum.VerticalAlignment.Center,
			}),
		}

		if props.Icon then
			table.insert(headerRow, Icons.render(props.Icon, {
				Size = UDim2.fromOffset(16, 16),
				LayoutOrder = 1,
				Color = Computed(function()
					return Fusion.peek(theme).Primary
				end),
			}))
		end

		table.insert(headerRow, New("Frame")({
			Name = "Titles",
			AutomaticSize = Enum.AutomaticSize.XY,
			BackgroundTransparency = 1,
			LayoutOrder = 2,
			[Children] = {
				New("UIListLayout")({
					FillDirection = Enum.FillDirection.Vertical,
					Padding = UDim.new(0, 2),
				}),
				New("TextLabel")({
					AutomaticSize = Enum.AutomaticSize.XY,
					BackgroundTransparency = 1,
					Text = props.Title,
					Font = Enum.Font.GothamBold,
					TextSize = 14,
					TextColor3 = Computed(function()
						return Fusion.peek(theme).Text
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
						return Fusion.peek(theme).TextMuted
					end),
					TextXAlignment = Enum.TextXAlignment.Left,
					TextWrapped = true,
				}) or nil,
			},
		}))

		if props.HeaderActions then
			table.insert(headerRow, New("Frame")({
				Name = "Actions",
				AutomaticSize = Enum.AutomaticSize.XY,
				BackgroundTransparency = 1,
				LayoutOrder = 99,
				[Children] = {
					New("UIListLayout")({
						FillDirection = Enum.FillDirection.Horizontal,
						Padding = UDim.new(0, 6),
					}),
					props.HeaderActions :: any,
				},
			}))
		end

		table.insert(body, New("Frame")({
			Name = "Header",
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			LayoutOrder = 0,
			[Children] = headerRow,
		}))
	end

	if props.Children then
		for i, child in ipairs(props.Children) do
			if child:IsA("GuiObject") then
				child.LayoutOrder = i
			end
			table.insert(body, child)
		end
	end

	return Primitives.Surface({
		Name = "AetherCard",
		Size = props.Size or UDim2.new(1, 0, 0, 0),
		AutomaticSize = props.AutomaticSize or Enum.AutomaticSize.Y,
		Padding = props.Padding or 16,
		Glass = props.Glass,
		Shadow = true,
		LayoutOrder = props.LayoutOrder,
		Parent = props.Parent,
		[Children] = body,
	}) :: Frame
end

export type SectionProps = {
	Title: string,
	LayoutOrder: number?,
	Parent: Instance?,
	Children: { Instance }?,
}

function Card.Section(props: SectionProps): Frame
	local theme = Theme.Current
	local body: { Instance } = {
		New("UIListLayout")({
			FillDirection = Enum.FillDirection.Vertical,
			Padding = UDim.new(0, 10),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
		New("TextLabel")({
			Size = UDim2.new(1, 0, 0, 14),
			BackgroundTransparency = 1,
			Text = string.upper(props.Title),
			Font = Enum.Font.GothamBold,
			TextSize = 11,
			TextColor3 = Computed(function()
				return Fusion.peek(theme).TextMuted
			end),
			TextXAlignment = Enum.TextXAlignment.Left,
			LayoutOrder = 0,
		}),
	}

	if props.Children then
		for i, child in ipairs(props.Children) do
			if child:IsA("GuiObject") then
				child.LayoutOrder = i
			end
			table.insert(body, child)
		end
	end

	return New("Frame")({
		Name = "AetherSection",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = props.LayoutOrder,
		Parent = props.Parent,
		[Children] = body,
	}) :: Frame
end

return Card
