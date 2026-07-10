--[[
	Mock Roblox environment for running AetherUI outside Roblox (luau CLI).
	Implements just enough of the API surface the library + Fusion 0.2 touch.
	Property assignments are TYPE-CHECKED like real Roblox instances, so nil
	or wrong-typed values assigned to Color3/UDim2/etc properties raise the
	same class of errors seen in the Developer Console.
]]

local ERRORS = {}
local function recordError(msg)
	table.insert(ERRORS, tostring(msg))
end

-- typeof override ------------------------------------------------------------
local nativeTypeof = typeof or type
local function mockTypeof(v)
	if type(v) == "table" then
		local mt = getmetatable(v)
		if mt and mt.__rtype then
			return mt.__rtype
		end
	end
	return nativeTypeof(v)
end
typeof = mockTypeof

warn = function(...)
	local parts = {}
	for _, v in { ... } do
		table.insert(parts, tostring(v))
	end
	local msg = table.concat(parts, " ")
	recordError("[warn] " .. msg)
	print("[warn]", msg)
end

tick = tick or os.clock

-- Datatypes -------------------------------------------------------------------
local function dtype(name, tbl)
	tbl = tbl or {}
	tbl.__rtype = name
	tbl.__index = tbl.__index or tbl
	return tbl
end

-- Vector2
local Vector2Meta = dtype("Vector2")
Vector2Meta.__add = function(a, b) return Vector2.new(a.X + b.X, a.Y + b.Y) end
Vector2Meta.__sub = function(a, b) return Vector2.new(a.X - b.X, a.Y - b.Y) end
Vector2Meta.__mul = function(a, b)
	if type(b) == "number" then return Vector2.new(a.X * b, a.Y * b) end
	if type(a) == "number" then return Vector2.new(b.X * a, b.Y * a) end
	return Vector2.new(a.X * b.X, a.Y * b.Y)
end
Vector2Meta.__div = function(a, b)
	if type(b) == "number" then return Vector2.new(a.X / b, a.Y / b) end
	return Vector2.new(a.X / b.X, a.Y / b.Y)
end
Vector2Meta.__eq = function(a, b) return a.X == b.X and a.Y == b.Y end
Vector2 = {}
function Vector2.new(x, y)
	local v = setmetatable({ X = x or 0, Y = y or 0 }, Vector2Meta)
	v.Magnitude = math.sqrt(v.X * v.X + v.Y * v.Y)
	v.Unit = v
	return v
end
Vector2.zero = Vector2.new(0, 0)
Vector2.one = Vector2.new(1, 1)

-- Vector3
local Vector3Meta = dtype("Vector3")
Vector3Meta.__add = function(a, b) return Vector3.new(a.X + b.X, a.Y + b.Y, a.Z + b.Z) end
Vector3Meta.__sub = function(a, b) return Vector3.new(a.X - b.X, a.Y - b.Y, a.Z - b.Z) end
Vector3 = {}
function Vector3.new(x, y, z)
	return setmetatable({ X = x or 0, Y = y or 0, Z = z or 0 }, Vector3Meta)
end
Vector3.zero = Vector3.new()

-- Color3
local Color3Meta = dtype("Color3")
Color3Meta.__eq = function(a, b) return a.R == b.R and a.G == b.G and a.B == b.B end
Color3 = {}
function Color3.new(r, g, b)
	local c = setmetatable({ R = r or 0, G = g or 0, B = b or 0 }, Color3Meta)
	return c
end
function Color3.fromRGB(r, g, b)
	return Color3.new((r or 0) / 255, (g or 0) / 255, (b or 0) / 255)
end
function Color3.fromHSV(h, s, v)
	local i = math.floor(h * 6) % 6
	local f = h * 6 - math.floor(h * 6)
	local p, q, t = v * (1 - s), v * (1 - f * s), v * (1 - (1 - f) * s)
	local r, g, b
	if i == 0 then r, g, b = v, t, p
	elseif i == 1 then r, g, b = q, v, p
	elseif i == 2 then r, g, b = p, v, t
	elseif i == 3 then r, g, b = p, q, v
	elseif i == 4 then r, g, b = t, p, v
	else r, g, b = v, p, q end
	return Color3.new(r, g, b)
end
function Color3.toHSV(c)
	local r, g, b = c.R, c.G, c.B
	local maxc, minc = math.max(r, g, b), math.min(r, g, b)
	local v = maxc
	local d = maxc - minc
	local s = maxc == 0 and 0 or d / maxc
	local h = 0
	if d ~= 0 then
		if maxc == r then h = ((g - b) / d) % 6
		elseif maxc == g then h = (b - r) / d + 2
		else h = (r - g) / d + 4 end
		h = h / 6
	end
	return h, s, v
end
function Color3.fromHex(hex)
	hex = hex:gsub("#", "")
	return Color3.fromRGB(tonumber(hex:sub(1, 2), 16) or 0, tonumber(hex:sub(3, 4), 16) or 0, tonumber(hex:sub(5, 6), 16) or 0)
end
Color3Meta.__index = {
	Lerp = function(a, b, t)
		return Color3.new(a.R + (b.R - a.R) * t, a.G + (b.G - a.G) * t, a.B + (b.B - a.B) * t)
	end,
	ToHSV = function(c)
		return Color3.toHSV(c)
	end,
	ToHex = function(c)
		return string.format("%02X%02X%02X", math.round(c.R * 255), math.round(c.G * 255), math.round(c.B * 255))
	end,
}
-- R/G/B live on the value itself; metatable only provides methods.
local color3Methods = Color3Meta.__index
Color3Meta.__index = function(self, k)
	return color3Methods[k]
end

-- UDim / UDim2
local UDimMeta = dtype("UDim")
UDimMeta.__add = function(a, b) return UDim.new(a.Scale + b.Scale, a.Offset + b.Offset) end
UDim = {}
function UDim.new(scale, offset)
	return setmetatable({ Scale = scale or 0, Offset = offset or 0 }, UDimMeta)
end
local UDim2Meta = dtype("UDim2")
UDim2Meta.__add = function(a, b) return UDim2.new(a.X + b.X, a.Y + b.Y) end
UDim2Meta.__eq = function(a, b)
	return a.X.Scale == b.X.Scale and a.X.Offset == b.X.Offset and a.Y.Scale == b.Y.Scale and a.Y.Offset == b.Y.Offset
end
UDim2 = {}
function UDim2.new(xs, xo, ys, yo)
	if typeof(xs) == "UDim" then
		return setmetatable({ X = xs, Y = xo, Width = xs, Height = xo }, UDim2Meta)
	end
	local x, y = UDim.new(xs, xo), UDim.new(ys, yo)
	return setmetatable({ X = x, Y = y, Width = x, Height = y }, UDim2Meta)
end
function UDim2.fromOffset(x, y) return UDim2.new(0, x, 0, y) end
function UDim2.fromScale(x, y) return UDim2.new(x, 0, y, 0) end

-- Rect
local RectMeta = dtype("Rect")
Rect = {}
function Rect.new(a, b, c, d)
	return setmetatable({ Min = Vector2.new(a, b), Max = Vector2.new(c, d), Left = a, Top = b, Right = c, Bottom = d }, RectMeta)
end

-- TweenInfo
local TweenInfoMeta = dtype("TweenInfo")
TweenInfo = {}
function TweenInfo.new(time, style, direction, repeatCount, reverses, delayTime)
	return setmetatable({
		Time = time or 1,
		EasingStyle = style,
		EasingDirection = direction,
		RepeatCount = repeatCount or 0,
		Reverses = reverses or false,
		DelayTime = delayTime or 0,
	}, TweenInfoMeta)
end

-- Font
local FontMeta = dtype("Font")
Font = {}
function Font.new(family, weight, style)
	return setmetatable({ Family = family, Weight = weight, Style = style, Bold = false }, FontMeta)
end
function Font.fromEnum(e) return Font.new("rbxasset://fonts/families/" .. tostring(e) .. ".json") end
function Font.fromName(name, weight, style) return Font.new("rbxasset://fonts/families/" .. tostring(name) .. ".json", weight, style) end

-- Number/Color sequences
local NumberSequenceMeta = dtype("NumberSequence")
NumberSequence = {}
function NumberSequence.new(a, b) return setmetatable({ Keypoints = {} }, NumberSequenceMeta) end
local NumberSequenceKeypointMeta = dtype("NumberSequenceKeypoint")
NumberSequenceKeypoint = {}
function NumberSequenceKeypoint.new(t, v, e) return setmetatable({ Time = t, Value = v }, NumberSequenceKeypointMeta) end
local ColorSequenceMeta = dtype("ColorSequence")
ColorSequence = {}
function ColorSequence.new(a, b) return setmetatable({ Keypoints = {} }, ColorSequenceMeta) end
local ColorSequenceKeypointMeta = dtype("ColorSequenceKeypoint")
ColorSequenceKeypoint = {}
function ColorSequenceKeypoint.new(t, v) return setmetatable({ Time = t, Value = v }, ColorSequenceKeypointMeta) end
local NumberRangeMeta = dtype("NumberRange")
NumberRange = {}
function NumberRange.new(a, b) return setmetatable({ Min = a, Max = b or a }, NumberRangeMeta) end

-- Enum ------------------------------------------------------------------------
local enumItemCache = {}
local EnumItemMeta = dtype("EnumItem")
EnumItemMeta.__tostring = function(e) return "Enum." .. e.EnumTypeName .. "." .. e.Name end
local EnumTypeMeta = {
	__rtype = "Enum",
	__index = function(self, name)
		local key = self._name .. "." .. name
		if not enumItemCache[key] then
			enumItemCache[key] = setmetatable({ Name = name, Value = 0, EnumTypeName = self._name, EnumType = self }, EnumItemMeta)
		end
		return enumItemCache[key]
	end,
}
local enumTypeCache = {}
Enum = setmetatable({}, {
	__index = function(_, typeName)
		if not enumTypeCache[typeName] then
			enumTypeCache[typeName] = setmetatable({ _name = typeName, GetEnumItems = function() return {} end }, EnumTypeMeta)
		end
		return enumTypeCache[typeName]
	end,
})

-- Signals ----------------------------------------------------------------------
local SignalMeta = dtype("RBXScriptSignal")
local function newSignal()
	local s = setmetatable({ _handlers = {} }, SignalMeta)
	return s
end
SignalMeta.__index = {
	Connect = function(self, fn)
		local conn = { Connected = true }
		local ConnMeta = { __rtype = "RBXScriptConnection", __index = { Disconnect = function(c) c.Connected = false; self._handlers[fn] = nil end } }
		setmetatable(conn, ConnMeta)
		self._handlers[fn] = true
		return conn
	end,
	Once = function(self, fn) return self.Connect(self, fn) end,
	Wait = function() return nil end,
	Fire = function(self, ...)
		for fn in pairs(self._handlers) do
			local ok, err = pcall(fn, ...)
			if not ok then recordError("[signal handler] " .. tostring(err)) end
		end
	end,
}

-- task -------------------------------------------------------------------------
task = {
	spawn = function(fn, ...)
		local co = coroutine.create(fn)
		local ok, err = coroutine.resume(co, ...)
		if not ok then
			recordError("[task.spawn] " .. tostring(err))
			print("[task.spawn error]", tostring(err))
		end
	end,
	defer = function(fn, ...)
		local co = coroutine.create(fn)
		local ok, err = coroutine.resume(co, ...)
		if not ok then
			recordError("[task.defer] " .. tostring(err))
			print("[task.defer error]", tostring(err))
		end
	end,
	delay = function(_t, fn, ...)
		-- Do not execute delayed work in the smoke test.
	end,
	wait = function(t)
		if coroutine.isyieldable() then
			coroutine.yield() -- abandon spawned loops at their first wait
		end
		return t or 0
	end,
	cancel = function() end,
}

-- Instances ---------------------------------------------------------------------
local PROP_TYPES = {
	BackgroundColor3 = "Color3", TextColor3 = "Color3", ImageColor3 = "Color3",
	BorderColor3 = "Color3", PlaceholderColor3 = "Color3", ScrollBarImageColor3 = "Color3",
	Color = nil, -- UIStroke.Color is Color3 but ColorSequence on UIGradient; skip strict check
	TextStrokeColor3 = "Color3",
	Size = "UDim2", Position = "UDim2", CanvasSize = "UDim2",
	AnchorPoint = "Vector2", ImageRectOffset = "Vector2", ImageRectSize = "Vector2", CanvasPosition = "Vector2",
	BackgroundTransparency = "number", TextTransparency = "number", ImageTransparency = "number",
	Transparency = "number", TextSize = "number", Rotation = "number", ZIndex = "number",
	LayoutOrder = "number", Thickness = "number",
	Visible = "boolean", Active = "boolean", ClipsDescendants = "boolean", AutoButtonColor = "boolean",
	Text = "string", PlaceholderText = "string", Image = "string", Name = "string",
}
-- Properties that may legally be assigned nil (object refs).
local NILLABLE = { Parent = true, Adornee = true, NextSelectionDown = true, NextSelectionUp = true, SelectionImageObject = true }

local KNOWN_EVENTS = {
	MouseButton1Click = true, MouseButton1Down = true, MouseButton1Up = true, MouseButton2Click = true,
	MouseButton2Down = true, MouseButton2Up = true, MouseEnter = true, MouseLeave = true, MouseMoved = true,
	MouseWheelForward = true, MouseWheelBackward = true, InputBegan = true, InputEnded = true, InputChanged = true,
	Activated = true, FocusLost = true, Focused = true, Changed = true, ChildAdded = true, ChildRemoved = true,
	AncestryChanged = true, Destroying = true, TouchTap = true, SelectionGained = true, SelectionLost = true,
	DescendantAdded = true, DescendantRemoving = true, Completed = true, Ended = true, Played = true,
	Paused = true, Loaded = true, DidLoop = true, ReturnPressedFromOnScreenKeyboard = true,
}

local READ_DEFAULTS = {
	AbsoluteSize = function() return Vector2.new(360, 586) end,
	AbsolutePosition = function() return Vector2.new(0, 0) end,
	AbsoluteWindowSize = function() return Vector2.new(360, 586) end,
	AbsoluteCanvasSize = function() return Vector2.new(360, 900) end,
	TextBounds = function() return Vector2.new(60, 14) end,
	ContentText = function() return "" end,
	CursorPosition = function() return 1 end,
	SelectionStart = function() return -1 end,
	IsLoaded = function() return true end,
	TimeLength = function() return 1 end,
	PlaybackState = function() return Enum.PlaybackState.Completed end,
	ViewportSize = function() return Vector2.new(1920, 1080) end,
}

local instanceMethods -- forward decl
local InstanceMeta

local function newInstance(className)
	local inst = {
		_class = className,
		_props = { Name = className, Visible = true, Text = "", BackgroundTransparency = 0 },
		_children = {},
		_events = {},
		_propSignals = {},
		_attributes = {},
		_destroyed = false,
	}
	setmetatable(inst, InstanceMeta)
	return inst
end

instanceMethods = {
	IsA = function(self, class)
		if class == self._class then return true end
		local generic = { Instance = true, GuiObject = true, GuiBase2d = true, GuiBase = true }
		if generic[class] then return true end
		if class == "GuiButton" then return self._class == "TextButton" or self._class == "ImageButton" end
		if class == "ScrollingFrame" then return self._class == "ScrollingFrame" end
		return false
	end,
	GetPropertyChangedSignal = function(self, prop)
		if not self._propSignals[prop] then self._propSignals[prop] = newSignal() end
		return self._propSignals[prop]
	end,
	FindFirstChild = function(self, name)
		for _, c in ipairs(self._children) do
			if c._props.Name == name then return c end
		end
		return nil
	end,
	FindFirstChildOfClass = function(self, class)
		for _, c in ipairs(self._children) do
			if c._class == class then return c end
		end
		return nil
	end,
	FindFirstAncestorOfClass = function(self, class)
		local p = self._props.Parent
		while p do
			if type(p) == "table" and p._class == class then return p end
			p = type(p) == "table" and p._props and p._props.Parent or nil
		end
		return nil
	end,
	WaitForChild = function(self, name)
		local found = self:FindFirstChild(name)
		if found then return found end
		local child = newInstance("Folder")
		child._props.Name = name
		child._props.Parent = self
		table.insert(self._children, child)
		return child
	end,
	GetChildren = function(self)
		return table.clone(self._children)
	end,
	GetDescendants = function(self)
		local out = {}
		local function walk(node)
			for _, c in ipairs(node._children) do
				table.insert(out, c)
				walk(c)
			end
		end
		walk(self)
		return out
	end,
	IsDescendantOf = function(self, ancestor)
		local p = self._props.Parent
		while p do
			if p == ancestor then return true end
			p = type(p) == "table" and p._props and p._props.Parent or nil
		end
		return false
	end,
	Destroy = function(self)
		self._destroyed = true
		local parent = self._props.Parent
		if parent and parent._children then
			for i, c in ipairs(parent._children) do
				if c == self then table.remove(parent._children, i) break end
			end
		end
		self._props.Parent = nil
	end,
	ClearAllChildren = function(self)
		self._children = {}
	end,
	Clone = function(self)
		local copy = newInstance(self._class)
		for k, v in pairs(self._props) do
			if k ~= "Parent" then copy._props[k] = v end
		end
		return copy
	end,
	GetAttribute = function(self, name) return self._attributes[name] end,
	SetAttribute = function(self, name, value) self._attributes[name] = value end,
	GetFullName = function(self) return self._props.Name end,
	CaptureFocus = function() end,
	ReleaseFocus = function() end,
	Play = function() end,
	Stop = function() end,
	Pause = function() end,
	Resume = function() end,
	Cancel = function() end,
	TweenSize = function(self, size, _d, _s, _t, _o, cb) self._props.Size = size if cb then cb() end return true end,
	TweenPosition = function(self, pos, _d, _s, _t, _o, cb) self._props.Position = pos if cb then cb() end return true end,
}

InstanceMeta = {
	__rtype = "Instance",
	__index = function(self, key)
		if instanceMethods[key] then return instanceMethods[key] end
		if KNOWN_EVENTS[key] then
			if not self._events[key] then self._events[key] = newSignal() end
			return self._events[key]
		end
		local v = self._props[key]
		if v ~= nil then return v end
		local d = READ_DEFAULTS[key]
		if d then return d() end
		-- child lookup by name
		for _, c in ipairs(self._children) do
			if c._props.Name == key then return c end
		end
		return nil
	end,
	__newindex = function(self, key, value)
		local expected = PROP_TYPES[key]
		if expected ~= nil then
			local got = mockTypeof(value)
			if got ~= expected then
				error(("'%s.%s' expected a '%s' type, but got a '%s' type."):format(self._class, key, expected, got), 2)
			end
		elseif value == nil and not NILLABLE[key] and KNOWN_EVENTS[key] == nil then
			-- Unknown property set to nil: allow (unknown props are permissive in mock)
		end
		if key == "Parent" then
			local old = self._props.Parent
			if old and old._children then
				for i, c in ipairs(old._children) do
					if c == self then table.remove(old._children, i) break end
				end
			end
			if value ~= nil and mockTypeof(value) ~= "Instance" then
				error(("'%s.Parent' expected an 'Instance' type, but got a '%s' type."):format(self._class, mockTypeof(value)), 2)
			end
			self._props.Parent = value
			if value and value._children then
				table.insert(value._children, self)
			end
		else
			self._props[key] = value
		end
		local sig = self._propSignals[key]
		if sig then sig:Fire() end
	end,
	__tostring = function(self) return self._props.Name end,
}

Instance = {
	new = function(className)
		return newInstance(className)
	end,
}

-- Services ------------------------------------------------------------------------
local function makeService(name, extra)
	local svc = newInstance(name)
	for k, v in pairs(extra or {}) do
		rawget(svc, "_props")[k] = v
	end
	return svc
end

local RunService = makeService("RunService")
RunService._props.Heartbeat = newSignal()
RunService._props.RenderStepped = newSignal()
RunService._props.PostSimulation = newSignal()
RunService._props.PreRender = newSignal()
rawset(RunService, "IsStudio", function() return false end)
rawset(RunService, "IsRunning", function() return true end)
rawset(RunService, "IsClient", function() return true end)
-- rawset places them on the table itself; __index checks methods first, so route through _props instead:
RunService._props.IsStudio = function() return false end
RunService._props.IsRunning = function() return true end
RunService._props.IsClient = function() return true end
RunService._props.BindToRenderStep = function() end
RunService._props.UnbindFromRenderStep = function() end

local UserInputService = makeService("UserInputService")
UserInputService._props.InputBegan = newSignal()
UserInputService._props.InputEnded = newSignal()
UserInputService._props.InputChanged = newSignal()
UserInputService._props.LastInputTypeChanged = newSignal()
UserInputService._props.TextBoxFocused = newSignal()
UserInputService._props.TextBoxFocusReleased = newSignal()
UserInputService._props.MouseEnabled = true
UserInputService._props.TouchEnabled = false
UserInputService._props.KeyboardEnabled = true
UserInputService._props.GamepadEnabled = false
UserInputService._props.IsKeyDown = function() return false end
UserInputService._props.GetMouseLocation = function() return Vector2.new(180, 290) end
UserInputService._props.GetLastInputType = function() return Enum.UserInputType.MouseMovement end
UserInputService._props.GetFocusedTextBox = function() return nil end

local TweenService = makeService("TweenService")
TweenService._props.Create = function(_, instance, _info, goal)
	local tween = newInstance("Tween")
	tween._props.Completed = newSignal()
	tween._props.Play = function()
		for prop, v in pairs(goal or {}) do
			instance[prop] = v
		end
		tween._props.Completed:Fire(Enum.PlaybackState.Completed)
	end
	tween._props.Cancel = function() end
	tween._props.Pause = function() end
	return tween
end
TweenService._props.GetValue = function(_, alpha) return alpha end

local HttpService = makeService("HttpService")
HttpService._props.GenerateGUID = function() return "MOCK-GUID" end
HttpService._props.JSONEncode = function(_, data)
	local function enc(v)
		local t = type(v)
		if t == "table" then
			local isArray = #v > 0
			local parts = {}
			if isArray then
				for _, item in ipairs(v) do table.insert(parts, enc(item)) end
				return "[" .. table.concat(parts, ",") .. "]"
			end
			for k, item in pairs(v) do
				table.insert(parts, string.format("%q", tostring(k)) .. ":" .. enc(item))
			end
			return "{" .. table.concat(parts, ",") .. "}"
		elseif t == "string" then return string.format("%q", v)
		elseif t == "number" or t == "boolean" then return tostring(v)
		else return "null" end
	end
	return enc(data)
end
HttpService._props.JSONDecode = function(_, _s) return {} end

local SoundService = makeService("SoundService")
SoundService._props.PlayLocalSound = function() end

local GuiService = makeService("GuiService")
GuiService._props.GetGuiInset = function() return Vector2.new(0, 36), Vector2.zero end

local TextService = makeService("TextService")
TextService._props.GetTextSize = function(_, text) return Vector2.new(#tostring(text) * 7, 14) end

local CoreGui = makeService("CoreGui")
local Lighting = makeService("Lighting")
local ContextActionService = makeService("ContextActionService")
ContextActionService._props.BindAction = function() end
ContextActionService._props.UnbindAction = function() end

local Players = makeService("Players")
local localPlayer = newInstance("Player")
localPlayer._props.Name = "MockPlayer"
localPlayer._props.UserId = 1
local playerGui = newInstance("PlayerGui")
playerGui._props.Name = "PlayerGui"
playerGui._props.Parent = localPlayer
table.insert(localPlayer._children, playerGui)
Players._props.LocalPlayer = localPlayer
Players._props.GetUserThumbnailAsync = function() return "rbxasset://mock", true end

local services = {
	RunService = RunService,
	UserInputService = UserInputService,
	TweenService = TweenService,
	HttpService = HttpService,
	SoundService = SoundService,
	GuiService = GuiService,
	TextService = TextService,
	CoreGui = CoreGui,
	Lighting = Lighting,
	Players = Players,
	ContextActionService = ContextActionService,
}

game = newInstance("DataModel")
game._props.Name = "game"
game._props.GetService = function(_, name)
	if not services[name] then
		services[name] = makeService(name)
	end
	return services[name]
end
game._props.HttpGet = function() error("HttpGet not available in smoke test") end

-- workspace + camera
workspace = newInstance("Workspace")
local camera = newInstance("Camera")
camera._props.ViewportSize = Vector2.new(1920, 1080)
workspace._props.CurrentCamera = camera
workspace._props.Parent = game
table.insert(game._children, workspace)
CoreGui._props.Parent = game
table.insert(game._children, CoreGui)

-- Expose error log for the driver
_MOCK_ERRORS = ERRORS

return true
