--!strict
--[[
	AetherUI • Hooks/UsePress
	Reactive pressed state + press handlers, with optional click sound.
]]

local Fusion = require(script.Parent.Parent.Core.Fusion)
local Sound = require(script.Parent.Parent.Core.Sound)

export type Press = {
	Pressed: any,
	Down: () -> (),
	Up: () -> (),
	Activate: (callback: (() -> ())?) -> (),
}

return function(options: { Sound: boolean? }?): Press
	local pressed = Fusion.Value(false)
	local playSound = if options then options.Sound ~= false else true

	return {
		Pressed = pressed,
		Down = function()
			pressed:set(true)
		end,
		Up = function()
			pressed:set(false)
		end,
		Activate = function(callback)
			if playSound then
				Sound.Play("Click")
			end
			if callback then
				callback()
			end
		end,
	}
end
