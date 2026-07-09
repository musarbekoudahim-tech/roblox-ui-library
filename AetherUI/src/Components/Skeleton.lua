--!strict
--[[
	AetherUI • Components/Skeleton

	Shimmering loading placeholder.

	props:
		Size: UDim2?              (default full-width, 16px tall)
		Radius: any?              (theme radius token or number, default "Sm")
		Lines: number?            (renders N stacked lines with the last one shorter)
		LayoutOrder: number?      Parent: Instance?
]]

local RunService = game:GetService("RunService")

local Fusion = require(script.Parent.Parent.Core.Fusion)
local Theme = require(script.Parent.Parent.Core.Theme)
local Primitives = require(script.Parent.Primitives)

local New = Fusion.New
local Children = Fusion.Children
local Computed = Fusion.Computed
local Value = Fusion.Value

local function shimmerBlock(size: UDim2, radius: any, order: number?): Frame
	local phase = Value(0)

	local block = New("Frame")({
		Name = "Skeleton",
		Size = size,
		BackgroundColor3 = Computed(function()
			local base: Color3 = Theme.Colors.SurfaceHigh:get()
			local sheen: Color3 = Theme.Colors.SurfaceHover:get()
			-- Smooth ping-pong blend between base and sheen.
			local t = (math.sin(phase:get()) + 1) / 2
			return base:Lerp(sheen, t)
		end),
		LayoutOrder = order,
		[Children] = { Primitives.Corner(radius) },
	}) :: Frame

	local connection: RBXScriptConnection? = nil
	connection = RunService.Heartbeat:Connect(function(dt)
		if not block:IsDescendantOf(game) and block.Parent == nil then
			if connection then
				connection:Disconnect()
			end
			return
		end
		phase:set(phase:get() + dt * 4)
	end)

	block.Destroying:Connect(function()
		if connection then
			connection:Disconnect()
		end
	end)

	return block
end

return function(props: { [string]: any }): Frame
	local radius = props.Radius or "Sm"

	if props.Lines and props.Lines > 1 then
		local lines: { any } = { Primitives.List({ Padding = 8 }) }
		for i = 1, props.Lines do
			local width = if i == props.Lines then 0.6 else 1
			table.insert(lines, shimmerBlock(UDim2.new(width, 0, 0, 12), radius, i))
		end
		return New("Frame")({
			Name = "AetherSkeletonGroup",
			AutomaticSize = Enum.AutomaticSize.Y,
			Size = props.Size or UDim2.new(1, 0, 0, 0),
			BackgroundTransparency = 1,
			LayoutOrder = props.LayoutOrder,
			Parent = props.Parent,
			[Children] = lines,
		})
	end

	local block = shimmerBlock(props.Size or UDim2.new(1, 0, 0, 16), radius, props.LayoutOrder)
	if props.Parent then
		block.Parent = props.Parent
	end
	return block
end
