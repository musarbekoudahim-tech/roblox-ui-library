--!strict
--[[
	AetherUI • Components/DatePicker

	Calendar month grid with year/month navigation.

	props:
		Value: { Year: number, Month: number, Day: number }?   (defaults to today)
		OnChanged: ((date: { Year: number, Month: number, Day: number }) -> ())?
		LayoutOrder: number?    Parent: Instance?
]]

local Fusion = require(script.Parent.Parent.Core.Fusion)
local Theme = require(script.Parent.Parent.Core.Theme)
local Primitives = require(script.Parent.Primitives)
local Button = require(script.Parent.Button)

local New = Fusion.New
local Children = Fusion.Children
local Computed = Fusion.Computed
local Value = Fusion.Value
local ForValues = Fusion.ForValues
local OnEvent = Fusion.OnEvent

local MONTHS = {
	"January", "February", "March", "April", "May", "June",
	"July", "August", "September", "October", "November", "December",
}
local WEEKDAYS = { "Su", "Mo", "Tu", "We", "Th", "Fr", "Sa" }

local CELL = 34
local GRID_PAD = 12

local function daysInMonth(year: number, month: number): number
	local next = os.time({ year = if month == 12 then year + 1 else year, month = if month == 12 then 1 else month + 1, day = 1 }) - 86400
	return tonumber(os.date("%d", next)) :: number
end

local function firstWeekday(year: number, month: number): number
	-- 1 = Sunday
	return tonumber(os.date("%w", os.time({ year = year, month = month, day = 1 }))) :: number + 1
end

return function(props: { [string]: any }): Frame
	local today = os.date("*t")
	local initial = props.Value or { Year = today.year, Month = today.month, Day = today.day }

	local viewYear = Value(initial.Year)
	local viewMonth = Value(initial.Month)
	local selected = Value(initial)

	local function shiftMonth(delta: number)
		local m = viewMonth:get() + delta
		local y = viewYear:get()
		if m < 1 then
			m, y = 12, y - 1
		elseif m > 12 then
			m, y = 1, y + 1
		end
		viewMonth:set(m)
		viewYear:set(y)
	end

	-- Day cells for the visible month --------------------------------------------

	local cells = Computed(function()
		local year = viewYear:get()
		local month = viewMonth:get()
		local offset = firstWeekday(year, month) - 1
		local total = daysInMonth(year, month)
		local out = {}
		for day = 1, total do
			local slot = offset + day - 1
			table.insert(out, {
				Day = day,
				Column = slot % 7,
				Row = math.floor(slot / 7),
			})
		end
		return out
	end)

	local rowCount = Computed(function()
		local list = cells:get()
		local last = list[#list]
		return if last then last.Row + 1 else 5
	end)

	-- Header ------------------------------------------------------------------------

	local header = New("Frame")({
		Name = "Header",
		Size = UDim2.new(1, 0, 0, 44),
		BackgroundTransparency = 1,
		LayoutOrder = 1,
		[Children] = {
			Primitives.Padding({ X = 8 }),
			Button({
				Icon = "chevron-left",
				Variant = "Ghost",
				Size = "Sm",
				Props = { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0) },
				OnClick = function()
					shiftMonth(-1)
				end,
			}),
			Primitives.Text({
				Text = Computed(function()
					return `{MONTHS[viewMonth:get()]} {viewYear:get()}`
				end),
				Size = 14,
				Bold = true,
				Props = {
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(0.5, 0.5),
				},
			}),
			Button({
				Icon = "chevron-right",
				Variant = "Ghost",
				Size = "Sm",
				Props = { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0) },
				OnClick = function()
					shiftMonth(1)
				end,
			}),
		},
	})

	-- Weekday labels -------------------------------------------------------------------

	local weekdayLabels: { any } = {}
	for i, wd in WEEKDAYS do
		table.insert(weekdayLabels, Primitives.Text({
			Text = wd,
			Size = 10,
			Muted = true,
			Props = {
				Size = UDim2.fromOffset(CELL, 16),
				Position = UDim2.fromOffset(GRID_PAD + (i - 1) * CELL, 0),
				TextXAlignment = Enum.TextXAlignment.Center,
			},
		}))
	end

	local weekdayRow = New("Frame")({
		Name = "Weekdays",
		Size = UDim2.new(1, 0, 0, 20),
		BackgroundTransparency = 1,
		LayoutOrder = 2,
		[Children] = weekdayLabels,
	})

	-- Day grid ----------------------------------------------------------------------------

	local grid = New("Frame")({
		Name = "Grid",
		Size = Computed(function()
			return UDim2.new(1, 0, 0, rowCount:get() * CELL + 8)
		end),
		BackgroundTransparency = 1,
		LayoutOrder = 3,
		[Children] = {
			ForValues(cells, function(cell: { [string]: any })
				local isSelected = Computed(function()
					local sel = selected:get()
					return sel.Day == cell.Day
						and sel.Month == viewMonth:get()
						and sel.Year == viewYear:get()
				end)
				local isToday = cell.Day == today.day
					and viewMonth:get() == today.month
					and viewYear:get() == today.year
				local hovering = Value(false)

				return New("TextButton")({
					Name = "Day_" .. cell.Day,
					Size = UDim2.fromOffset(CELL - 4, CELL - 4),
					Position = UDim2.fromOffset(GRID_PAD + cell.Column * CELL + 2, cell.Row * CELL + 2),
					BackgroundColor3 = Computed(function()
						if isSelected:get() then
							return Theme.Colors.Primary:get()
						end
						return Theme.Colors.SurfaceHover:get()
					end),
					BackgroundTransparency = Computed(function()
						if isSelected:get() then
							return 0
						end
						return if hovering:get() then 0.4 else 1
					end),
					Text = tostring(cell.Day),
					TextSize = 12,
					FontFace = Computed(function()
						return Theme.Fonts.Body:get()
					end),
					TextColor3 = Computed(function()
						if isSelected:get() then
							return Theme.Colors.PrimaryText:get()
						end
						if isToday then
							return Theme.Colors.Primary:get()
						end
						return Theme.Colors.Text:get()
					end),
					AutoButtonColor = false,
					[OnEvent("MouseEnter")] = function()
						hovering:set(true)
					end,
					[OnEvent("MouseLeave")] = function()
						hovering:set(false)
					end,
					[OnEvent("Activated")] = function()
						local date = { Year = viewYear:get(), Month = viewMonth:get(), Day = cell.Day }
						selected:set(date)
						if props.OnChanged then
							props.OnChanged(date)
						end
					end,
					[Children] = { Primitives.Corner("Sm") },
				})
			end, Fusion.cleanup),
		},
	})

	return New("Frame")({
		Name = "AetherDatePicker",
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.fromOffset(CELL * 7 + GRID_PAD * 2, 0),
		BackgroundColor3 = Computed(function()
			return Theme.Colors.Surface:get()
		end),
		LayoutOrder = props.LayoutOrder,
		Parent = props.Parent,
		[Children] = {
			Primitives.Corner("Lg"),
			Primitives.Stroke(),
			New("UIListLayout")({ SortOrder = Enum.SortOrder.LayoutOrder }),
			header,
			weekdayRow,
			grid,
		},
	})
end
