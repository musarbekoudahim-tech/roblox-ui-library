--!strict
--[[
	AetherUI — Showcase
	===================
	A complete tour of every AetherUI component, wired into a single window
	with a sidebar. Drop this in a LocalScript under StarterPlayerScripts
	(with AetherUI placed in ReplicatedStorage) and hit Play.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AetherUI = require(ReplicatedStorage:WaitForChild("AetherUI"):WaitForChild("Init"))

-- 1. Theme + global systems ---------------------------------------------------

AetherUI.Theme.Apply("Dark") -- "Dark" | "Light" | "Amoled" | "Aurora"
AetherUI.Sound.SetEnabled(true)

-- Global keybinds
AetherUI.Keybinds.Register("toggle-ui", {
	Key = Enum.KeyCode.RightShift,
	Callback = function()
		print("[Showcase] Toggle UI")
	end,
})

-- 2. Window -------------------------------------------------------------------

local window = AetherUI.Window({
	Title = "AetherUI Showcase",
	Subtitle = "v" .. AetherUI.Version,
	Icon = "sparkles",
	Size = UDim2.fromOffset(860, 560),
	Draggable = true,
	Resizable = true,
})

-- 3. Sidebar navigation ---------------------------------------------------------

local pages = {} :: { [string]: Frame }

local function makePage(name: string): Frame
	local page = AetherUI.ScrollFrame({
		Size = UDim2.new(1, 0, 1, 0),
		Padding = 20,
		Gap = 14,
		Visible = false,
		Parent = window.Content,
	})
	pages[name] = page
	return page
end

local sidebar = AetherUI.Sidebar({
	Title = "Aether",
	Collapsible = true,
	Default = "inputs",
	Items = {
		{ Id = "inputs", Label = "Inputs", Icon = "text-cursor-input" },
		{ Id = "selection", Label = "Selection", Icon = "list-checks" },
		{ Id = "display", Label = "Display", Icon = "layout-dashboard" },
		{ Id = "overlays", Label = "Overlays", Icon = "app-window" },
		{ Id = "data", Label = "Data", Icon = "table" },
	},
	OnChanged = function(id: string)
		for name, page in pages do
			page.Visible = (name == id)
		end
	end,
	Parent = window.Content,
})

-- 4. Inputs page -----------------------------------------------------------------

local inputsPage = makePage("inputs")
inputsPage.Visible = true

AetherUI.FormField({
	Label = "Username",
	HelperText = "3-16 characters, letters and numbers only.",
	Required = true,
	Input = AetherUI.TextInput({
		Placeholder = "Enter username...",
		Icon = "user",
		Clearable = true,
		MaxLength = 16,
		ShowCounter = true,
		Validate = function(text: string): (boolean, string?)
			if #text < 3 then
				return false, "Too short"
			end
			return true
		end,
	}),
	Parent = inputsPage,
})

AetherUI.FormField({
	Label = "Password",
	Input = AetherUI.TextInput({
		Placeholder = "Enter password...",
		Icon = "lock",
		Password = true,
	}),
	Parent = inputsPage,
})

AetherUI.TextArea({
	Placeholder = "Write a bio...",
	MaxLength = 200,
	ShowCounter = true,
	Rows = 4,
	Parent = inputsPage,
})

AetherUI.Slider({
	Label = "Volume",
	Min = 0,
	Max = 100,
	Step = 1,
	Value = 60,
	Suffix = "%",
	ShowTooltip = true,
	OnChange = function(v: number)
		print("[Showcase] Volume:", v)
	end,
	Parent = inputsPage,
})

AetherUI.Slider({
	Label = "Price range",
	Range = true,
	Min = 0,
	Max = 500,
	Value = { 50, 320 },
	Prefix = "$",
	Parent = inputsPage,
})

AetherUI.ColorPicker({
	Label = "Accent color",
	Value = Color3.fromRGB(94, 106, 255),
	Presets = {
		Color3.fromRGB(94, 106, 255),
		Color3.fromRGB(16, 185, 129),
		Color3.fromRGB(244, 63, 94),
		Color3.fromRGB(245, 158, 11),
	},
	OnChange = function(color: Color3)
		print("[Showcase] Color:", color)
	end,
	Parent = inputsPage,
})

AetherUI.KeybindInput({
	Label = "Open menu",
	Default = Enum.KeyCode.M,
	OnChange = function(bind)
		print("[Showcase] Rebound to", bind.Key.Name)
	end,
	Parent = inputsPage,
})

-- 5. Selection page ------------------------------------------------------------

local selectionPage = makePage("selection")

AetherUI.Dropdown({
	Label = "Region",
	Options = { "North America", "Europe", "Asia Pacific", "South America" },
	Value = "Europe",
	Searchable = true,
	Parent = selectionPage,
})

AetherUI.MultiSelect({
	Label = "Tags",
	Options = { "PvP", "Roleplay", "Simulator", "Obby", "Tycoon", "Horror" },
	Value = { "PvP", "Simulator" },
	MaxChips = 4,
	Parent = selectionPage,
})

AetherUI.Checkbox({
	Label = "Enable notifications",
	Checked = true,
	Parent = selectionPage,
})

AetherUI.Toggle({
	Label = "Dark mode",
	Description = "Switch between light and dark themes.",
	On = true,
	OnChange = function(on: boolean)
		AetherUI.Theme.Apply(if on then "Dark" else "Light")
	end,
	Parent = selectionPage,
})

AetherUI.RadioGroup({
	Label = "Quality",
	Options = { "Low", "Medium", "High", "Ultra" },
	Value = "High",
	Parent = selectionPage,
})

AetherUI.DatePicker({
	Label = "Event date",
	Parent = selectionPage,
})

AetherUI.TimePicker({
	Label = "Start time",
	Use24Hour = false,
	Parent = selectionPage,
})

-- 6. Display page ------------------------------------------------------------------

local displayPage = makePage("display")

local card = AetherUI.Card({
	Title = "Server Status",
	Subtitle = "Updated 2 minutes ago",
	Icon = "activity",
	Parent = displayPage,
})

AetherUI.Badge({ Text = "Online", Variant = "Success", Dot = true, Parent = card.Content })
AetherUI.Badge({ Text = "v2.4.1", Variant = "Outline", Parent = card.Content })
AetherUI.ProgressBar({ Value = 0.72, Label = "CPU", ShowPercent = true, Parent = card.Content })
AetherUI.CircularProgress({ Value = 0.45, Size = 64, Label = "Memory", Parent = card.Content })

AetherUI.Avatar({
	UserId = 1,
	Size = 48,
	Status = "Online",
	Parent = displayPage,
})

AetherUI.Separator({ Label = "Details", Parent = displayPage })

AetherUI.Accordion({
	Items = {
		{ Title = "What is AetherUI?", Body = "A premium Fusion-based UI library for Roblox." },
		{ Title = "Is it free?", Body = "Yes - MIT licensed, forever." },
		{ Title = "Does it support themes?", Body = "Dark, Light, Amoled, Aurora and unlimited custom themes." },
	},
	Multiple = false,
	Parent = displayPage,
})

AetherUI.Tabs({
	Variant = "Pill",
	Tabs = {
		{ Id = "overview", Label = "Overview", Icon = "home" },
		{ Id = "stats", Label = "Stats", Icon = "bar-chart" },
		{ Id = "settings", Label = "Settings", Icon = "settings" },
	},
	Parent = displayPage,
})

AetherUI.Stepper({
	Steps = { "Account", "Profile", "Preferences", "Done" },
	Current = 2,
	Parent = displayPage,
})

AetherUI.Skeleton({ Lines = 3, Avatar = true, Parent = displayPage })

AetherUI.EmptyState({
	Icon = "inbox",
	Title = "No messages",
	Description = "When you receive messages, they will appear here.",
	ActionText = "Refresh",
	OnAction = function()
		AetherUI.Toast.Info("Refreshing...", { Description = "Checking for new messages." })
	end,
	Parent = displayPage,
})

-- 7. Overlays page -----------------------------------------------------------------

local overlaysPage = makePage("overlays")

AetherUI.Button({
	Text = "Open Modal",
	Icon = "app-window",
	Variant = "Primary",
	OnClick = function()
		AetherUI.Modal({
			Title = "Confirm action",
			Description = "Are you sure you want to reset all settings? This cannot be undone.",
			Variant = "Destructive",
			ConfirmText = "Reset",
			CancelText = "Cancel",
			OnConfirm = function()
				AetherUI.Toast.Success("Settings reset", { Description = "All settings restored to defaults." })
			end,
		})
	end,
	Parent = overlaysPage,
})

AetherUI.Button({
	Text = "Show Toasts",
	Icon = "bell",
	Variant = "Secondary",
	OnClick = function()
		AetherUI.Toast.Success("Saved successfully")
		task.wait(0.25)
		AetherUI.Toast.Warning("Low disk space", { Description = "Only 2 GB remaining." })
		task.wait(0.25)
		AetherUI.Toast.Error("Connection lost", {
			Description = "Retrying in 5 seconds...",
			Action = { Text = "Retry now", OnClick = function() print("retry") end },
		})
	end,
	Parent = overlaysPage,
})

local tooltipTarget = AetherUI.Button({
	Text = "Hover me",
	Variant = "Outline",
	Parent = overlaysPage,
})
AetherUI.Tooltip.Attach(tooltipTarget, {
	Text = "Rich tooltips with delay",
	Shortcut = "Ctrl+H",
	Delay = 0.4,
})

local contextTarget = AetherUI.Button({
	Text = "Right-click me",
	Variant = "Ghost",
	Parent = overlaysPage,
})
AetherUI.ContextMenu.Attach(contextTarget, {
	Items = {
		{ Label = "Copy", Icon = "copy", Shortcut = "Ctrl+C" },
		{ Label = "Paste", Icon = "clipboard", Shortcut = "Ctrl+V" },
		{ Kind = "Separator" },
		{ Label = "Delete", Icon = "trash-2", Destructive = true },
	},
})

-- Command palette: fuzzy search across registered commands, Ctrl+K to toggle.
local palette = AetherUI.CommandPalette({
	Hotkey = Enum.KeyCode.K, -- Ctrl+K (default)
	Commands = {
		{ Id = "theme-dark", Label = "Theme: Dark", Icon = "moon", Group = "Appearance", Run = function()
			AetherUI.Theme.Apply("Dark")
		end },
		{ Id = "theme-light", Label = "Theme: Light", Icon = "sun", Group = "Appearance", Run = function()
			AetherUI.Theme.Apply("Light")
		end },
		{ Id = "toast-hello", Label = "Say hello", Icon = "hand", Group = "Fun", Run = function()
			AetherUI.Toast.Info("Hello from the palette!")
		end },
	},
})

AetherUI.Button({
	Text = "Command Palette (Ctrl+K)",
	Icon = "command",
	Variant = "Outline",
	OnClick = function()
		palette.Open()
	end,
	Parent = overlaysPage,
})

-- 8. Data page ----------------------------------------------------------------------

local dataPage = makePage("data")

AetherUI.Breadcrumbs({
	Items = {
		{ Label = "Home", Icon = "home" },
		{ Label = "Players" },
		{ Label = "Leaderboard" },
	},
	Parent = dataPage,
})

AetherUI.DataTable({
	Columns = {
		{ Key = "name", Label = "Player", Sortable = true },
		{ Key = "score", Label = "Score", Sortable = true, Align = "Right" },
		{ Key = "status", Label = "Status" },
	},
	Rows = {
		{ name = "builderman", score = 9420, status = "Online" },
		{ name = "Shedletsky", score = 8113, status = "Away" },
		{ name = "Stickmasterluke", score = 7770, status = "Online" },
		{ name = "loleris", score = 6521, status = "Offline" },
		{ name = "Quenty", score = 5980, status = "Online" },
	},
	PageSize = 4,
	Searchable = true,
	Parent = dataPage,
})

AetherUI.TreeView({
	Nodes = {
		{
			Label = "src",
			Icon = "folder",
			Children = {
				{ Label = "Core", Icon = "folder", Children = {
					{ Label = "Theme.lua", Icon = "file" },
					{ Label = "Icons.lua", Icon = "file" },
				} },
				{ Label = "Init.lua", Icon = "file" },
			},
		},
		{ Label = "README.md", Icon = "file-text" },
	},
	Parent = dataPage,
})

print("[Showcase] AetherUI showcase loaded. Press Ctrl+K for the command palette.")
