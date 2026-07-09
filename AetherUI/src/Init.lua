--!strict
--[[
	     █████╗ ███████╗████████╗██╗  ██╗███████╗██████╗ ██╗   ██╗██╗
	    ██╔══██╗██╔════╝╚══██╔══╝██║  ██║██╔════╝██╔══██╗██║   ██║██║
	    ███████║█████╗     ██║   ███████║█████╗  ██████╔╝██║   ██║██║
	    ██╔══██║██╔══╝     ██║   ██╔══██║██╔══╝  ██╔══██╗██║   ██║██║
	    ██║  ██║███████╗   ██║   ██║  ██║███████╗██║  ██║╚██████╔╝██║
	    ╚═╝  ╚═╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝ ╚═════╝ ╚═╝

	AetherUI — a premium, production-grade UI library for Roblox.
	Built on Fusion. Themeable, animated, accessible, obsessively polished.

	STANDALONE RUNTIME BUILD
	  • No dependencies on ReplicatedStorage, StarterPlayerScripts, or any
	    local game project folders.
	  • The UI container is parented to game:GetService("CoreGui") (or the
	    executor's hidden UI via gethui when available), so the interface
	    persists across respawns, independent of the local character state.
	  • This module returns the full library table, so it can be initialized
	    dynamically:
			local AetherUI = loadstring(game:HttpGet("URL"))()

	Quick start:
		local AetherUI = loadstring(game:HttpGet("URL"))()
		AetherUI.Theme.Apply("Dark")

		local window = AetherUI.Window({ Title = "My App" })
		AetherUI.Button({
			Text = "Hello",
			OnClick = function() AetherUI.Toast.Success("It works!") end,
			Parent = window.Content,
		})

	https://github.com/your-name/AetherUI • MIT License
]]

local Core = script.Parent.Core
local Components = script.Parent.Components
local Hooks = script.Parent.Hooks

local AetherUI = {}

AetherUI.Version = "1.0.0"

-- Core systems -----------------------------------------------------------------

AetherUI.Fusion = require(Core.Fusion)
AetherUI.Theme = require(Core.Theme)
AetherUI.Icons = require(Core.Icons)
AetherUI.Keybinds = require(Core.Keybinds)
AetherUI.Animation = require(Core.Animation)
AetherUI.Sound = require(Core.Sound)
AetherUI.Accessibility = require(Core.Accessibility)
AetherUI.Responsive = require(Core.Responsive)
AetherUI.Signal = require(Core.Signal)
AetherUI.Maid = require(Core.Maid)
AetherUI.Utils = require(Core.Utils)
AetherUI.Overlay = require(Core.Overlay)

-- Building blocks ----------------------------------------------------------------

AetherUI.Primitives = require(Components.Primitives)
AetherUI.Hooks = {
	UseHover = require(Hooks.UseHover),
	UsePress = require(Hooks.UsePress),
	UseDrag = require(Hooks.UseDrag),
}

-- Components -----------------------------------------------------------------------

AetherUI.Window = require(Components.Window)
AetherUI.Button = require(Components.Button)
AetherUI.TextInput = require(Components.TextInput)
AetherUI.TextArea = require(Components.TextArea)
AetherUI.Slider = require(Components.Slider)
AetherUI.Dropdown = require(Components.Dropdown)
AetherUI.MultiSelect = require(Components.MultiSelect)
AetherUI.Checkbox = require(Components.Checkbox)
AetherUI.RadioGroup = require(Components.RadioGroup)
AetherUI.Toggle = require(Components.Toggle)
AetherUI.ColorPicker = require(Components.ColorPicker)
local FormFieldModule = require(Components.FormField)
AetherUI.FormField = FormFieldModule.Field
AetherUI.Label = FormFieldModule.Label
AetherUI.HelperText = FormFieldModule.HelperText
AetherUI.KeybindInput = require(Components.KeybindInput)

AetherUI.Tabs = require(Components.Tabs)
local CardModule = require(Components.Card)
AetherUI.Card = CardModule.Card
AetherUI.Section = CardModule.Section
AetherUI.Accordion = require(Components.Accordion)
AetherUI.Separator = require(Components.Separator)
AetherUI.ScrollFrame = require(Components.ScrollFrame)
AetherUI.Sidebar = require(Components.Sidebar)
AetherUI.Breadcrumbs = require(Components.Breadcrumbs)

AetherUI.Modal = require(Components.Modal)
AetherUI.Toast = require(Components.Toast)
AetherUI.Tooltip = require(Components.Tooltip)
AetherUI.ContextMenu = require(Components.ContextMenu)
AetherUI.CommandPalette = require(Components.CommandPalette)

AetherUI.Progress = require(Components.Progress)
AetherUI.DataTable = require(Components.DataTable)
AetherUI.TreeView = require(Components.TreeView)
local BadgeModule = require(Components.Badge)
AetherUI.Badge = BadgeModule.new
AetherUI.DatePicker = require(Components.DatePicker)
AetherUI.TimePicker = require(Components.TimePicker)
AetherUI.Stepper = require(Components.Stepper)
AetherUI.Skeleton = require(Components.Skeleton)
AetherUI.EmptyState = require(Components.EmptyState)

-- Convenience aliases ---------------------------------------------------------------

AetherUI.Avatar = BadgeModule.Avatar
AetherUI.StatusIndicator = BadgeModule.Status
AetherUI.ProgressBar = AetherUI.Progress.Bar
AetherUI.CircularProgress = AetherUI.Progress.Circular

--- Reactive state helper re-exported from Fusion for controlled components:
---   local volume = AetherUI.Value(50)
---   AetherUI.Slider({ Value = volume })
AetherUI.Value = AetherUI.Fusion.Value
AetherUI.Computed = AetherUI.Fusion.Computed

-- Lifecycle --------------------------------------------------------------------------

--- Tears down all global state (overlays, sounds, keybinds).
--- Call when your UI is being unmounted for good.
function AetherUI.Destroy()
	AetherUI.Keybinds.DisconnectAll()
	AetherUI.Sound.Destroy()
	AetherUI.Overlay.destroy()
end

-- The library table is returned at the very end so the script works when
-- executed dynamically via loadstring(game:HttpGet("URL"))().
return AetherUI
