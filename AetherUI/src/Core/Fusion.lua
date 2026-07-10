--!strict
--[[
	AetherUI • Core/Fusion
	Standalone-runtime Fusion resolver. No game-project dependencies
	(ReplicatedStorage / StarterPlayerScripts are never touched).

	Resolution order:
	  1. A `Fusion` ModuleScript vendored inside the AetherUI folder
	     (or as a sibling of it) — used when the library is bundled.
	  2. A preloaded global: `getgenv().Fusion` (or `_G.Fusion`) — used when
	     the host script fetches Fusion itself before loading AetherUI, e.g.
	         getgenv().Fusion = loadstring(game:HttpGet(FUSION_URL))()
	AetherUI targets Fusion 0.2.x (New, Value, Computed, Spring, Tween, Observer).
]]

local function resolve(): any
	-- 1. Vendored / sibling ModuleScript (bundled distribution)
	local ok, found = pcall(function()
		local src = script.Parent.Parent -- AetherUI/src (library root)
		local candidates: { Instance? } = {
			src:FindFirstChild("Fusion"),
			src.Parent and src.Parent:FindFirstChild("Fusion"),
		}
		for _, candidate in candidates do
			if candidate and candidate:IsA("ModuleScript") then
				return require(candidate) :: any
			end
		end
		return nil
	end)
	if ok and found ~= nil then
		return found
	end

	-- 2. Executor / loadstring environment globals
	local env = getfenv() :: any
	if typeof(env.getgenv) == "function" then
		local genv = env.getgenv()
		if genv and genv.Fusion ~= nil then
			return genv.Fusion
		end
	end
	if _G.Fusion ~= nil then
		return _G.Fusion
	end

	error(
		"[AetherUI] Could not find Fusion. Either bundle a `Fusion` ModuleScript "
			.. "inside the AetherUI folder, or preload it before loading AetherUI:\n"
			.. '    getgenv().Fusion = loadstring(game:HttpGet("<fusion-url>"))()'
	)
end

--- Fusion 0.2 compatibility: `peek` was only added in Fusion 0.3, and 0.2's
--- strict export table hard-errors when indexing unknown members. AetherUI
--- uses `Fusion.peek` throughout, so when the resolved Fusion lacks it we
--- wrap the exports in a proxy that adds a shim. In 0.2, `state:get(false)`
--- reads a value WITHOUT registering a dependency — identical semantics.
local function withCompat(fusion: any): any
	local hasPeek = pcall(function()
		return fusion.peek
	end)
	if hasPeek then
		return fusion
	end

	local function peek(target: any): any
		if typeof(target) == "table" and typeof(target.get) == "function" then
			return target:get(false)
		end
		return target
	end

	-- rawget finds `peek` on the proxy first; everything else falls through
	-- to the real Fusion exports (whose own strict guard still applies).
	return setmetatable({ peek = peek }, { __index = fusion })
end

return withCompat(resolve())
