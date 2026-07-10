--!strict
--[[
	AetherUI • Components/Primitives
	Low-level themed building blocks shared by every component:
	corners, strokes, padding, soft shadows, glass, themed text, icons.
]]

local Fusion = require(script.Parent.Parent.Core.Fusion)
local Theme = require(script.Parent.Parent.Core.Theme)
local Icons = require(script.Parent.Parent.Core.Icons)

local New = Fusion.New
local Children = Fusion.Children
local Computed = Fusion.Computed

local SHADOW_IMAGE = "rbxassetid://6014261993" -- soft radial drop shadow (9-slice)

local Primitives = {}

--- UICorner bound to a theme radius token name ("Sm"|"Md"|"Lg"|"Xl"|"Full") or a number.
function Primitives.Corner(radius: any): Instance
	local value = if type(radius) == "string" then Theme.Radius[radius] else radius
	return New("UICorner")({
		CornerRadius = if type(value) == "number"
			then UDim.new(0, value)
			else Computed(function()
				return UDim.new(0, value:get())
			end),
	})
end

--- Themed hairline border. props: { Color?, Transparency?, Thickness? } (all optional / reactive-friendly).
function Primitives.Stroke(props: { [string]: any }?): Instance
	local p = props or {}
	return New("UIStroke")({
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Color = p.Color or Theme.Colors.Border,
		Transparency = p.Transparency or Theme.StrokeTransparency,
		Thickness = p.Thickness or 1,
	})
end

--- UIPadding. Accepts a number (all sides) or { Top?, Bottom?, Left?, Right?, X?, Y? }.
function Primitives.Padding(padding: any): Instance
	if type(padding) == "number" then
		local u = UDim.new(0, padding)
		return New("UIPadding")({
			PaddingTop = u,
			PaddingBottom = u,
			PaddingLeft = u,
			PaddingRight = u,
		})
	end
	local p = padding or {}
	return New("UIPadding")({
		PaddingTop = UDim.new(0, p.Top or p.Y or 0),
		PaddingBottom = UDim.new(0, p.Bottom or p.Y or 0),
		PaddingLeft = UDim.new(0, p.Left or p.X or 0),
		PaddingRight = UDim.new(0, p.Right or p.X or 0),
	})
end

--- Soft drop shadow rendered behind the parent. props: { Size?, Transparency?, Offset? }.
function Primitives.Shadow(props: { [string]: any }?): Instance
	local p = props or {}
	local spread = p.Size or 24
	return New("ImageLabel")({
		Name = "Shadow",
		BackgroundTransparency = 1,
		Image = SHADOW_IMAGE,
		ImageColor3 = Color3.new(0, 0, 0),
		ImageTransparency = p.Transparency or Theme.ShadowTransparency,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(49, 49, 450, 450),
		Size = UDim2.new(1, spread, 1, spread),
		Position = UDim2.new(0.5, 0, 0.5, p.Offset or 4),
		AnchorPoint = Vector2.new(0.5, 0.5),
		ZIndex = -1,
	})
end

--- Vertical or horizontal UIListLayout with sensible defaults.
function Primitives.List(props: { [string]: any }?): Instance
	local p = props or {}
	return New("UIListLayout")({
		FillDirection = p.Direction or Enum.FillDirection.Vertical,
		Padding = UDim.new(0, p.Gap or Theme.Spacing.Sm),
		SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = p.HorizontalAlignment or Enum.HorizontalAlignment.Left,
		VerticalAlignment = p.VerticalAlignment or Enum.VerticalAlignment.Top,
		HorizontalFlex = p.HorizontalFlex,
		VerticalFlex = p.VerticalFlex,
		Wraps = p.Wraps,
	})
end

--- Themed text label. props: Text, Size ("Xs".."Xxl" or number), Color, Font ("Body"|"Heading"|"Mono"),
--- Muted, Bold, Wrapped, XAlignment, plus any TextLabel overrides in Props.
function Primitives.Text(props: { [string]: any }): Instance
	local sizeToken = props.Size or "Md"
	local textSize = if type(sizeToken) == "number" then sizeToken else Theme.TextSizes[sizeToken] or 14
	local fontToken = props.Font or (if props.Bold then "Heading" else "Body")

	local label: { [any]: any } = {
		Name = props.Name or "Text",
		BackgroundTransparency = 1,
		Text = props.Text or "",
		FontFace = Theme.Fonts[fontToken],
		TextSize = textSize,
		TextColor3 = props.Color or (if props.Muted then Theme.Colors.TextMuted else Theme.Colors.Text),
		TextXAlignment = props.XAlignment or Enum.TextXAlignment.Left,
		TextYAlignment = props.YAlignment or Enum.TextYAlignment.Center,
		TextWrapped = props.Wrapped or false,
		TextTruncate = props.Truncate or Enum.TextTruncate.None,
		AutomaticSize = props.AutomaticSize or Enum.AutomaticSize.XY,
		Size = props.SizeUDim2 or UDim2.fromOffset(0, 0),
		Position = props.Position,
		AnchorPoint = props.AnchorPoint,
		LayoutOrder = props.LayoutOrder or 0,
		TextTransparency = props.Transparency or 0,
		RichText = props.RichText or false,
		ZIndex = props.ZIndex or 1,
	}
	for key, value in (props.Props or {}) :: { [string]: any } do
		label[key] = value
	end
	return New("TextLabel")(label)
end

--- Lucide icon. Renders an ImageLabel when the icon resolves, otherwise a subtle dot glyph.
--- props: { Name, Size?, Color?, Transparency?, LayoutOrder?, Position?, AnchorPoint?, Rotation? }
function Primitives.Icon(props: { [string]: any }): Instance
	local size = props.Size or 16
	local data = Icons.Get(props.Name)

	if data then
		return New("ImageLabel")({
			Name = "Icon",
			BackgroundTransparency = 1,
			Image = data.Id,
			ImageRectOffset = data.ImageRectOffset or Vector2.zero,
			ImageRectSize = data.ImageRectSize or Vector2.zero,
			ImageColor3 = props.Color or Theme.Colors.Text,
			ImageTransparency = props.Transparency or 0,
			Size = UDim2.fromOffset(size, size),
			Position = props.Position,
			AnchorPoint = props.AnchorPoint,
			LayoutOrder = props.LayoutOrder or 0,
			Rotation = props.Rotation or 0,
			ZIndex = props.ZIndex or 1,
		})
	end

	-- Graceful fallback: a small themed dot so layouts never break
	return New("Frame")({
		Name = "IconFallback",
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(size, size),
		Position = props.Position,
		AnchorPoint = props.AnchorPoint,
		LayoutOrder = props.LayoutOrder or 0,
		[Children] = {
			New("Frame")({
				BackgroundColor3 = props.Color or Theme.Colors.TextMuted,
				BackgroundTransparency = 0.35,
				Size = UDim2.fromOffset(math.max(4, size // 3), math.max(4, size // 3)),
				Position = UDim2.fromScale(0.5, 0.5),
				AnchorPoint = Vector2.new(0.5, 0.5),
				[Children] = { New("UICorner")({ CornerRadius = UDim.new(1, 0) }) },
			}),
		},
	})
end

--[[
	Themed elevated container: Surface background + rounded corner + hairline
	stroke, with optional glassmorphism, drop shadow, and padding.
	props: { Name?, Size?, AutomaticSize?, Padding? (number|table), Glass?,
	Shadow?, LayoutOrder?, Parent?, ClipsDescendants?, [Children]? }
]]
function Primitives.Surface(props: { [any]: any }): Instance
	local inner: { any } = {}

	if props.Glass then
		for _, deco in Primitives.Glass("Lg") do
			table.insert(inner, deco)
		end
	else
		table.insert(inner, Primitives.Corner("Lg"))
		table.insert(inner, Primitives.Stroke(nil))
	end

	if props.Shadow then
		table.insert(inner, Primitives.Shadow(nil))
	end

	if props.Padding ~= nil and props.Padding ~= 0 then
		table.insert(inner, Primitives.Padding(props.Padding))
	end

	local extra = props[Children]
	if extra ~= nil then
		table.insert(inner, extra)
	end

	return New("Frame")({
		Name = props.Name or "Surface",
		Size = props.Size or UDim2.new(1, 0, 0, 0),
		AutomaticSize = props.AutomaticSize,
		BackgroundColor3 = Theme.Colors.Surface,
		BackgroundTransparency = if props.Glass then Theme.GlassTransparency else 0,
		LayoutOrder = props.LayoutOrder,
		ClipsDescendants = props.ClipsDescendants,
		Parent = props.Parent,
		[Children] = inner,
	})
end

--- Glassmorphism surface children: translucent fill + hairline stroke + top sheen.
function Primitives.Glass(radius: any?): { Instance }
	return {
		Primitives.Corner(radius or "Lg"),
		Primitives.Stroke({
			Transparency = Computed(function()
				return math.clamp(Theme.StrokeTransparency:get() - 0.1, 0, 1)
			end),
		}),
		New("UIGradient")({
			Rotation = 90,
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0),
				NumberSequenceKeypoint.new(0.12, 0.35),
				NumberSequenceKeypoint.new(1, 0.45),
			}),
			Color = ColorSequence.new(Color3.new(1, 1, 1)),
			Enabled = false, -- sheen kept subtle; flip Enabled for extra shine
		}),
	}
end

return Primitives
