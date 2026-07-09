--!strict
--[=[
	AetherUI · KeybindInput
	Click to capture a new key combination. Integrates with Core/Keybinds.
]=]

local Fusion = require(script.Parent.Parent.Core.Fusion)
local Theme = require(script.Parent.Parent.Core.Theme)
local Keybinds = require(script.Parent.Parent.Core.Keybinds)
local Sound = require(script.Parent.Parent.Core.Sound)

local New = Fusion.New
local Children = Fusion.Children
local Value = Fusion.Value
local Computed = Fusion.Computed
local OnEvent = Fusion.OnEvent

local UserInputService = game:GetService("UserInputService")

export type KeybindInputProps = {
	Keybind: Keybinds.Bind?,
	OnChanged: ((bind: Keybinds.Bind) -> ())?,
	AllowModifiers: boolean?,
	Size: UDim2?,
	LayoutOrder: number?,
	Parent: Instance?,
}

local function KeybindInput(props: KeybindInputProps): TextButton
	local theme = Theme.Current
	local capturing = Value(false)
	local bind = Value(props.Keybind)
	local captureConn: RBXScriptConnection? = nil

	local labelText = Computed(function()
		if Fusion.peek(capturing) then
			return "Press a key…"
		end
		local b = Fusion.peek(bind)
		return b and Keybinds.format(b) or "Not set"
	end)

	local function stopCapture()
		capturing:set(false)
		if captureConn then
			captureConn:Disconnect()
			captureConn = nil
		end
	end

	local function startCapture()
		if Fusion.peek(capturing) then
			return
		end
		capturing:set(true)
		Sound.play("Click")

		captureConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
			if input.UserInputType ~= Enum.UserInputType.Keyboard then
				return
			end
			local key = input.KeyCode
			if key == Enum.KeyCode.Escape then
				stopCapture()
				return
			end
			-- Ignore bare modifier presses so combos can be captured
			if key == Enum.KeyCode.LeftControl or key == Enum.KeyCode.RightControl
				or key == Enum.KeyCode.LeftShift or key == Enum.KeyCode.RightShift
				or key == Enum.KeyCode.LeftAlt or key == Enum.KeyCode.RightAlt then
				return
			end

			local newBind: Keybinds.Bind = {
				Key = key,
				Ctrl = props.AllowModifiers ~= false and (UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)) or false,
				Shift = props.AllowModifiers ~= false and (UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.RightShift)) or false,
				Alt = props.AllowModifiers ~= false and (UserInputService:IsKeyDown(Enum.KeyCode.LeftAlt) or UserInputService:IsKeyDown(Enum.KeyCode.RightAlt)) or false,
			}
			bind:set(newBind)
			stopCapture()
			Sound.play("Success")
			if props.OnChanged then
				props.OnChanged(newBind)
			end
		end)
	end

	return New("TextButton")({
		Name = "AetherKeybindInput",
		Size = props.Size or UDim2.new(0, 140, 0, 32),
		BackgroundColor3 = Computed(function()
			local t = Fusion.peek(theme)
			return Fusion.peek(capturing) and t.SurfaceHigh or t.Surface
		end),
		Text = "",
		AutoButtonColor = false,
		LayoutOrder = props.LayoutOrder,
		Parent = props.Parent,
		[OnEvent("Activated")] = startCapture,
		[Children] = {
			New("UICorner")({ CornerRadius = Computed(function()
				return UDim.new(0, Fusion.peek(theme).RadiusSm)
			end) }),
			New("UIStroke")({
				Color = Computed(function()
					local t = Fusion.peek(theme)
					return Fusion.peek(capturing) and t.Primary or t.Border
				end),
				Thickness = Computed(function()
					return Fusion.peek(capturing) and 2 or 1
				end),
			}),
			New("TextLabel")({
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				Text = labelText,
				Font = Enum.Font.RobotoMono,
				TextSize = 12,
				TextColor3 = Computed(function()
					local t = Fusion.peek(theme)
					if Fusion.peek(capturing) then
						return t.Primary
					end
					return Fusion.peek(bind) and t.Text or t.TextMuted
				end),
			}),
		},
	}) :: TextButton
end

return KeybindInput
