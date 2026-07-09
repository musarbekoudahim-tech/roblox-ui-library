--!strict
--[[
	AetherUI • Core/Theme
	Reactive theme manager built on Fusion Values.

	Every token is a Fusion Value, so switching themes live-updates the whole
	UI (and animates anywhere a token is wrapped in Tween/Spring).

	Usage:
		Theme.Apply("Light")
		Theme.Register("Dracula", { Colors = { Primary = Color3.fromRGB(...) } }, "Dark")
		local json = Theme.Save()      -- serialize custom themes
		Theme.Load(json)               -- restore them later
]]

local HttpService = game:GetService("HttpService")

local Fusion = require(script.Parent.Fusion)
local Themes = require(script.Parent.Themes)
local Types = require(script.Parent.Parent.Types)
local Utils = require(script.Parent.Utils)
local Signal = require(script.Parent.Signal)

local Value = Fusion.Value

type ThemeSpec = Types.ThemeSpec

local Theme = {}

Theme.Registered = {} :: { [string]: ThemeSpec }
for name, spec in Themes :: { [string]: ThemeSpec } do
	Theme.Registered[name] = spec
end

--- Flattens a theme spec into a single token table:
--- all Colors at the top level, plus RadiusSm/RadiusMd/... numbers.
local function flatten(spec: ThemeSpec): { [string]: any }
	local flat: { [string]: any } = {}
	for key, color in spec.Colors :: any do
		flat[key] = color
	end
	for key, value in spec.Radius :: any do
		flat["Radius" .. key] = value
	end
	flat.StrokeTransparency = spec.StrokeTransparency
	flat.GlassTransparency = spec.GlassTransparency
	flat.ShadowTransparency = spec.ShadowTransparency
	flat.Mode = spec.Mode or "Dark"
	return flat
end

--- Name of the active theme ("Dark" by default).
Theme.ActiveName = Value("Dark")
--- Reactive flat token table of the active theme. Components read
--- `theme:get().Primary`, `theme:get().RadiusMd`, etc. inside Computeds so
--- switching themes live-updates everything.
Theme.Current = Value(flatten(Theme.Registered.Dark))
Theme.Changed = Signal.new() :: any

-- Reactive token stores ---------------------------------------------------

local default = Theme.Registered.Dark

Theme.Colors = {} :: { [string]: any }
for key, color in default.Colors :: any do
	Theme.Colors[key] = Value(color)
end

Theme.Radius = {} :: { [string]: any }
for key, value in default.Radius :: any do
	Theme.Radius[key] = Value(value)
end

Theme.Spacing = table.clone(default.Spacing)
Theme.TextSizes = table.clone(default.TextSizes)

Theme.Fonts = {
	Body = Value(default.Fonts.Body),
	Heading = Value(default.Fonts.Heading),
	Mono = Value(default.Fonts.Mono),
}

Theme.StrokeTransparency = Value(default.StrokeTransparency)
Theme.GlassTransparency = Value(default.GlassTransparency)
Theme.ShadowTransparency = Value(default.ShadowTransparency)
Theme.Mode = Value(default.Mode or "Dark")

-- API ----------------------------------------------------------------------

--- Applies a registered theme by name. Live-updates every mounted component.
function Theme.Apply(name: string)
	local spec = Theme.Registered[name]
	assert(spec ~= nil, `[AetherUI] Unknown theme "{name}". Register it first with Theme.Register.`)

	for key, color in spec.Colors :: any do
		if Theme.Colors[key] then
			Theme.Colors[key]:set(color)
		end
	end
	for key, value in spec.Radius :: any do
		if Theme.Radius[key] then
			Theme.Radius[key]:set(value)
		end
	end
	Theme.Fonts.Body:set(spec.Fonts.Body)
	Theme.Fonts.Heading:set(spec.Fonts.Heading)
	Theme.Fonts.Mono:set(spec.Fonts.Mono)
	Theme.StrokeTransparency:set(spec.StrokeTransparency)
	Theme.GlassTransparency:set(spec.GlassTransparency)
	Theme.ShadowTransparency:set(spec.ShadowTransparency)
	Theme.Mode:set(spec.Mode or "Dark")
	Theme.Spacing = table.clone(spec.Spacing)
	Theme.TextSizes = table.clone(spec.TextSizes)

	Theme.ActiveName:set(name)
	Theme.Current:set(flatten(spec))
	Theme.Changed:Fire(name)
end

--- Registers a new theme. `overrides` is deep-merged on top of `base` (default "Dark").
function Theme.Register(name: string, overrides: { [string]: any }, base: string?): ThemeSpec
	local parent = Theme.Registered[base or "Dark"]
	assert(parent ~= nil, `[AetherUI] Unknown base theme "{tostring(base)}".`)
	local spec = Utils.DeepMerge(parent :: any, overrides) :: any
	spec.Name = name
	Theme.Registered[name] = spec
	return spec
end

--- Returns the raw spec of the current theme.
function Theme.GetSpec(): ThemeSpec
	return Theme.Registered[Theme.ActiveName:get()]
end

--- Sets a single color token on the fly (e.g. Theme.SetColor("Primary", myColor)).
function Theme.SetColor(token: string, color: Color3)
	local state = Theme.Colors[token]
	assert(state ~= nil, `[AetherUI] Unknown color token "{token}".`)
	state:set(color)
	-- Propagate into the flat reactive token table so all components update.
	local flat = table.clone(Theme.Current:get())
	flat[token] = color
	Theme.Current:set(flat)
end

-- Persistence ----------------------------------------------------------------

local function serializeColor(c: Color3): { number }
	return { math.round(c.R * 255), math.round(c.G * 255), math.round(c.B * 255) }
end

--- Serializes all custom (non-builtin) themes + the active theme name to JSON.
function Theme.Save(): string
	local custom = {}
	for name, spec in Theme.Registered do
		if Themes[name] == nil then
			local colors = {}
			for key, color in spec.Colors :: any do
				colors[key] = serializeColor(color)
			end
			custom[name] = { Colors = colors, Mode = spec.Mode, Base = "Dark" }
		end
	end
	return HttpService:JSONEncode({
		Active = Theme.ActiveName:get(),
		Custom = custom,
	})
end

--- Restores themes serialized with Theme.Save() and re-applies the active theme.
function Theme.Load(json: string)
	local ok, data = pcall(HttpService.JSONDecode, HttpService, json)
	if not ok or type(data) ~= "table" then
		warn("[AetherUI] Theme.Load received invalid JSON")
		return
	end
	for name, entry in (data.Custom or {}) :: { [string]: any } do
		local colors = {}
		for key, rgb in (entry.Colors or {}) :: { [string]: { number } } do
			colors[key] = Color3.fromRGB(rgb[1], rgb[2], rgb[3])
		end
		Theme.Register(name, { Colors = colors, Mode = entry.Mode }, entry.Base or "Dark")
	end
	if data.Active and Theme.Registered[data.Active] then
		Theme.Apply(data.Active)
	end
end

return Theme
