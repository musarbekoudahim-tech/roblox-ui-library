--!strict
--[[
	AetherUI • Core/Icons
	Lucide icon integration with caching + pluggable icon packs.

	AetherUI ships with support for the community `lucide-roblox` spritesheet
	format (https://github.com/latte-soft/lucide-roblox). Load the generated
	icon data module and register it once:

		local lucideData = loadstring(game:HttpGet("<lucide-pack-url>"))()
		AetherUI.Icons.LoadPack(lucideData)

	After that, every component accepts icons by name:

		AetherUI.Button({ Text = "Save", Icon = "save" })

	You can also register single icons (your own uploads):

		AetherUI.Icons.Register("brand-logo", { Id = "rbxassetid://123456" })

	If an icon is missing, components render a subtle placeholder glyph
	instead of a broken image — the UI never looks broken.
]]

export type IconData = {
	Id: string,
	ImageRectOffset: Vector2?,
	ImageRectSize: Vector2?,
}

local Icons = {}

local registry: { [string]: IconData } = {}
local resolveCache: { [string]: IconData | false } = {}
local aliases: { [string]: string } = {
	["x"] = "x",
	["close"] = "x",
	["chevron-down"] = "chevron-down",
	["chevron-up"] = "chevron-up",
	["chevron-left"] = "chevron-left",
	["chevron-right"] = "chevron-right",
	["check"] = "check",
	["search"] = "search",
	["settings"] = "settings",
}

--- Registers a single icon by name.
function Icons.Register(name: string, data: IconData)
	registry[name:lower()] = data
	resolveCache[name:lower()] = nil
end

--- Adds an alias (e.g. Icons.Alias("cog", "settings")).
function Icons.Alias(alias: string, target: string)
	aliases[alias:lower()] = target:lower()
end

--[[
	Loads a lucide-roblox style pack. Supported shapes:

	1. { IconData = { [name] = { Url|Id, ImageRectOffset, ImageRectSize } } }
	2. { [name] = { Id = ..., ImageRectOffset = ..., ImageRectSize = ... } }
	3. { GetAsset = function(name, size?) -> { Url, ImageRectOffset, ImageRectSize } }
]]
function Icons.LoadPack(pack: any)
	if type(pack) ~= "table" then
		warn("[AetherUI] Icons.LoadPack expects a table")
		return
	end
	if type(pack.GetAsset) == "function" then
		Icons._provider = pack
		table.clear(resolveCache)
		return
	end
	local source = pack.IconData or pack
	for name, data in source :: { [string]: any } do
		if type(data) == "table" then
			Icons.Register(name, {
				Id = data.Id or data.Url or data.Image or "",
				ImageRectOffset = data.ImageRectOffset,
				ImageRectSize = data.ImageRectSize,
			})
		end
	end
end

Icons._provider = nil :: any

--- Resolves an icon by name. Returns nil when unknown (components then show a fallback).
function Icons.Get(name: string?): IconData?
	if name == nil or name == "" then
		return nil
	end
	local key = name:lower()
	key = aliases[key] or key

	local cached = resolveCache[key]
	if cached ~= nil then
		return if cached == false then nil else cached :: IconData
	end

	local data: IconData? = registry[key]

	if data == nil and Icons._provider then
		local ok, asset = pcall(function()
			return Icons._provider.GetAsset(key, 48)
		end)
		if ok and type(asset) == "table" then
			data = {
				Id = asset.Url or asset.Id or "",
				ImageRectOffset = asset.ImageRectOffset,
				ImageRectSize = asset.ImageRectSize,
			}
		end
	end

	resolveCache[key] = data or false
	return data
end

--- True when the icon can be rendered as an image.
function Icons.Has(name: string?): boolean
	return Icons.Get(name) ~= nil
end

--- Lists all directly registered icon names (excludes provider-backed icons).
function Icons.List(): { string }
	local names = {}
	for name in registry do
		table.insert(names, name)
	end
	table.sort(names)
	return names
end

--[[
	Renders an icon as an ImageLabel. Used by every component that accepts
	an `Icon` prop.

	`name` may be a plain string OR a Fusion state object (Value/Computed)
	for reactive icon swapping. `props` supports: Name, Size, Position,
	AnchorPoint, LayoutOrder, ZIndex, Rotation, Visible, Color (-> ImageColor3),
	Transparency (-> ImageTransparency) — each either static or reactive.

	Unknown icons render an empty (invisible) label so the UI never breaks.
]]
function Icons.render(name: any, props: any): Instance
	local Fusion = require(script.Parent.Fusion) :: any
	local New = Fusion.New
	local Computed = Fusion.Computed

	props = props or {}

	local isReactive = typeof(name) == "table" and typeof(name.get) == "function"

	local image: any
	local rectOffset: any
	local rectSize: any

	if isReactive then
		image = Computed(function()
			local data = Icons.Get(name:get())
			return if data then data.Id else ""
		end)
		rectOffset = Computed(function()
			local data = Icons.Get(name:get())
			return if data and data.ImageRectOffset then data.ImageRectOffset else Vector2.zero
		end)
		rectSize = Computed(function()
			local data = Icons.Get(name:get())
			return if data and data.ImageRectSize then data.ImageRectSize else Vector2.zero
		end)
	else
		local data = Icons.Get(name)
		image = if data then data.Id else ""
		rectOffset = if data and data.ImageRectOffset then data.ImageRectOffset else Vector2.zero
		rectSize = if data and data.ImageRectSize then data.ImageRectSize else Vector2.zero
	end

	return New("ImageLabel")({
		Name = props.Name or "Icon",
		Size = props.Size or UDim2.fromOffset(16, 16),
		Position = props.Position,
		AnchorPoint = props.AnchorPoint,
		LayoutOrder = props.LayoutOrder,
		ZIndex = props.ZIndex,
		Rotation = props.Rotation,
		Visible = props.Visible,
		BackgroundTransparency = 1,
		Image = image,
		ImageRectOffset = rectOffset,
		ImageRectSize = rectSize,
		ImageColor3 = props.Color,
		ImageTransparency = props.Transparency,
		ScaleType = Enum.ScaleType.Fit,
	})
end

return Icons
