--!strict
--[=[
	AetherUI · Tabs
	Variants: "underline" (animated indicator), "pill", "vertical".
	Supports icons per tab, disabled tabs, and lazy content mounting.
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
local ForPairs = Fusion.ForPairs

export type Tab = {
	Id: string,
	Label: string,
	Icon: string?,
	Disabled: boolean?,
	Content: (() -> Instance)?,
}

export type TabsProps = {
	Tabs: { Tab },
	Default: string?,
	Variant: ("underline" | "pill" | "vertical")?,
	OnChanged: ((id: string) -> ())?,
	Size: UDim2?,
	LayoutOrder: number?,
	Parent: Instance?,
}

local function Tabs(props: TabsProps): Frame
	local theme = Theme.Current
	local variant = props.Variant or "underline"
	local vertical = variant == "vertical"

	local active = Value(props.Default or (props.Tabs[1] and props.Tabs[1].Id) or "")
	local hovered = Value("")

	-- Track absolute layout of each tab button for the underline indicator
	local tabRefs: { [string]: TextButton } = {}
	local indicatorPos = Value(UDim2.new())
	local indicatorSize = Value(UDim2.new())

	local function refreshIndicator()
		local btn = tabRefs[Fusion.peek(active)]
		if not btn or variant ~= "underline" then
			return
		end
		indicatorPos:set(UDim2.fromOffset(btn.Position.X.Offset, 0))
		indicatorSize:set(UDim2.new(0, btn.AbsoluteSize.X, 0, 2))
	end

	local function select(id: string)
		if Fusion.peek(active) == id then
			return
		end
		active:set(id)
		Sound.play("Click")
		task.defer(refreshIndicator)
		if props.OnChanged then
			props.OnChanged(id)
		end
	end

	-- Tab list ----------------------------------------------------------
	local tabButtons: { Instance } = {
		New("UIListLayout")({
			FillDirection = vertical and Enum.FillDirection.Vertical or Enum.FillDirection.Horizontal,
			Padding = UDim.new(0, variant == "pill" and 4 or (vertical and 2 or 16)),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	}

	for i, tab in ipairs(props.Tabs) do
		local isActive = Computed(function()
			return Fusion.peek(active) == tab.Id
		end)
		local isHovered = Computed(function()
			return Fusion.peek(hovered) == tab.Id
		end)

		local innerChildren: { Instance } = {
			New("UIListLayout")({
				FillDirection = Enum.FillDirection.Horizontal,
				Padding = UDim.new(0, 6),
				VerticalAlignment = Enum.VerticalAlignment.Center,
				HorizontalAlignment = vertical and Enum.HorizontalAlignment.Left or Enum.HorizontalAlignment.Center,
			}),
			New("UIPadding")({
				PaddingLeft = UDim.new(0, vertical and 10 or (variant == "pill" and 12 or 2)),
				PaddingRight = UDim.new(0, variant == "pill" and 12 or 2),
			}),
		}

		if tab.Icon then
			table.insert(innerChildren, Icons.render(tab.Icon, {
				Size = UDim2.fromOffset(15, 15),
				LayoutOrder = 1,
				Color = Computed(function()
					local t = theme:get()
					if tab.Disabled then
						return t.TextDisabled
					end
					return Fusion.peek(isActive) and t.Text or t.TextMuted
				end),
			}))
		end

		table.insert(innerChildren, New("TextLabel")({
			AutomaticSize = Enum.AutomaticSize.X,
			Size = UDim2.new(0, 0, 1, 0),
			BackgroundTransparency = 1,
			Text = tab.Label,
			Font = Enum.Font.GothamMedium,
			TextSize = 13,
			LayoutOrder = 2,
			TextColor3 = Spring(Computed(function()
				local t = theme:get()
				if tab.Disabled then
					return t.TextDisabled
				end
				if Fusion.peek(isActive) then
					return t.Text
				end
				return Fusion.peek(isHovered) and t.Text or t.TextMuted
			end), 30, 1),
		}))

		local btn = New("TextButton")({
			Name = "Tab_" .. tab.Id,
			AutomaticSize = vertical and Enum.AutomaticSize.None or Enum.AutomaticSize.X,
			Size = vertical and UDim2.new(1, 0, 0, 34) or UDim2.new(0, 0, 1, 0),
			Text = "",
			AutoButtonColor = false,
			LayoutOrder = i,
			BackgroundColor3 = Computed(function()
				return theme:get().SurfaceHigh
			end),
			BackgroundTransparency = Spring(Computed(function()
				if variant == "underline" then
					return 1
				end
				if Fusion.peek(isActive) then
					return 0
				end
				return Fusion.peek(isHovered) and 0.5 or 1
			end), 30, 1),
			[OnEvent("Activated")] = function()
				if not tab.Disabled then
					select(tab.Id)
				end
			end,
			[OnEvent("MouseEnter")] = function()
				if not tab.Disabled then
					hovered:set(tab.Id)
					Sound.play("Hover")
				end
			end,
			[OnEvent("MouseLeave")] = function()
				if Fusion.peek(hovered) == tab.Id then
					hovered:set("")
				end
			end,
			[Children] = {
				New("UICorner")({ CornerRadius = Computed(function()
					return UDim.new(0, theme:get().RadiusSm)
				end) }),
				New("Frame")({
					Size = UDim2.fromScale(1, 1),
					BackgroundTransparency = 1,
					AutomaticSize = Enum.AutomaticSize.X,
					[Children] = innerChildren,
				}),
			},
		}) :: TextButton

		tabRefs[tab.Id] = btn
		table.insert(tabButtons, btn)
	end

	-- Underline indicator
	if variant == "underline" then
		table.insert(tabButtons, New("Frame")({
			Name = "Indicator",
			AnchorPoint = Vector2.new(0, 1),
			Position = Spring(Computed(function()
				local base = Fusion.peek(indicatorPos)
				return UDim2.new(0, base.X.Offset, 1, 0)
			end), 30, 1),
			Size = Spring(indicatorSize, 30, 1),
			BackgroundColor3 = Computed(function()
				return theme:get().Primary
			end),
			BorderSizePixel = 0,
			ZIndex = 2,
			[Children] = { New("UICorner")({ CornerRadius = UDim.new(1, 0) }) },
		}))
	end

	local tabList = New("Frame")({
		Name = "TabList",
		Size = vertical and UDim2.new(0, 160, 1, 0) or UDim2.new(1, 0, 0, 36),
		BackgroundTransparency = 1,
		[Children] = tabButtons,
	})

	-- initial indicator placement
	task.defer(refreshIndicator)

	-- Content -----------------------------------------------------------
	local contentPane = New("Frame")({
		Name = "Content",
		Size = vertical and UDim2.new(1, -172, 1, 0) or UDim2.new(1, 0, 1, -44),
		Position = vertical and UDim2.fromOffset(172, 0) or UDim2.fromOffset(0, 44),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		[Children] = ForPairs(Computed(function()
			-- lazy: only the active tab content is mounted
			local out: { [string]: Tab } = {}
			for _, tab in ipairs(props.Tabs) do
				if tab.Id == Fusion.peek(active) and tab.Content then
					out[tab.Id] = tab
				end
			end
			return out
		end), function(_, id: string, tab: Tab)
			local content = (tab.Content :: () -> Instance)()
			return id, content
		end),
	})

	return New("Frame")({
		Name = "AetherTabs",
		Size = props.Size or UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		LayoutOrder = props.LayoutOrder,
		Parent = props.Parent,
		[Children] = { tabList, contentPane },
	}) :: Frame
end

return Tabs
