--!strict
--[[
	AetherUI • Components/Stepper

	Multi-step wizard header + content + navigation.

	props:
		Steps: { { Title: string, Description: string?, Icon: string?, Content: (() -> Instance)? } }
		Step: Fusion Value?          (bind current step externally; 1-based)
		OnFinish: (() -> ())?
		OnStepChanged: ((step: number) -> ())?
		Size: UDim2?    LayoutOrder: number?    Parent: Instance?
]]

local Fusion = require(script.Parent.Parent.Core.Fusion)
local Theme = require(script.Parent.Parent.Core.Theme)
local Primitives = require(script.Parent.Primitives)
local Button = require(script.Parent.Button)

local New = Fusion.New
local Children = Fusion.Children
local Computed = Fusion.Computed
local Value = Fusion.Value
local Tween = Fusion.Tween

local DOT = 30

return function(props: { [string]: any }): Frame
	local steps: { { [string]: any } } = props.Steps or {}
	local current = props.Step or Value(1)

	local function goTo(step: number)
		local clamped = math.clamp(step, 1, #steps)
		current:set(clamped)
		if props.OnStepChanged then
			props.OnStepChanged(clamped)
		end
	end

	-- Step indicator rail -------------------------------------------------------

	local rail: { any } = {
		Primitives.List({
			Direction = "Horizontal",
			Padding = 0,
			VerticalAlignment = Enum.VerticalAlignment.Top,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
		}),
	}

	for index, step in steps do
		local state = Computed(function()
			local c = current:get()
			return if index < c then "Done" elseif index == c then "Active" else "Todo"
		end)

		local dotChildren: { any } = { Primitives.Corner("Full") }

		table.insert(dotChildren, Primitives.Icon({
			Name = "check",
			Size = 14,
			Color = Computed(function()
				return Theme.Colors.PrimaryText:get()
			end),
			Transparency = Computed(function()
				return if state:get() == "Done" then 0 else 1
			end),
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
		}))

		table.insert(dotChildren, Primitives.Text({
			Text = tostring(index),
			Size = 12,
			Bold = true,
			Color = Computed(function()
				return if state:get() == "Active"
					then Theme.Colors.PrimaryText:get()
					else Theme.Colors.TextMuted:get()
			end),
			Props = {
				Size = UDim2.fromScale(1, 1),
				TextXAlignment = Enum.TextXAlignment.Center,
				TextTransparency = Computed(function()
					return if state:get() == "Done" then 1 else 0
				end),
			},
		}))

		local column = New("Frame")({
			Name = "Step_" .. index,
			Size = UDim2.new(1 / #steps, 0, 0, 64),
			BackgroundTransparency = 1,
			LayoutOrder = index,
			[Children] = {
				-- Connector line (behind dot, spans full column, hidden on first step)
				New("Frame")({
					Name = "Connector",
					Size = UDim2.new(1, -DOT, 0, 2),
					Position = UDim2.new(-0.5, DOT / 2, 0, DOT / 2 - 1),
					BackgroundColor3 = Tween(
						Computed(function()
							return if current:get() > index - 1
								then Theme.Colors.Primary:get()
								else Theme.Colors.Border:get()
						end),
						TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
					),
					BorderSizePixel = 0,
					Visible = index > 1,
					ZIndex = 1,
				}),
				New("Frame")({
					Name = "Dot",
					Size = UDim2.fromOffset(DOT, DOT),
					Position = UDim2.new(0.5, -DOT / 2, 0, 0),
					BackgroundColor3 = Tween(
						Computed(function()
							local s = state:get()
							return if s == "Todo"
								then Theme.Colors.SurfaceHigh:get()
								else Theme.Colors.Primary:get()
						end),
						TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
					),
					ZIndex = 2,
					[Children] = dotChildren,
				}),
				Primitives.Text({
					Text = step.Title,
					Size = 11,
					Color = Computed(function()
						return if state:get() == "Todo"
							then Theme.Colors.TextMuted:get()
							else Theme.Colors.Text:get()
					end),
					Props = {
						Size = UDim2.new(1, -8, 0, 26),
						Position = UDim2.new(0, 4, 0, DOT + 6),
						TextXAlignment = Enum.TextXAlignment.Center,
						TextWrapped = true,
					},
				}),
			},
		})

		table.insert(rail, column)
	end

	local railFrame = New("Frame")({
		Name = "Rail",
		Size = UDim2.new(1, 0, 0, 70),
		BackgroundTransparency = 1,
		LayoutOrder = 1,
		[Children] = rail,
	})

	-- Content area ------------------------------------------------------------------

	local contentArea = New("Frame")({
		Name = "Content",
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, 0),
		BackgroundTransparency = 1,
		LayoutOrder = 2,
		[Children] = Computed(function()
			local step = steps[current:get()]
			if step and step.Content then
				return { step.Content() }
			end
			if step and step.Description then
				return {
					Primitives.Padding({ Y = 8 }),
					Primitives.Text({
						Text = step.Description,
						Size = 13,
						Muted = true,
						Wrapped = true,
						Props = { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y },
					}),
				}
			end
			return {}
		end, Fusion.cleanup),
	})

	-- Navigation --------------------------------------------------------------------

	local nav = New("Frame")({
		Name = "Nav",
		Size = UDim2.new(1, 0, 0, 48),
		BackgroundTransparency = 1,
		LayoutOrder = 3,
		[Children] = {
			Button({
				Text = "Back",
				Icon = "chevron-left",
				Variant = "Outline",
				Disabled = Computed(function()
					return current:get() <= 1
				end),
				Props = { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0) },
				OnClick = function()
					goTo(current:get() - 1)
				end,
			}),
			Button({
				Text = Computed(function()
					return if current:get() >= #steps then "Finish" else "Continue"
				end),
				IconRight = "chevron-right",
				Variant = "Primary",
				Props = { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0) },
				OnClick = function()
					if current:get() >= #steps then
						if props.OnFinish then
							props.OnFinish()
						end
					else
						goTo(current:get() + 1)
					end
				end,
			}),
		},
	})

	return New("Frame")({
		Name = "AetherStepper",
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = props.Size or UDim2.new(1, 0, 0, 0),
		BackgroundTransparency = 1,
		LayoutOrder = props.LayoutOrder,
		Parent = props.Parent,
		[Children] = {
			Primitives.List({ Padding = 12 }),
			railFrame,
			contentArea,
			nav,
		},
	})
end
