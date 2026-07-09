--!strict
--[[
	AetherUI • Hooks/UseHover
	Returns a reactive hover state plus enter/leave handlers to wire to OnEvent.

		local hover = UseHover()
		New "TextButton" {
			[OnEvent "MouseEnter"] = hover.Enter,
			[OnEvent "MouseLeave"] = hover.Leave,
			BackgroundColor3 = Tween(Computed(function()
				return if hover.Hovering:get() then ... else ...
			end), Animation.Presets.Fast),
		}
]]

local Fusion = require(script.Parent.Parent.Core.Fusion)
local Sound = require(script.Parent.Parent.Core.Sound)

export type Hover = {
	Hovering: any,
	Enter: () -> (),
	Leave: () -> (),
}

return function(options: { Sound: boolean? }?): Hover
	local hovering = Fusion.Value(false)
	local playSound = if options then options.Sound ~= false else true

	return {
		Hovering = hovering,
		Enter = function()
			hovering:set(true)
			if playSound then
				Sound.Play("Hover")
			end
		end,
		Leave = function()
			hovering:set(false)
		end,
	}
end
