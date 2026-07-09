--!strict
--[[
	AetherUI • Components/TreeView

	Hierarchical tree with expand/collapse animation, icons and selection.

	props:
		Nodes: { TreeNode }         TreeNode = { Id: string, Label: string, Icon: string?, Children: { TreeNode }? }
		OnSelect: ((node: TreeNode) -> ())?
		DefaultExpanded: { string }?      (list of node ids expanded initially)
		Size: UDim2?    LayoutOrder: number?    Parent: Instance?
]]

local Fusion = require(script.Parent.Parent.Core.Fusion)
local Theme = require(script.Parent.Parent.Core.Theme)
local Primitives = require(script.Parent.Primitives)

local New = Fusion.New
local Children = Fusion.Children
local Computed = Fusion.Computed
local Value = Fusion.Value
local OnEvent = Fusion.OnEvent
local Tween = Fusion.Tween

local ROW_HEIGHT = 30
local INDENT = 18

return function(props: { [string]: any }): Frame
	local selected = Value(nil :: string?)
	local expandedSet: { [string]: any } = {}

	local defaultExpanded: { [string]: boolean } = {}
	for _, id in (props.DefaultExpanded or {}) :: { string } do
		defaultExpanded[id] = true
	end

	local function isExpanded(id: string): any
		if expandedSet[id] == nil then
			expandedSet[id] = Value(defaultExpanded[id] == true)
		end
		return expandedSet[id]
	end

	local function buildNode(node: { [string]: any }, depth: number): Instance
		local hasChildren = node.Children ~= nil and #node.Children > 0
		local expanded = isExpanded(node.Id)
		local hovering = Value(false)

		local rowChildren: { any } = {
			Primitives.Padding({ Left = 8 + depth * INDENT, Right = 8 }),
			Primitives.List({ Direction = "Horizontal", Padding = 6, VerticalAlignment = Enum.VerticalAlignment.Center }),
			Primitives.Corner("Sm"),
		}

		-- Chevron (only for parents)
		table.insert(rowChildren, Primitives.Icon({
			Name = "chevron-right",
			Size = 12,
			Color = Computed(function()
				return Theme.Colors.TextMuted:get()
			end),
			Transparency = if hasChildren then 0 else 1,
			Rotation = Tween(
				Computed(function()
					return if expanded:get() then 90 else 0
				end),
				TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			),
			LayoutOrder = 1,
		}))

		if node.Icon then
			table.insert(rowChildren, Primitives.Icon({
				Name = node.Icon,
				Size = 14,
				Color = Computed(function()
					return if selected:get() == node.Id
						then Theme.Colors.Primary:get()
						else Theme.Colors.TextMuted:get()
				end),
				LayoutOrder = 2,
			}))
		end

		table.insert(rowChildren, Primitives.Text({
			Text = node.Label,
			Size = 13,
			Color = Computed(function()
				return if selected:get() == node.Id
					then Theme.Colors.Text:get()
					else Theme.Colors.TextMuted:get()
			end),
			LayoutOrder = 3,
		}))

		local row = New("TextButton")({
			Name = "Row",
			Size = UDim2.new(1, 0, 0, ROW_HEIGHT),
			BackgroundColor3 = Computed(function()
				return if selected:get() == node.Id
					then Theme.Colors.Surface:get():Lerp(Theme.Colors.Primary:get(), 0.12)
					else Theme.Colors.SurfaceHover:get()
			end),
			BackgroundTransparency = Computed(function()
				if selected:get() == node.Id then
					return 0
				end
				return if hovering:get() then 0.5 else 1
			end),
			Text = "",
			AutoButtonColor = false,
			LayoutOrder = 1,
			[OnEvent("MouseEnter")] = function()
				hovering:set(true)
			end,
			[OnEvent("MouseLeave")] = function()
				hovering:set(false)
			end,
			[OnEvent("Activated")] = function()
				if hasChildren then
					expanded:set(not expanded:get())
				end
				selected:set(node.Id)
				if props.OnSelect then
					props.OnSelect(node)
				end
			end,
			[Children] = rowChildren,
		})

		if not hasChildren then
			return New("Frame")({
				Name = "Node_" .. node.Id,
				AutomaticSize = Enum.AutomaticSize.Y,
				Size = UDim2.new(1, 0, 0, 0),
				BackgroundTransparency = 1,
				[Children] = { Primitives.List({ Padding = 1 }), row },
			})
		end

		-- Children container: clipped, animated open/close.
		local childItems: { any } = { Primitives.List({ Padding = 1 }) }
		for order, child in node.Children :: { { [string]: any } } do
			local built = buildNode(child, depth + 1)
			;(built :: any).LayoutOrder = order
			table.insert(childItems, built)
		end

		local contentHeight = Value(0)

		local childContent = New("Frame")({
			Name = "ChildContent",
			AutomaticSize = Enum.AutomaticSize.Y,
			Size = UDim2.new(1, 0, 0, 0),
			BackgroundTransparency = 1,
			[Children] = childItems,
		})

		-- Track real content height reactively so the holder animates to the
		-- correct size even when nested nodes expand/collapse.
		childContent:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
			contentHeight:set((childContent :: Frame).AbsoluteSize.Y)
		end)

		local childrenHolder = New("Frame")({
			Name = "Children",
			Size = Tween(
				Computed(function()
					return if expanded:get()
						then UDim2.new(1, 0, 0, contentHeight:get())
						else UDim2.new(1, 0, 0, 0)
				end),
				TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			),
			BackgroundTransparency = 1,
			ClipsDescendants = true,
			LayoutOrder = 2,
			[Children] = { childContent },
		})

		return New("Frame")({
			Name = "Node_" .. node.Id,
			AutomaticSize = Enum.AutomaticSize.Y,
			Size = UDim2.new(1, 0, 0, 0),
			BackgroundTransparency = 1,
			[Children] = {
				Primitives.List({ Padding = 1 }),
				row,
				childrenHolder,
			},
		})
	end

	local items: { any } = { Primitives.List({ Padding = 1 }) }
	for order, node in (props.Nodes or {}) :: { { [string]: any } } do
		local built = buildNode(node, 0)
		;(built :: any).LayoutOrder = order
		table.insert(items, built)
	end

	return New("Frame")({
		Name = "AetherTreeView",
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = props.Size or UDim2.new(1, 0, 0, 0),
		BackgroundTransparency = 1,
		LayoutOrder = props.LayoutOrder,
		Parent = props.Parent,
		[Children] = items,
	})
end
