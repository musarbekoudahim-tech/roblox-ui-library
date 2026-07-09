--!strict
--[[
	AetherUI • Components/Dropdown
	Single-select dropdown with search, icons, keyboard-friendly close and smooth reveal.

	props:
		Items: { { Label, Value, Icon?, Disabled? } }
		Value: Fusion.Value<any>?      Placeholder: string?
		Searchable: boolean?           OnChanged: (value: any) -> ()?
		FullWidth: boolean?            LayoutOrder
]]

local Fusion = require(script.Parent.Parent.Core.Fusion)
local Theme = require(script.Parent.Parent.Core.Theme)
local Animation = require(script.Parent.Parent.Core.Animation)
local Sound = require(script.Parent.Parent.Core.Sound)
local Primitives = require(script.Parent.Primitives)
local UseHover = require(script.Parent.Parent.Hooks.UseHover)

local New = Fusion.New
local Children = Fusion.Children
local OnEvent = Fusion.OnEvent
local OnChange = Fusion.OnChange
local Computed = Fusion.Computed
local ForValues = Fusion.ForValues
local Tween = Fusion.Tween
local Value = Fusion.Value

local ROW = 32

return function(props: { [string]: any }): Frame
	local items = props.Items or {}
	local selected = props.Value or Value(nil)
	local open = Value(false)
	local query = Value("")
	local hover = UseHover({ Sound = false })

	local filtered = Computed(function()
		local q = query:get():lower()
		if q == "" then
			return items
		end
		local out = {}
		for _, item in items :: { any } do
			if item.Label:lower():find(q, 1, true) then
				table.insert(out, item)
			end
		end
		return out
	end)

	local selectedLabel = Computed(function()
		local current = selected:get()
		for _, item in items :: { any } do
			if item.Value == current then
				return item.Label
			end
		end
		return props.Placeholder or "Select…"
	end)

	local hasSelection = Computed(function()
		return selected:get() ~= nil
	end)

	local function choose(item: any)
		if item.Disabled then
			return
		end
		selected:set(item.Value)
		open:set(false)
		query:set("")
		Sound.Play("Click")
		if props.OnChanged then
			props.OnChanged(item.Value)
		end
	end

	local listHeight = Computed(function()
		local count = math.min(#filtered:get(), 6)
		local search = if props.Searchable then ROW + 6 else 0
		return if open:get() then count * ROW + 8 + search else 0
	end)

	return New("Frame")({
		Name = "AetherDropdown",
		Parent = props.Parent,
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = if props.FullWidth ~= false then UDim2.new(1, 0, 0, 0) else UDim2.fromOffset(240, 0),
		LayoutOrder = props.LayoutOrder or 0,
		ZIndex = 10,
		[Children] = {
			Primitives.List({ Gap = 4 }),

			-- Trigger
			New("TextButton")({
				Name = "Trigger",
				Text = "",
				AutoButtonColor = false,
				BackgroundColor3 = Tween(
					Computed(function()
						return if hover.Hovering:get() then Theme.Colors.SurfaceHover:get() else Theme.Colors.Surface:get()
					end),
					Animation.Presets.Fast
				),
				Size = UDim2.new(1, 0, 0, 36),
				LayoutOrder = 0,
				[OnEvent("MouseEnter")] = hover.Enter,
				[OnEvent("MouseLeave")] = hover.Leave,
				[OnEvent("Activated")] = function()
					open:set(not open:get())
					Sound.Play(if open:get() then "Open" else "Close")
				end,
				[Children] = {
					Primitives.Corner("Md"),
					Primitives.Stroke({
						Color = Tween(
							Computed(function()
								return if open:get() then Theme.Colors.Primary:get() else Theme.Colors.Border:get()
							end),
							Animation.Presets.Fast
						),
						Transparency = Computed(function()
							return if open:get() then 0 else 0.35
						end),
					}),
					Primitives.Padding({ X = 12 }),
					Primitives.Text({
						Text = selectedLabel,
						Size = "Md",
						Color = Computed(function()
							return if hasSelection:get() then Theme.Colors.Text:get() else Theme.Colors.TextDisabled:get()
						end),
						Props = { Position = UDim2.fromScale(0, 0.5), AnchorPoint = Vector2.new(0, 0.5) },
					}),
					New("Frame")({
						Name = "Chevron",
						BackgroundTransparency = 1,
						Size = UDim2.fromOffset(16, 16),
						Position = UDim2.new(1, 0, 0.5, 0),
						AnchorPoint = Vector2.new(1, 0.5),
						Rotation = Tween(
							Computed(function()
								return if open:get() then 180 else 0
							end),
							Animation.Presets.Normal
						),
						[Children] = {
							Primitives.Icon({ Name = "chevron-down", Size = 16, Color = Theme.Colors.TextMuted }),
						},
					}),
				},
			}),

			-- Menu
			New("Frame")({
				Name = "Menu",
				BackgroundColor3 = Theme.Colors.Elevated,
				ClipsDescendants = true,
				Size = Tween(
					Computed(function()
						return UDim2.new(1, 0, 0, listHeight:get())
					end),
					Animation.Presets.Normal
				),
				LayoutOrder = 1,
				ZIndex = 20,
				Visible = Computed(function()
					return listHeight:get() > 0 or open:get()
				end),
				[Children] = {
					Primitives.Corner("Md"),
					Primitives.Stroke(),
					Primitives.Padding(4),
					Primitives.List({ Gap = 2 }),
					Primitives.Shadow({ Size = 32 }),

					if props.Searchable
						then New("Frame")({
							Name = "Search",
							BackgroundColor3 = Theme.Colors.Surface,
							Size = UDim2.new(1, 0, 0, ROW),
							LayoutOrder = -1,
							[Children] = {
								Primitives.Corner("Sm"),
								Primitives.Padding({ X = 10 }),
								New("TextBox")({
									BackgroundTransparency = 1,
									PlaceholderText = "Search…",
									PlaceholderColor3 = Theme.Colors.TextDisabled,
									Text = "",
									TextColor3 = Theme.Colors.Text,
									FontFace = Theme.Fonts.Body,
									TextSize = Theme.TextSizes.Sm,
									TextXAlignment = Enum.TextXAlignment.Left,
									ClearTextOnFocus = false,
									Size = UDim2.fromScale(1, 1),
									[OnChange("Text")] = function(t: string)
										query:set(t)
									end,
								}),
							},
						})
						else nil,

					ForValues(filtered, function(item: any)
						local rowHover = Value(false)
						local isSelected = Computed(function()
							return selected:get() == item.Value
						end)
						return New("TextButton")({
							Name = "Item",
							Text = "",
							AutoButtonColor = false,
							BackgroundColor3 = Tween(
								Computed(function()
									return if rowHover:get() or isSelected:get()
										then Theme.Colors.SurfaceHover:get()
										else Theme.Colors.Elevated:get()
									end
								end),
								Animation.Presets.Fast
							),
							BackgroundTransparency = Computed(function()
								return if rowHover:get() or isSelected:get() then 0 else 1
							end),
							Size = UDim2.new(1, 0, 0, ROW),
							[OnEvent("MouseEnter")] = function()
								rowHover:set(true)
							end,
							[OnEvent("MouseLeave")] = function()
								rowHover:set(false)
							end,
							[OnEvent("Activated")] = function()
								choose(item)
							end,
							[Children] = {
								Primitives.Corner("Sm"),
								Primitives.Padding({ X = 10 }),
								Primitives.List({
									Direction = Enum.FillDirection.Horizontal,
									Gap = 8,
									VerticalAlignment = Enum.VerticalAlignment.Center,
								}),
								if item.Icon
									then Primitives.Icon({
										Name = item.Icon,
										Size = 14,
										Color = Theme.Colors.TextMuted,
										LayoutOrder = 0,
									})
									else nil,
								Primitives.Text({
									Text = item.Label,
									Size = "Sm",
									Color = if item.Disabled then Theme.Colors.TextDisabled else Theme.Colors.Text,
									LayoutOrder = 1,
								}),
								New("Frame")({
									BackgroundTransparency = 1,
									Size = UDim2.fromOffset(14, 14),
									LayoutOrder = 2,
									Visible = isSelected,
									[Children] = {
										Primitives.Icon({ Name = "check", Size = 14, Color = Theme.Colors.Primary }),
									},
								}),
							},
						})
					end, Fusion.cleanup),
				},
			}),
		},
	}) :: Frame
end
