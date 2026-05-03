local Sound = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local SPEED_OF_SOUND = 343

local function GetListenerPosition()
	if RunService:IsClient() then
		local camera = workspace.CurrentCamera
		if camera then
			return camera.CFrame.Position
		end
	end
	return nil
end

function Sound.Execution(origin: Vector3, soundInstance: Sound, maxDistance: number)
	print("SoundDistance: Executing sound at " .. tostring(origin))
	local listenerPos = GetListenerPosition()
	local distance = 0
	local travelTime = 0
	local isOccluded = false

	if listenerPos then
		distance = (origin - listenerPos).Magnitude
		-- Calculate travel time based on distance and speed of sound
		travelTime = distance / SPEED_OF_SOUND
		
		local rayDirection = origin - listenerPos
		local rayParams = RaycastParams.new()
		rayParams.FilterType = Enum.RaycastFilterType.Exclude
		
		local excludeList = {}
		for _, p in Players:GetPlayers() do
			if p.Character then table.insert(excludeList, p.Character) end
		end
		rayParams.FilterDescendantsInstances = excludeList
		
		local result = workspace:Raycast(listenerPos, rayDirection, rayParams)
		if result then
			isOccluded = true
			print("SoundDistance: Sound is occluded by " .. result.Instance.Name)
		end
	end

	task.delay(travelTime, function()
		local attachment = Instance.new("Attachment")
		attachment.Name = "SoundDistanceAttachment"
		attachment.WorldPosition = origin
		attachment.Parent = workspace.Terrain

		local player = Instance.new("AudioPlayer")
		player.Name = "DistanceAudioPlayer"
		player.AssetId = soundInstance.SoundId

		local filter = Instance.new("AudioFilter")
		filter.Name = "DistanceAudioFilter"
		filter.FilterType = Enum.AudioFilterType.Lowpass12dB
		
		local frequency = 22000
		if isOccluded then
			-- Apply low frequency cutoff for occluded sounds
			frequency = 800 
		else
			-- Scale frequency based on distance to simulate air absorption
			frequency = math.clamp(22000 - (distance * 25), 1500, 22000)
		end
		filter.Frequency = frequency

		local reverb = Instance.new("AudioReverb")
		reverb.Name = "DistanceAudioReverb"
		reverb.DecayTime = math.clamp(distance / 100, 0.5, 3.5) 
		
		local rawWet = math.clamp((distance / maxDistance) * 1.5, 0.001, 0.7) 
		reverb.WetLevel = 20 * math.log10(rawWet)

		local emitter = Instance.new("AudioEmitter")
		emitter.Name = "DistanceAudioEmitter"
		emitter:SetDistanceAttenuation({
			[0] = 1,
			[maxDistance * 0.1] = 0.8,
			[maxDistance * 0.5] = 0.3,
			[maxDistance] = 0
		})

		local w_play_to_filter = Instance.new("Wire")
		w_play_to_filter.Name = "Wire_PlayerToFilter"
		w_play_to_filter.SourceInstance = player
		w_play_to_filter.TargetInstance = filter
		w_play_to_filter.Parent = attachment

		local w_filter_to_emit = Instance.new("Wire")
		w_filter_to_emit.Name = "Wire_FilterToEmitter"
		w_filter_to_emit.SourceInstance = filter
		w_filter_to_emit.TargetInstance = emitter
		w_filter_to_emit.Parent = attachment

		local w_filter_to_rev = Instance.new("Wire")
		w_filter_to_rev.Name = "Wire_FilterToReverb"
		w_filter_to_rev.SourceInstance = filter
		w_filter_to_rev.TargetInstance = reverb
		w_filter_to_rev.Parent = attachment

		local w_rev_to_emit = Instance.new("Wire")
		w_rev_to_emit.Name = "Wire_ReverbToEmitter"
		w_rev_to_emit.SourceInstance = reverb
		w_rev_to_emit.TargetInstance = emitter
		w_rev_to_emit.Parent = attachment

		player.Parent = attachment
		filter.Parent = attachment
		reverb.Parent = attachment
		emitter.Parent = attachment

		player.Ended:Connect(function()
			attachment:Destroy()
		end)

		player:Play()
	end)
end

return Sound
