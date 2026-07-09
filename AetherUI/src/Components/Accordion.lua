--!strict
--[=[
	AetherUI · Accordion / Collapsible
	Smooth height animation, rotating chevron, single or multiple open.
]=]

local Fusion = require(script.Parent.Parent.Core.Fusion)
local Theme = require(script.Parent.Parent.Core.Theme)
local Icons = require(script.Parent.Parent.Core.Icons)
local Sound = require(script.Parent.Parent.Core.Sound)
local Primitives = require(script.Parent.Parent.Components.Primitives)

local New = Fusion.New
local Children = Fusion.Children
local Value = Fusion.Value
local Computed = Fusion.Computed
local OnEvent = Fusion.OnEvent
local Spring = Fusion.Spring

export type AccordionItem = {
	Id: string,
	Title: string,
	Icon: string?,
	Content: () -> Instance,
	DefaultOpen: boolean?,
}

export type AccordionProps = {
	Items: { AccordionItem },
	Multiple: boolean?,
	Size: UDim2?,
	LayoutOrder: number?,
	Parent: Instance?,
}

local function Accordion(props: AccordionProps): Frame
	local theme = Theme.Current

	local openSet: Fusion.Value<{ [string]: boolean }> = Value({})
	do
		local initial: { [string]: boolean } = {}
		for _, item in ipairs(props.Items) do
			if item.DefaultOpen then
				initial[item.Id] = true
			end
		end
		openSet:set(initial)
	end

	local function toggle(id: string)
		local current = table.clone(Fusion.peek(openSet))
		if current[id] then
			current[id] = nil
		else
			if not props.Multiple then
				table.clear(current)
			end
			current[id] = true
		end
		openSet:set(current)
		Sound.play("Click")
	end

	local itemFrames: { Instance } = {
		New("UIListLayout")({
			FillDirection = Enum.FillDirection.Vertical,
			Padding = UDim.new(0, 8),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	}

	for i, item in ipairs(props.Items) do
		local isOpen = Computed(function()
			return Fusion.peek(openSet)[item.Id] == true
		end)
		local hovered = Value(false)

		-- content is mounted once, revealed via ClipsDescendants + size spring
		local contentInstance = item.Content()
		local contentHeight = Value(0)
		if contentInstance:IsA("GuiObject") then
			local function measure()
				contentHeight:set((contentInstance :: GuiObject).AbsoluteSize.Y + 12)
			end
			(contentInstance :: GuiObject):GetPropertyChangedSignal("AbsoluteSize"):Connect(measure)
			task.defer(measure)
		end

		local headerChildren: { Instance } = {
			New("UIListLayout")({
				FillDirection = Enum.FillDirection.Horizontal,
				Padding = UDim.new(0, 8),
				VerticalAlignment = Enum.VerticalAlignment.Center,
			}),
			New("UIPadding")({ PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12) }),
		}

		if item.Icon then
			table.insert(headerChildren, Icons.render(item.Icon, {
				Size = UDim2.fromOffset(15, 15),
				LayoutOrder = 1,
				Color = Computed(function()
					return Fusion.peek(theme).TextMuted
				end),
			}))
		end

		table.insert(headerChildren, New("TextLabel")({
			Size = UDim2.new(1, item.Icon and -60 or -40, 1, 0),
			BackgroundTransparency = 1,
			Text = item.Title,
			Font = Enum.Font.GothamMedium,
			TextSize = 13,
			TextColor3 = Computed(function()
				return Fusion.peek(theme).Text
			end),
			TextXAlignment = Enum.TextXAlignment.Left,
			LayoutOrder = 2,
		}))

		table.insert(headerChildren, Icons.render("chevron-down", {
			Size = UDim2.fromOffset(14, 14),
			LayoutOrder = 3,
			Rotation = Spring(Computed(function()
				return Fusion.peek(isOpen) and 180 or 0
			end), 25, 1),
			Color = Computed(function()
				return Fusion.peek(theme).TextMuted
			end),
		}))

		table.insert(itemFrames, Primitives.Surface({
			Name = "AccordionItem_" .. item.Id,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			LayoutOrder = i,
			Padding = 0,
			[Children] = {
				New("UIListLayout")({
					FillDirection = Enum.FillDirection.Vertical,
					SortOrder = Enum.SortOrder.LayoutOrder,
				}),
				New("TextButton")({
					Name = "Header",
					Size = UDim2.new(1, 0, 0, 40),
					Text = "",
					AutoButtonColor = false,
					LayoutOrder = 1,
					BackgroundColor3 = Computed(function()
						return Fusion.peek(theme).SurfaceHigh
					end),
					BackgroundTransparency = Spring(Computed(function()
						return Fusion.peek(hovered) and 0.5 or 1
					end), 30, 1),
					[OnEvent("Activated")] = function()
						toggle(item.Id)
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
							return UDim.new(0, Fusion.peek(theme).RadiusSm)
						end) }),
						New("Frame")({
							Size = UDim2.fromScale(1, 1),
							BackgroundTransparency = 1,
							[Children] = headerChildren,
						}),
					},
				}),
				New("Frame")({
					Name = "ContentClip",
					Size = Spring(Computed(function()
						return UDim2.new(1, 0, 0, Fusion.peek(isOpen) and Fusion.peek(contentHeight) or 0)
					end), 28, 1),
					BackgroundTransparency = 1,
					ClipsDescendants = true,
					LayoutOrder = 2,
					[Children] = {
						New("Frame")({
							Size = UDim2.new(1, 0, 0, 0),
							AutomaticSize = Enum.AutomaticSize.Y,
							BackgroundTransparency = 1,
							[Children] = {
								New("UIPadding")({
									PaddingLeft = UDim.new(0, 12),
									PaddingRight = UDim.new(0, 12),
									PaddingBottom = UDim.new(0, 12),
								}),
								contentInstance,
							},
						}),
					},
				}),
			},
		}))
	end

	return New("Frame")({
		Name = "AetherAccordion",
		Size = props.Size or UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = props.LayoutOrder,
		Parent = props.Parent,
		[Children] = itemFrames,
	}) :: Frame
end

return Accordion
