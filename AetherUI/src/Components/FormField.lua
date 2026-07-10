--!strict
--[=[
	AetherUI · FormField, Label, HelperText
	Wrapper that composes a Label + control + HelperText/error message.
]=]

local Fusion = require(script.Parent.Parent.Core.Fusion)
local Theme = require(script.Parent.Parent.Core.Theme)

local New = Fusion.New
local Children = Fusion.Children
local Computed = Fusion.Computed

local FormField = {}

export type LabelProps = {
	Text: string,
	Required: boolean?,
	LayoutOrder: number?,
	Parent: Instance?,
}

function FormField.Label(props: LabelProps): TextLabel
	local theme = Theme.Current
	return New("TextLabel")({
		Name = "AetherLabel",
		Size = UDim2.new(1, 0, 0, 16),
		BackgroundTransparency = 1,
		Text = props.Required and (props.Text .. ' <font color="#ef4444">*</font>') or props.Text,
		RichText = true,
		Font = Enum.Font.GothamMedium,
		TextSize = 13,
		TextColor3 = Computed(function()
			return theme:get().Text
		end),
		TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = props.LayoutOrder,
		Parent = props.Parent,
	}) :: TextLabel
end

export type HelperTextProps = {
	Text: Fusion.CanBeState<string>,
	Variant: ("default" | "error" | "success")?,
	LayoutOrder: number?,
	Parent: Instance?,
}

function FormField.HelperText(props: HelperTextProps): TextLabel
	local theme = Theme.Current
	return New("TextLabel")({
		Name = "AetherHelperText",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Text = props.Text,
		Font = Enum.Font.Gotham,
		TextSize = 12,
		TextWrapped = true,
		TextColor3 = Computed(function()
			local t = theme:get()
			if props.Variant == "error" then
				return t.Danger
			elseif props.Variant == "success" then
				return t.Success
			end
			return t.TextMuted
		end),
		TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = props.LayoutOrder,
		Parent = props.Parent,
	}) :: TextLabel
end

export type FormFieldProps = {
	Label: string?,
	Required: boolean?,
	HelperText: Fusion.CanBeState<string>?,
	Error: Fusion.CanBeState<string>?,
	Content: Instance?,
	--- Alias for `Content`.
	Child: Instance?,
	LayoutOrder: number?,
	Parent: Instance?,
}

function FormField.Field(props: FormFieldProps): Frame
	local content = props.Content or props.Child
	assert(
		typeof(content) == "Instance",
		"[AetherUI] FormField requires a `Content` (or `Child`) Instance — e.g. FormField({ Label = ..., Content = AetherUI.TextInput({...}) })"
	)

	local children: { Instance } = {
		New("UIListLayout")({
			FillDirection = Enum.FillDirection.Vertical,
			Padding = UDim.new(0, 6),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	}

	if props.Label then
		local label = FormField.Label({ Text = props.Label, Required = props.Required, LayoutOrder = 1 })
		table.insert(children, label)
	end

	(content :: any).LayoutOrder = 2
	table.insert(children, content)

	if props.Error then
		table.insert(children, FormField.HelperText({ Text = props.Error, Variant = "error", LayoutOrder = 3 }))
	elseif props.HelperText then
		table.insert(children, FormField.HelperText({ Text = props.HelperText, LayoutOrder = 3 }))
	end

	return New("Frame")({
		Name = "AetherFormField",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = props.LayoutOrder,
		Parent = props.Parent,
		[Children] = children,
	}) :: Frame
end

return FormField
