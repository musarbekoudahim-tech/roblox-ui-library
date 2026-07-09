# Theming

AetherUI's theme system is a set of reactive design tokens. Every token is a Fusion `Value`, and every component reads tokens reactively — so switching themes live-updates the entire UI instantly, no re-mounting.

## Built-in themes

| Theme | Description |
|---|---|
| `Dark` | The default. Deep neutral surfaces, blue primary, soft shadows |
| `Light` | Clean white surfaces, high-contrast text |
| `Amoled` | True-black backgrounds with a mint primary, ideal for OLED |
| `Aurora` | Cool navy surfaces with a cyan primary |

```lua
AetherUI.Theme.Apply("Aurora")
```

## Token reference

### Color tokens

| Token | Purpose |
|---|---|
| `Background` | App / window background |
| `Surface` | Cards, panels, inputs |
| `SurfaceHover` | Hover state for surfaces |
| `Elevated` | Popovers, dropdown menus, tooltips |
| `Overlay` | Modal backdrop tint |
| `Border` / `BorderStrong` | Default and emphasized borders |
| `Primary` / `PrimaryHover` / `PrimaryText` | Brand color, its hover state, and text drawn on it |
| `Secondary` / `SecondaryHover` | Secondary button and control surfaces |
| `Text` / `TextMuted` / `TextDisabled` | Text hierarchy |
| `Success` / `Warning` / `Info` | Semantic colors |
| `Danger` / `DangerHover` | Destructive actions |
| `Accent` | Decorative accent (defaults to `Primary`) |

### Non-color tokens

- `Radius` — `Sm`, `Md`, `Lg`, `Xl`, `Full` corner radii
- `Spacing` — `Xs` through `Xl` spacing scale
- `TextSizes` — `Xs` through `Xl` font sizes
- `Fonts` — `Body`, `Heading`, `Mono` font families
- `StrokeTransparency`, `GlassTransparency`, `ShadowTransparency` — depth and glassmorphism intensity
- `Mode` — `"Dark"` or `"Light"`, used by components for contrast decisions

## Custom themes

`Theme.Register(name, overrides, base?)` deep-merges your overrides on top of a base theme (default `"Dark"`):

```lua
AetherUI.Theme.Register("Crimson", {
	Colors = {
		Primary = Color3.fromRGB(225, 29, 72),
		PrimaryHover = Color3.fromRGB(244, 63, 94),
	},
	Radius = { Md = 6 }, -- sharper corners
}, "Dark")

AetherUI.Theme.Apply("Crimson")
```

You can also mutate a single token at runtime without registering a theme:

```lua
AetherUI.Theme.SetColor("Primary", Color3.fromRGB(56, 189, 248))
```

## Reading tokens in your own components

Tokens live in `Theme.Colors`, `Theme.Radius`, and `Theme.Fonts` as Fusion `Value`s:

```lua
local Theme = AetherUI.Theme
local Fusion = AetherUI.Fusion

local myFrame = Fusion.New("Frame")({
	-- Reactive: updates automatically on theme switch
	BackgroundColor3 = Theme.Colors.Surface,
})
```

For one-off, non-reactive reads use `Theme.GetSpec()`, which returns the full current theme spec.

## Saving and loading

`Theme.Save()` serializes all custom (non-builtin) themes plus the active theme name to a JSON string — safe to store in a DataStore:

```lua
local json = AetherUI.Theme.Save()
-- store `json`...

-- Later / on another session:
AetherUI.Theme.Load(json) -- re-registers custom themes and re-applies the active one
```

## Listening for changes

```lua
AetherUI.Theme.Changed:Connect(function(themeName: string)
	print("Theme is now", themeName)
end)
```
