# Keybinds Guide

AetherUI ships a global keybind manager plus a `KeybindInput` component for user-facing rebinding.

## Registering global hotkeys

```lua
AetherUI.Keybinds.Register("open-menu", {
	Key = Enum.KeyCode.M,
	Modifiers = { "Ctrl" },          -- "Ctrl" | "Shift" | "Alt" (any combination)
	Callback = function()
		menu.Toggle()
	end,
})
```

- IDs are unique — registering with an existing ID replaces the old bind.
- Binds are ignored while the player is typing in a TextBox (gameProcessed input is skipped).

## Managing binds

```lua
local handle = AetherUI.Keybinds.Register("open-menu", { ... })

handle:SetEnabled(false)                              -- temporarily disable one bind
AetherUI.Keybinds.Rebind("open-menu", Enum.KeyCode.N) -- change the key in place
AetherUI.Keybinds.Unregister("open-menu")             -- remove
AetherUI.Keybinds.SetEnabled(false)                   -- master switch (all binds)
```

## Formatting for display

```lua
AetherUI.Keybinds.Format(Enum.KeyCode.K, { "Ctrl" })            -- "Ctrl + K"
AetherUI.Keybinds.format({ Key = Enum.KeyCode.S, Ctrl = true }) -- "Ctrl + S" (Bind table form)
```

## Rebinding UI

`KeybindInput` renders a button showing the current bind. Clicking it enters listening mode — the next key (plus held modifiers) becomes the new bind. ESC cancels.

```lua
AetherUI.FormField({
	Label = "Toggle inventory",
	Content = AetherUI.KeybindInput({
		Keybind = { Key = Enum.KeyCode.Tab },
		AllowModifiers = true,
		OnChanged = function(bind)
			AetherUI.Keybinds.Rebind("toggle-inventory", bind.Key)
		end,
	}),
	Parent = settingsPage,
})
```

## Built-in bindings

Several components register their own keys automatically and clean them up on destroy:

| Component | Key | Action |
|---|---|---|
| `Modal` | ESC | Close (when `CloseOnBackdrop` is enabled) |
| `CommandPalette` | Ctrl+K (configurable) | Toggle palette; Up/Down/Enter navigate |
| `Window` | `ToggleKey` prop | Show/hide window |
| `ContextMenu` | ESC | Close active menu |

## Persisting user binds

Serialize binds yourself (e.g. into a DataStore) and re-register on join:

```lua
-- Save
local saved = { Key = bind.Key.Name, Ctrl = bind.Ctrl == true }

-- Load
AetherUI.Keybinds.Register("toggle-inventory", {
	Key = Enum.KeyCode[saved.Key],
	Modifiers = saved.Ctrl and { "Ctrl" } or nil,
	Callback = toggleInventory,
})
```
