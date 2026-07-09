--!strict
--[[
	AetherUI • Components/DataTable

	Sortable, filterable, paginated data table with row actions.

	props:
		Columns: { { Key: string, Label: string, Width: number?, Sortable: boolean?, Format: ((any) -> string)? } }
		Rows: { { [string]: any } } | Fusion Value
		PageSize: number?           (default 10)
		Searchable: boolean?        (adds a search input, filters all columns)
		Actions: { { Icon: string, Tooltip: string?, OnClick: (row) -> () } }?
		OnRowClick: ((row: { [string]: any }) -> ())?
		Size: UDim2?                LayoutOrder: number?    Parent: Instance?
]]

local Fusion = require(script.Parent.Parent.Core.Fusion)
local Theme = require(script.Parent.Parent.Core.Theme)
local Utils = require(script.Parent.Parent.Core.Utils)
local Primitives = require(script.Parent.Primitives)
local Button = require(script.Parent.Button)
local TextInput = require(script.Parent.TextInput)

local New = Fusion.New
local Children = Fusion.Children
local Computed = Fusion.Computed
local Value = Fusion.Value
local ForValues = Fusion.ForValues
local OnEvent = Fusion.OnEvent

local ROW_HEIGHT = 40
local HEADER_HEIGHT = 38

local function asState(value: any): any
	if type(value) == "table" and type(value.get) == "function" then
		return value
	end
	return Value(value or {})
end

return function(props: { [string]: any }): Frame
	local columns: { { [string]: any } } = props.Columns or {}
	local rows = asState(props.Rows)
	local pageSize: number = props.PageSize or 10

	local sortKey = Value(nil :: string?)
	local sortAsc = Value(true)
	local page = Value(1)
	local search = Value("")

	-- Derived pipeline: filter -> sort -> paginate --------------------------------

	local filtered = Computed(function()
		local all: { { [string]: any } } = rows:get()
		local query = string.lower(search:get())
		if query == "" then
			return all
		end
		return Utils.Filter(all, function(row)
			for _, col in columns do
				local cell = row[col.Key]
				if cell ~= nil and string.find(string.lower(tostring(cell)), query, 1, true) then
					return true
				end
			end
			return false
		end)
	end)

	local sorted = Computed(function()
		local list = table.clone(filtered:get())
		local key = sortKey:get()
		if key ~= nil then
			local asc = sortAsc:get()
			table.sort(list, function(a, b)
				local av, bv = a[key], b[key]
				if type(av) == "number" and type(bv) == "number" then
					return if asc then av < bv else av > bv
				end
				return if asc
					then tostring(av) < tostring(bv)
					else tostring(av) > tostring(bv)
			end)
		end
		return list
	end)

	local pageCount = Computed(function()
		return math.max(1, math.ceil(#sorted:get() / pageSize))
	end)

	local pageRows = Computed(function()
		local list = sorted:get()
		local p = math.clamp(page:get(), 1, math.max(1, math.ceil(#list / pageSize)))
		local out = {}
		for i = (p - 1) * pageSize + 1, math.min(p * pageSize, #list) do
			table.insert(out, { Index = i, Row = list[i] })
		end
		return out
	end)

	-- Column width resolution ------------------------------------------------------

	local flexCount = 0
	local fixedTotal = 0
	for _, col in columns do
		if col.Width then
			fixedTotal += col.Width
		else
			flexCount += 1
		end
	end
	local actionsWidth = if props.Actions and #props.Actions > 0 then #props.Actions * 32 + 8 else 0

	local function columnSize(col: { [string]: any }): UDim2
		if col.Width then
			return UDim2.new(0, col.Width, 1, 0)
		end
		return UDim2.new(1 / math.max(flexCount, 1), -math.floor((fixedTotal + actionsWidth) / math.max(flexCount, 1)), 1, 0)
	end

	-- Header ------------------------------------------------------------------------

	local headerCells: { any } = {
		Primitives.List({ Direction = "Horizontal", Padding = 0, VerticalAlignment = Enum.VerticalAlignment.Center }),
		Primitives.Padding({ Left = 12, Right = 12 }),
	}

	for order, col in columns do
		local isSorted = Computed(function()
			return sortKey:get() == col.Key
		end)
		table.insert(headerCells, New("TextButton")({
			Name = "Head_" .. col.Key,
			Size = columnSize(col),
			BackgroundTransparency = 1,
			Text = "",
			AutoButtonColor = false,
			LayoutOrder = order,
			[OnEvent("Activated")] = function()
				if col.Sortable == false then
					return
				end
				if sortKey:get() == col.Key then
					sortAsc:set(not sortAsc:get())
				else
					sortKey:set(col.Key)
					sortAsc:set(true)
				end
			end,
			[Children] = {
				Primitives.List({ Direction = "Horizontal", Padding = 4, VerticalAlignment = Enum.VerticalAlignment.Center }),
				Primitives.Text({
					Text = col.Label or col.Key,
					Size = 11,
					Bold = true,
					Color = Computed(function()
						return if isSorted:get() then Theme.Colors.Text:get() else Theme.Colors.TextMuted:get()
					end),
					LayoutOrder = 1,
				}),
				Primitives.Icon({
					Name = "chevron-up",
					Size = 12,
					Color = Computed(function()
						return Theme.Colors.TextMuted:get()
					end),
					Transparency = Computed(function()
						return if isSorted:get() then 0 else 1
					end),
					Rotation = Computed(function()
						return if sortAsc:get() then 0 else 180
					end),
					LayoutOrder = 2,
				}),
			},
		}))
	end

	if actionsWidth > 0 then
		table.insert(headerCells, New("Frame")({
			Name = "Head_Actions",
			Size = UDim2.new(0, actionsWidth, 1, 0),
			BackgroundTransparency = 1,
			LayoutOrder = #columns + 1,
		}))
	end

	local header = New("Frame")({
		Name = "Header",
		Size = UDim2.new(1, 0, 0, HEADER_HEIGHT),
		BackgroundColor3 = Computed(function()
			return Theme.Colors.SurfaceHigh:get()
		end),
		LayoutOrder = 2,
		[Children] = headerCells,
	})

	-- Rows ----------------------------------------------------------------------------

	local body = New("Frame")({
		Name = "Body",
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, 0),
		BackgroundTransparency = 1,
		LayoutOrder = 3,
		[Children] = {
			Primitives.List({ Padding = 0 }),
			ForValues(pageRows, function(entry: { [string]: any })
				local row = entry.Row
				local hovering = Value(false)

				local cells: { any } = {
					Primitives.List({ Direction = "Horizontal", Padding = 0, VerticalAlignment = Enum.VerticalAlignment.Center }),
					Primitives.Padding({ Left = 12, Right = 12 }),
					New("Frame")({
						Name = "Divider",
						Size = UDim2.new(1, 0, 0, 1),
						Position = UDim2.new(0, 0, 1, -1),
						BackgroundColor3 = Computed(function()
							return Theme.Colors.Border:get()
						end),
						BackgroundTransparency = 0.5,
						BorderSizePixel = 0,
					}),
				}

				for order, col in columns do
					local cell = row[col.Key]
					local text = if col.Format then col.Format(cell) else tostring(cell == nil and "—" or cell)
					table.insert(cells, New("Frame")({
						Name = "Cell_" .. col.Key,
						Size = columnSize(col),
						BackgroundTransparency = 1,
						LayoutOrder = order,
						[Children] = {
							Primitives.Text({
								Text = text,
								Size = 12,
								Props = {
									Size = UDim2.fromScale(1, 1),
									TextTruncate = Enum.TextTruncate.AtEnd,
									TextXAlignment = Enum.TextXAlignment.Left,
								},
							}),
						},
					}))
				end

				if props.Actions and #props.Actions > 0 then
					local actionButtons: { any } = {
						Primitives.List({ Direction = "Horizontal", Padding = 4, VerticalAlignment = Enum.VerticalAlignment.Center, HorizontalAlignment = Enum.HorizontalAlignment.Right }),
					}
					for aOrder, action in props.Actions :: { { [string]: any } } do
						table.insert(actionButtons, Button({
							Icon = action.Icon,
							Variant = "Ghost",
							Size = "Sm",
							LayoutOrder = aOrder,
							OnClick = function()
								action.OnClick(row)
							end,
						}))
					end
					table.insert(cells, New("Frame")({
						Name = "Cell_Actions",
						Size = UDim2.new(0, actionsWidth, 1, 0),
						BackgroundTransparency = 1,
						LayoutOrder = #columns + 1,
						[Children] = actionButtons,
					}))
				end

				return New("TextButton")({
					Name = "Row_" .. entry.Index,
					Size = UDim2.new(1, 0, 0, ROW_HEIGHT),
					BackgroundColor3 = Computed(function()
						return Theme.Colors.SurfaceHover:get()
					end),
					BackgroundTransparency = Computed(function()
						return if hovering:get() and props.OnRowClick then 0.5 else 1
					end),
					Text = "",
					AutoButtonColor = false,
					LayoutOrder = entry.Index,
					[OnEvent("MouseEnter")] = function()
						hovering:set(true)
					end,
					[OnEvent("MouseLeave")] = function()
						hovering:set(false)
					end,
					[OnEvent("Activated")] = function()
						if props.OnRowClick then
							props.OnRowClick(row)
						end
					end,
					[Children] = cells,
				})
			end, Fusion.cleanup),
		},
	})

	-- Toolbar (search) ------------------------------------------------------------------

	local toolbar: Instance? = nil
	if props.Searchable then
		toolbar = New("Frame")({
			Name = "Toolbar",
			Size = UDim2.new(1, 0, 0, 48),
			BackgroundTransparency = 1,
			LayoutOrder = 1,
			[Children] = {
				Primitives.Padding({ X = 12, Y = 8 }),
				TextInput({
					Placeholder = "Search...",
					Icon = "search",
					Clearable = true,
					Value = search,
					OnChanged = function(text: string)
						search:set(text)
						page:set(1)
					end,
					Props = { Size = UDim2.new(0, 240, 0, 32) },
				}),
			},
		})
	end

	-- Pagination footer --------------------------------------------------------------------

	local footer = New("Frame")({
		Name = "Footer",
		Size = UDim2.new(1, 0, 0, 48),
		BackgroundTransparency = 1,
		LayoutOrder = 4,
		[Children] = {
			Primitives.Padding({ X = 12 }),
			Primitives.Text({
				Text = Computed(function()
					local total = #sorted:get()
					local p = page:get()
					local from = math.min((p - 1) * pageSize + 1, total)
					local to = math.min(p * pageSize, total)
					return if total == 0 then "No results" else `{from}–{to} of {total}`
				end),
				Size = 12,
				Muted = true,
				Props = {
					Size = UDim2.new(0.5, 0, 1, 0),
					TextXAlignment = Enum.TextXAlignment.Left,
				},
			}),
			New("Frame")({
				Name = "Pager",
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -12, 0.5, 0),
				AutomaticSize = Enum.AutomaticSize.XY,
				BackgroundTransparency = 1,
				[Children] = {
					Primitives.List({ Direction = "Horizontal", Padding = 6, VerticalAlignment = Enum.VerticalAlignment.Center }),
					Button({
						Icon = "chevron-left",
						Variant = "Outline",
						Size = "Sm",
						LayoutOrder = 1,
						OnClick = function()
							page:set(math.max(1, page:get() - 1))
						end,
					}),
					Primitives.Text({
						Text = Computed(function()
							return `{page:get()} / {pageCount:get()}`
						end),
						Size = 12,
						Muted = true,
						LayoutOrder = 2,
					}),
					Button({
						Icon = "chevron-right",
						Variant = "Outline",
						Size = "Sm",
						LayoutOrder = 3,
						OnClick = function()
							page:set(math.min(pageCount:get(), page:get() + 1))
						end,
					}),
				},
			}),
		},
	})

	-- Container --------------------------------------------------------------------------------

	local content: { any } = {
		Primitives.Corner("Lg"),
		Primitives.Stroke(),
		New("UIListLayout")({
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
		header,
		body,
		footer,
	}
	if toolbar then
		table.insert(content, toolbar)
	end

	return New("Frame")({
		Name = "AetherDataTable",
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = props.Size or UDim2.new(1, 0, 0, 0),
		BackgroundColor3 = Computed(function()
			return Theme.Colors.Surface:get()
		end),
		ClipsDescendants = true,
		LayoutOrder = props.LayoutOrder,
		Parent = props.Parent,
		[Children] = content,
	})
end
