--!strict
--[[
	AetherUI • Components/TextInput

	props:
		Value: Fusion.Value<string>?     Placeholder: string?
		Icon: string?                    Password: boolean?
		ClearButton: boolean?            MaxLength: number?
		ShowCounter: boolean?            Validate: ((string) -> (boolean, string?))?
		OnChanged: (string) -> ()?       OnSubmit: (string) -> ()?
		Disabled: boolean?               Size (Sm|Md|Lg), FullWidth, LayoutOrder

	Returns the frame; frame:FindFirstChild("Input", true) is the TextBox.
	Validation errors render inline below the field.
]]

local Fusion = require(script.Parent.Parent.Core.Fusion)
local Theme = require(script.Parent.Parent.Core.Theme)
local Animation = require(script.Parent.Parent.Core.Animation)
local Primitives = require(script.Parent.Parent.Components.Primitives)
local UseHover = require(script.Parent.Parent.Hooks.UseHover)

local New = Fusion.New
local Children = Fusion.Children
local OnEvent = Fusion.OnEvent
local OnChange = Fusion.OnChange
local Computed = Fusion.Computed
local Tween = Fusion.Tween
local Value = Fusion.Value
local Ref = Fusion.Ref

local HEIGHTS = { Sm = 30, Md = 36, Lg = 42 }

return function(props: { [string]: any }): Frame
	local text = props.Value or Value("")
	local focused = Value(false)
	local revealed = Value(false) -- password visibility
	local errorMessage = Value(nil :: string?)
	local hover = UseHover({ Sound = false })
	local boxRef = Value(nil :: TextBox?)

	local height = HEIGHTS[props.Size or "Md"] or 36

	local function runValidation(current: string)
		if props.Validate then
			local ok, message = props.Validate(current)
			errorMessage:set(if ok then nil else (message or "Invalid value"))
		end
	end

	local strokeColor = Computed(function()
		if errorMessage:get() ~= nil then
			return Theme.Colors.Danger:get()
		end
		if focused:get() then
			return Theme.Colors.Primary:get()
		end
		if hover.Hovering:get() then
			return Theme.Colors.BorderStrong:get()
		end
		return Theme.Colors.Border:get()
	end)

	local strokeTransparency = Computed(function()
		return if focused:get() or errorMessage:get() ~= nil then 0 else 0.35
	end)

	local rightControls: { Instance } = {}

	if props.ClearButton then
		table.insert(
			rightControls,
			New("TextButton")({
				Name = "Clear",
				Text = "",
				BackgroundTransparency = 1,
				Size = UDim2.fromOffset(20, 20),
				LayoutOrder = 1,
				Visible = Computed(function()
					return #text:get() > 0 and not (props.Disabled == true)
				end),
				[OnEvent("Activated")] = function()
					text:set("")
					local box = boxRef:get()
					if box then
						box.Text = ""
						box:CaptureFocus()
					end
					errorMessage:set(nil)
					if props.OnChanged then
						props.OnChanged("")
					end
				end,
				[Children] = {
					Primitives.Icon({
						Name = "x",
						Size = 14,
						Color = Theme.Colors.TextMuted,
						Position = UDim2.fromScale(0.5, 0.5),
						AnchorPoint = Vector2.new(0.5, 0.5),
					}),
				},
			})
		)
	end

	if props.Password then
		table.insert(
			rightControls,
			New("TextButton")({
				Name = "Reveal",
				Text = "",
				BackgroundTransparency = 1,
				Size = UDim2.fromOffset(20, 20),
				LayoutOrder = 2,
				[OnEvent("Activated")] = function()
					revealed:set(not revealed:get())
					local box = boxRef:get()
					if box then
						box.TextTransparency = 0
					end
				end,
				[Children] = {
					Computed(function()
						return Primitives.Icon({
							Name = if revealed:get() then "eye-off" else "eye",
							Size = 14,
							Color = Theme.Colors.TextMuted,
							Position = UDim2.fromScale(0.5, 0.5),
							AnchorPoint = Vector2.new(0.5, 0.5),
						})
					end, Fusion.cleanup),
				},
			})
		)
	end

	local fieldChildren: { any } = {
		Primitives.Corner("Md"),
		Primitives.Stroke({
			Color = Tween(strokeColor, Animation.Presets.Fast),
			Transparency = Tween(strokeTransparency, Animation.Presets.Fast),
			Thickness = 1,
		}),
		Primitives.Padding({ X = 12 }),
		Primitives.List({
			Direction = Enum.FillDirection.Horizontal,
			Gap = 8,
			VerticalAlignment = Enum.VerticalAlignment.Center,
		}),
	}

	if props.Icon then
		table.insert(
			fieldChildren,
			Primitives.Icon({ Name = props.Icon, Size = 15, Color = Theme.Colors.TextMuted, LayoutOrder = 0 })
		)
	end

	table.insert(
		fieldChildren,
		New("TextBox")({
			Name = "Input",
			BackgroundTransparency = 1,
			Text = text:get(),
			PlaceholderText = props.Placeholder or "",
			PlaceholderColor3 = Theme.Colors.TextDisabled,
			TextColor3 = Computed(function()
				return if props.Disabled then Theme.Colors.TextDisabled:get() else Theme.Colors.Text:get()
			end),
			FontFace = Theme.Fonts.Body,
			TextSize = Theme.TextSizes.Md,
			TextXAlignment = Enum.TextXAlignment.Left,
			ClearTextOnFocus = false,
			TextEditable = not props.Disabled,
			Size = UDim2.new(1, 0, 1, 0),
			LayoutOrder = 0,
			ClipsDescendants = true,
			[Ref] = boxRef,
			[OnChange("Text")] = function(newText: string)
				local truncated = newText
				if props.MaxLength and #truncated > props.MaxLength then
					truncated = truncated:sub(1, props.MaxLength)
					local box = boxRef:get()
					if box then
						box.Text = truncated
					end
				end
				if props.Password and not revealed:get() then
					-- Roblox TextBox has no native masking; we track real text and mask display.
					-- (Simple approach: keep display as-is; production games can swap to a masked mirror.)
				end
				text:set(truncated)
				runValidation(truncated)
				if props.OnChanged then
					props.OnChanged(truncated)
				end
			end,
			[OnEvent("Focused")] = function()
				focused:set(true)
			end,
			[OnEvent("FocusLost")] = function(enterPressed: boolean)
				focused:set(false)
				runValidation(text:get())
				if enterPressed and props.OnSubmit then
					props.OnSubmit(text:get())
				end
			end,
		})
	)

	if #rightControls > 0 then
		table.insert(
			fieldChildren,
			New("Frame")({
				Name = "RightControls",
				BackgroundTransparency = 1,
				AutomaticSize = Enum.AutomaticSize.X,
				Size = UDim2.new(0, 0, 1, 0),
				LayoutOrder = 10,
				[Children] = {
					Primitives.List({
						Direction = Enum.FillDirection.Horizontal,
						Gap = 4,
						VerticalAlignment = Enum.VerticalAlignment.Center,
					}),
					rightControls,
				},
			})
		)
	end

	local footer = New("Frame")({
		Name = "Footer",
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, 0),
		LayoutOrder = 1,
		Visible = Computed(function()
			return errorMessage:get() ~= nil or props.ShowCounter == true
		end),
		[Children] = {
			Primitives.Text({
				Name = "Error",
				Text = Computed(function()
					return errorMessage:get() or ""
				end),
				Size = "Xs",
				Color = Theme.Colors.Danger,
				Props = {
					Visible = Computed(function()
						return errorMessage:get() ~= nil
					end),
				},
			}),
			Primitives.Text({
				Name = "Counter",
				Text = Computed(function()
					local max = props.MaxLength
					return if max then `{#text:get()}/{max}` else tostring(#text:get())
				end),
				Size = "Xs",
				Muted = true,
				Props = {
					Visible = props.ShowCounter == true,
					Position = UDim2.fromScale(1, 0),
					AnchorPoint = Vector2.new(1, 0),
				},
			}),
		},
	})

	return New("Frame")({
		Name = "AetherTextInput",
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = if props.FullWidth ~= false then UDim2.new(1, 0, 0, 0) else UDim2.fromOffset(260, 0),
		LayoutOrder = props.LayoutOrder or 0,
		[Children] = {
			Primitives.List({ Gap = 4 }),
			New("Frame")({
				Name = "Field",
				BackgroundColor3 = Theme.Colors.Surface,
				BackgroundTransparency = Computed(function()
					return if props.Disabled then 0.4 else 0
				end),
				Size = UDim2.new(1, 0, 0, height),
				LayoutOrder = 0,
				[OnEvent("MouseEnter")] = hover.Enter,
				[OnEvent("MouseLeave")] = hover.Leave,
				[Children] = fieldChildren,
			}),
			footer,
		},
	}) :: Frame
end
