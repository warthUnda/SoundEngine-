local SoundRemote = game.ReplicatedStorage:WaitForChild("SoundRemotes"):WaitForChild("SoundClient")
local SoundProxRemote = game.ReplicatedStorage:WaitForChild("SoundRemotes"):WaitForChild("SoundClose")

-- Cache the SoundFolder so we can look up sounds by name
local SoundFolder = workspace:WaitForChild("SoundFolder")

-- Helper: Find a Sound in the SoundFolder by name and clone it
local function fetchSound(soundName: string): Sound?
	local template = SoundFolder:FindFirstChild(soundName)
	if not template then
		warn("SoundReceiver: No sound named '" .. soundName .. "' found in SoundFolder!")
		return nil
	end
	return template:Clone()
end

SoundRemote.OnClientEvent:Connect(
	function(Runtime, DecayTime, BOOST_AMOUNT, SoundName, HitPosition, SoundVolume, hfAbsorption, wetAdd)
		local bounceSound = fetchSound(SoundName)
		if not bounceSound then
			return
		end

		local bounceAttachment = Instance.new("Attachment")
		bounceAttachment.Name = "AcousticBounceAttachment"
		bounceAttachment.CFrame = CFrame.new(HitPosition)
		bounceAttachment.Parent = workspace.Terrain

		bounceSound.Name = "AcousticBounceSound"
		bounceSound.Parent = bounceAttachment
		bounceSound.Volume = SoundVolume

		local currentEq = Instance.new("EqualizerSoundEffect")
		currentEq.Name = "BounceEQ"
		currentEq.Parent = bounceSound

		local currentReverb = Instance.new("ReverbSoundEffect")
		currentReverb.Name = "BounceReverb"
		currentReverb.Parent = bounceSound

		-- Lowpass effect: Distance traveled (Runtime) and material absorption removes high-end frequencies
		local highLoss = math.clamp(hfAbsorption + (Runtime * 15), 0, 80)
		local midLoss = math.clamp(highLoss * 0.4, 0, 80)

		currentEq.HighGain = -highLoss
		currentEq.MidGain = -midLoss
		currentEq.LowGain = math.clamp(-Runtime * 2, -20, 5) -- Low frequencies penetrate further

		-- Reverb equalizer: More bounces/distance = longer decay and more diffuse sound
		local accumulatedDecay = math.clamp(0.5 + DecayTime + (BOOST_AMOUNT * 0.1) + (Runtime * 0.2), 0.1, 20)
		local targetWetLevel = math.clamp(-40 + wetAdd + (BOOST_AMOUNT * 2), -80, 10)

		currentReverb.DecayTime = accumulatedDecay
		currentReverb.WetLevel = targetWetLevel

		bounceSound.Ended:Connect(function()
			bounceAttachment:Destroy()
		end)
		bounceSound:Play()
	end
)

SoundProxRemote.OnClientEvent:Connect(function(TargetPosition, CurrentPos, Data, SoundName)
	-- Fetch the sound template from the SoundFolder by name
	local SoundEffect = fetchSound(SoundName)
	if not SoundEffect then
		return false
	end

	local rayDir = TargetPosition - CurrentPos
	local raycastResult = workspace:Raycast(CurrentPos, rayDir, RaycastParams.new())

	if not raycastResult then
		SoundEffect:Destroy()
		return false
	end

	local hitPart = raycastResult.Instance
	local hitNormal = raycastResult.Normal

	local localNormal = hitPart.CFrame:VectorToObjectSpace(hitNormal)

	local tActual = 0
	if math.abs(localNormal.X) > 0.5 then
		tActual = hitPart.Size.X
	elseif math.abs(localNormal.Y) > 0.5 then
		tActual = hitPart.Size.Y
	else
		tActual = hitPart.Size.Z
	end

	local cosTheta = math.abs(rayDir.Unit:Dot(hitNormal))
	cosTheta = math.clamp(cosTheta, 0.01, 1)

	local tEff = tActual / cosTheta

	local materialMultiplier = 1.0
	if hitPart.Material == Enum.Material.Metal or hitPart.Material == Enum.Material.Concrete then
		materialMultiplier = 1.5 -- Harder to penetrate
	elseif hitPart.Material == Enum.Material.Wood or hitPart.Material == Enum.Material.Fabric then
		materialMultiplier = 0.5 -- Easier to penetrate
	end

	local finalThickness = tEff * materialMultiplier

	if Data.SoundVolume > finalThickness then
		Data.SoundVolume -= finalThickness
		local exitPoint = raycastResult.Position + (rayDir.Unit * tEff)

		Data.SoundVolume = exitPoint

		-- Muffle the sound realistically based on how much wall it punched through
		Data.SoundVolume = Data.SoundVolume * math.clamp(1 - (finalThickness / 10), 0.1, 1)
		Data.BOOST_AMOUNT += (finalThickness * 2)

		SoundEffect:Play()

		return true
	else
		Data.SoundVolume = 0
		SoundEffect:Destroy()
		return false
	end
end)
