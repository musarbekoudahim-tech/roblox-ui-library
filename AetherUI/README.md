<div align="center">

# AetherUI

**A premium, production-grade UI library for Roblox.**

Built on [Fusion](https://elttob.uk/Fusion/) · Cinematic animations · Glassmorphism · Full theming · Lucide icons

[Features](#features) · [Installation](#installation) · [Quick Start](#quick-start) · [Components](#components) · [Theming](#theming) · [Keybinds](#keybinds) · [Contributing](#contributing)

![Preview](docs/assets/hero-preview.png)
*Placeholder — add a hero screenshot or GIF of the Showcase here.*

</div>

---

## Features

- **35+ polished components** — from buttons to data tables, color pickers to command palettes
- **Design-system quality** — inspired by Linear, Vercel, Arc and Figma; consistent radii, spacing, typography and depth across every component
- **Powerful theming** — Dark, Light, Amoled and Aurora built in, unlimited custom themes, live switching, save/load support
- **Lucide icons** — a curated, cached icon set with a one-line API
- **Advanced animation system** — tween presets, spring-like easings, staggered entrances, micro-interactions on every hover and press
- **Global + component keybinds** — register hotkeys anywhere, rebind them at runtime with `KeybindInput`
- **Sound feedback** — optional, subtle hover/click/success/error sounds
- **Accessibility-aware** — reduced-motion support, focus-visible states, readable contrast in every theme
- **Responsive scaling** — adapts to screen size with a single scale token
- **Strictly typed Luau** — `--!strict` everywhere, exported types for every component's props
- **Clean memory management** — Maid-based cleanup, no leaked connections

## Installation

### Wally (recommended)

```toml
[dependencies]
AetherUI = "your-name/aetherui@1.0.0"
```

```bash
wally install
```

### GitHub

1. Download or clone this repository
2. Place the `src` folder in `ReplicatedStorage` and rename it `AetherUI`
3. Require it from a LocalScript:

```lua
local AetherUI = require(game.ReplicatedStorage.AetherUI.Init)
```

### Rojo

Point your `default.project.json` at `src/`:

```json
{
  "ReplicatedStorage": {
    "AetherUI": { "$path": "src" }
  }
}
```

> **Dependency:** AetherUI requires [Fusion 0.2+](https://elttob.uk/Fusion/). Place it as a sibling of AetherUI in ReplicatedStorage, or install it via Wally — the internal resolver finds it automatically.

## Quick Start

```lua
local AetherUI = require(game.ReplicatedStorage.AetherUI.Init)

-- Apply a theme
AetherUI.Theme.Apply("Dark")

-- Create a window
local window = AetherUI.Window({
	Title = "My App",
	Icon = "sparkles",
	Size = UDim2.fromOffset(720, 480),
	Draggable = true,
})

-- Add components
AetherUI.Button({
	Text = "Click me",
	Variant = "Primary",
	Icon = "zap",
	OnClick = function()
		AetherUI.Toast.Success("It works!", { Description = "Welcome to AetherUI." })
	end,
	Parent = window.Content,
})
```

Run `examples/Showcase.lua` for a complete tour of every component.

## Components

### Forms & Inputs

| Component | Highlights |
|---|---|
| `Button` | Primary / Secondary / Outline / Ghost / Destructive / Icon variants, loading spinner, disabled state |
| `TextInput` | Icons, clear button, password mode, validation, character counter |
| `TextArea` | Multi-line, auto-size, counter |
| `Slider` | Single + range mode, step, prefix/suffix formatting, live tooltip |
| `Dropdown` | Search, icons, smooth open animation |
| `MultiSelect` | Chips/tags, max-chip overflow, search |
| `Checkbox` / `RadioGroup` / `Toggle` | Springy micro-interactions, descriptions |
| `ColorPicker` | HSV area + hue/alpha rails, RGB + HEX inputs, presets, copy button |
| `FormField` | Label + helper text + error wrapper for any input |
| `KeybindInput` | Live key rebinding with modifier support |
| `DatePicker` / `TimePicker` | Calendar grid, 12/24-hour time |

### Layout & Navigation

| Component | Highlights |
|---|---|
| `Window` | Draggable, resizable, glassmorphic chrome, minimize/close |
| `Tabs` | Underline / Pill / Vertical variants with animated indicator |
| `Card` | Header, icon, subtitle, hoverable variant |
| `Accordion` | Smooth height animation, single or multiple open |
| `Sidebar` | Collapsible, icons, badges, active indicator |
| `Breadcrumbs` | Icons, clickable trail |
| `ScrollFrame` | Slim auto-hiding custom scrollbar |
| `Separator` | Horizontal/vertical, optional label |
| `Stepper` | Wizard progress with completed/current/pending states |

### Overlays & Feedback

| Component | Highlights |
|---|---|
| `Modal` | Backdrop blur, ESC to close, Default/Destructive variants, custom content |
| `Toast` | Stacking, Success/Error/Warning/Info, actions, auto-dismiss with progress |
| `Tooltip` | Rich content, shortcut hints, configurable delay |
| `ContextMenu` | Icons, shortcuts, separators, destructive items |
| `CommandPalette` | Fuzzy search, groups, hotkey binding (Ctrl+K style) |

### Data Display

| Component | Highlights |
|---|---|
| `DataTable` | Sorting, filtering, pagination, per-row actions |
| `TreeView` | Nested nodes, animated expand/collapse |
| `ProgressBar` / `CircularProgress` | Determinate + indeterminate, labels |
| `Badge` / `Avatar` / `StatusIndicator` | Variants, status dots with pulse |
| `Skeleton` | Shimmering loading placeholders |
| `EmptyState` | Icon + title + description + action |

### Example: FormField + validation

```lua
AetherUI.FormField({
	Label = "Email",
	HelperText = "We never share your email.",
	Required = true,
	Input = AetherUI.TextInput({
		Placeholder = "you@example.com",
		Icon = "mail",
		Validate = function(text)
			if not text:match("^[%w.]+@[%w.]+%.%w+$") then
				return false, "Invalid email address"
			end
			return true
		end,
	}),
	Parent = page,
})
```

### Example: DataTable

```lua
AetherUI.DataTable({
	Columns = {
		{ Key = "name", Label = "Name", Sortable = true },
		{ Key = "score", Label = "Score", Sortable = true, Align = "Right" },
	},
	Rows = playerData,
	PageSize = 10,
	Searchable = true,
	Parent = page,
})
```

## Theming

Four themes ship out of the box: **Dark**, **Light**, **Amoled**, and **Aurora**.

```lua
-- Live switch at any time — every mounted component updates instantly
AetherUI.Theme.Apply("Light")
```

### Custom themes

```lua
-- Overrides are deep-merged on top of a base theme (default "Dark")
AetherUI.Theme.Register("Midnight", {
	Colors = {
		Primary = Color3.fromRGB(56, 189, 248),
		Background = Color3.fromRGB(8, 10, 18),
		Surface = Color3.fromRGB(14, 17, 28),
	},
	Radius = { Md = 10, Lg = 16 },
}, "Dark")

AetherUI.Theme.Apply("Midnight")

-- Or tweak a single token at runtime:
AetherUI.Theme.SetColor("Primary", Color3.fromRGB(225, 29, 72))
```

### Tokens

Every theme controls: `Colors` (background, surfaces, primary/secondary, text hierarchy, borders, semantic colors), `Radius`, `Spacing`, `TextSizes`, `Fonts` (Body / Heading / Mono), and depth tokens (`StrokeTransparency`, `GlassTransparency`, `ShadowTransparency`). See [docs/theming.md](docs/theming.md) for the full reference.

### Saving / loading

```lua
local json = AetherUI.Theme.Save()   -- serializes custom themes + active theme to JSON
-- store `json` in a DataStore...
AetherUI.Theme.Load(json)            -- restores and re-applies on the next session
```

## Keybinds

```lua
-- Global hotkey
AetherUI.Keybinds.Register("open-menu", {
	Key = Enum.KeyCode.M,
	Modifiers = { "Ctrl" },
	Callback = function() menu:Toggle() end,
})

-- Rebindable in UI
AetherUI.KeybindInput({
	Label = "Open menu",
	Default = Enum.KeyCode.M,
	OnChange = function(bind) print("Rebound to", bind.Key.Name) end,
	Parent = settingsPage,
})

-- Cleanup
AetherUI.Keybinds.Unregister("open-menu")
```

## Icons

AetherUI bundles a curated [Lucide](https://lucide.dev/) icon set:

```lua
local icon = AetherUI.Icons.Get("settings")   -- cached { Image, RectOffset, RectSize }
print(AetherUI.Icons.List())                  -- all available icon names

-- Register your own icons or aliases:
AetherUI.Icons.Register("my-logo", { Image = "rbxassetid://123456" })
AetherUI.Icons.Alias("gear", "settings")
```

Every component that takes an `Icon` prop accepts an icon name string (e.g. `Icon = "zap"`).

## Sounds

```lua
AetherUI.Sound.SetEnabled(true)        -- master switch (off by default)
AetherUI.Sound.SetMasterVolume(0.4)
AetherUI.Sound.Play("Click")           -- Hover | Click | Success | Error | Toggle | Open | Close
```

## Project Structure

```
AetherUI/
├── src/
│   ├── Core/         # Theme, Icons, Keybinds, Animation, Sound, Overlay, ...
│   ├── Components/   # All 35+ components
│   ├── Hooks/        # UseHover, UsePress, UseDrag
│   ├── Types/        # Shared type definitions
│   └── Init.lua      # Public API entry point
├── examples/
│   └── Showcase.lua  # Full component tour
├── docs/             # Extended documentation
├── README.md
├── LICENSE
└── wally.toml
```

## Contributing

Contributions are welcome!

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-component`)
3. Follow the existing conventions: `--!strict`, exported prop types, theme tokens only (no hardcoded colors), Maid-based cleanup
4. Open a pull request with screenshots/GIFs of visual changes

Bug reports and component requests are equally appreciated — open an issue.

## Credits

- **[Lucide Icons](https://lucide.dev/)** — the beautiful open-source icon set that powers AetherUI's iconography (ISC License)
- **[Fusion](https://elttob.uk/Fusion/)** by Elttob — the reactive UI framework AetherUI is built on
- Design inspiration: Linear, Vercel, Arc, Figma, Apple HIG

## License

MIT © AetherUI contributors — see [LICENSE](LICENSE).
