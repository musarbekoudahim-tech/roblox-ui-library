--!strict
--[[
	AetherUI • Components/MultiSelect
	Multi-select dropdown rendering selections as removable chips/tags.

	props:
		Items: { { Label, Value, Icon? } }
		Values: Fusion.Value<{ any }>?
		Placeholder: string?     MaxVisibleChips: number?
		OnChanged: (values: { any }) -> ()?     LayoutOrder
]]

local Fusion = require(script.Parent.Parent.Core.Fusion)
local Theme = require(script.Parent.Parent.Core.Theme)
local Animation = require(script.Parent.Parent.Core.Animation)
local Sound = require(script.Parent.Parent.Core.Sound)
local Primitives = require(script.Parent.Primitives)

local New = Fusion.New
local Children = Fusion.Children
local OnEvent = Fusion.OnEvent
local Computed = Fusion.Computed
local ForValues = Fusion.ForValues
local Tween = Fusion.Tween
local Value = Fusion.Value

local ROW = 32

return function(props: { [string]: any }): Frame
	local items = props.Items or {}
	local values = props.Values or Value({})
	local open = Value(false)

	local function isPicked(v: any): boolean
		return table.find(values:get(), v) ~= nil
	end

	local function toggle(v: any)
		local current = table.clone(values:get())
		local index = table.find(current, v)
		if index then
			table.remove(current, index)
		else
			table.insert(current, v)
		end
		values:set(current)
		Sound.Play("Click")
		if props.OnChanged then
			props.OnChanged(current)
		end
	end

	local function labelOf(v: any): string
		for _, item in items :: { any } do
			if item.Value == v then
				return item.Label
			end
		end
		return tostring(v)
	end

	local chips = Computed(function()
		local out = {}
		local maxChips = props.MaxVisibleChips or 4
		local current = values:get()
		for index, v in current do
			if index > maxChips then
				table.insert(out, { Kind = "overflow", Count = #current - maxChips })
				break
			end
			table.insert(out, { Kind = "chip", Value = v, Label = labelOf(v) })
		end
		return out
	end)

	local menuHeight = Computed(function()
		return if open:get() then math.min(#items, 6) * ROW + 8 else 0
	end)

	return New("Frame")({
		Name = "AetherMultiSelect",
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, 0),
		LayoutOrder = props.LayoutOrder or 0,
		ZIndex = 10,
		[Children] = {
			Primitives.List({ Gap = 4 }),

			-- Trigger with chips
			New("TextButton")({
				Name = "Trigger",
				Text = "",
				AutoButtonColor = false,
				BackgroundColor3 = Theme.Colors.Surface,
				AutomaticSize = Enum.AutomaticSize.Y,
				Size = UDim2.new(1, 0, 0, 36),
				LayoutOrder = 0,
				[OnEvent("Activated")] = function()
					open:set(not open:get())
				end,
				[Children] = {
					Primitives.Corner("Md"),
					Primitives.Stroke({
						Color = Computed(function()
							return if open:get() then Theme.Colors.Primary:get() else Theme.Colors.Border:get()
						end),
						Transparency = Computed(function()
							return if open:get() then 0 else 0.35
						end),
					}),
					Primitives.Padding({ X = 8, Y = 6 }),
					Primitives.List({
						Direction = Enum.FillDirection.Horizontal,
						Gap = 4,
						VerticalAlignment = Enum.VerticalAlignment.Center,
						Wraps = true,
					}),

					Primitives.Text({
						Text = props.Placeholder or "Select…",
						Size = "Md",
						Color = Theme.Colors.TextDisabled,
						LayoutOrder = 0,
						Props = {
							Visible = Computed(function()
								return #values:get() == 0
							end),
						},
					}),

					ForValues(chips, function(chip: any)
						if chip.Kind == "overflow" then
							return New("Frame")({
								BackgroundColor3 = Theme.Colors.Secondary,
								AutomaticSize = Enum.AutomaticSize.XY,
								LayoutOrder = 99,
								[Children] = {
									Primitives.Corner("Full"),
									Primitives.Padding({ X = 8, Y = 3 }),
									Primitives.Text({ Text = `+{chip.Count}`, Size = "Xs", Muted = true }),
								},
							})
						end
						return New("Frame")({
							Name = "Chip",
							BackgroundColor3 = Theme.Colors.Secondary,
							AutomaticSize = Enum.AutomaticSize.XY,
							LayoutOrder = 1,
							[Children] = {
								Primitives.Corner("Full"),
								Primitives.Padding({ Left = 8, Right = 4, Y = 3 }),
								Primitives.List({
									Direction = Enum.FillDirection.Horizontal,
									Gap = 4,
									VerticalAlignment = Enum.VerticalAlignment.Center,
								}),
								Primitives.Text({ Text = chip.Label, Size = "Xs" }),
								New("TextButton")({
									Text = "",
									BackgroundTransparency = 1,
									Size = UDim2.fromOffset(14, 14),
									LayoutOrder = 2,
									[OnEvent("Activated")] = function()
										toggle(chip.Value)
									end,
									[Children] = {
										Primitives.Icon({
											Name = "x",
											Size = 10,
											Color = Theme.Colors.TextMuted,
											Position = UDim2.fromScale(0.5, 0.5),
											AnchorPoint = Vector2.new(0.5, 0.5),
										}),
									},
								}),
							},
						})
					end, Fusion.cleanup),
				},
			}),

			-- Menu
			New("Frame")({
				Name = "Menu",
				BackgroundColor3 = Theme.Colors.Elevated,
				ClipsDescendants = true,
				Size = Tween(
					Computed(function()
						return UDim2.new(1, 0, 0, menuHeight:get())
					end),
					Animation.Presets.Normal
				),
				LayoutOrder = 1,
				ZIndex = 20,
				[Children] = {
					Primitives.Corner("Md"),
					Primitives.Stroke(),
					Primitives.Padding(4),
					Primitives.List({ Gap = 2 }),

					ForValues(items, function(item: any)
						local rowHover = Value(false)
						local picked = Computed(function()
							local _ = values:get()
							return isPicked(item.Value)
						end)
						return New("TextButton")({
							Text = "",
							AutoButtonColor = false,
							BackgroundColor3 = Theme.Colors.SurfaceHover,
							BackgroundTransparency = Computed(function()
								return if rowHover:get() then 0 else 1
							end),
							Size = UDim2.new(1, 0, 0, ROW),
							[OnEvent("MouseEnter")] = function()
								rowHover:set(true)
							end,
							[OnEvent("MouseLeave")] = function()
								rowHover:set(false)
							end,
							[OnEvent("Activated")] = function()
								toggle(item.Value)
							end,
							[Children] = {
								Primitives.Corner("Sm"),
								Primitives.Padding({ X = 10 }),
								Primitives.List({
									Direction = Enum.FillDirection.Horizontal,
									Gap = 8,
									VerticalAlignment = Enum.VerticalAlignment.Center,
								}),
								-- Checkbox indicator
								New("Frame")({
									BackgroundColor3 = Tween(
										Computed(function()
											return if picked:get() then Theme.Colors.Primary:get() else Theme.Colors.Surface:get()
										end),
										Animation.Presets.Fast
									),
									Size = UDim2.fromOffset(16, 16),
									LayoutOrder = 0,
									[Children] = {
										Primitives.Corner(4),
										Primitives.Stroke({
											Color = Computed(function()
												return if picked:get() then Theme.Colors.Primary:get() else Theme.Colors.BorderStrong:get()
											end),
											Transparency = 0,
										}),
										New("Frame")({
											BackgroundTransparency = 1,
											Size = UDim2.fromScale(1, 1),
											Visible = picked,
											[Children] = {
												Primitives.Icon({
													Name = "check",
													Size = 11,
													Color = Theme.Colors.PrimaryText,
													Position = UDim2.fromScale(0.5, 0.5),
													AnchorPoint = Vector2.new(0.5, 0.5),
												}),
											},
										}),
									},
								}),
								Primitives.Text({ Text = item.Label, Size = "Sm", LayoutOrder = 1 }),
							},
						})
					end, Fusion.cleanup),
				},
			}),
		},
	}) :: Frame
end
