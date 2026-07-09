--!strict
--[[
	AetherUI • Core/Sound
	Optional audio feedback layer. Disabled by default — call Sound.SetEnabled(true).

	The default asset ids are intentionally generic placeholders; override them
	with your own uploads via Sound.Configure for a fully branded feel:

		Sound.Configure("Click", { Id = "rbxassetid://YOUR_ID", Volume = 0.35 })
]]

local SoundService = game:GetService("SoundService")

local Sound = {}

Sound.Enabled = false
Sound.MasterVolume = 0.5

type SoundDef = { Id: string, Volume: number, PlaybackSpeed: number? }

local registry: { [string]: SoundDef } = {
	Hover = { Id = "rbxassetid://10066936758", Volume = 0.12, PlaybackSpeed = 1.15 },
	Click = { Id = "rbxassetid://10066931761", Volume = 0.3 },
	Toggle = { Id = "rbxassetid://10066931761", Volume = 0.25, PlaybackSpeed = 1.2 },
	Success = { Id = "rbxassetid://10066947742", Volume = 0.35 },
	Error = { Id = "rbxassetid://10066947742", Volume = 0.35, PlaybackSpeed = 0.7 },
	Open = { Id = "rbxassetid://10066936758", Volume = 0.2 },
	Close = { Id = "rbxassetid://10066936758", Volume = 0.2, PlaybackSpeed = 0.85 },
}

local cache: { [string]: Sound } = {}

local function getInstance(name: string): Sound?
	local def = registry[name]
	if not def then
		return nil
	end
	local cached = cache[name]
	if cached then
		return cached
	end
	local sound = Instance.new("Sound")
	sound.Name = "AetherUI_" .. name
	sound.SoundId = def.Id
	sound.Volume = def.Volume
	sound.PlaybackSpeed = def.PlaybackSpeed or 1
	sound.Parent = SoundService
	cache[name] = sound
	return sound
end

function Sound.SetEnabled(enabled: boolean)
	Sound.Enabled = enabled
end

function Sound.SetMasterVolume(volume: number)
	Sound.MasterVolume = math.clamp(volume, 0, 1)
end

--- Registers or overrides a sound (name: Hover | Click | Toggle | Success | Error | Open | Close | custom).
function Sound.Configure(name: string, def: SoundDef)
	registry[name] = def
	local cached = cache[name]
	if cached then
		cached:Destroy()
		cache[name] = nil
	end
end

--- Plays a named sound if the sound system is enabled.
function Sound.Play(name: string)
	if not Sound.Enabled then
		return
	end
	local sound = getInstance(name)
	if sound then
		local def = registry[name]
		sound.Volume = def.Volume * Sound.MasterVolume
		sound:Play()
	end
end

function Sound.Destroy()
	for _, sound in cache do
		sound:Destroy()
	end
	table.clear(cache)
end

return Sound
