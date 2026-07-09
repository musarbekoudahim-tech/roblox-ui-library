--!strict
--[[
	AetherUI • Components/Button

	Variants: Primary | Secondary | Outline | Ghost | Destructive
	Sizes:    Sm | Md | Lg | Icon

	props:
		Text: string?               Icon: string?          IconRight: string?
		Variant: string?            Size: string?          Disabled: boolean | Value?
		Loading: boolean | Value?   OnClick: () -> ()?     FullWidth: boolean?
		LayoutOrder, Position, AnchorPoint, ZIndex
]]

local Fusion = require(script.Parent.Parent.Core.Fusion)
local Theme = require(script.Parent.Parent.Core.Theme)
local Animation = require(script.Parent.Parent.Core.Animation)
local Primitives = require(script.Parent.Primitives)
local UseHover = require(script.Parent.Parent.Hooks.UseHover)
local UsePress = require(script.Parent.Parent.Hooks.UsePress)

local New = Fusion.New
local Children = Fusion.Children
local OnEvent = Fusion.OnEvent
local Computed = Fusion.Computed
local Tween = Fusion.Tween
local Value = Fusion.Value

local SIZES = {
	Sm = { Height = 30, Text = "Sm", PadX = 12, Icon = 14 },
	Md = { Height = 36, Text = "Md", PadX = 16, Icon = 16 },
	Lg = { Height = 42, Text = "Lg", PadX = 20, Icon = 18 },
	Icon = { Height = 36, Text = "Md", PadX = 0, Icon = 16 },
}

local function asState(value: any): any
	if type(value) == "table" and type(value.get) == "function" then
		return value
	end
	return Value(value or false)
end

return function(props: { [string]: any }): TextButton
	local variant: string = props.Variant or "Primary"
	local size = SIZES[props.Size or "Md"] or SIZES.Md
	local disabled = asState(props.Disabled)
	local loading = asState(props.Loading)

	local hover = UseHover()
	local press = UsePress()

	local interactive = Computed(function()
		return not disabled:get() and not loading:get()
	end)

	local background = Computed(function()
		local c = Theme.Colors
		local hovering = hover.Hovering:get() and interactive:get()
		if variant == "Primary" then
			return if hovering then c.PrimaryHover:get() else c.Primary:get()
		elseif variant == "Destructive" then
			return if hovering then c.DangerHover:get() else c.Danger:get()
		elseif variant == "Secondary" then
			return if hovering then c.SecondaryHover:get() else c.Secondary:get()
		else -- Outline / Ghost
			return if hovering then c.SurfaceHover:get() else c.Surface:get()
		end
	end)

	local backgroundTransparency = Computed(function()
		if variant == "Ghost" and not (hover.Hovering:get() and interactive:get()) then
			return 1
		end
		if variant == "Outline" and not (hover.Hovering:get() and interactive:get()) then
			return 1
		end
		return if disabled:get() then 0.45 else 0
	end)

	local textColor = Computed(function()
		local c = Theme.Colors
		if disabled:get() then
			return c.TextDisabled:get()
		end
		if variant == "Primary" then
			return c.PrimaryText:get()
		elseif variant == "Destructive" then
			return Color3.new(1, 1, 1)
		end
		return c.Text:get()
	end)

	local spinnerRotation = Value(0)
	task.spawn(function()
		-- lightweight spinner driver; stops itself when button is gone
		while task.wait(1 / 60) do
			if loading:get() then
				spinnerRotation:set((spinnerRotation:get() + 7) % 360)
			end
		end
	end)

	local isIconOnly = props.Size == "Icon"

	local content: { any } = {
		Primitives.Corner("Md"),
		Primitives.List({
			Direction = Enum.FillDirection.Horizontal,
			Gap = 8,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Center,
		}),
	}

	if variant == "Outline" then
		table.insert(content, Primitives.Stroke({ Color = Theme.Colors.BorderStrong, Transparency = 0.4 }))
	end

	if not isIconOnly then
		table.insert(content, Primitives.Padding({ X = size.PadX }))
	end

	-- Loading spinner replaces the left icon
	table.insert(
		content,
		New("ImageLabel")({
			Name = "Spinner",
			BackgroundTransparency = 1,
			Image = "rbxassetid://11304130802",
			ImageColor3 = textColor,
			Size = UDim2.fromOffset(size.Icon, size.Icon),
			Rotation = Computed(function()
				return spinnerRotation:get()
			end),
			Visible = Computed(function()
				return loading:get()
			end),
			LayoutOrder = 0,
		})
	)

	if props.Icon then
		table.insert(
			content,
			New("Frame")({
				Name = "IconSlot",
				BackgroundTransparency = 1,
				Size = UDim2.fromOffset(size.Icon, size.Icon),
				LayoutOrder = 1,
				Visible = Computed(function()
					return not loading:get()
				end),
				[Children] = { Primitives.Icon({ Name = props.Icon, Size = size.Icon, Color = textColor }) },
			})
		)
	end

	if props.Text and not isIconOnly then
		table.insert(
			content,
			Primitives.Text({
				Text = props.Text,
				Size = size.Text,
				Color = textColor,
				LayoutOrder = 2,
			})
		)
	end

	if props.IconRight then
		table.insert(
			content,
			Primitives.Icon({ Name = props.IconRight, Size = size.Icon, Color = textColor, LayoutOrder = 3 })
		)
	end

	local button: TextButton

	button = New("TextButton")({
		Name = "AetherButton",
		Text = "",
		AutoButtonColor = false,
		BackgroundColor3 = Tween(background, Animation.Presets.Fast),
		BackgroundTransparency = Tween(backgroundTransparency, Animation.Presets.Fast),
		Size = if props.FullWidth
			then UDim2.new(1, 0, 0, size.Height)
			elseif isIconOnly then UDim2.fromOffset(size.Height, size.Height)
			else UDim2.fromOffset(0, size.Height),
		AutomaticSize = if props.FullWidth or isIconOnly then Enum.AutomaticSize.None else Enum.AutomaticSize.X,
		LayoutOrder = props.LayoutOrder or 0,
		Position = props.Position,
		AnchorPoint = props.AnchorPoint,
		ZIndex = props.ZIndex or 1,
		Active = interactive,

		[OnEvent("MouseEnter")] = hover.Enter,
		[OnEvent("MouseLeave")] = function()
			hover.Leave()
			press.Up()
		end,
		[OnEvent("MouseButton1Down")] = function()
			if interactive:get() then
				press.Down()
			end
		end,
		[OnEvent("MouseButton1Up")] = press.Up,
		[OnEvent("Activated")] = function()
			if interactive:get() then
				Animation.Pulse(button)
				press.Activate(props.OnClick)
			end
		end,

		[Children] = content,
	}) :: TextButton

	return button
end
