--!strict
--[[
	AetherUI • Core/Keybinds
	Global + per-component hotkey registry.

		local bind = Keybinds.Register("toggle-menu", {
			Key = Enum.KeyCode.K,
			Modifiers = { "Ctrl" },
			Description = "Toggle the menu",
			Callback = function() window:Toggle() end,
		})
		bind:Disconnect()

	Capture mode (used by the KeybindInput component):

		Keybinds.BeginCapture(function(keyCode, modifiers) ... end)
]]

local UserInputService = game:GetService("UserInputService")

local Signal = require(script.Parent.Signal)
local Types = require(script.Parent.Parent.Types)

type KeybindSpec = Types.KeybindSpec

export type KeybindHandle = {
	Id: string,
	Spec: KeybindSpec,
	SetEnabled: (self: KeybindHandle, enabled: boolean) -> (),
	Disconnect: (self: KeybindHandle) -> (),
}

--- Lightweight bind descriptor used by KeybindInput and transient binds.
export type Bind = {
	Key: Enum.KeyCode,
	Ctrl: boolean?,
	Shift: boolean?,
	Alt: boolean?,
}

local Keybinds = {}

Keybinds.Enabled = true
Keybinds.Triggered = Signal.new() :: any

local registry: { [string]: KeybindHandle } = {}
local captureCallback: ((Enum.KeyCode, { string }) -> ())? = nil

local MODIFIER_KEYS = {
	[Enum.KeyCode.LeftControl] = "Ctrl",
	[Enum.KeyCode.RightControl] = "Ctrl",
	[Enum.KeyCode.LeftShift] = "Shift",
	[Enum.KeyCode.RightShift] = "Shift",
	[Enum.KeyCode.LeftAlt] = "Alt",
	[Enum.KeyCode.RightAlt] = "Alt",
}

local function activeModifiers(): { [string]: boolean }
	return {
		Ctrl = UserInputService:IsKeyDown(Enum.KeyCode.LeftControl)
			or UserInputService:IsKeyDown(Enum.KeyCode.RightControl),
		Shift = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)
			or UserInputService:IsKeyDown(Enum.KeyCode.RightShift),
		Alt = UserInputService:IsKeyDown(Enum.KeyCode.LeftAlt)
			or UserInputService:IsKeyDown(Enum.KeyCode.RightAlt),
	}
end

local function modifiersMatch(required: { string }?, active: { [string]: boolean }): boolean
	local requiredSet = { Ctrl = false, Shift = false, Alt = false }
	for _, mod in required or {} do
		requiredSet[mod] = true
	end
	return requiredSet.Ctrl == active.Ctrl
		and requiredSet.Shift == active.Shift
		and requiredSet.Alt == active.Alt
end

--- Registers a keybind. Returns a handle with :Disconnect() and :SetEnabled().
function Keybinds.Register(id: string, spec: KeybindSpec): KeybindHandle
	local handle = {} :: KeybindHandle
	handle.Id = id
	handle.Spec = spec
	if spec.Enabled == nil then
		spec.Enabled = true
	end

	function handle.SetEnabled(_, enabled: boolean)
		spec.Enabled = enabled
	end

	function handle.Disconnect()
		registry[id] = nil
	end

	registry[id] = handle
	return handle
end

function Keybinds.Unregister(id: string)
	registry[id] = nil
end

--- Changes the key (and optionally modifiers) of an existing bind in place.
function Keybinds.Rebind(id: string, key: Enum.KeyCode, modifiers: { string }?)
	local handle = registry[id]
	if handle then
		handle.Spec.Key = key
		if modifiers ~= nil then
			handle.Spec.Modifiers = modifiers
		end
	end
end

function Keybinds.GetAll(): { [string]: KeybindSpec }
	local out = {}
	for id, handle in registry do
		out[id] = handle.Spec
	end
	return out
end

function Keybinds.SetEnabled(enabled: boolean)
	Keybinds.Enabled = enabled
end

--- Enters capture mode: the next key press is reported and swallowed. Escape cancels.
function Keybinds.BeginCapture(callback: (Enum.KeyCode?, { string }) -> ())
	captureCallback = callback :: any
end

function Keybinds.CancelCapture()
	captureCallback = nil
end

--- Formats a keybind for display, e.g. "Ctrl + Shift + K".
function Keybinds.Format(key: Enum.KeyCode?, modifiers: { string }?): string
	local parts = {}
	for _, mod in modifiers or {} do
		table.insert(parts, mod)
	end
	if key then
		table.insert(parts, key.Name)
	end
	return if #parts > 0 then table.concat(parts, " + ") else "None"
end

--- Formats a Bind descriptor for display, e.g. "Ctrl + K".
function Keybinds.format(bind: Bind): string
	local mods = {}
	if bind.Ctrl then
		table.insert(mods, "Ctrl")
	end
	if bind.Shift then
		table.insert(mods, "Shift")
	end
	if bind.Alt then
		table.insert(mods, "Alt")
	end
	return Keybinds.Format(bind.Key, mods)
end

--- Binds a single key until unbound. Returns an unbind function.
--- Used internally for transient bindings like Escape-to-close.
local transientCounter = 0
function Keybinds.bindTransient(key: Enum.KeyCode, callback: () -> ()): () -> ()
	transientCounter += 1
	local id = "__transient_" .. transientCounter
	Keybinds.Register(id, {
		Key = key,
		Callback = callback,
	})
	return function()
		Keybinds.Unregister(id)
	end
end

-- Input handling ------------------------------------------------------------

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if input.UserInputType ~= Enum.UserInputType.Keyboard then
		return
	end

	-- Capture mode takes priority over everything
	if captureCallback then
		if MODIFIER_KEYS[input.KeyCode] then
			return -- wait for a non-modifier key
		end
		local callback = captureCallback
		captureCallback = nil
		local mods = {}
		local active = activeModifiers()
		for _, name in { "Ctrl", "Shift", "Alt" } do
			if active[name] then
				table.insert(mods, name)
			end
		end
		if input.KeyCode == Enum.KeyCode.Escape then
			callback(nil, {})
		else
			callback(input.KeyCode, mods)
		end
		return
	end

	if not Keybinds.Enabled or gameProcessed then
		return
	end

	local active = activeModifiers()
	for id, handle in registry do
		local spec = handle.Spec
		if spec.Enabled ~= false and spec.Key == input.KeyCode and modifiersMatch(spec.Modifiers, active) then
			Keybinds.Triggered:Fire(id)
			task.spawn(spec.Callback)
		end
	end
end)

--- Removes every registered keybind. Used by AetherUI.Destroy() on teardown.
function Keybinds.DisconnectAll()
	captureCallback = nil
	table.clear(registry)
end

return Keybinds
