--!strict
--[[
	AetherUI • Types
	Public type definitions shared across the library.
]]

export type ThemeColors = {
	Background: Color3,
	Surface: Color3,
	SurfaceHover: Color3,
	Elevated: Color3,
	Overlay: Color3,
	Border: Color3,
	BorderStrong: Color3,
	Primary: Color3,
	PrimaryHover: Color3,
	PrimaryText: Color3,
	Secondary: Color3,
	SecondaryHover: Color3,
	Text: Color3,
	TextMuted: Color3,
	TextDisabled: Color3,
	Success: Color3,
	Warning: Color3,
	Danger: Color3,
	DangerHover: Color3,
	Info: Color3,
	Accent: Color3,
}

export type ThemeSpec = {
	Name: string?,
	Mode: ("Dark" | "Light")?,
	Colors: ThemeColors,
	Radius: { Sm: number, Md: number, Lg: number, Xl: number, Full: number },
	Spacing: { Xs: number, Sm: number, Md: number, Lg: number, Xl: number },
	Fonts: { Body: Font, Heading: Font, Mono: Font },
	TextSizes: { Xs: number, Sm: number, Md: number, Lg: number, Xl: number, Xxl: number },
	StrokeTransparency: number,
	GlassTransparency: number,
	ShadowTransparency: number,
}

export type KeybindSpec = {
	Key: Enum.KeyCode,
	Modifiers: { "Ctrl" | "Shift" | "Alt" }?,
	Callback: () -> (),
	Description: string?,
	Enabled: boolean?,
}

export type ToastOptions = {
	Title: string,
	Description: string?,
	Variant: ("Default" | "Success" | "Warning" | "Error" | "Info")?,
	Duration: number?,
	Icon: string?,
	Action: { Label: string, Callback: () -> () }?,
}

export type DropdownItem = {
	Label: string,
	Value: any,
	Icon: string?,
	Disabled: boolean?,
}

export type TableColumn = {
	Key: string,
	Label: string,
	Width: number?,
	Sortable: boolean?,
	Format: ((any, { [string]: any }) -> string)?,
}

export type TreeNode = {
	Label: string,
	Icon: string?,
	Children: { TreeNode }?,
	Value: any?,
	Expanded: boolean?,
}

export type CommandItem = {
	Label: string,
	Description: string?,
	Icon: string?,
	Keywords: { string }?,
	Shortcut: string?,
	Callback: () -> (),
}

export type StepItem = {
	Label: string,
	Description: string?,
	Icon: string?,
}

return nil
