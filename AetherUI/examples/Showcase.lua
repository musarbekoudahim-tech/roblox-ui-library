--!strict
--[[
	AetherUI — Showcase
	===================
	A complete tour of every AetherUI component, wired into a single window
	with a sidebar. Drop this in a LocalScript under StarterPlayerScripts
	(with AetherUI placed in ReplicatedStorage) and hit Play.

	Press RightShift to toggle the window, Ctrl+K for the command palette.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AetherUI = require(ReplicatedStorage:WaitForChild("AetherUI"):WaitForChild("Init"))

-- 1. Theme + global systems ---------------------------------------------------

AetherUI.Theme.Apply("Dark") -- "Dark" | "Light" | "Amoled" | "Aurora"
AetherUI.Sound.SetEnabled(true)

-- 2. Window -------------------------------------------------------------------

local window = AetherUI.Window({
	Title = "AetherUI Showcase",
	Subtitle = "v" .. AetherUI.Version,
	Icon = "sparkles",
	Size = UDim2.fromOffset(880, 560),
	ToggleKey = Enum.KeyCode.RightShift,
	Resizable = true,
})

-- 3. Sidebar navigation --------------------------------------------------------

local pages = {} :: { [string]: ScrollingFrame }

local function makePage(name: string): ScrollingFrame
	local page = AetherUI.ScrollFrame({
		Size = UDim2.new(1, -220, 1, 0),
		Position = UDim2.new(0, 220, 0, 0),
		Padding = 20,
		ListPadding = 14,
		Parent = window.Content,
	})
	page.Visible = false
	pages[name] = page
	return page
end

AetherUI.Sidebar({
	Title = "Aether",
	Collapsible = true,
	Default = "inputs",
	Size = UDim2.new(0, 210, 1, 0),
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

-- 4. Inputs page ----------------------------------------------------------------

local inputsPage = makePage("inputs")
inputsPage.Visible = true

local username = AetherUI.Value("")

AetherUI.FormField({
	Label = "Username",
	HelperText = "3-16 characters, letters and numbers only.",
	Required = true,
	Content = AetherUI.TextInput({
		Value = username,
		Placeholder = "Enter username...",
		Icon = "user",
		ClearButton = true,
		MaxLength = 16,
		ShowCounter = true,
		Validate = function(text: string): (boolean, string?)
			if #text > 0 and #text < 3 then
				return false, "Too short"
			end
			return true
		end,
	}),
	Parent = inputsPage,
})

AetherUI.FormField({
	Label = "Password",
	Content = AetherUI.TextInput({
		Placeholder = "Enter password...",
		Icon = "lock",
		Password = true,
	}),
	Parent = inputsPage,
})

local bioField = AetherUI.TextArea({
	Placeholder = "Write a bio...",
	MaxLength = 200,
	ShowCounter = true,
	Rows = 4,
})
bioField.Parent = inputsPage

local volume = AetherUI.Value(60)
local volumeSlider = AetherUI.Slider({
	Label = "Volume",
	Min = 0,
	Max = 100,
	Step = 1,
	Value = volume,
	ShowValue = true,
	Format = function(v: number): string
		return ("%d%%"):format(v)
	end,
	OnChanged = function(v: number)
		print("[Showcase] Volume:", v)
	end,
})
volumeSlider.Parent = inputsPage

local priceRange = AetherUI.Value({ 50, 320 })
local rangeSlider = AetherUI.Slider({
	Label = "Price range",
	Min = 0,
	Max = 500,
	RangeValue = priceRange,
	ShowValue = true,
	Format = function(v: number): string
		return ("$%d"):format(v)
	end,
})
rangeSlider.Parent = inputsPage

AetherUI.FormField({
	Label = "Accent color",
	Content = AetherUI.ColorPicker({
		Value = Color3.fromRGB(94, 106, 255),
		Presets = {
			Color3.fromRGB(94, 106, 255),
			Color3.fromRGB(16, 185, 129),
			Color3.fromRGB(244, 63, 94),
			Color3.fromRGB(245, 158, 11),
		},
		OnChanged = function(color: Color3)
			print("[Showcase] Color:", color)
		end,
	}),
	Parent = inputsPage,
})

AetherUI.FormField({
	Label = "Open menu key",
	Content = AetherUI.KeybindInput({
		Keybind = { Key = Enum.KeyCode.M },
		AllowModifiers = true,
		OnChanged = function(bind)
			print("[Showcase] Rebound to", AetherUI.Keybinds.format(bind))
		end,
	}),
	Parent = inputsPage,
})

-- 5. Selection page --------------------------------------------------------------

local selectionPage = makePage("selection")

local region = AetherUI.Value("eu")
AetherUI.FormField({
	Label = "Region",
	Content = AetherUI.Dropdown({
		Items = {
			{ Label = "North America", Value = "na" },
			{ Label = "Europe", Value = "eu" },
			{ Label = "Asia Pacific", Value = "apac" },
			{ Label = "South America", Value = "sa" },
		},
		Value = region,
		Searchable = true,
		FullWidth = true,
	}),
	Parent = selectionPage,
})

local tags = AetherUI.Value({ "pvp", "sim" })
AetherUI.FormField({
	Label = "Tags",
	Content = AetherUI.MultiSelect({
		Items = {
			{ Label = "PvP", Value = "pvp" },
			{ Label = "Roleplay", Value = "rp" },
			{ Label = "Simulator", Value = "sim" },
			{ Label = "Obby", Value = "obby" },
			{ Label = "Tycoon", Value = "tycoon" },
			{ Label = "Horror", Value = "horror" },
		},
		Values = tags,
		Placeholder = "Pick tags...",
		MaxVisibleChips = 4,
	}),
	Parent = selectionPage,
})

local notifications = AetherUI.Value(true)
local notifyBox = AetherUI.Checkbox({
	Label = "Enable notifications",
	Value = notifications,
})
notifyBox.Parent = selectionPage

local darkMode = AetherUI.Value(true)
local darkToggle = AetherUI.Toggle({
	Label = "Dark mode",
	Description = "Switch between light and dark themes.",
	Value = darkMode,
	OnChanged = function(on: boolean)
		AetherUI.Theme.Apply(if on then "Dark" else "Light")
	end,
})
darkToggle.Parent = selectionPage

local quality = AetherUI.Value("high")
local qualityRadios = AetherUI.RadioGroup({
	Items = {
		{ Label = "Low", Value = "low" },
		{ Label = "Medium", Value = "medium" },
		{ Label = "High", Value = "high" },
		{ Label = "Ultra", Value = "ultra", Description = "Requires a beefy device." },
	},
	Value = quality,
})
qualityRadios.Parent = selectionPage

AetherUI.FormField({
	Label = "Event date",
	Content = AetherUI.DatePicker({
		OnChanged = function(date)
			print(("[Showcase] Date: %d-%02d-%02d"):format(date.Year, date.Month, date.Day))
		end,
	}),
	Parent = selectionPage,
})

AetherUI.FormField({
	Label = "Start time",
	Content = AetherUI.TimePicker({
		Use24Hour = false,
		MinuteStep = 5,
	}),
	Parent = selectionPage,
})

-- 6. Display page -----------------------------------------------------------------

local displayPage = makePage("display")

AetherUI.Card({
	Title = "Server Status",
	Description = "Updated 2 minutes ago",
	Icon = "activity",
	Parent = displayPage,
	Children = {
		AetherUI.Badge({ Text = "Online", Variant = "Success", Dot = true }),
		AetherUI.Badge({ Text = "v2.4.1", Variant = "Outline" }),
		AetherUI.ProgressBar({ Value = 0.72, ShowLabel = true }),
		AetherUI.CircularProgress({ Value = 0.45, Diameter = 64, ShowLabel = true }),
	},
})

local avatar = AetherUI.Avatar({
	Name = "builderman",
	Size = 48,
	Status = "Online",
	Ring = true,
})
avatar.Parent = displayPage

local status = AetherUI.StatusIndicator({
	Status = "Busy",
	Label = "In a match",
	Pulse = true,
})
status.Parent = displayPage

AetherUI.Separator({ Label = "Details", Parent = displayPage })

AetherUI.Accordion({
	Items = {
		{
			Id = "what",
			Title = "What is AetherUI?",
			Content = function()
				return AetherUI.HelperText({ Text = "A premium Fusion-based UI library for Roblox." })
			end,
		},
		{
			Id = "free",
			Title = "Is it free?",
			Content = function()
				return AetherUI.HelperText({ Text = "Yes - MIT licensed, forever." })
			end,
			DefaultOpen = true,
		},
		{
			Id = "themes",
			Title = "Does it support themes?",
			Content = function()
				return AetherUI.HelperText({ Text = "Dark, Light, Amoled, Aurora and unlimited custom themes." })
			end,
		},
	},
	Multiple = false,
	Parent = displayPage,
})

AetherUI.Tabs({
	Variant = "pill",
	Default = "overview",
	Tabs = {
		{ Id = "overview", Label = "Overview", Icon = "home" },
		{ Id = "stats", Label = "Stats", Icon = "bar-chart" },
		{ Id = "settings", Label = "Settings", Icon = "settings" },
	},
	Parent = displayPage,
})

AetherUI.Stepper({
	Steps = {
		{ Title = "Account", Icon = "user" },
		{ Title = "Profile", Icon = "id-card" },
		{ Title = "Preferences", Icon = "sliders-horizontal" },
		{ Title = "Done", Icon = "check" },
	},
	OnFinish = function()
		AetherUI.Toast.Success("Setup complete!")
	end,
	Parent = displayPage,
})

AetherUI.Skeleton({ Lines = 3, Parent = displayPage })

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

-- 7. Overlays page ----------------------------------------------------------------

local overlaysPage = makePage("overlays")

local modalButton = AetherUI.Button({
	Text = "Open Modal",
	Icon = "app-window",
	Variant = "Primary",
	OnClick = function()
		AetherUI.Modal({
			Title = "Confirm action",
			Description = "Are you sure you want to reset all settings? This cannot be undone.",
			Icon = "triangle-alert",
			Variant = "danger",
			Actions = {
				{ Label = "Cancel", Variant = "Ghost", CloseOnClick = true },
				{
					Label = "Reset",
					Variant = "Destructive",
					CloseOnClick = true,
					OnClick = function()
						AetherUI.Toast.Success("Settings reset", {
							Description = "All settings restored to defaults.",
						})
					end,
				},
			},
		})
	end,
})
modalButton.Parent = overlaysPage

local toastButton = AetherUI.Button({
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
			Action = {
				Label = "Retry now",
				OnClick = function()
					print("[Showcase] Retry")
				end,
			},
		})
	end,
})
toastButton.Parent = overlaysPage

local tooltipTarget = AetherUI.Button({
	Text = "Hover me",
	Variant = "Outline",
})
tooltipTarget.Parent = overlaysPage
AetherUI.Tooltip.Attach(tooltipTarget, {
	Title = "Rich tooltip",
	Text = "Tooltips support titles, shortcuts and custom delays.",
	Shortcut = "Ctrl+H",
	Delay = 0.4,
})

local contextTarget = AetherUI.Button({
	Text = "Right-click me",
	Variant = "Ghost",
})
contextTarget.Parent = overlaysPage
AetherUI.ContextMenu.Attach(contextTarget, {
	{ Label = "Copy", Icon = "copy", Shortcut = "Ctrl+C" },
	{ Label = "Paste", Icon = "clipboard", Shortcut = "Ctrl+V" },
	{ Separator = true },
	{ Label = "Delete", Icon = "trash-2", Destructive = true },
})

-- Command palette: fuzzy search across registered commands, Ctrl+K to toggle.
local palette = AetherUI.CommandPalette({
	Hotkey = Enum.KeyCode.K, -- Ctrl+K (default)
	Commands = {
		{
			Id = "theme-dark",
			Label = "Theme: Dark",
			Icon = "moon",
			Group = "Appearance",
			Run = function()
				AetherUI.Theme.Apply("Dark")
			end,
		},
		{
			Id = "theme-light",
			Label = "Theme: Light",
			Icon = "sun",
			Group = "Appearance",
			Run = function()
				AetherUI.Theme.Apply("Light")
			end,
		},
		{
			Id = "toast-hello",
			Label = "Say hello",
			Icon = "hand",
			Group = "Fun",
			Run = function()
				AetherUI.Toast.Info("Hello from the palette!")
			end,
		},
	},
})

local paletteButton = AetherUI.Button({
	Text = "Command Palette (Ctrl+K)",
	Icon = "command",
	Variant = "Outline",
	OnClick = function()
		palette.Open()
	end,
})
paletteButton.Parent = overlaysPage

-- 8. Data page --------------------------------------------------------------------

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
		{ Key = "score", Label = "Score", Sortable = true },
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
			Id = "src",
			Label = "src",
			Icon = "folder",
			Children = {
				{
					Id = "core",
					Label = "Core",
					Icon = "folder",
					Children = {
						{ Id = "theme", Label = "Theme.lua", Icon = "file" },
						{ Id = "icons", Label = "Icons.lua", Icon = "file" },
					},
				},
				{ Id = "init", Label = "Init.lua", Icon = "file" },
			},
		},
		{ Id = "readme", Label = "README.md", Icon = "file-text" },
	},
	DefaultExpanded = { "src" },
	OnSelect = function(node)
		print("[Showcase] Selected:", node.Label)
	end,
	Parent = dataPage,
})

print("[Showcase] AetherUI loaded. RightShift toggles the window, Ctrl+K opens the palette.")
