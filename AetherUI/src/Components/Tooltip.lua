--!strict
--[=[
	AetherUI · Tooltip
	Attach rich, delayed tooltips to any GuiObject.

		Tooltip.attach(button, { Text = "Save changes", Shortcut = "Ctrl+S" })
]=]

local Fusion = require(script.Parent.Parent.Core.Fusion)
local Theme = require(script.Parent.Parent.Core.Theme)
local Overlay = require(script.Parent.Parent.Core.Overlay)

local New = Fusion.New
local Children = Fusion.Children
local Value = Fusion.Value
local Computed = Fusion.Computed
local Spring = Fusion.Spring

local UserInputService = game:GetService("UserInputService")

export type TooltipOptions = {
	Text: string,
	Title: string?,
	Shortcut: string?,
	Delay: number?,
	MaxWidth: number?,
}

local Tooltip = {}

local activeTip: Frame? = nil

local function destroyActive()
	if activeTip then
		activeTip:Destroy()
		activeTip = nil
	end
end

local function createTip(options: TooltipOptions, anchorPos: Vector2, anchorSize: Vector2): Frame
	local theme = Theme.Current
	local layer = Overlay.getLayer("Tooltips", 300)
	local visible = Value(false)

	local maxWidth = options.MaxWidth or 240

	local rows: { Instance } = {
		New("UIListLayout")({
			FillDirection = Enum.FillDirection.Vertical,
			Padding = UDim.new(0, 3),
		}),
	}

	if options.Title then
		table.insert(rows, New("TextLabel")({
			AutomaticSize = Enum.AutomaticSize.XY,
			BackgroundTransparency = 1,
			Text = options.Title,
			Font = Enum.Font.GothamBold,
			TextSize = 12,
			TextColor3 = Computed(function()
				return Fusion.peek(theme).Text
			end),
			TextXAlignment = Enum.TextXAlignment.Left,
		}))
	end

	local textRow: { Instance } = {
		New("UIListLayout")({
			FillDirection = Enum.FillDirection.Horizontal,
			Padding = UDim.new(0, 8),
			VerticalAlignment = Enum.VerticalAlignment.Center,
		}),
		New("TextLabel")({
			AutomaticSize = Enum.AutomaticSize.XY,
			BackgroundTransparency = 1,
			Text = options.Text,
			Font = Enum.Font.Gotham,
			TextSize = 12,
			TextWrapped = true,
			TextColor3 = Computed(function()
				return options.Title and Fusion.peek(theme).TextMuted or Fusion.peek(theme).Text
			end),
			TextXAlignment = Enum.TextXAlignment.Left,
			LayoutOrder = 1,
			[Children] = {
				New("UISizeConstraint")({ MaxSize = Vector2.new(maxWidth, math.huge) }),
			},
		}),
	}

	if options.Shortcut then
		table.insert(textRow, New("TextLabel")({
			AutomaticSize = Enum.AutomaticSize.XY,
			BackgroundColor3 = Computed(function()
				return Fusion.peek(theme).SurfaceHigh
			end),
			Text = options.Shortcut,
			Font = Enum.Font.RobotoMono,
			TextSize = 10,
			TextColor3 = Computed(function()
				return Fusion.peek(theme).TextMuted
			end),
			LayoutOrder = 2,
			[Children] = {
				New("UICorner")({ CornerRadius = UDim.new(0, 4) }),
				New("UIPadding")({
					PaddingLeft = UDim.new(0, 5),
					PaddingRight = UDim.new(0, 5),
					PaddingTop = UDim.new(0, 2),
					PaddingBottom = UDim.new(0, 2),
				}),
			},
		}))
	end

	table.insert(rows, New("Frame")({
		AutomaticSize = Enum.AutomaticSize.XY,
		BackgroundTransparency = 1,
		[Children] = textRow,
	}))

	-- Position below the anchor, centered; flip above if near bottom
	local camera = workspace.CurrentCamera
	local screenH = camera and camera.ViewportSize.Y or 1080
	local below = anchorPos.Y + anchorSize.Y + 60 < screenH
	local yOffset = below and (anchorPos.Y + anchorSize.Y + 8) or (anchorPos.Y - 8)

	local tip = New("Frame")({
		Name = "AetherTooltip",
		AutomaticSize = Enum.AutomaticSize.XY,
		AnchorPoint = Vector2.new(0.5, below and 0 or 1),
		Position = Spring(Computed(function()
			local lift = Fusion.peek(visible) and 0 or (below and -4 or 4)
			return UDim2.fromOffset(anchorPos.X + anchorSize.X / 2, yOffset + lift)
		end), 40, 1),
		BackgroundColor3 = Computed(function()
			return Fusion.peek(theme).SurfaceHigh
		end),
		BackgroundTransparency = Spring(Computed(function()
			return Fusion.peek(visible) and 0 or 1
		end), 40, 1),
		ZIndex = 301,
		Parent = layer,
		[Children] = {
			New("UICorner")({ CornerRadius = Computed(function()
				return UDim.new(0, Fusion.peek(theme).RadiusSm)
			end) }),
			New("UIStroke")({
				Color = Computed(function()
					return Fusion.peek(theme).Border
				end),
				Thickness = 1,
			}),
			New("UIPadding")({
				PaddingLeft = UDim.new(0, 10),
				PaddingRight = UDim.new(0, 10),
				PaddingTop = UDim.new(0, 7),
				PaddingBottom = UDim.new(0, 7),
			}),
			New("Frame")({
				AutomaticSize = Enum.AutomaticSize.XY,
				BackgroundTransparency = 1,
				[Children] = rows,
			}),
		},
	}) :: Frame

	task.defer(function()
		visible:set(true)
	end)
	return tip
end

--- Attaches a tooltip to a GuiObject. Returns a detach function.
function Tooltip.attach(target: GuiObject, options: TooltipOptions): () -> ()
	local hoverToken = 0
	local conns: { RBXScriptConnection } = {}

	table.insert(conns, target.MouseEnter:Connect(function()
		hoverToken += 1
		local token = hoverToken
		task.delay(options.Delay or 0.45, function()
			if token ~= hoverToken then
				return
			end
			-- still hovered?
			local mouse = UserInputService:GetMouseLocation()
			local pos = target.AbsolutePosition
			local size = target.AbsoluteSize
			local inset = game:GetService("GuiService"):GetGuiInset()
			local mx, my = mouse.X, mouse.Y - inset.Y
			if mx >= pos.X and mx <= pos.X + size.X and my >= pos.Y and my <= pos.Y + size.Y then
				destroyActive()
				activeTip = createTip(options, pos, size)
			end
		end)
	end))

	table.insert(conns, target.MouseLeave:Connect(function()
		hoverToken += 1
		destroyActive()
	end))

	table.insert(conns, target.Destroying:Connect(function()
		hoverToken += 1
		destroyActive()
	end))

	return function()
		hoverToken += 1
		destroyActive()
		for _, conn in ipairs(conns) do
			conn:Disconnect()
		end
	end
end

-- PascalCase alias for public API consistency.
Tooltip.Attach = Tooltip.attach

return Tooltip
