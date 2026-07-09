--!strict
--[[
	AetherUI • Hooks/UseDrag
	Makes a GuiObject draggable by a handle. Returns a cleanup function.

		local stopDrag = UseDrag(windowFrame, titleBar)
]]

local UserInputService = game:GetService("UserInputService")

local Maid = require(script.Parent.Parent.Core.Maid)

return function(target: GuiObject, handle: GuiObject?): () -> ()
	local maid = Maid.new()
	local dragHandle = handle or target

	local dragging = false
	local dragStart = Vector2.zero
	local startPosition = UDim2.new()

	maid:Add(dragHandle.InputBegan:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			dragging = true
			dragStart = Vector2.new(input.Position.X, input.Position.Y)
			startPosition = target.Position
		end
	end))

	maid:Add(dragHandle.InputEnded:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			dragging = false
		end
	end))

	maid:Add(UserInputService.InputChanged:Connect(function(input)
		if not dragging then
			return
		end
		if
			input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch
		then
			local delta = Vector2.new(input.Position.X, input.Position.Y) - dragStart
			target.Position = UDim2.new(
				startPosition.X.Scale,
				startPosition.X.Offset + delta.X,
				startPosition.Y.Scale,
				startPosition.Y.Offset + delta.Y
			)
		end
	end))

	return function()
		maid:Clean()
	end
end
