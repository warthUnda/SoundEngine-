--! strict very strict infact

local SoundHals = {}

function SoundHals.DistantHal(SoundEffect, DestroyTimer)
	-- Create a clone of the sound effect for the hallucination
	local ClonedSound = SoundEffect:Clone()
	ClonedSound.Name = "DistantHalSound"
	ClonedSound.Parent = game.Workspace

	-- Apply reverb to simulate a distant, echoing sound
	local Reverb = Instance.new("ReverbSoundEffect")
	Reverb.Name = "DistantHalReverb"
	Reverb.Parent = ClonedSound
	Reverb.DecayTime = 1

	-- Lower volume significantly for distant effect
	ClonedSound.Volume = ClonedSound.Volume / 4

	ClonedSound:Play()
	print("SoundHals: Playing distant hallucination sound")

	task.delay(DestroyTimer, function()
		ClonedSound:Destroy()
		print("SoundHals: Distant sound destroyed")
	end)
end

function SoundHals.MediumDist(SoundEffect, DestroyTimer)
	-- Create a clone of the sound effect for the hallucination
	local ClonedSound = SoundEffect:Clone()
	ClonedSound.Name = "MediumDistHalSound"
	ClonedSound.Parent = game.Workspace

	-- Apply reverb for environmental depth
	local Reverb = Instance.new("ReverbSoundEffect")
	Reverb.Name = "MediumDistHalReverb"
	Reverb.Parent = ClonedSound
	
	-- Lower volume moderately for medium distance effect
	ClonedSound.Volume = ClonedSound.Volume / 2

	ClonedSound:Play()
	print("SoundHals: Playing medium distance hallucination sound")

	task.delay(DestroyTimer, function()
		ClonedSound:Destroy()
		print("SoundHals: Medium distance sound destroyed")
	end)
end

function SoundHals.CloseDist(SoundEffect, DestroyTimer)
	-- Create a clone of the sound effect for the hallucination
	local ClonedSound = SoundEffect:Clone()
	ClonedSound.Name = "CloseDistHalSound"
	ClonedSound.Parent = game.Workspace

	-- Apply subtle reverb for close proximity
	local Reverb = Instance.new("ReverbSoundEffect")
	Reverb.Name = "CloseDistHalReverb"
	Reverb.Parent = ClonedSound
	Reverb.DecayTime = 1

	ClonedSound:Play()
	print("SoundHals: Playing close distance hallucination sound")

	task.delay(DestroyTimer, function()
		ClonedSound:Destroy()
		print("SoundHals: Close distance sound destroyed")
	end)
end

return SoundHals
