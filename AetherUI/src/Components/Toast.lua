--!strict
--[=[
	AetherUI · Toast / Notification system
	Stacking notifications with variants (info, success, warning, error),
	progress countdown bar, actions, and slide-in/out springs.

		AetherUI.Toast.success({ Title = "Saved", Description = "Settings updated." })
]=]

local Fusion = require(script.Parent.Parent.Core.Fusion)
local Theme = require(script.Parent.Parent.Core.Theme)
local Icons = require(script.Parent.Parent.Core.Icons)
local Sound = require(script.Parent.Parent.Core.Sound)
local Overlay = require(script.Parent.Parent.Core.Overlay)

local New = Fusion.New
local Children = Fusion.Children
local Value = Fusion.Value
local Computed = Fusion.Computed
local OnEvent = Fusion.OnEvent
local Spring = Fusion.Spring

local TweenService = game:GetService("TweenService")

export type ToastOptions = {
	Title: string,
	Description: string?,
	Duration: number?,
	Icon: string?,
	Action: { Label: string, OnClick: () -> () }?,
	Position: ("bottom-right" | "top-right" | "bottom-left" | "top-left")?,
}

type ToastVariant = "info" | "success" | "warning" | "error"

local Toast = {}

local WIDTH = 320
local MAX_VISIBLE = 5

local containerCache: { [string]: Frame } = {}

local VARIANT_META: { [ToastVariant]: { Icon: string, ColorKey: string } } = {
	info = { Icon = "info", ColorKey = "Primary" },
	success = { Icon = "circle-check", ColorKey = "Success" },
	warning = { Icon = "triangle-alert", ColorKey = "Warning" },
	error = { Icon = "circle-x", ColorKey = "Danger" },
}

local function getContainer(position: string): Frame
	local cached = containerCache[position]
	if cached and cached.Parent then
		return cached
	end
	local layer = Overlay.getLayer("Toasts", 200)

	local bottom = string.find(position, "bottom") ~= nil
	local right = string.find(position, "right") ~= nil

	local container = New("Frame")({
		Name = "ToastStack_" .. position,
		AnchorPoint = Vector2.new(right and 1 or 0, bottom and 1 or 0),
		Position = UDim2.new(right and 1 or 0, right and -16 or 16, bottom and 1 or 0, bottom and -16 or 16),
		Size = UDim2.fromOffset(WIDTH, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Parent = layer,
		[Children] = {
			New("UIListLayout")({
				FillDirection = Enum.FillDirection.Vertical,
				Padding = UDim.new(0, 8),
				SortOrder = Enum.SortOrder.LayoutOrder,
				VerticalAlignment = bottom and Enum.VerticalAlignment.Bottom or Enum.VerticalAlignment.Top,
			}),
		},
	}) :: Frame
	containerCache[position] = container
	return container
end

local toastCounter = 0

local function show(variant: ToastVariant, options: ToastOptions)
	local theme = Theme.Current
	local meta = VARIANT_META[variant]
	local position = options.Position or "bottom-right"
	local container = getContainer(position)
	local duration = options.Duration or 4

	-- Cull overflow
	local existing = {}
	for _, child in ipairs(container:GetChildren()) do
		if child:IsA("Frame") then
			table.insert(existing, child)
		end
	end
	if #existing >= MAX_VISIBLE then
		table.sort(existing, function(a, b)
			return a.LayoutOrder < b.LayoutOrder
		end)
		existing[1]:Destroy()
	end

	toastCounter += 1
	local visible = Value(false)
	local hovered = Value(false)
	local dismissed = false

	local accent = Computed(function()
		return (theme:get() :: any)[meta.ColorKey] :: Color3
	end)

	local bodyChildren: { Instance } = {
		New("UIListLayout")({
			FillDirection = Enum.FillDirection.Vertical,
			Padding = UDim.new(0, 3),
		}),
		New("TextLabel")({
			Size = UDim2.new(1, 0, 0, 16),
			BackgroundTransparency = 1,
			Text = options.Title,
			Font = Enum.Font.GothamBold,
			TextSize = 13,
			TextColor3 = Computed(function()
				return theme:get().Text
			end),
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
		}),
	}

	if options.Description then
		table.insert(bodyChildren, New("TextLabel")({
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			Text = options.Description,
			Font = Enum.Font.Gotham,
			TextSize = 12,
			TextWrapped = true,
			TextColor3 = Computed(function()
				return theme:get().TextMuted
			end),
			TextXAlignment = Enum.TextXAlignment.Left,
		}))
	end

	if options.Action then
		table.insert(bodyChildren, New("TextButton")({
			AutomaticSize = Enum.AutomaticSize.XY,
			BackgroundTransparency = 1,
			Text = options.Action.Label,
			Font = Enum.Font.GothamBold,
			TextSize = 12,
			TextColor3 = accent,
			[OnEvent("Activated")] = options.Action.OnClick,
		}))
	end

	local progressBar = New("Frame")({
		Name = "Progress",
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.new(1, 0, 0, 2),
		BackgroundColor3 = accent,
		BorderSizePixel = 0,
		ZIndex = 3,
	}) :: Frame

	local frame: Frame
	local function dismiss()
		if dismissed then
			return
		end
		dismissed = true
		visible:set(false)
		task.delay(0.3, function()
			frame:Destroy()
		end)
	end

	frame = New("Frame")({
		Name = "Toast_" .. toastCounter,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = toastCounter,
		BackgroundColor3 = Computed(function()
			return theme:get().Surface
		end),
		BackgroundTransparency = Spring(Computed(function()
			return Fusion.peek(visible) and 0 or 1
		end), 30, 1),
		Parent = container,
		ClipsDescendants = true,
		[OnEvent("MouseEnter")] = function()
			hovered:set(true)
		end,
		[OnEvent("MouseLeave")] = function()
			hovered:set(false)
		end,
		[Children] = {
			New("UICorner")({ CornerRadius = Computed(function()
				return UDim.new(0, theme:get().RadiusMd)
			end) }),
			New("UIStroke")({
				Color = Computed(function()
					return theme:get().Border
				end),
				Thickness = 1,
			}),
			New("Frame")({
				Name = "Content",
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				[Children] = {
					New("UIPadding")({
						PaddingLeft = UDim.new(0, 12),
						PaddingRight = UDim.new(0, 12),
						PaddingTop = UDim.new(0, 12),
						PaddingBottom = UDim.new(0, 12),
					}),
					New("UIListLayout")({
						FillDirection = Enum.FillDirection.Horizontal,
						Padding = UDim.new(0, 10),
						VerticalAlignment = Enum.VerticalAlignment.Top,
					}),
					Icons.render(options.Icon or meta.Icon, {
						Size = UDim2.fromOffset(16, 16),
						LayoutOrder = 1,
						Color = accent,
					}),
					New("Frame")({
						Size = UDim2.new(1, -56, 0, 0),
						AutomaticSize = Enum.AutomaticSize.Y,
						BackgroundTransparency = 1,
						LayoutOrder = 2,
						[Children] = bodyChildren,
					}),
					New("TextButton")({
						Size = UDim2.fromOffset(18, 18),
						BackgroundTransparency = 1,
						Text = "",
						LayoutOrder = 3,
						[OnEvent("Activated")] = dismiss,
						[Children] = {
							Icons.render("x", {
								Size = UDim2.fromOffset(13, 13),
								Position = UDim2.fromScale(0.5, 0.5),
								AnchorPoint = Vector2.new(0.5, 0.5),
								Color = Computed(function()
									return theme:get().TextMuted
								end),
							}),
						},
					}),
				},
			}),
			progressBar,
		},
	}) :: Frame

	Sound.play(variant == "error" and "Error" or (variant == "success" and "Success" or "Open"))
	task.defer(function()
		visible:set(true)
	end)

	-- Countdown with pause-on-hover
	task.spawn(function()
		local remaining = duration
		local tween = TweenService:Create(progressBar, TweenInfo.new(0.1, Enum.EasingStyle.Linear), {})
		local _ = tween
		while remaining > 0 and not dismissed do
			task.wait(0.05)
			if not Fusion.peek(hovered) then
				remaining -= 0.05
				progressBar.Size = UDim2.new(math.max(remaining / duration, 0), 0, 0, 2)
			end
		end
		dismiss()
	end)

	return { Dismiss = dismiss }
end

function Toast.info(options: ToastOptions)
	return show("info", options)
end
function Toast.success(options: ToastOptions)
	return show("success", options)
end
function Toast.warning(options: ToastOptions)
	return show("warning", options)
end
function Toast.error(options: ToastOptions)
	return show("error", options)
end
--- Generic entry point: Toast.show("success", { ... })
function Toast.show(variant: ToastVariant, options: ToastOptions)
	return show(variant, options)
end

-- PascalCase conveniences: accept either a title string or a full options table.
--   Toast.Success("Saved!")
--   Toast.Success("Saved!", { Description = "All changes stored." })
--   Toast.Success({ Title = "Saved!", Duration = 5 })
local function coerce(titleOrOptions: string | ToastOptions, options: ToastOptions?): ToastOptions
	if type(titleOrOptions) == "string" then
		local opts = if options then table.clone(options) else {}
		opts.Title = titleOrOptions
		return opts
	end
	return titleOrOptions
end

function Toast.Info(titleOrOptions: string | ToastOptions, options: ToastOptions?)
	return show("info", coerce(titleOrOptions, options))
end
function Toast.Success(titleOrOptions: string | ToastOptions, options: ToastOptions?)
	return show("success", coerce(titleOrOptions, options))
end
function Toast.Warning(titleOrOptions: string | ToastOptions, options: ToastOptions?)
	return show("warning", coerce(titleOrOptions, options))
end
function Toast.Error(titleOrOptions: string | ToastOptions, options: ToastOptions?)
	return show("error", coerce(titleOrOptions, options))
end
function Toast.Show(variant: ToastVariant, titleOrOptions: string | ToastOptions, options: ToastOptions?)
	return show(variant, coerce(titleOrOptions, options))
end

return Toast
