# Components Reference

Every component takes a single props table. Most accept `Parent`, `LayoutOrder`, and `Size` where sensible. Reactive props accept Fusion `Value` objects (create them with `AetherUI.Value(...)`).

---

## Forms & Inputs

### Button

```lua
AetherUI.Button({
	Text = "Save changes",          -- string?
	Icon = "save",                  -- string? (Lucide name, left side)
	IconRight = "arrow-right",      -- string?
	Variant = "Primary",            -- "Primary" | "Secondary" | "Outline" | "Ghost" | "Destructive"
	Size = "Md",                    -- "Sm" | "Md" | "Lg"
	Disabled = false,               -- boolean | Fusion.Value<boolean>
	Loading = loadingState,         -- boolean | Fusion.Value<boolean> (shows spinner)
	FullWidth = false,
	OnClick = function() end,
	Parent = frame,
})
```

Icon-only button: pass `Icon` without `Text`.

### TextInput

```lua
local name = AetherUI.Value("")

AetherUI.TextInput({
	Value = name,                   -- Fusion.Value<string>? (controlled)
	Placeholder = "Your name...",
	Icon = "user",
	Password = false,               -- adds a show/hide eye button
	ClearButton = true,             -- shows an X when non-empty
	MaxLength = 32,
	ShowCounter = true,             -- "12/32" counter
	Validate = function(text)       -- ((string) -> (boolean, string?))?
		return #text >= 3, "Too short"
	end,
	OnChanged = function(text) end,
	OnSubmit = function(text) end,  -- Enter pressed
	Disabled = false,
	Size = "Md",                    -- "Sm" | "Md" | "Lg"
	FullWidth = true,
	Parent = frame,
})
```

### TextArea

```lua
AetherUI.TextArea({
	Value = bio,                    -- Fusion.Value<string>?
	Placeholder = "Write a bio...",
	Rows = 4,
	MaxLength = 200,
	ShowCounter = true,
	OnChanged = function(text) end,
	Parent = frame,
})
```

### Slider

```lua
-- Single value
local volume = AetherUI.Value(60)
AetherUI.Slider({
	Label = "Volume",
	Min = 0, Max = 100, Step = 1,
	Value = volume,
	ShowValue = true,
	Format = function(v) return ("%d%%"):format(v) end,
	OnChanged = function(v) end,
})

-- Range mode
local range = AetherUI.Value({ 50, 320 })
AetherUI.Slider({
	Label = "Price",
	Min = 0, Max = 500,
	RangeValue = range,             -- enables dual-thumb range mode
	Format = function(v) return ("$%d"):format(v) end,
})
```

### Dropdown

```lua
local region = AetherUI.Value("eu")

AetherUI.Dropdown({
	Items = {
		{ Label = "Europe", Value = "eu", Icon = "globe" },
		{ Label = "North America", Value = "na" },
		{ Label = "Disabled option", Value = "x", Disabled = true },
	},
	Value = region,
	Placeholder = "Select region...",
	Searchable = true,
	FullWidth = true,
	OnChanged = function(value) end,
})
```

### MultiSelect

```lua
local tags = AetherUI.Value({ "pvp" })

AetherUI.MultiSelect({
	Items = {
		{ Label = "PvP", Value = "pvp" },
		{ Label = "Roleplay", Value = "rp" },
	},
	Values = tags,                  -- Fusion.Value<{ any }>
	Placeholder = "Pick tags...",
	MaxVisibleChips = 4,            -- overflow collapses into "+N"
	OnChanged = function(values) end,
})
```

### Checkbox / Toggle

```lua
local enabled = AetherUI.Value(true)

AetherUI.Checkbox({ Label = "Notifications", Description = "Optional text", Value = enabled })
AetherUI.Toggle({ Label = "Dark mode", Value = enabled, OnChanged = function(on) end })
```

### RadioGroup

```lua
local quality = AetherUI.Value("high")

AetherUI.RadioGroup({
	Items = {
		{ Label = "Low", Value = "low" },
		{ Label = "High", Value = "high", Description = "Best visuals" },
	},
	Value = quality,
	OnChanged = function(value) end,
})
```

### ColorPicker

```lua
AetherUI.ColorPicker({
	Value = Color3.fromRGB(94, 106, 255),
	Presets = { Color3.fromRGB(94, 106, 255), Color3.fromRGB(16, 185, 129) },
	ShowHex = true,                 -- HEX input + copy button
	ShowRGB = true,                 -- R/G/B number inputs
	OnChanged = function(color) end,
})
```

### FormField / Label / HelperText

```lua
AetherUI.FormField({
	Label = "Email",
	Required = true,                -- red asterisk
	HelperText = "We never share it.",
	Error = errorState,             -- Fusion.Value<string>? — replaces helper text in red
	Content = AetherUI.TextInput({ Placeholder = "you@example.com" }),
	Parent = frame,
})

AetherUI.Label({ Text = "Standalone label" })
AetherUI.HelperText({ Text = "Muted helper copy", Variant = "default" }) -- "default" | "error" | "success"
```

### KeybindInput

```lua
AetherUI.KeybindInput({
	Keybind = { Key = Enum.KeyCode.M, Ctrl = true },
	AllowModifiers = true,
	OnChanged = function(bind)
		print(AetherUI.Keybinds.format(bind)) -- "Ctrl + M"
	end,
})
```

### DatePicker / TimePicker

```lua
AetherUI.DatePicker({
	Value = { Year = 2026, Month = 7, Day = 9 }, -- defaults to today
	OnChanged = function(date) end,
})

AetherUI.TimePicker({
	Value = { Hour = 14, Minute = 30 },          -- 24h internally
	Use24Hour = false,
	MinuteStep = 5,
	OnChanged = function(time) end,
})
```

---

## Layout & Navigation

### Window

```lua
local window = AetherUI.Window({
	Title = "My App",
	Subtitle = "v1.0",
	Icon = "sparkles",
	Size = UDim2.fromOffset(720, 480),
	MinSize = Vector2.new(420, 300),
	ToggleKey = Enum.KeyCode.RightShift,
	Resizable = true,
	OnClose = function() end,
})

window.Content   -- Frame: parent your UI here
window.Toggle()  -- show/hide
window.Show() / window.Hide() / window.Close()
```

### Tabs

```lua
AetherUI.Tabs({
	Variant = "underline",           -- "underline" | "pill" | "vertical"
	Default = "home",
	Tabs = {
		{ Id = "home", Label = "Home", Icon = "home", Content = function()
			return someFrame
		end },
		{ Id = "settings", Label = "Settings", Icon = "settings", Disabled = false },
	},
	OnChanged = function(id) end,
	Parent = frame,
})
```

### Card / Section

```lua
AetherUI.Card({
	Title = "Server Status",
	Description = "Updated 2 minutes ago",
	Icon = "activity",
	Glass = true,                    -- glassmorphic background
	Children = { AetherUI.Badge({ Text = "Online", Variant = "Success" }) },
	Parent = frame,
})

AetherUI.Section({ Title = "General", Children = { ... }, Parent = frame })
```

### Accordion

```lua
AetherUI.Accordion({
	Items = {
		{
			Id = "faq-1",
			Title = "What is AetherUI?",
			Icon = "circle-help",
			DefaultOpen = true,
			Content = function()
				return AetherUI.HelperText({ Text = "A premium UI library." })
			end,
		},
	},
	Multiple = false,                -- allow multiple open at once
	Parent = frame,
})
```

### Sidebar

```lua
local sidebar = AetherUI.Sidebar({
	Title = "Aether",
	Collapsible = true,
	Default = "home",
	Items = {
		{ Id = "home", Label = "Home", Icon = "home" },
		{ Id = "mail", Label = "Inbox", Icon = "mail", Badge = "3" },
		{ Id = "settings", Label = "Settings", Icon = "settings", Section = "System" },
	},
	OnChanged = function(id) end,
	Parent = window.Content,
})

sidebar.SetActive("settings")
sidebar.Toggle() -- collapse/expand
```

### Breadcrumbs / Separator / ScrollFrame

```lua
AetherUI.Breadcrumbs({
	Items = {
		{ Label = "Home", Icon = "home", OnClick = function() end },
		{ Label = "Players" },
	},
})

AetherUI.Separator({ Label = "Optional label", Vertical = false })

AetherUI.ScrollFrame({
	Size = UDim2.new(1, 0, 1, 0),
	Padding = 16,                    -- inner padding
	ListPadding = 12,                -- gap between children
	Horizontal = false,
	Children = { ... },
})
```

### Stepper

```lua
AetherUI.Stepper({
	Steps = {
		{ Title = "Account", Icon = "user", Content = function() return frame1 end },
		{ Title = "Done", Icon = "check" },
	},
	Step = stepValue,                -- Fusion.Value<number>? (external control)
	OnStepChanged = function(step) end,
	OnFinish = function() end,
})
```

---

## Overlays & Feedback

### Modal

```lua
local modal = AetherUI.Modal({
	Title = "Confirm action",
	Description = "This cannot be undone.",
	Icon = "triangle-alert",
	Variant = "danger",              -- "default" | "danger" | "success"
	Draggable = true,
	CloseOnBackdrop = true,          -- also closes on ESC
	BlurBackground = true,
	Content = function()             -- optional custom body
		return customFrame
	end,
	Actions = {
		{ Label = "Cancel", Variant = "Ghost", CloseOnClick = true },
		{ Label = "Delete", Variant = "Destructive", CloseOnClick = true, OnClick = function() end },
	},
	OnClose = function() end,
})

modal.Close()
```

### Toast

```lua
AetherUI.Toast.Success("Saved!")
AetherUI.Toast.Info("Heads up", { Description = "Something happened." })
AetherUI.Toast.Warning({ Title = "Low disk space", Duration = 6 })
AetherUI.Toast.Error("Failed", {
	Description = "Connection lost.",
	Action = { Label = "Retry", OnClick = function() end },
	Position = "bottom-right",       -- "bottom-right" | "top-right" | "bottom-left" | "top-left"
})
```

### Tooltip

```lua
local detach = AetherUI.Tooltip.Attach(button, {
	Title = "Optional title",
	Text = "Explains what this does.",
	Shortcut = "Ctrl+S",
	Delay = 0.45,
	MaxWidth = 240,
})

detach() -- remove the tooltip
```

### ContextMenu

```lua
local detach = AetherUI.ContextMenu.Attach(target, {
	{ Label = "Copy", Icon = "copy", Shortcut = "Ctrl+C", OnClick = function() end },
	{ Separator = true },
	{ Label = "Nested", Icon = "chevron-right", Items = { { Label = "Child" } } },
	{ Label = "Delete", Icon = "trash-2", Destructive = true },
})
```

### CommandPalette

```lua
local palette = AetherUI.CommandPalette({
	Hotkey = Enum.KeyCode.K,         -- Ctrl+K; pass false to disable
	Commands = {
		{ Id = "dark", Label = "Theme: Dark", Icon = "moon", Group = "Appearance",
			Run = function() AetherUI.Theme.Apply("Dark") end },
	},
})

palette.Open() / palette.Close() / palette.Destroy()
```

---

## Data Display

### DataTable

```lua
AetherUI.DataTable({
	Columns = {
		{ Key = "name", Label = "Player", Sortable = true },
		{ Key = "score", Label = "Score", Sortable = true, Width = 90,
			Format = function(v) return ("%,d"):format(v) end },
	},
	Rows = rows,                     -- array or Fusion.Value (live updates)
	PageSize = 10,
	Searchable = true,
	Actions = {
		{ Icon = "pencil", Tooltip = "Edit", OnClick = function(row) end },
	},
	OnRowClick = function(row) end,
	Parent = frame,
})
```

### TreeView

```lua
AetherUI.TreeView({
	Nodes = {
		{ Id = "src", Label = "src", Icon = "folder", Children = {
			{ Id = "init", Label = "Init.lua", Icon = "file" },
		} },
	},
	DefaultExpanded = { "src" },
	OnSelect = function(node) end,
})
```

### Progress

```lua
AetherUI.ProgressBar({ Value = 0.72, ShowLabel = true })        -- Value = nil → indeterminate
AetherUI.CircularProgress({ Value = 0.45, Diameter = 64, ShowLabel = true })
AetherUI.CircularProgress({ Diameter = 32 })                    -- spinner
```

### Badge / Avatar / StatusIndicator

```lua
AetherUI.Badge({ Text = "New", Variant = "Primary", Dot = false })
-- Variants: Default | Primary | Success | Warning | Danger | Info | Outline

AetherUI.Avatar({ Name = "builderman", Size = 48, Status = "Online", Ring = true })
AetherUI.Avatar({ Image = "rbxassetid://...", Size = 32 })

AetherUI.StatusIndicator({ Status = "Busy", Label = "In a match", Pulse = true })
-- Statuses: Online | Idle | Busy | Offline
```

### Skeleton / EmptyState

```lua
AetherUI.Skeleton({ Lines = 3 })                 -- shimmering placeholder lines
AetherUI.Skeleton({ Size = UDim2.fromOffset(200, 120) })

AetherUI.EmptyState({
	Icon = "inbox",
	Title = "No messages",
	Description = "New messages appear here.",
	ActionText = "Refresh",
	OnAction = function() end,
})
```
