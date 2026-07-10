--!strict
--[[
	AetherUI • Core/Themes
	Built-in theme presets: Dark (default), Light, Amoled, Midnight.
	Design language inspired by Linear / Vercel / Arc — restrained palettes,
	soft contrast, one strong accent.
]]

local Types = require(script.Parent.Parent.Types)

local GOTHAM = "rbxasset://fonts/families/GothamSSm.json"
local MONO = "rbxasset://fonts/families/RobotoMono.json"

local function fonts()
	return {
		Body = Font.new(GOTHAM, Enum.FontWeight.Medium),
		Heading = Font.new(GOTHAM, Enum.FontWeight.Bold),
		Mono = Font.new(MONO, Enum.FontWeight.Medium),
	}
end

local base = {
	Radius = { Sm = 6, Md = 8, Lg = 12, Xl = 16, Full = 999 },
	Spacing = { Xs = 4, Sm = 8, Md = 12, Lg = 16, Xl = 24 },
	TextSizes = { Xs = 11, Sm = 12, Md = 14, Lg = 16, Xl = 20, Xxl = 26 },
	StrokeTransparency = 0.86,
	GlassTransparency = 0.06,
	ShadowTransparency = 0.72,
}

local Themes: { [string]: Types.ThemeSpec } = {}

Themes.Dark = {
	Name = "Dark",
	Mode = "Dark",
	Colors = {
		Background = Color3.fromRGB(9, 9, 12),
		Surface = Color3.fromRGB(16, 16, 21),
		SurfaceHover = Color3.fromRGB(24, 24, 30),
		SurfaceHigh = Color3.fromRGB(30, 30, 38),
		Elevated = Color3.fromRGB(22, 22, 28),
		Overlay = Color3.fromRGB(0, 0, 0),
		Border = Color3.fromRGB(48, 48, 58),
		BorderStrong = Color3.fromRGB(70, 70, 84),
		Primary = Color3.fromRGB(94, 141, 255),
		PrimaryHover = Color3.fromRGB(122, 162, 255),
		PrimaryText = Color3.fromRGB(255, 255, 255),
		Secondary = Color3.fromRGB(34, 34, 42),
		SecondaryHover = Color3.fromRGB(44, 44, 54),
		Text = Color3.fromRGB(240, 240, 245),
		TextDim = Color3.fromRGB(190, 190, 200),
		TextMuted = Color3.fromRGB(148, 148, 160),
		TextDisabled = Color3.fromRGB(95, 95, 106),
		Success = Color3.fromRGB(74, 200, 128),
		Warning = Color3.fromRGB(240, 180, 70),
		Danger = Color3.fromRGB(240, 88, 92),
		DangerHover = Color3.fromRGB(250, 116, 120),
		Info = Color3.fromRGB(90, 170, 250),
		Accent = Color3.fromRGB(94, 141, 255),
	},
	Radius = base.Radius,
	Spacing = base.Spacing,
	Fonts = fonts(),
	TextSizes = base.TextSizes,
	StrokeTransparency = base.StrokeTransparency,
	GlassTransparency = base.GlassTransparency,
	ShadowTransparency = base.ShadowTransparency,
}

Themes.Light = {
	Name = "Light",
	Mode = "Light",
	Colors = {
		Background = Color3.fromRGB(248, 248, 250),
		Surface = Color3.fromRGB(255, 255, 255),
		SurfaceHover = Color3.fromRGB(242, 242, 246),
		SurfaceHigh = Color3.fromRGB(234, 234, 240),
		Elevated = Color3.fromRGB(255, 255, 255),
		Overlay = Color3.fromRGB(15, 15, 20),
		Border = Color3.fromRGB(222, 222, 230),
		BorderStrong = Color3.fromRGB(198, 198, 208),
		Primary = Color3.fromRGB(56, 106, 235),
		PrimaryHover = Color3.fromRGB(40, 90, 220),
		PrimaryText = Color3.fromRGB(255, 255, 255),
		Secondary = Color3.fromRGB(238, 238, 243),
		SecondaryHover = Color3.fromRGB(228, 228, 234),
		Text = Color3.fromRGB(24, 24, 30),
		TextDim = Color3.fromRGB(70, 70, 84),
		TextMuted = Color3.fromRGB(108, 108, 122),
		TextDisabled = Color3.fromRGB(168, 168, 178),
		Success = Color3.fromRGB(34, 160, 92),
		Warning = Color3.fromRGB(202, 138, 4),
		Danger = Color3.fromRGB(220, 56, 60),
		DangerHover = Color3.fromRGB(200, 40, 44),
		Info = Color3.fromRGB(40, 130, 220),
		Accent = Color3.fromRGB(56, 106, 235),
	},
	Radius = base.Radius,
	Spacing = base.Spacing,
	Fonts = fonts(),
	TextSizes = base.TextSizes,
	StrokeTransparency = 0.5,
	GlassTransparency = 0.12,
	ShadowTransparency = 0.86,
}

Themes.Amoled = {
	Name = "Amoled",
	Mode = "Dark",
	Colors = {
		Background = Color3.fromRGB(0, 0, 0),
		Surface = Color3.fromRGB(8, 8, 10),
		SurfaceHover = Color3.fromRGB(18, 18, 22),
		SurfaceHigh = Color3.fromRGB(24, 24, 30),
		Elevated = Color3.fromRGB(14, 14, 17),
		Overlay = Color3.fromRGB(0, 0, 0),
		Border = Color3.fromRGB(38, 38, 46),
		BorderStrong = Color3.fromRGB(60, 60, 72),
		Primary = Color3.fromRGB(120, 220, 170),
		PrimaryHover = Color3.fromRGB(148, 236, 192),
		PrimaryText = Color3.fromRGB(6, 20, 14),
		Secondary = Color3.fromRGB(24, 24, 30),
		SecondaryHover = Color3.fromRGB(34, 34, 42),
		Text = Color3.fromRGB(238, 238, 242),
		TextDim = Color3.fromRGB(184, 184, 194),
		TextMuted = Color3.fromRGB(138, 138, 150),
		TextDisabled = Color3.fromRGB(84, 84, 94),
		Success = Color3.fromRGB(74, 200, 128),
		Warning = Color3.fromRGB(240, 180, 70),
		Danger = Color3.fromRGB(240, 88, 92),
		DangerHover = Color3.fromRGB(250, 116, 120),
		Info = Color3.fromRGB(90, 170, 250),
		Accent = Color3.fromRGB(120, 220, 170),
	},
	Radius = base.Radius,
	Spacing = base.Spacing,
	Fonts = fonts(),
	TextSizes = base.TextSizes,
	StrokeTransparency = base.StrokeTransparency,
	GlassTransparency = 0.03,
	ShadowTransparency = 0.6,
}

Themes.Midnight = {
	Name = "Midnight",
	Mode = "Dark",
	Colors = {
		Background = Color3.fromRGB(10, 12, 20),
		Surface = Color3.fromRGB(16, 19, 31),
		SurfaceHover = Color3.fromRGB(24, 28, 44),
		SurfaceHigh = Color3.fromRGB(30, 35, 54),
		Elevated = Color3.fromRGB(21, 25, 40),
		Overlay = Color3.fromRGB(2, 3, 8),
		Border = Color3.fromRGB(44, 50, 74),
		BorderStrong = Color3.fromRGB(64, 72, 104),
		Primary = Color3.fromRGB(96, 186, 255),
		PrimaryHover = Color3.fromRGB(130, 202, 255),
		PrimaryText = Color3.fromRGB(8, 18, 28),
		Secondary = Color3.fromRGB(30, 35, 54),
		SecondaryHover = Color3.fromRGB(40, 46, 68),
		Text = Color3.fromRGB(236, 240, 250),
		TextDim = Color3.fromRGB(188, 196, 218),
		TextMuted = Color3.fromRGB(140, 150, 178),
		TextDisabled = Color3.fromRGB(92, 100, 124),
		Success = Color3.fromRGB(84, 210, 148),
		Warning = Color3.fromRGB(244, 190, 86),
		Danger = Color3.fromRGB(244, 98, 104),
		DangerHover = Color3.fromRGB(252, 126, 132),
		Info = Color3.fromRGB(96, 186, 255),
		Accent = Color3.fromRGB(96, 186, 255),
	},
	Radius = base.Radius,
	Spacing = base.Spacing,
	Fonts = fonts(),
	TextSizes = base.TextSizes,
	StrokeTransparency = base.StrokeTransparency,
	GlassTransparency = base.GlassTransparency,
	ShadowTransparency = base.ShadowTransparency,
}

return Themes
