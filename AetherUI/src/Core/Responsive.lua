--!strict
--[[
	AetherUI • Core/Responsive
	Viewport-aware scaling. Attach a managed UIScale to any root gui:

		Responsive.Attach(myScreenGuiRootFrame)          -- auto scale
		Responsive.SetUserScale(1.15)                    -- user preference on top
]]

local Fusion = require(script.Parent.Fusion)
local Maid = require(script.Parent.Maid)

local Value = Fusion.Value

local Responsive = {}

--- Reference resolution the UI was designed against.
Responsive.BaseResolution = Vector2.new(1920, 1080)

--- Reactive user scale preference multiplied on top of auto scale.
Responsive.UserScale = Value(1)

--- Reactive auto scale derived from viewport size.
Responsive.AutoScale = Value(1)

Responsive.MinScale = 0.65
Responsive.MaxScale = 1.5

local function computeScale(viewport: Vector2): number
	if viewport.X <= 0 or viewport.Y <= 0 then
		return 1
	end
	local scale = math.min(viewport.X / Responsive.BaseResolution.X, viewport.Y / Responsive.BaseResolution.Y)
	-- Never scale up past 1 automatically; blend towards 1 to avoid tiny UI on small screens
	scale = 0.5 + scale * 0.5
	return math.clamp(scale, Responsive.MinScale, Responsive.MaxScale)
end

function Responsive.SetUserScale(scale: number)
	Responsive.UserScale:set(math.clamp(scale, 0.5, 2))
end

--- Attaches a managed UIScale to `gui` that tracks viewport size and user scale.
--- Returns a cleanup function.
function Responsive.Attach(gui: GuiObject): () -> ()
	local maid = Maid.new()
	local uiScale = Instance.new("UIScale")
	uiScale.Parent = gui
	maid:Add(uiScale)

	local camera = workspace.CurrentCamera

	local function update()
		if camera then
			Responsive.AutoScale:set(computeScale(camera.ViewportSize))
		end
		uiScale.Scale = Responsive.AutoScale:get() * Responsive.UserScale:get()
	end

	if camera then
		maid:Add(camera:GetPropertyChangedSignal("ViewportSize"):Connect(update))
	end
	maid:Add(Fusion.Observer(Responsive.UserScale):onChange(update))
	maid:Add(Fusion.Observer(Responsive.AutoScale):onChange(update))
	update()

	return function()
		maid:Clean()
	end
end

return Responsive
