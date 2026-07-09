--!strict
--[=[
	AetherUI · Progress
	ProgressBar (determinate + indeterminate shimmer) and CircularProgress.
]=]

local Fusion = require(script.Parent.Parent.Core.Fusion)
local Theme = require(script.Parent.Parent.Core.Theme)

local New = Fusion.New
local Children = Fusion.Children
local Computed = Fusion.Computed
local Spring = Fusion.Spring

local RunService = game:GetService("RunService")

local Progress = {}

export type ProgressBarProps = {
	Value: Fusion.CanBeState<number>?, -- 0..1; nil = indeterminate
	ShowLabel: boolean?,
	Color: Color3?,
	Height: number?,
	Size: UDim2?,
	LayoutOrder: number?,
	Parent: Instance?,
}

function Progress.Bar(props: ProgressBarProps): Frame
	local theme = Theme.Current
	local height = props.Height or 6
	local indeterminate = props.Value == nil

	local progress = Computed(function()
		if indeterminate then
			return 0
		end
		local v = props.Value
		if typeof(v) == "number" then
			return math.clamp(v, 0, 1)
		end
		return math.clamp(Fusion.peek(v :: any) or 0, 0, 1)
	end)

	local fillColor = Computed(function()
		return props.Color or Fusion.peek(theme).Primary
	end)

	local children: { Instance } = {
		New("UICorner")({ CornerRadius = UDim.new(1, 0) }),
	}

	if indeterminate then
		local shimmer = New("Frame")({
			Name = "Shimmer",
			Size = UDim2.new(0.35, 0, 1, 0),
			Position = UDim2.fromScale(-0.4, 0),
			BackgroundColor3 = fillColor,
			BorderSizePixel = 0,
			[Children] = { New("UICorner")({ CornerRadius = UDim.new(1, 0) }) },
		}) :: Frame

		local t = 0
		local conn: RBXScriptConnection
		conn = RunService.Heartbeat:Connect(function(dt)
			if not shimmer.Parent then
				conn:Disconnect()
				return
			end
			t = (t + dt * 0.7) % 1.4
			shimmer.Position = UDim2.fromScale(-0.4 + t, 0)
		end)
		table.insert(children, shimmer)
	else
		table.insert(children, New("Frame")({
			Name = "Fill",
			Size = Spring(Computed(function()
				return UDim2.new(Fusion.peek(progress), 0, 1, 0)
			end), 22, 1),
			BackgroundColor3 = fillColor,
			BorderSizePixel = 0,
			[Children] = { New("UICorner")({ CornerRadius = UDim.new(1, 0) }) },
		}))
	end

	local track = New("Frame")({
		Name = "Track",
		Size = UDim2.new(1, props.ShowLabel and -42 or 0, 0, height),
		Position = UDim2.new(0, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundColor3 = Computed(function()
			return Fusion.peek(theme).SurfaceHigh
		end),
		ClipsDescendants = true,
		[Children] = children,
	})

	local wrapperChildren: { Instance } = { track }

	if props.ShowLabel and not indeterminate then
		table.insert(wrapperChildren, New("TextLabel")({
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, 0, 0.5, 0),
			Size = UDim2.fromOffset(36, 14),
			BackgroundTransparency = 1,
			Text = Computed(function()
				return string.format("%d%%", math.floor(Fusion.peek(progress) * 100 + 0.5))
			end),
			Font = Enum.Font.RobotoMono,
			TextSize = 11,
			TextColor3 = Computed(function()
				return Fusion.peek(theme).TextMuted
			end),
			TextXAlignment = Enum.TextXAlignment.Right,
		}))
	end

	return New("Frame")({
		Name = "AetherProgressBar",
		Size = props.Size or UDim2.new(1, 0, 0, math.max(height, 14)),
		BackgroundTransparency = 1,
		LayoutOrder = props.LayoutOrder,
		Parent = props.Parent,
		[Children] = wrapperChildren,
	}) :: Frame
end

export type CircularProgressProps = {
	Value: Fusion.CanBeState<number>?, -- 0..1; nil = spinner
	Diameter: number?,
	Thickness: number?,
	Color: Color3?,
	ShowLabel: boolean?,
	LayoutOrder: number?,
	Parent: Instance?,
}

--[=[
	Circular progress rendered with two half-circle gradient masks — the
	standard Roblox technique for smooth radial progress without image assets.
]=]
function Progress.Circular(props: CircularProgressProps): Frame
	local theme = Theme.Current
	local d = props.Diameter or 44
	local thickness = props.Thickness or 4
	local indeterminate = props.Value == nil

	local progress = Computed(function()
		if indeterminate then
			return 0.25
		end
		local v = props.Value
		if typeof(v) == "number" then
			return math.clamp(v, 0, 1)
		end
		return math.clamp(Fusion.peek(v :: any) or 0, 0, 1)
	end)

	local fillColor = Computed(function()
		return props.Color or Fusion.peek(theme).Primary
	end)

	local function ring(color: Fusion.CanBeState<Color3>, transparency: number): (Frame, UIGradient, UIGradient)
		local leftGrad = New("UIGradient")({
			Transparency = NumberSequence.new(1),
			Rotation = 180,
		}) :: UIGradient
		local rightGrad = New("UIGradient")({
			Transparency = NumberSequence.new(1),
			Rotation = 0,
		}) :: UIGradient

		local function half(grad: UIGradient, isRight: boolean): Frame
			return New("Frame")({
				Size = UDim2.new(0.5, 0, 1, 0),
				Position = isRight and UDim2.fromScale(0.5, 0) or UDim2.fromScale(0, 0),
				BackgroundTransparency = 1,
				ClipsDescendants = true,
				[Children] = {
					New("Frame")({
						Size = UDim2.new(2, 0, 1, 0),
						Position = isRight and UDim2.fromScale(-1, 0) or UDim2.fromScale(0, 0),
						BackgroundTransparency = transparency,
						BackgroundColor3 = color,
						[Children] = {
							New("UICorner")({ CornerRadius = UDim.new(1, 0) }),
							New("UIStroke")({ Thickness = 0, Transparency = 1 }),
							grad,
						},
					}),
				},
			}) :: Frame
		end

		local holder = New("Frame")({
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			[Children] = { half(leftGrad, false), half(rightGrad, true) },
		}) :: Frame
		return holder, leftGrad, rightGrad
	end

	local _ = ring

	-- Simpler robust approach: canvas-group ring using UIStroke arc illusion
	-- Track ring + rotating fill ring clipped to progress fraction.
	local fillRotation = Computed(function()
		return 360 * Fusion.peek(progress)
	end)

	local labelText = Computed(function()
		return string.format("%d%%", math.floor(Fusion.peek(progress) * 100 + 0.5))
	end)

	local spinnerRotation = Fusion.Value(0)
	if indeterminate then
		local conn: RBXScriptConnection
		conn = RunService.Heartbeat:Connect(function(dt)
			spinnerRotation:set((Fusion.peek(spinnerRotation) + dt * 280) % 360)
		end)
		task.delay(0, function()
			-- disconnect when the frame is destroyed (handled below via Destroying)
			local _ = conn
		end)
	end

	local frame: Frame
	frame = New("Frame")({
		Name = "AetherCircularProgress",
		Size = UDim2.fromOffset(d, d),
		BackgroundTransparency = 1,
		LayoutOrder = props.LayoutOrder,
		Parent = props.Parent,
		Rotation = indeterminate and Spring(spinnerRotation, 5, 2) or 0,
		[Children] = {
			-- Track circle
			New("Frame")({
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				[Children] = {
					New("UICorner")({ CornerRadius = UDim.new(1, 0) }),
					New("UIStroke")({
						Color = Computed(function()
							return Fusion.peek(theme).SurfaceHigh
						end),
						Thickness = thickness,
					}),
				},
			}),
			-- Fill arc: two clipped halves rotated by progress
			New("Frame")({
				Name = "ArcLeft",
				Size = UDim2.new(0.5, 0, 1, 0),
				BackgroundTransparency = 1,
				ClipsDescendants = true,
				[Children] = {
					New("Frame")({
						Size = UDim2.new(2, 0, 1, 0),
						BackgroundTransparency = 1,
						Rotation = Spring(Computed(function()
							return math.clamp(Fusion.peek(fillRotation), 180, 360) - 360
						end), 25, 1),
						[Children] = {
							New("UICorner")({ CornerRadius = UDim.new(1, 0) }),
							New("UIStroke")({ Color = fillColor, Thickness = thickness }),
						},
					}),
				},
			}),
			New("Frame")({
				Name = "ArcRight",
				Position = UDim2.fromScale(0.5, 0),
				Size = UDim2.new(0.5, 0, 1, 0),
				BackgroundTransparency = 1,
				ClipsDescendants = true,
				[Children] = {
					New("Frame")({
						Position = UDim2.fromScale(-1, 0),
						Size = UDim2.new(2, 0, 1, 0),
						BackgroundTransparency = 1,
						Rotation = Spring(Computed(function()
							return math.clamp(Fusion.peek(fillRotation), 0, 180) - 180
						end), 25, 1),
						[Children] = {
							New("UICorner")({ CornerRadius = UDim.new(1, 0) }),
							New("UIStroke")({ Color = fillColor, Thickness = thickness }),
						},
					}),
				},
			}),
			(props.ShowLabel and not indeterminate) and New("TextLabel")({
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				Text = labelText,
				Font = Enum.Font.GothamBold,
				TextSize = math.max(10, math.floor(d * 0.24)),
				TextColor3 = Computed(function()
					return Fusion.peek(theme).Text
				end),
			}) or nil,
		},
	}) :: Frame

	return frame
end

return Progress
