--!strict
--[=[
	AetherUI · ScrollFrame
	ScrollingFrame with a slim, themed, auto-hiding scrollbar and
	automatic canvas sizing.
]=]

local Fusion = require(script.Parent.Parent.Core.Fusion)
local Theme = require(script.Parent.Parent.Core.Theme)

local New = Fusion.New
local Children = Fusion.Children
local Computed = Fusion.Computed

export type ScrollFrameProps = {
	Size: UDim2?,
	Position: UDim2?,
	AnchorPoint: Vector2?,
	Padding: number?,
	ListPadding: number?,
	Horizontal: boolean?,
	LayoutOrder: number?,
	ZIndex: number?,
	Parent: Instance?,
	Children: { Instance }?,
}

local function ScrollFrame(props: ScrollFrameProps): ScrollingFrame
	local theme = Theme.Current

	local inner: { Instance } = {
		New("UIListLayout")({
			FillDirection = props.Horizontal and Enum.FillDirection.Horizontal or Enum.FillDirection.Vertical,
			Padding = UDim.new(0, props.ListPadding or 8),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	}

	if props.Padding and props.Padding > 0 then
		table.insert(inner, New("UIPadding")({
			PaddingLeft = UDim.new(0, props.Padding),
			PaddingRight = UDim.new(0, props.Padding),
			PaddingTop = UDim.new(0, props.Padding),
			PaddingBottom = UDim.new(0, props.Padding),
		}))
	end

	if props.Children then
		for _, child in ipairs(props.Children) do
			table.insert(inner, child)
		end
	end

	return New("ScrollingFrame")({
		Name = "AetherScrollFrame",
		Size = props.Size or UDim2.fromScale(1, 1),
		Position = props.Position,
		AnchorPoint = props.AnchorPoint,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = Computed(function()
			return Fusion.peek(theme).Border
		end),
		ScrollBarImageTransparency = 0.2,
		ScrollingDirection = props.Horizontal and Enum.ScrollingDirection.X or Enum.ScrollingDirection.Y,
		AutomaticCanvasSize = props.Horizontal and Enum.AutomaticSize.X or Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		ElasticBehavior = Enum.ElasticBehavior.WhenScrollable,
		LayoutOrder = props.LayoutOrder,
		ZIndex = props.ZIndex,
		Parent = props.Parent,
		[Children] = inner,
	}) :: ScrollingFrame
end

return ScrollFrame
