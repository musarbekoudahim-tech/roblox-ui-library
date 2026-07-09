--!strict
--[=[
	AetherUI · ContextMenu
	Right-click (or programmatic) menus with icons, shortcuts, separators,
	destructive items and nested submenus.

		ContextMenu.attach(frame, {
			{ Label = "Rename", Icon = "pencil", OnClick = ... },
			{ Separator = true },
			{ Label = "Delete", Icon = "trash-2", Destructive = true, OnClick = ... },
		})
]=]

local Fusion = require(script.Parent.Parent.Core.Fusion)
local Theme = require(script.Parent.Parent.Core.Theme)
local Icons = require(script.Parent.Parent.Core.Icons)
local Sound = require(script.Parent.Parent.Core.Sound)
local Overlay = require(script.Parent.Parent.Core.Overlay)

local New = Fusion.New
local Children = Fusion.Children
local Value = Fusion.Value
local Computed = Fusion.Computed
local OnEvent = Fusion.OnEvent
local Spring = Fusion.Spring

local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

export type MenuItem = {
	Label: string?,
	Icon: string?,
	Shortcut: string?,
	Destructive: boolean?,
	Disabled: boolean?,
	Separator: boolean?,
	OnClick: (() -> ())?,
	Items: { MenuItem }?, -- submenu
}

local ContextMenu = {}

local activeMenu: Frame? = nil
local dismissConn: RBXScriptConnection? = nil

local function closeActive()
	if activeMenu then
		activeMenu:Destroy()
		activeMenu = nil
	end
	if dismissConn then
		dismissConn:Disconnect()
		dismissConn = nil
	end
end

local MENU_WIDTH = 200

local function buildMenu(items: { MenuItem }, position: Vector2, depth: number): Frame
	local theme = Theme.Current
	local layer = Overlay.getLayer("Menus", 250)
	local visible = Value(false)

	local rows: { Instance } = {
		New("UIListLayout")({
			FillDirection = Enum.FillDirection.Vertical,
			Padding = UDim.new(0, 2),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
		New("UIPadding")({
			PaddingLeft = UDim.new(0, 4),
			PaddingRight = UDim.new(0, 4),
			PaddingTop = UDim.new(0, 4),
			PaddingBottom = UDim.new(0, 4),
		}),
	}

	local openSubmenu: Frame? = nil

	for i, item in ipairs(items) do
		if item.Separator then
			table.insert(rows, New("Frame")({
				Size = UDim2.new(1, 0, 0, 1),
				BackgroundColor3 = Computed(function()
					return theme:get().Border
				end),
				BorderSizePixel = 0,
				LayoutOrder = i,
			}))
			continue
		end

		local hovered = Value(false)

		local rowChildren: { Instance } = {
			New("UIListLayout")({
				FillDirection = Enum.FillDirection.Horizontal,
				Padding = UDim.new(0, 8),
				VerticalAlignment = Enum.VerticalAlignment.Center,
			}),
			New("UIPadding")({ PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }),
		}

		local itemColor = Computed(function()
			local t = theme:get()
			if item.Disabled then
				return t.TextDisabled
			end
			return item.Destructive and t.Danger or t.Text
		end)

		if item.Icon then
			table.insert(rowChildren, Icons.render(item.Icon, {
				Size = UDim2.fromOffset(14, 14),
				LayoutOrder = 1,
				Color = itemColor,
			}))
		end

		table.insert(rowChildren, New("TextLabel")({
			Size = UDim2.new(1, item.Icon and -70 or -48, 1, 0),
			BackgroundTransparency = 1,
			Text = item.Label or "",
			Font = Enum.Font.GothamMedium,
			TextSize = 12,
			TextColor3 = itemColor,
			TextXAlignment = Enum.TextXAlignment.Left,
			LayoutOrder = 2,
		}))

		if item.Shortcut then
			table.insert(rowChildren, New("TextLabel")({
				AutomaticSize = Enum.AutomaticSize.XY,
				BackgroundTransparency = 1,
				Text = item.Shortcut,
				Font = Enum.Font.RobotoMono,
				TextSize = 10,
				TextColor3 = Computed(function()
					return theme:get().TextMuted
				end),
				LayoutOrder = 3,
			}))
		elseif item.Items then
			table.insert(rowChildren, Icons.render("chevron-right", {
				Size = UDim2.fromOffset(12, 12),
				LayoutOrder = 3,
				Color = Computed(function()
					return theme:get().TextMuted
				end),
			}))
		end

		local row: TextButton
		row = New("TextButton")({
			Name = "Item_" .. i,
			Size = UDim2.new(1, 0, 0, 30),
			Text = "",
			AutoButtonColor = false,
			LayoutOrder = i,
			BackgroundColor3 = Computed(function()
				local t = theme:get()
				return item.Destructive and t.Danger or t.SurfaceHigh
			end),
			BackgroundTransparency = Spring(Computed(function()
				if item.Disabled then
					return 1
				end
				return Fusion.peek(hovered) and (item.Destructive and 0.85 or 0.4) or 1
			end), 40, 1),
			[OnEvent("MouseEnter")] = function()
				if item.Disabled then
					return
				end
				hovered:set(true)
				Sound.play("Hover")
				if openSubmenu then
					openSubmenu:Destroy()
					openSubmenu = nil
				end
				if item.Items then
					local abs = row.AbsolutePosition
					openSubmenu = buildMenu(item.Items, Vector2.new(abs.X + MENU_WIDTH, abs.Y), depth + 1)
				end
			end,
			[OnEvent("MouseLeave")] = function()
				hovered:set(false)
			end,
			[OnEvent("Activated")] = function()
				if item.Disabled or item.Items then
					return
				end
				Sound.play("Click")
				closeActive()
				if item.OnClick then
					item.OnClick()
				end
			end,
			[Children] = {
				New("UICorner")({ CornerRadius = UDim.new(0, 6) }),
				New("Frame")({
					Size = UDim2.fromScale(1, 1),
					BackgroundTransparency = 1,
					[Children] = rowChildren,
				}),
			},
		}) :: TextButton

		table.insert(rows, row)
	end

	-- clamp to screen
	local camera = workspace.CurrentCamera
	local vp = camera and camera.ViewportSize or Vector2.new(1920, 1080)
	local x = math.min(position.X, vp.X - MENU_WIDTH - 8)
	local estHeight = #items * 32 + 8
	local y = math.min(position.Y, vp.Y - estHeight - 8)

	local menu = New("Frame")({
		Name = "AetherContextMenu_" .. depth,
		Position = UDim2.fromOffset(x, y),
		Size = UDim2.fromOffset(MENU_WIDTH, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Computed(function()
			return theme:get().Surface
		end),
		BackgroundTransparency = Spring(Computed(function()
			return Fusion.peek(visible) and 0 or 1
		end), 45, 1),
		ZIndex = 251 + depth,
		Parent = layer,
		[Children] = {
			New("UICorner")({ CornerRadius = Computed(function()
				return UDim.new(0, theme:get().RadiusMd)
			end) }),
			New("UIStroke")({
				Color = Computed(function()
					return theme:get().Border
				end),
				Thickness = 1,
			}),
			New("Frame")({
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				[Children] = rows,
			}),
		},
	}) :: Frame

	task.defer(function()
		visible:set(true)
	end)
	return menu
end

--- Opens a menu at a screen position (programmatic use).
function ContextMenu.open(items: { MenuItem }, position: Vector2?)
	closeActive()
	local pos = position
	if not pos then
		local mouse = UserInputService:GetMouseLocation()
		local inset = GuiService:GetGuiInset()
		pos = Vector2.new(mouse.X, mouse.Y - inset.Y)
	end
	Sound.play("Open")
	activeMenu = buildMenu(items, pos :: Vector2, 0)

	-- Dismiss on any click outside
	task.defer(function()
		dismissConn = UserInputService.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.MouseButton2
				or input.UserInputType == Enum.UserInputType.Touch then
				local menu = activeMenu
				if menu then
					local mouse = UserInputService:GetMouseLocation()
					local inset = GuiService:GetGuiInset()
					local mx, my = mouse.X, mouse.Y - inset.Y
					local pos2 = menu.AbsolutePosition
					local size = menu.AbsoluteSize
					if mx < pos2.X or mx > pos2.X + size.X or my < pos2.Y or my > pos2.Y + size.Y then
						closeActive()
					end
				end
			end
		end)
	end)
end

--- Attaches a right-click menu to a GuiObject. Returns a detach function.
function ContextMenu.attach(target: GuiObject, items: { MenuItem }): () -> ()
	local conn = target.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton2 then
			ContextMenu.open(items)
		end
	end)
	return function()
		conn:Disconnect()
		closeActive()
	end
end

function ContextMenu.close()
	closeActive()
end

--- PascalCase alias. Accepts either an items array or `{ Items = { ... } }`.
function ContextMenu.Attach(target: GuiObject, itemsOrOptions: { MenuItem } | { Items: { MenuItem } }): () -> ()
	local items = (itemsOrOptions :: any).Items or itemsOrOptions
	return ContextMenu.attach(target, items :: { MenuItem })
end

ContextMenu.Open = ContextMenu.open
ContextMenu.Close = ContextMenu.close

return ContextMenu
