--!strict
--[[
	AetherUI • Components/Badge

	Badge(props)          pill label with semantic variants + optional icon/dot
	Badge.Avatar(props)   image or initials avatar with ring + status dot
	Badge.Status(props)   pulsing status indicator with optional label

	Badge props:
		Text: string          Variant: "Default"|"Primary"|"Success"|"Warning"|"Danger"|"Info"|"Outline"
		Icon: string?         Dot: boolean?      Size: "Sm"|"Md"?
	Avatar props:
		Image: string?        Name: string?      Size: number? (px)
		Status: "Online"|"Idle"|"Busy"|"Offline"?   Ring: boolean?
	Status props:
		Status: same as above    Label: string?    Pulse: boolean?
]]

local Fusion = require(script.Parent.Parent.Core.Fusion)
local Theme = require(script.Parent.Parent.Core.Theme)
local Utils = require(script.Parent.Parent.Core.Utils)
local Primitives = require(script.Parent.Primitives)

local New = Fusion.New
local Children = Fusion.Children
local Computed = Fusion.Computed
local Value = Fusion.Value
local Spring = Fusion.Spring

local Badge = {}

-- Variant -> { fg token, mix ratio for bg } -----------------------------------

local VARIANT_TOKENS: { [string]: string } = {
	Default = "TextMuted",
	Primary = "Primary",
	Success = "Success",
	Warning = "Warning",
	Danger = "Danger",
	Info = "Info",
	Outline = "TextMuted",
}

local function fgColor(variant: string)
	local token = VARIANT_TOKENS[variant] or "TextMuted"
	return Computed(function()
		return Theme.Colors[token]:get()
	end)
end

local function bgColor(variant: string)
	local token = VARIANT_TOKENS[variant] or "TextMuted"
	return Computed(function()
		if variant == "Default" then
			return Theme.Colors.SurfaceHigh:get()
		end
		-- Tint: 15% accent over surface.
		local accent: Color3 = Theme.Colors[token]:get()
		local surface: Color3 = Theme.Colors.Surface:get()
		return surface:Lerp(accent, 0.15)
	end)
end

-- Badge ------------------------------------------------------------------------

function Badge.new(props: { [string]: any }): Frame
	local variant: string = props.Variant or "Default"
	local size: string = props.Size or "Md"
	local height = if size == "Sm" then 18 else 22
	local textSize = if size == "Sm" then 10 else 11
	local fg = fgColor(variant)

	local content: { any } = {
		Primitives.Corner("Full"),
		Primitives.Stroke({
			Color = if variant == "Outline" then nil else fg,
			Transparency = if variant == "Outline" then nil else 0.75,
		}),
		Primitives.Padding({ Left = if props.Dot or props.Icon then 8 else 10, Right = 10 }),
		Primitives.List({ Direction = "Horizontal", Padding = 5, VerticalAlignment = Enum.VerticalAlignment.Center }),
	}

	if props.Dot then
		table.insert(content, New("Frame")({
			Name = "Dot",
			Size = UDim2.fromOffset(6, 6),
			BackgroundColor3 = fg,
			LayoutOrder = 1,
			[Children] = { Primitives.Corner("Full") },
		}))
	elseif props.Icon then
		table.insert(content, Primitives.Icon({
			Name = props.Icon,
			Size = 12,
			Color = fg,
			LayoutOrder = 1,
		}))
	end

	table.insert(content, Primitives.Text({
		Text = props.Text or "",
		Size = textSize,
		Color = fg,
		Bold = true,
		LayoutOrder = 2,
	}))

	return New("Frame")({
		Name = "AetherBadge",
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.fromOffset(0, height),
		BackgroundColor3 = bgColor(variant),
		BackgroundTransparency = if variant == "Outline" then 1 else 0,
		LayoutOrder = props.LayoutOrder,
		Position = props.Position,
		AnchorPoint = props.AnchorPoint,
		Parent = props.Parent,
		[Children] = content,
	})
end

-- Status color helper ------------------------------------------------------------

local STATUS_TOKENS: { [string]: string } = {
	Online = "Success",
	Idle = "Warning",
	Busy = "Danger",
	Offline = "TextDim",
}

local function statusColor(status: string)
	local token = STATUS_TOKENS[status] or "TextDim"
	return Computed(function()
		return Theme.Colors[token]:get()
	end)
end

-- Avatar ------------------------------------------------------------------------

local function initialsOf(name: string): string
	local parts = string.split(name, " ")
	local first = string.sub(parts[1] or "?", 1, 1)
	local second = if #parts > 1 then string.sub(parts[#parts], 1, 1) else ""
	return string.upper(first .. second)
end

function Badge.Avatar(props: { [string]: any }): Frame
	local px: number = props.Size or 36

	local inner: Instance
	if props.Image then
		inner = New("ImageLabel")({
			Name = "Image",
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = Computed(function()
				return Theme.Colors.SurfaceHigh:get()
			end),
			Image = props.Image,
			ScaleType = Enum.ScaleType.Crop,
			[Children] = { Primitives.Corner("Full") },
		})
	else
		inner = New("TextLabel")({
			Name = "Initials",
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = Computed(function()
				return Theme.Colors.Surface:get():Lerp(Theme.Colors.Primary:get(), 0.2)
			end),
			Text = initialsOf(props.Name or "?"),
			TextSize = math.max(10, math.floor(px * 0.36)),
			FontFace = Computed(function()
				return Theme.Fonts.Heading:get()
			end),
			TextColor3 = Computed(function()
				return Theme.Colors.Primary:get()
			end),
			[Children] = { Primitives.Corner("Full") },
		})
	end

	local content: { any } = { inner }

	if props.Ring then
		table.insert(content, New("UIStroke")({
			Color = Computed(function()
				return Theme.Colors.Primary:get()
			end),
			Thickness = 2,
			Transparency = 0.25,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		}))
	end

	if props.Status then
		local dotPx = math.max(8, math.floor(px * 0.28))
		table.insert(content, New("Frame")({
			Name = "StatusDot",
			Size = UDim2.fromOffset(dotPx, dotPx),
			Position = UDim2.new(1, -dotPx + 1, 1, -dotPx + 1),
			BackgroundColor3 = statusColor(props.Status),
			ZIndex = 2,
			[Children] = {
				Primitives.Corner("Full"),
				New("UIStroke")({
					Color = Computed(function()
						return Theme.Colors.Surface:get()
					end),
					Thickness = 2,
					ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				}),
			},
		}))
	end

	return New("Frame")({
		Name = "AetherAvatar",
		Size = UDim2.fromOffset(px, px),
		BackgroundTransparency = 1,
		LayoutOrder = props.LayoutOrder,
		Position = props.Position,
		AnchorPoint = props.AnchorPoint,
		Parent = props.Parent,
		[Children] = content,
	})
end

-- StatusIndicator ------------------------------------------------------------------

function Badge.Status(props: { [string]: any }): Frame
	local pulseScale = Value(1)

	local dot = New("Frame")({
		Name = "Dot",
		Size = UDim2.fromOffset(8, 8),
		BackgroundColor3 = statusColor(props.Status or "Offline"),
		LayoutOrder = 1,
		[Children] = {
			Primitives.Corner("Full"),
			New("UIScale")({
				Scale = Spring(pulseScale, 8, 0.6),
			}),
		},
	})

	if props.Pulse and props.Status ~= "Offline" then
		task.spawn(function()
			task.wait() -- allow one frame for mounting
			while dot:IsDescendantOf(game) do
				pulseScale:set(1.25)
				task.wait(0.9)
				pulseScale:set(1)
				task.wait(0.9)
			end
		end)
	end

	local content: { any } = {
		Primitives.List({ Direction = "Horizontal", Padding = 6, VerticalAlignment = Enum.VerticalAlignment.Center }),
		dot,
	}

	if props.Label then
		table.insert(content, Primitives.Text({
			Text = props.Label,
			Size = 12,
			Muted = true,
			LayoutOrder = 2,
		}))
	end

	return New("Frame")({
		Name = "AetherStatus",
		AutomaticSize = Enum.AutomaticSize.XY,
		BackgroundTransparency = 1,
		LayoutOrder = props.LayoutOrder,
		Position = props.Position,
		AnchorPoint = props.AnchorPoint,
		Parent = props.Parent,
		[Children] = content,
	})
end

local _ = Utils -- reserved for future color utilities

setmetatable(Badge, {
	__call = function(_, props)
		return Badge.new(props)
	end,
})

return Badge
