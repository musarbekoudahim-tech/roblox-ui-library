--[[
	Smoke test driver: constructs every AetherUI component with realistic
	props and reports failures. Runs after mock_roblox.lua + the bundle
	(combined by scripts/smoke.mjs). `AetherUI` is provided as a local.
]]

local failures = 0
local passes = 0

local function check(label, fn)
	local ok, err = pcall(fn)
	if ok then
		passes += 1
		print("PASS " .. label)
	else
		failures += 1
		print("FAIL " .. label .. " -> " .. tostring(err))
	end
end

local Value = AetherUI.Fusion and AetherUI.Fusion.Value

-- Themes ------------------------------------------------------------------
check("Theme.Apply Dark", function() AetherUI.Theme.Apply("Dark") end)
check("Theme.Apply Light", function() AetherUI.Theme.Apply("Light") end)
check("Theme.Apply Amoled", function() AetherUI.Theme.Apply("Amoled") end)
check("Theme.Apply Midnight", function() AetherUI.Theme.Apply("Midnight") end)
check("Theme.Apply Dark again", function() AetherUI.Theme.Apply("Dark") end)

-- Icons ---------------------------------------------------------------------
check("Icons.List", function() AetherUI.Icons.List() end)
check("Icons.render known", function() AetherUI.Icons.render("close") end)
check("Icons.render unknown", function() AetherUI.Icons.render("definitely-not-an-icon") end)

-- Window (must come early; other floating pieces attach to overlay) ----------
local windowApi
check("Window", function()
	windowApi = AetherUI.Window({
		Title = "Smoke Test",
		Size = UDim2.fromOffset(560, 420),
		Draggable = true,
		Resizable = true,
	})
end)

-- Every component --------------------------------------------------------------
check("Button primary", function()
	AetherUI.Button({ Text = "Click", Variant = "Primary", OnClick = function() end })
end)
check("Button secondary+icon", function()
	AetherUI.Button({ Text = "Go", Variant = "Secondary", Icon = "check", OnClick = function() end })
end)
check("Button ghost disabled", function()
	AetherUI.Button({ Text = "Nope", Variant = "Ghost", Disabled = true })
end)
check("Button danger", function()
	AetherUI.Button({ Text = "Delete", Variant = "Danger" })
end)

check("TextInput", function()
	AetherUI.TextInput({ Placeholder = "Type here", OnChange = function() end })
end)
check("TextInput with icon+error", function()
	AetherUI.TextInput({ Placeholder = "Email", Icon = "search", Error = "Required" })
end)
check("TextArea", function()
	AetherUI.TextArea({ Placeholder = "Notes", Rows = 3 })
end)

check("Toggle", function()
	AetherUI.Toggle({ Label = "Enable", Description = "Turns it on", OnChange = function() end })
end)
check("Checkbox", function()
	AetherUI.Checkbox({ Label = "Agree", Description = "Terms", OnChange = function() end })
end)
check("RadioGroup", function()
	AetherUI.RadioGroup({
		Items = {
			{ Value = "a", Label = "Alpha", Description = "First" },
			{ Value = "b", Label = "Beta" },
		},
		OnChange = function() end,
	})
end)

check("Slider", function()
	AetherUI.Slider({ Min = 0, Max = 100, Default = 50, OnChange = function() end })
end)
check("Slider stepped", function()
	AetherUI.Slider({ Min = 0, Max = 10, Step = 2, Default = 4, ShowValue = true })
end)

check("Dropdown", function()
	AetherUI.Dropdown({
		Items = {
			{ Value = "1", Label = "One", Icon = "check" },
			{ Value = "2", Label = "Two", Disabled = true },
		},
		Placeholder = "Pick one",
		Searchable = true,
		OnChange = function() end,
	})
end)
check("MultiSelect", function()
	AetherUI.MultiSelect({
		Items = { { Value = "x", Label = "X" }, { Value = "y", Label = "Y" } },
		OnChange = function() end,
	})
end)

check("Tabs", function()
	AetherUI.Tabs({
		Tabs = {
			{ Id = "one", Label = "One", Icon = "home" },
			{ Id = "two", Label = "Two" },
		},
	})
end)
check("Sidebar", function()
	AetherUI.Sidebar({
		Items = {
			{ Id = "home", Label = "Home", Icon = "home" },
			{ Id = "settings", Label = "Settings", Icon = "settings", Badge = "3" },
		},
		Footer = { { Id = "logout", Label = "Log out" } },
		OnSelect = function() end,
	})
end)
check("Breadcrumbs", function()
	AetherUI.Breadcrumbs({
		Items = { { Label = "Home" }, { Label = "Library" }, { Label = "Data" } },
		OnClick = function() end,
	})
end)

check("Card", function()
	AetherUI.Card({ Title = "Card", Description = "Body text" })
end)
check("Section", function()
	AetherUI.Section({ Title = "Section" })
end)
check("Accordion", function()
	AetherUI.Accordion({
		Items = {
			{ Id = "a", Title = "First", Body = "Content A", Icon = "info" },
			{ Id = "b", Title = "Second", Body = "Content B" },
		},
	})
end)
check("Separator", function() AetherUI.Separator({}) end)
check("ScrollFrame", function()
	AetherUI.ScrollFrame({ Size = UDim2.fromOffset(200, 200) })
end)

check("Badge", function() AetherUI.Badge({ Text = "New", Variant = "Primary" }) end)
check("Avatar", function() AetherUI.Avatar({ Name = "Mock Player" }) end)
check("StatusDot", function() AetherUI.StatusDot({ Status = "Online" }) end)
check("Progress.Bar", function() AetherUI.Progress.Bar({ Value = 0.5 }) end)
check("Progress.Circular", function() AetherUI.Progress.Circular({ Value = 0.75 }) end)
check("Skeleton", function() AetherUI.Skeleton({ Lines = 3 }) end)
check("EmptyState", function()
	AetherUI.EmptyState({ Title = "Nothing here", Description = "Add something", Icon = "inbox" })
end)

check("ColorPicker", function()
	AetherUI.ColorPicker({ Default = Color3.fromRGB(200, 60, 60), OnChange = function() end })
end)
check("KeybindInput", function()
	AetherUI.KeybindInput({ Default = Enum.KeyCode.E, OnChange = function() end })
end)
check("FormField", function()
	AetherUI.FormField({ Label = "Field", Child = AetherUI.TextInput({}) })
end)
check("Stepper", function()
	AetherUI.Stepper({ Min = 0, Max = 10, Default = 5, OnChange = function() end })
end)
check("DatePicker", function()
	AetherUI.DatePicker({ OnChange = function() end })
end)
check("TimePicker", function()
	AetherUI.TimePicker({ OnChange = function() end })
end)

check("DataTable", function()
	AetherUI.DataTable({
		Columns = { { Key = "name", Label = "Name" }, { Key = "level", Label = "Level" } },
		Rows = { { name = "Alpha", level = 3 }, { name = "Beta", level = 7 } },
	})
end)
check("TreeView", function()
	AetherUI.TreeView({
		Nodes = {
			{ Id = "root", Label = "Root", Children = { { Id = "leaf", Label = "Leaf" } } },
		},
	})
end)

check("Toast.Success", function() AetherUI.Toast.Success("Saved", "It worked") end)
check("Toast.Error", function() AetherUI.Toast.Error("Oops", "It broke") end)
check("Modal.Confirm", function()
	AetherUI.Modal.Confirm({ Title = "Sure?", Body = "Really?", OnConfirm = function() end })
end)
check("Tooltip.Attach", function()
	local target = AetherUI.Button({ Text = "Hover me" })
	AetherUI.Tooltip.Attach(target, { Text = "Tip" })
end)
check("ContextMenu.Attach", function()
	local target = AetherUI.Button({ Text = "Right click" })
	AetherUI.ContextMenu.Attach(target, {
		Items = { { Label = "Copy", Icon = "copy" }, { Label = "Delete", Danger = true } },
	})
end)
check("CommandPalette", function()
	AetherUI.CommandPalette({
		Commands = { { Id = "run", Label = "Run", Keywords = "execute" } },
	})
end)
check("Notification/Keybinds api", function()
	AetherUI.Keybinds.Register("test", { Key = Enum.KeyCode.K, Callback = function() end })
	AetherUI.Keybinds.Unregister("test")
	AetherUI.Keybinds.DisconnectAll()
end)

check("Window destroy", function()
	if windowApi and windowApi.Destroy then windowApi:Destroy() end
end)
check("AetherUI.Destroy", function()
	if AetherUI.Destroy then AetherUI.Destroy() end
end)

-- Async errors captured by the mock (task.spawn failures, warns) --------------
print("")
print(("=== ASYNC/CAPTURED ERRORS: %d ==="):format(#_MOCK_ERRORS))
for i, e in ipairs(_MOCK_ERRORS) do
	if i <= 40 then print("  " .. e) end
end

print("")
print(("=== SMOKE RESULT: %d passed, %d failed, %d captured async errors ==="):format(passes, failures, #_MOCK_ERRORS))
