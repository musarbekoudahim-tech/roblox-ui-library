--!strict
--[[
	AetherUI • Components/CommandPalette

	Linear/Raycast-style command palette. Fuzzy search, keyboard navigation,
	grouped commands, shortcut hints. Opens as a centered overlay.

	Usage:
		local palette = CommandPalette({
			Commands = {
				{ Id = "theme", Label = "Toggle theme", Icon = "moon", Group = "General",
				  Shortcut = "Ctrl T", Run = function() ... end },
			},
		})
		palette.Open()          -- or bind to a keybind (Ctrl+K is registered by default)
		palette.Close()
		palette.Destroy()
]]

local UserInputService = game:GetService("UserInputService")

local Fusion = require(script.Parent.Parent.Core.Fusion)
local Theme = require(script.Parent.Parent.Core.Theme)
local Overlay = require(script.Parent.Parent.Core.Overlay)
local Keybinds = require(script.Parent.Parent.Core.Keybinds)
local Sound = require(script.Parent.Parent.Core.Sound)
local Primitives = require(script.Parent.Primitives)

local New = Fusion.New
local Children = Fusion.Children
local Computed = Fusion.Computed
local Value = Fusion.Value
local ForValues = Fusion.ForValues
local OnEvent = Fusion.OnEvent
local Tween = Fusion.Tween
local Spring = Fusion.Spring

local WIDTH = 560
local ROW = 44
local MAX_VISIBLE = 8

-- Simple subsequence fuzzy match with scoring (lower = better).
local function fuzzyScore(query: string, target: string): number?
	query = string.lower(query)
	target = string.lower(target)
	if query == "" then
		return 0
	end
	local qi = 1
	local score = 0
	local lastMatch = 0
	for ti = 1, #target do
		if qi > #query then
			break
		end
		if string.sub(target, ti, ti) == string.sub(query, qi, qi) then
			score += if lastMatch > 0 then (ti - lastMatch - 1) else ti - 1
			lastMatch = ti
			qi += 1
		end
	end
	if qi <= #query then
		return nil -- not all query chars matched
	end
	return score
end

return function(props: { [string]: any })
	local commands: { { [string]: any } } = props.Commands or {}

	local open = Value(false)
	local query = Value("")
	local highlighted = Value(1)

	local results = Computed(function()
		local q = query:get()
		local scored = {}
		for _, cmd in commands do
			local score = fuzzyScore(q, cmd.Label .. " " .. (cmd.Group or ""))
			if score ~= nil then
				table.insert(scored, { Score = score, Cmd = cmd })
			end
		end
		table.sort(scored, function(a, b)
			return a.Score < b.Score
		end)
		local out = {}
		for i, entry in scored do
			entry.Cmd.__order = i
			table.insert(out, entry.Cmd)
		end
		return out
	end)

	local function close()
		open:set(false)
		query:set("")
		highlighted:set(1)
	end

	local function runHighlighted()
		local list = results:get()
		local cmd = list[highlighted:get()]
		if cmd then
			close()
			Sound.Play("Success")
			if cmd.Run then
				cmd.Run()
			end
		end
	end

	-- Input box ------------------------------------------------------------------

	local inputBox: TextBox

	inputBox = New("TextBox")({
		Name = "Query",
		Size = UDim2.new(1, -44, 1, 0),
		Position = UDim2.fromOffset(40, 0),
		BackgroundTransparency = 1,
		PlaceholderText = props.Placeholder or "Type a command or search...",
		PlaceholderColor3 = Computed(function()
			return Theme.Colors.TextDim:get()
		end),
		Text = "",
		TextSize = 15,
		FontFace = Computed(function()
			return Theme.Fonts.Body:get()
		end),
		TextColor3 = Computed(function()
			return Theme.Colors.Text:get()
		end),
		TextXAlignment = Enum.TextXAlignment.Left,
		ClearTextOnFocus = false,
	}) :: TextBox

	inputBox:GetPropertyChangedSignal("Text"):Connect(function()
		query:set(inputBox.Text)
		highlighted:set(1)
	end)

	-- Rows -----------------------------------------------------------------------------

	local listFrame = New("ScrollingFrame")({
		Name = "Results",
		Size = Computed(function()
			local count = math.min(#results:get(), MAX_VISIBLE)
			return UDim2.new(1, 0, 0, math.max(count, 1) * ROW)
		end),
		CanvasSize = Computed(function()
			return UDim2.new(0, 0, 0, #results:get() * ROW)
		end),
		BackgroundTransparency = 1,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = Computed(function()
			return Theme.Colors.Border:get()
		end),
		BorderSizePixel = 0,
		LayoutOrder = 3,
		[Children] = {
			New("UIListLayout")({ SortOrder = Enum.SortOrder.LayoutOrder }),
			ForValues(results, function(cmd: { [string]: any })
				local index = cmd.__order :: number
				local isHighlighted = Computed(function()
					return highlighted:get() == index
				end)

				local rowContent: { any } = {
					Primitives.Padding({ Left = 14, Right = 14 }),
					Primitives.List({ Direction = "Horizontal", Padding = 10, VerticalAlignment = Enum.VerticalAlignment.Center }),
				}

				if cmd.Icon then
					table.insert(rowContent, Primitives.Icon({
						Name = cmd.Icon,
						Size = 16,
						Color = Computed(function()
							return if isHighlighted:get()
								then Theme.Colors.Primary:get()
								else Theme.Colors.TextMuted:get()
						end),
						LayoutOrder = 1,
					}))
				end

				table.insert(rowContent, Primitives.Text({
					Text = cmd.Label,
					Size = 13,
					Color = Computed(function()
						return if isHighlighted:get()
							then Theme.Colors.Text:get()
							else Theme.Colors.TextMuted:get()
					end),
					LayoutOrder = 2,
				}))

				if cmd.Group then
					table.insert(rowContent, Primitives.Text({
						Text = cmd.Group,
						Size = 11,
						Muted = true,
						LayoutOrder = 3,
					}))
				end

				if cmd.Shortcut then
					table.insert(rowContent, New("Frame")({
						Name = "Shortcut",
						AutomaticSize = Enum.AutomaticSize.XY,
						BackgroundColor3 = Computed(function()
							return Theme.Colors.SurfaceHigh:get()
						end),
						LayoutOrder = 4,
						[Children] = {
							Primitives.Corner("Sm"),
							Primitives.Padding({ X = 6, Y = 3 }),
							Primitives.Text({
								Text = cmd.Shortcut,
								Size = 10,
								Font = "Mono",
								Muted = true,
							}),
						},
					}))
				end

				return New("TextButton")({
					Name = "Cmd_" .. (cmd.Id or index),
					Size = UDim2.new(1, 0, 0, ROW),
					BackgroundColor3 = Computed(function()
						return Theme.Colors.SurfaceHover:get()
					end),
					BackgroundTransparency = Computed(function()
						return if isHighlighted:get() then 0.3 else 1
					end),
					Text = "",
					AutoButtonColor = false,
					LayoutOrder = index,
					[OnEvent("MouseEnter")] = function()
						highlighted:set(index)
					end,
					[OnEvent("Activated")] = function()
						highlighted:set(index)
						runHighlighted()
					end,
					[Children] = rowContent,
				})
			end, Fusion.cleanup),
		},
	})

	-- Panel ----------------------------------------------------------------------------------

	local panelScale = Computed(function()
		return if open:get() then 1 else 0.96
	end)

	local panel = New("Frame")({
		Name = "Panel",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0.22, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.fromOffset(WIDTH, 0),
		BackgroundColor3 = Computed(function()
			return Theme.Colors.Surface:get()
		end),
		ZIndex = 100,
		[Children] = {
			Primitives.Corner("Xl"),
			Primitives.Stroke(),
			Primitives.Shadow({ Size = 40 }),
			New("UIScale")({ Scale = Spring(panelScale, 30, 0.9) }),
			New("UIListLayout")({ SortOrder = Enum.SortOrder.LayoutOrder }),
			-- Search row
			New("Frame")({
				Name = "SearchRow",
				Size = UDim2.new(1, 0, 0, 52),
				BackgroundTransparency = 1,
				LayoutOrder = 1,
				[Children] = {
					Primitives.Padding({ Left = 16, Right = 16 }),
					Primitives.Icon({
						Name = "search",
						Size = 16,
						Color = Computed(function()
							return Theme.Colors.TextMuted:get()
						end),
						Position = UDim2.new(0, 0, 0.5, 0),
						AnchorPoint = Vector2.new(0, 0.5),
					}),
					inputBox,
				},
			}),
			New("Frame")({
				Name = "Divider",
				Size = UDim2.new(1, 0, 0, 1),
				BackgroundColor3 = Computed(function()
					return Theme.Colors.Border:get()
				end),
				BorderSizePixel = 0,
				LayoutOrder = 2,
			}),
			listFrame,
			-- Footer hints
			New("Frame")({
				Name = "Hints",
				Size = UDim2.new(1, 0, 0, 34),
				BackgroundTransparency = 1,
				LayoutOrder = 4,
				[Children] = {
					Primitives.Padding({ X = 14 }),
					Primitives.List({ Direction = "Horizontal", Padding = 14, VerticalAlignment = Enum.VerticalAlignment.Center }),
					Primitives.Text({ Text = "↑↓ Navigate", Size = 10, Muted = true, LayoutOrder = 1 }),
					Primitives.Text({ Text = "↵ Run", Size = 10, Muted = true, LayoutOrder = 2 }),
					Primitives.Text({ Text = "Esc Close", Size = 10, Muted = true, LayoutOrder = 3 }),
				},
			}),
		},
	})

	-- Backdrop + mount -----------------------------------------------------------------------

	local backdrop = New("TextButton")({
		Name = "AetherCommandPalette",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = Tween(
			Computed(function()
				return if open:get() then 0.45 else 1
			end),
			TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		),
		Text = "",
		AutoButtonColor = false,
		Visible = open,
		ZIndex = 99,
		[OnEvent("Activated")] = function()
			close()
		end,
		[Children] = { panel },
	})

	backdrop.Parent = Overlay.getLayer("Palette", 400)

	-- Keyboard navigation ---------------------------------------------------------------------

	local navConnection = UserInputService.InputBegan:Connect(function(input, _processed)
		if not open:get() then
			return
		end
		if input.KeyCode == Enum.KeyCode.Down then
			highlighted:set(math.min(highlighted:get() + 1, #results:get()))
		elseif input.KeyCode == Enum.KeyCode.Up then
			highlighted:set(math.max(highlighted:get() - 1, 1))
		elseif input.KeyCode == Enum.KeyCode.Return then
			runHighlighted()
		elseif input.KeyCode == Enum.KeyCode.Escape then
			close()
		end
	end)

	-- Default hotkey: Ctrl+K
	local hotkeyId = "AetherUI_CommandPalette_" .. tostring(math.random(1, 1e9))
	if props.Hotkey ~= false then
		Keybinds.Register(hotkeyId, {
			Key = props.Hotkey or Enum.KeyCode.K,
			Modifiers = { "Ctrl" },
			Callback = function()
				open:set(not open:get())
				if open:get() then
					task.defer(function()
						inputBox:CaptureFocus()
					end)
				end
			end,
		})
	end

	-- Public API --------------------------------------------------------------------------------

	local api = {}

	function api.Open()
		open:set(true)
		Sound.Play("Open")
		task.defer(function()
			inputBox:CaptureFocus()
		end)
	end

	function api.Close()
		close()
	end

	api.IsOpen = open

	function api.Destroy()
		navConnection:Disconnect()
		if props.Hotkey ~= false then
			Keybinds.Unregister(hotkeyId)
		end
		backdrop:Destroy()
	end

	return api
end
