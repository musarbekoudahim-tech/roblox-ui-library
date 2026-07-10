# Getting Started

AetherUI is a **standalone runtime library** — it never touches ReplicatedStorage, StarterPlayerScripts, or any local game project folders. The UI container is parented to `game:GetService("CoreGui")` (preferring the executor's hidden UI via `gethui()` when available), so the interface persists across character respawns and is fully independent of the local player's state.

## Requirements

- A runtime environment with `loadstring` and `game:HttpGet` support
- Nothing else — [Fusion 0.2](https://elttob.uk/Fusion/) is vendored inside the bundle

## Installation

### loadstring (recommended)

The single-file bundle at `dist/AetherUI.lua` returns the full library table at the very end, so it initializes directly when called dynamically:

```lua
local AetherUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/musarbekoudahim-tech/roblox-ui-library/main/AetherUI/dist/AetherUI.lua"))()
```

### Building from source

If you change anything under `src/`, regenerate the bundle with Node.js:

```bash
node scripts/bundle.mjs   # -> dist/AetherUI.lua
```

The bundler merges `src/` and `vendor/Fusion` into one script, rewriting all `require(script.Parent...)` instance paths into an internal module registry. Host the output anywhere raw (GitHub, gist, your own server) and point the loadstring URL at it.

## Your first window

```lua
local AetherUI = loadstring(game:HttpGet("URL"))()

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
