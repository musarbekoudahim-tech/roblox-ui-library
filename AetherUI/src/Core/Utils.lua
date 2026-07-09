--!strict
--[[
	AetherUI • Core/Utils
	Shared helpers: table utilities, color math, formatting, ids.
]]

local HttpService = game:GetService("HttpService")

local Utils = {}

-- // Tables --------------------------------------------------------------

function Utils.Merge<T>(base: T, overrides: { [string]: any }?): T
	local result = table.clone(base :: any)
	if overrides then
		for key, value in overrides do
			result[key] = value
		end
	end
	return (result :: any) :: T
end

function Utils.DeepMerge(base: { [string]: any }, overrides: { [string]: any }?): { [string]: any }
	local result = table.clone(base)
	if overrides then
		for key, value in overrides do
			if type(value) == "table" and type(result[key]) == "table" then
				result[key] = Utils.DeepMerge(result[key], value)
			else
				result[key] = value
			end
		end
	end
	return result
end

function Utils.Map<T, U>(list: { T }, fn: (T, number) -> U): { U }
	local out = table.create(#list)
	for index, value in list do
		out[index] = fn(value, index)
	end
	return out
end

function Utils.Filter<T>(list: { T }, fn: (T, number) -> boolean): { T }
	local out = {}
	for index, value in list do
		if fn(value, index) then
			table.insert(out, value)
		end
	end
	return out
end

-- // Ids -----------------------------------------------------------------

local counter = 0
function Utils.Uid(prefix: string?): string
	counter += 1
	return (prefix or "aether") .. "_" .. tostring(counter)
end

function Utils.Guid(): string
	return HttpService:GenerateGUID(false)
end

-- // Math ----------------------------------------------------------------

function Utils.Clamp(value: number, min: number, max: number): number
	return math.max(min, math.min(max, value))
end

function Utils.Round(value: number, step: number?): number
	local s = step or 1
	return math.floor(value / s + 0.5) * s
end

function Utils.Lerp(a: number, b: number, t: number): number
	return a + (b - a) * t
end

-- // Colors --------------------------------------------------------------

function Utils.Lighten(color: Color3, amount: number): Color3
	local h, s, v = color:ToHSV()
	return Color3.fromHSV(h, math.max(0, s - amount * 0.35), math.min(1, v + amount))
end

function Utils.Darken(color: Color3, amount: number): Color3
	local h, s, v = color:ToHSV()
	return Color3.fromHSV(h, s, math.max(0, v - amount))
end

function Utils.Luminance(color: Color3): number
	return 0.2126 * color.R + 0.7152 * color.G + 0.0722 * color.B
end

--- Returns a readable text color (near-black or near-white) for the given background.
function Utils.ContrastText(background: Color3): Color3
	return if Utils.Luminance(background) > 0.55
		then Color3.fromRGB(20, 20, 24)
		else Color3.fromRGB(248, 248, 250)
end

function Utils.ToHex(color: Color3): string
	return string.format(
		"#%02X%02X%02X",
		math.round(color.R * 255),
		math.round(color.G * 255),
		math.round(color.B * 255)
	)
end

function Utils.FromHex(hex: string): Color3?
	local cleaned = hex:gsub("#", "")
	if #cleaned == 3 then
		cleaned = cleaned:gsub("(.)", "%1%1")
	end
	if #cleaned ~= 6 then
		return nil
	end
	local r = tonumber(cleaned:sub(1, 2), 16)
	local g = tonumber(cleaned:sub(3, 4), 16)
	local b = tonumber(cleaned:sub(5, 6), 16)
	if r and g and b then
		return Color3.fromRGB(r, g, b)
	end
	return nil
end

-- // Formatting ----------------------------------------------------------

function Utils.FormatNumber(value: number, decimals: number?): string
	local d = decimals or 0
	return string.format("%." .. tostring(d) .. "f", value)
end

function Utils.Truncate(text: string, maxLength: number): string
	if #text <= maxLength then
		return text
	end
	return text:sub(1, maxLength - 1) .. "…"
end

function Utils.PadZero(value: number): string
	return string.format("%02d", value)
end

return Utils
