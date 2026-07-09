--!strict
--[=[
	AetherUI · Overlay
	Shared ScreenGui layer for modals, toasts, tooltips, menus and palettes.
	Guarantees a single top-most root with sensible DisplayOrder.
]=]

local Overlay = {}

local root: ScreenGui? = nil

--- Standalone runtime: the UI always lives in CoreGui so it persists across
--- character respawns and is fully independent of the LocalPlayer's PlayerGui.
--- Prefers the executor-provided hidden UI container (gethui) when available.
local function getParent(): Instance
	local getHui = (getfenv() :: any).gethui
	if typeof(getHui) == "function" then
		local ok, hui = pcall(getHui)
		if ok and typeof(hui) == "Instance" then
			return hui
		end
	end
	return game:GetService("CoreGui")
end

function Overlay.getRoot(): ScreenGui
	if root and root.Parent then
		return root
	end
	local gui = Instance.new("ScreenGui")
	gui.Name = "AetherUI_Overlay"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 1000
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = getParent()
	root = gui
	return gui
end

--[=[ Layer helpers — each subsystem gets its own folder-frame ]=]
function Overlay.getLayer(name: string, zIndex: number): Frame
	local gui = Overlay.getRoot()
	local existing = gui:FindFirstChild(name)
	if existing and existing:IsA("Frame") then
		return existing
	end
	local layer = Instance.new("Frame")
	layer.Name = name
	layer.Size = UDim2.fromScale(1, 1)
	layer.BackgroundTransparency = 1
	layer.ZIndex = zIndex
	layer.Parent = gui
	return layer
end

function Overlay.destroy()
	if root then
		root:Destroy()
		root = nil
	end
end

return Overlay
