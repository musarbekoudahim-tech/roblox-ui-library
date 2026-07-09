--!strict
--[[
	AetherUI • Core/Accessibility
	Reduced motion detection, font scaling, and focus-visible support.
]]

local GuiService = game:GetService("GuiService")

local Fusion = require(script.Parent.Fusion)
local Value = Fusion.Value

local Accessibility = {}

--- Reactive: true when the platform requests reduced motion.
Accessibility.ReducedMotion = Value(false)

--- Reactive: multiplier applied to all text sizes (1 = default).
Accessibility.FontScale = Value(1)

--- Reactive: when true, focus rings are always rendered (keyboard navigation mode).
Accessibility.FocusVisible = Value(false)

local ok, reduced = pcall(function()
	return (GuiService :: any).ReducedMotionEnabled
end)
if ok and reduced == true then
	Accessibility.ReducedMotion:set(true)
end

function Accessibility.SetFontScale(scale: number)
	Accessibility.FontScale:set(math.clamp(scale, 0.75, 2))
end

function Accessibility.SetReducedMotion(enabled: boolean)
	Accessibility.ReducedMotion:set(enabled)
end

function Accessibility.SetFocusVisible(enabled: boolean)
	Accessibility.FocusVisible:set(enabled)
end

--- Scales a base text size by the current font scale (non-reactive read).
function Accessibility.ScaleText(size: number): number
	return math.round(size * Accessibility.FontScale:get())
end

return Accessibility
