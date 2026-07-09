--!strict
--[=[
	AetherUI · Breadcrumbs
	Path navigation with chevron separators; last crumb is emphasized.
]=]

local Fusion = require(script.Parent.Parent.Core.Fusion)
local Theme = require(script.Parent.Parent.Core.Theme)
local Icons = require(script.Parent.Parent.Core.Icons)
local Sound = require(script.Parent.Parent.Core.Sound)

local New = Fusion.New
local Children = Fusion.Children
local Value = Fusion.Value
local Computed = Fusion.Computed
local OnEvent = Fusion.OnEvent
local Spring = Fusion.Spring

export type Crumb = {
	Label: string,
	Icon: string?,
	OnClick: (() -> ())?,
}

export type BreadcrumbsProps = {
	Items: { Crumb },
	LayoutOrder: number?,
	Parent: Instance?,
}

local function Breadcrumbs(props: BreadcrumbsProps): Frame
	local theme = Theme.Current

	local children: { Instance } = {
		New("UIListLayout")({
			FillDirection = Enum.FillDirection.Horizontal,
			Padding = UDim.new(0, 6),
			VerticalAlignment = Enum.VerticalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	}

	local order = 0
	for i, crumb in ipairs(props.Items) do
		local isLast = i == #props.Items
		local hovered = Value(false)

		order += 1
		local crumbChildren: { Instance } = {
			New("UIListLayout")({
				FillDirection = Enum.FillDirection.Horizontal,
				Padding = UDim.new(0, 4),
				VerticalAlignment = Enum.VerticalAlignment.Center,
			}),
		}
		if crumb.Icon then
			table.insert(crumbChildren, Icons.render(crumb.Icon, {
				Size = UDim2.fromOffset(13, 13),
				LayoutOrder = 1,
				Color = Computed(function()
					local t = theme:get()
					return isLast and t.Text or t.TextMuted
				end),
			}))
		end
		table.insert(crumbChildren, New("TextLabel")({
			AutomaticSize = Enum.AutomaticSize.XY,
			BackgroundTransparency = 1,
			Text = crumb.Label,
			Font = isLast and Enum.Font.GothamBold or Enum.Font.GothamMedium,
			TextSize = 12,
			LayoutOrder = 2,
			TextColor3 = Spring(Computed(function()
				local t = theme:get()
				if isLast then
					return t.Text
				end
				return Fusion.peek(hovered) and t.Text or t.TextMuted
			end), 30, 1),
		}))

		table.insert(children, New("TextButton")({
			Name = "Crumb_" .. i,
			AutomaticSize = Enum.AutomaticSize.XY,
			BackgroundTransparency = 1,
			Text = "",
			LayoutOrder = order,
			[OnEvent("Activated")] = function()
				if not isLast and crumb.OnClick then
					Sound.play("Click")
					crumb.OnClick()
				end
			end,
			[OnEvent("MouseEnter")] = function()
				if not isLast then
					hovered:set(true)
				end
			end,
			[OnEvent("MouseLeave")] = function()
				hovered:set(false)
			end,
			[Children] = crumbChildren,
		}))

		if not isLast then
			order += 1
			table.insert(children, Icons.render("chevron-right", {
				Size = UDim2.fromOffset(12, 12),
				LayoutOrder = order,
				Color = Computed(function()
					return theme:get().TextDisabled
				end),
			}))
		end
	end

	return New("Frame")({
		Name = "AetherBreadcrumbs",
		Size = UDim2.new(1, 0, 0, 24),
		BackgroundTransparency = 1,
		LayoutOrder = props.LayoutOrder,
		Parent = props.Parent,
		[Children] = children,
	}) :: Frame
end

return Breadcrumbs
