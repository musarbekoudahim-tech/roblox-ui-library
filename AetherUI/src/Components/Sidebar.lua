--!strict
--[=[
	AetherUI · Sidebar / Navigation
	Collapsible navigation rail with sections, icons, badges and an
	animated active-item indicator.
]=]

local Fusion = require(script.Parent.Parent.Core.Fusion)
local Theme = require(script.Parent.Parent.Core.Theme)
local Icons = require(script.Parent.Parent.Core.Icons)
local Sound = require(script.Parent.Parent.Core.Sound)
local ScrollFrame = require(script.Parent.Parent.Components.ScrollFrame)

local New = Fusion.New
local Children = Fusion.Children
local Value = Fusion.Value
local Computed = Fusion.Computed
local OnEvent = Fusion.OnEvent
local Spring = Fusion.Spring

export type NavItem = {
	Id: string,
	Label: string,
	Icon: string,
	Badge: string?,
	Section: string?,
}

export type SidebarProps = {
	Items: { NavItem },
	Default: string?,
	Title: string?,
	Collapsible: boolean?,
	OnChanged: ((id: string) -> ())?,
	Size: UDim2?,
	Parent: Instance?,
}

export type SidebarHandle = {
	Instance: Frame,
	SetActive: (id: string) -> (),
	Toggle: () -> (),
}

local EXPANDED = 220
local COLLAPSED = 60

local function Sidebar(props: SidebarProps): SidebarHandle
	local theme = Theme.Current
	local active = Value(props.Default or (props.Items[1] and props.Items[1].Id) or "")
	local collapsed = Value(false)

	local function select(id: string)
		if Fusion.peek(active) == id then
			return
		end
		active:set(id)
		Sound.play("Click")
		if props.OnChanged then
			props.OnChanged(id)
		end
	end

	-- Build item rows grouped by section --------------------------------
	local navChildren: { Instance } = {}
	local lastSection: string? = nil
	local order = 0

	for _, item in ipairs(props.Items) do
		if item.Section and item.Section ~= lastSection then
			lastSection = item.Section
			order += 1
			table.insert(navChildren, New("TextLabel")({
				Size = UDim2.new(1, 0, 0, 22),
				BackgroundTransparency = 1,
				Text = string.upper(item.Section),
				Font = Enum.Font.GothamBold,
				TextSize = 10,
				TextColor3 = Computed(function()
					return theme:get().TextMuted
				end),
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTransparency = Spring(Computed(function()
					return Fusion.peek(collapsed) and 1 or 0
				end), 30, 1),
				LayoutOrder = order,
				[Children] = {
					New("UIPadding")({ PaddingLeft = UDim.new(0, 10), PaddingTop = UDim.new(0, 8) }),
				},
			}))
		end

		order += 1
		local isActive = Computed(function()
			return Fusion.peek(active) == item.Id
		end)
		local hovered = Value(false)

		table.insert(navChildren, New("TextButton")({
			Name = "Nav_" .. item.Id,
			Size = UDim2.new(1, 0, 0, 36),
			Text = "",
			AutoButtonColor = false,
			LayoutOrder = order,
			BackgroundColor3 = Computed(function()
				local t = theme:get()
				return Fusion.peek(isActive) and t.Primary or t.SurfaceHigh
			end),
			BackgroundTransparency = Spring(Computed(function()
				if Fusion.peek(isActive) then
					return 0.85
				end
				return Fusion.peek(hovered) and 0.6 or 1
			end), 30, 1),
			[OnEvent("Activated")] = function()
				select(item.Id)
			end,
			[OnEvent("MouseEnter")] = function()
				hovered:set(true)
				Sound.play("Hover")
			end,
			[OnEvent("MouseLeave")] = function()
				hovered:set(false)
			end,
			[Children] = {
				New("UICorner")({ CornerRadius = Computed(function()
					return UDim.new(0, theme:get().RadiusSm)
				end) }),
				-- Active indicator pill
				New("Frame")({
					AnchorPoint = Vector2.new(0, 0.5),
					Position = UDim2.new(0, 0, 0.5, 0),
					Size = Spring(Computed(function()
						return Fusion.peek(isActive) and UDim2.fromOffset(3, 18) or UDim2.fromOffset(3, 0)
					end), 30, 1),
					BackgroundColor3 = Computed(function()
						return theme:get().Primary
					end),
					BorderSizePixel = 0,
					[Children] = { New("UICorner")({ CornerRadius = UDim.new(1, 0) }) },
				}),
				Icons.render(item.Icon, {
					Size = UDim2.fromOffset(17, 17),
					Position = UDim2.new(0, 12, 0.5, 0),
					AnchorPoint = Vector2.new(0, 0.5),
					Color = Computed(function()
						local t = theme:get()
						return Fusion.peek(isActive) and t.Primary or t.TextMuted
					end),
				}),
				New("TextLabel")({
					Position = UDim2.new(0, 38, 0, 0),
					Size = UDim2.new(1, -70, 1, 0),
					BackgroundTransparency = 1,
					Text = item.Label,
					Font = Enum.Font.GothamMedium,
					TextSize = 13,
					TextColor3 = Computed(function()
						local t = theme:get()
						return Fusion.peek(isActive) and t.Text or t.TextMuted
					end),
					TextXAlignment = Enum.TextXAlignment.Left,
					TextTransparency = Spring(Computed(function()
						return Fusion.peek(collapsed) and 1 or 0
					end), 30, 1),
					TextTruncate = Enum.TextTruncate.AtEnd,
				}),
				item.Badge and New("TextLabel")({
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, -10, 0.5, 0),
					AutomaticSize = Enum.AutomaticSize.XY,
					BackgroundColor3 = Computed(function()
						return theme:get().Primary
					end),
					Text = item.Badge,
					Font = Enum.Font.GothamBold,
					TextSize = 10,
					TextColor3 = Computed(function()
						return theme:get().PrimaryText
					end),
					TextTransparency = Spring(Computed(function()
						return Fusion.peek(collapsed) and 1 or 0
					end), 30, 1),
					BackgroundTransparency = Spring(Computed(function()
						return Fusion.peek(collapsed) and 1 or 0
					end), 30, 1),
					[Children] = {
						New("UICorner")({ CornerRadius = UDim.new(1, 0) }),
						New("UIPadding")({
							PaddingLeft = UDim.new(0, 6),
							PaddingRight = UDim.new(0, 6),
							PaddingTop = UDim.new(0, 2),
							PaddingBottom = UDim.new(0, 2),
						}),
					},
				}) or nil,
			},
		}))
	end

	-- Header --------------------------------------------------------------
	local headerChildren: { Instance } = {
		props.Title and New("TextLabel")({
			Position = UDim2.new(0, 12, 0, 0),
			Size = UDim2.new(1, -56, 1, 0),
			BackgroundTransparency = 1,
			Text = props.Title,
			Font = Enum.Font.GothamBold,
			TextSize = 15,
			TextColor3 = Computed(function()
				return theme:get().Text
			end),
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTransparency = Spring(Computed(function()
				return Fusion.peek(collapsed) and 1 or 0
			end), 30, 1),
		}) or nil,
	}

	if props.Collapsible ~= false then
		table.insert(headerChildren, New("TextButton")({
			Name = "CollapseButton",
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -10, 0.5, 0),
			Size = UDim2.fromOffset(28, 28),
			BackgroundTransparency = 1,
			Text = "",
			[OnEvent("Activated")] = function()
				collapsed:set(not Fusion.peek(collapsed))
				Sound.play("Click")
			end,
			[Children] = {
				Icons.render("panel-left", {
					Size = UDim2.fromOffset(15, 15),
					Position = UDim2.fromScale(0.5, 0.5),
					AnchorPoint = Vector2.new(0.5, 0.5),
					Color = Computed(function()
						return theme:get().TextMuted
					end),
				}),
			},
		}))
	end

	local frame = New("Frame")({
		Name = "AetherSidebar",
		Size = Spring(Computed(function()
			local base = props.Size or UDim2.new(0, EXPANDED, 1, 0)
			local width = Fusion.peek(collapsed) and COLLAPSED or (base.X.Offset > 0 and base.X.Offset or EXPANDED)
			return UDim2.new(0, width, base.Y.Scale, base.Y.Offset)
		end), 26, 1),
		BackgroundColor3 = Computed(function()
			return theme:get().Surface
		end),
		Parent = props.Parent,
		ClipsDescendants = true,
		[Children] = {
			New("UIStroke")({
				Color = Computed(function()
					return theme:get().Border
				end),
				Thickness = 1,
			}),
			New("UICorner")({ CornerRadius = Computed(function()
				return UDim.new(0, theme:get().RadiusMd)
			end) }),
			New("Frame")({
				Name = "Header",
				Size = UDim2.new(1, 0, 0, 48),
				BackgroundTransparency = 1,
				[Children] = headerChildren,
			}),
			ScrollFrame({
				Size = UDim2.new(1, -16, 1, -56),
				Position = UDim2.fromOffset(8, 52),
				ListPadding = 2,
				Children = navChildren,
			}),
		},
	}) :: Frame

	return {
		Instance = frame,
		SetActive = select,
		Toggle = function()
			collapsed:set(not Fusion.peek(collapsed))
		end,
	}
end

return Sidebar
