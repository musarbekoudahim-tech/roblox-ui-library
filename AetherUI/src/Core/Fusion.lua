--!strict
--[[
	AetherUI • Core/Fusion
	Resolves the Fusion dependency from common install locations:
	  1. A `Fusion` ModuleScript inside the AetherUI folder (vendored)
	  2. A sibling of the AetherUI folder (Wally / manual install)
	  3. ReplicatedStorage.Fusion or ReplicatedStorage.Packages.Fusion
	AetherUI targets Fusion 0.2.x (New, Value, Computed, Spring, Tween, Observer).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local function resolve(): any
	local src = script.Parent.Parent -- AetherUI/src (library root)
	local candidates: { Instance? } = {
		src:FindFirstChild("Fusion"),
		src.Parent and src.Parent:FindFirstChild("Fusion"),
		src.Parent and src.Parent.Parent and src.Parent.Parent:FindFirstChild("Fusion"),
		ReplicatedStorage:FindFirstChild("Fusion"),
	}

	local packages = ReplicatedStorage:FindFirstChild("Packages")
	if packages then
		table.insert(candidates, packages:FindFirstChild("Fusion"))
	end

	for _, candidate in candidates do
		if candidate and candidate:IsA("ModuleScript") then
			return require(candidate) :: any
		end
	end

	error(
		"[AetherUI] Could not find Fusion. Install it with Wally (elttob/fusion@0.2.0), "
			.. "or place a `Fusion` ModuleScript next to the AetherUI folder or in ReplicatedStorage."
	)
end

return resolve()
