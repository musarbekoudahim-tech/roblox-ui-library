--!strict
--[[
	AetherUI • Core/Animation
	Motion design tokens + helpers.

	• `Presets`  — TweenInfo presets for Fusion.Tween wrapping
	• `Springs`  — { Speed, Damping } configs for Fusion.Spring
	• `Stagger`  — run a callback across a list with per-item delay
	• `Enter/Exit` — imperative transitions for overlays (toasts, modals)

	All imperative helpers respect Accessibility.ReducedMotion.
]]

local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")

local Animation = {}

-- // TweenInfo presets ------------------------------------------------------

Animation.Presets = {
	Instant = TweenInfo.new(0.05, Enum.EasingStyle.Linear),
	Fast = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	Normal = TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
	Smooth = TweenInfo.new(0.32, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
	Slow = TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
	Bounce = TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
	Expressive = TweenInfo.new(0.6, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out),
}

-- // Spring configs (for Fusion.Spring(state, speed, damping)) ---------------

Animation.Springs = {
	Stiff = { Speed = 40, Damping = 1 },
	Snappy = { Speed = 28, Damping = 0.95 },
	Gentle = { Speed = 18, Damping = 1 },
	Wobbly = { Speed = 20, Damping = 0.55 },
	Slow = { Speed = 10, Damping = 1 },
}

-- // Reduced motion -----------------------------------------------------------

function Animation.ReducedMotion(): boolean
	local ok, reduced = pcall(function()
		return (GuiService :: any).ReducedMotionEnabled
	end)
	return ok and reduced == true
end

local function info(preset: TweenInfo): TweenInfo
	if Animation.ReducedMotion() then
		return TweenInfo.new(0.01, Enum.EasingStyle.Linear)
	end
	return preset
end

-- // Imperative helpers -------------------------------------------------------

--- Tweens properties on an instance and returns the Tween (already playing).
function Animation.Tween(instance: Instance, properties: { [string]: any }, preset: TweenInfo?): Tween
	local tween = TweenService:Create(instance, info(preset or Animation.Presets.Normal), properties)
	tween:Play()
	return tween
end

--- Fades a GuiObject (and its descendants' transparency-ish props) in from offset.
function Animation.Enter(gui: GuiObject, options: { Offset: UDim2?, From: number?, Preset: TweenInfo? }?)
	local opts = options or {}
	local targetPosition = gui.Position
	local offset = opts.Offset or UDim2.fromOffset(0, 8)

	gui.Position = targetPosition - offset
	if gui:IsA("Frame") or gui:IsA("TextButton") or gui:IsA("ImageButton") or gui:IsA("TextLabel") then
		local target = (gui :: any).BackgroundTransparency
		;(gui :: any).BackgroundTransparency = opts.From or 1
		Animation.Tween(gui, { Position = targetPosition, BackgroundTransparency = target }, opts.Preset or Animation.Presets.Smooth)
	else
		Animation.Tween(gui, { Position = targetPosition }, opts.Preset or Animation.Presets.Smooth)
	end
end

--- Fades a GuiObject out, then destroys (or calls onDone).
function Animation.Exit(gui: GuiObject, options: { Offset: UDim2?, Preset: TweenInfo?, OnDone: (() -> ())? }?)
	local opts = options or {}
	local offset = opts.Offset or UDim2.fromOffset(0, 8)
	local tween = Animation.Tween(gui, {
		Position = gui.Position + offset,
		BackgroundTransparency = 1,
	}, opts.Preset or Animation.Presets.Fast)
	tween.Completed:Once(function()
		if opts.OnDone then
			opts.OnDone()
		else
			gui:Destroy()
		end
	end)
end

--- Runs `fn(item, index)` for each item, spaced by `delay` seconds (default 0.04).
function Animation.Stagger<T>(items: { T }, fn: (T, number) -> (), delayPerItem: number?)
	local step = if Animation.ReducedMotion() then 0 else (delayPerItem or 0.04)
	for index, item in items do
		task.delay(step * (index - 1), fn, item, index)
	end
end

--- Pulse scale effect (micro-interaction for presses).
function Animation.Pulse(gui: GuiObject, scaleTo: number?)
	local uiScale = gui:FindFirstChildOfClass("UIScale")
	if not uiScale then
		uiScale = Instance.new("UIScale")
		assert(uiScale)
		uiScale.Parent = gui
	end
	assert(uiScale)
	uiScale.Scale = scaleTo or 0.965
	Animation.Tween(uiScale, { Scale = 1 }, Animation.Presets.Bounce)
end

return Animation
