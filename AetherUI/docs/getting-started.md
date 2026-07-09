# Getting Started

## Requirements

- Roblox Studio (any recent version)
- [Fusion 0.2+](https://elttob.uk/Fusion/) — placed in `ReplicatedStorage` as a sibling of AetherUI, or installed via Wally

## Installation

### Manual

1. Copy the `src` folder into `ReplicatedStorage`
2. Rename it to `AetherUI`
3. Place Fusion next to it (`ReplicatedStorage.Fusion`)

### Wally + Rojo

```toml
# wally.toml
[dependencies]
AetherUI = "your-name/aetherui@1.0.0"
```

```bash
wally install
rojo serve
```

## Your first window

```lua
-- StarterPlayerScripts/Main.client.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AetherUI = require(ReplicatedStorage.AetherUI.Init)

AetherUI.Theme.Apply("Dark")

local window = AetherUI.Window({
	Title = "Hello, Aether",
	Icon = "sparkles",
	Size = UDim2.fromOffset(640, 420),
})

AetherUI.Button({
	Text = "Say hi",
	Variant = "Primary",
	OnClick = function()
		AetherUI.Toast.Success("Hi there!")
	end,
	Parent = window.Content,
})
```

## Core concepts

### Props tables

Every component takes a single props table and returns the root Instance (or a controller table for stateful components like `Window` and `Tabs`):

```lua
local button = AetherUI.Button({ Text = "OK", Parent = frame })
```

### Parenting

Pass `Parent` in props, or parent the returned instance yourself:

```lua
local input = AetherUI.TextInput({ Placeholder = "Name" })
input.Parent = myFrame
```

### Reactive values

Because AetherUI is built on Fusion, many props accept either a static value or a Fusion `Value`/`Computed` for reactivity:

```lua
local Fusion = AetherUI.Fusion
local loading = Fusion.Value(false)

AetherUI.Button({
	Text = "Save",
	Loading = loading, -- reactive!
	OnClick = function()
		loading:set(true)
		task.wait(1)
		loading:set(false)
	end,
})
```

### Cleanup

Destroy the root instance to clean up a component — all connections are released automatically. For a full teardown of global systems (overlays, sounds, keybinds):

```lua
AetherUI.Destroy()
```

## Next steps

- [Theming guide](theming.md)
- [Components reference](components.md)
- [Keybinds guide](keybinds.md)
- Run `examples/Showcase.lua` for a live tour
