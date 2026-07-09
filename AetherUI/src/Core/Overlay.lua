--!strict
--[=[
	AetherUI · Overlay
	Shared ScreenGui layer for modals, toasts, tooltips, menus and palettes.
	Guarantees a single top-most root with sensible DisplayOrder.
]=]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Overlay = {}

local root: ScreenGui? = nil

local function getParent(): Instance
	if RunService:IsStudio() and not RunService:IsRunning() then
		return game:GetService("CoreGui")
	end
	local player = Players.LocalPlayer
	if player then
		return player:WaitForChild("PlayerGui")
	end
	-- exploit/hopperbin environments
	local ok, coreGui = pcall(function()
		return game:GetService("CoreGui")
	end)
	if ok then
		return coreGui
	end
	error("AetherUI: could not resolve a GUI parent")
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
