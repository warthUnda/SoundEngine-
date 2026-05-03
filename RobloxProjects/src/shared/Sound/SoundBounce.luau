--!optimize 2
--!native

local CollectionService = game:GetService("CollectionService")
local EncodingService = game:GetService("EncodingService")

local SoundRemote = game.ReplicatedStorage:WaitForChild("SoundRemotes"):WaitForChild("SoundClient")
local SoundProxRemote = game.ReplicatedStorage:WaitForChild("SoundRemotes"):WaitForChild("SoundClose")

local SoundProjectile = {}
SoundProjectile.__index = SoundProjectile

local ModelMath = require(game.ReplicatedStorage.Shared.Math.ModelMath)

-- !Object Pooler code! --

-- Configuration
function SoundProjectile:PartCreation()
	local PEAK_AMOUNT = 1500

	local INSTANCE_FOLDER = workspace:WaitForChild("FolderGuy")

	local actors = INSTANCE_FOLDER:GetChildren()
	local TargetActor = actors

	local targetIndex = 0
	for i = 1, PEAK_AMOUNT do
		targetIndex += 1

		print("SoundProjectile: Creating pool part " .. i)
		TargetActor = actors[targetIndex]
		if targetIndex == #actors then
			targetIndex = 0
		end

		local bin = TargetActor:WaitForChild("Bin")

		local poolPart = Instance.new("Part")
		poolPart.Name = "PoolPart_" .. i

		poolPart.Anchored = true
		poolPart.CanCollide = false
		poolPart.Transparency = 0

		poolPart.CastShadow = false
		poolPart.CanTouch = false
		poolPart.CanQuery = false
		poolPart.Massless = true

		poolPart.Transparency = 1

		poolPart.Parent = bin
	end
end

-- !Object Pooler code! --

export type SoundProjectile = {
	rotation: number,
	speed: number,

	owner: Part,
	HasHit: boolean,

	Destroy: boolean,

	rotationSpawn: Vector3,
	spawnLocation: Vector3,
}

local targetIndex = 0

function SoundProjectile.new(
	speed: number,
	owner: Part,
	spawnLocation: Vector3,
	Sound: Sound,
	PartWanted: number
): SoundProjectile
	local self = setmetatable({}, SoundProjectile)

	-- 1. Setup Data
	self.speed = speed
	self.owner = owner
	self.spawnLocation = spawnLocation
	self.rotation = 0
	self.Destroy = false

	local SoundDist = require(game.ReplicatedStorage.Shared.Sound.SoundDistance)

	local AssetId = Sound.SoundId

	local INSTANCE_FOLDER = workspace:WaitForChild("FolderGuy")

	local actors = INSTANCE_FOLDER:GetChildren()
	local TargetActor = actors

	targetIndex += 1

	print("SoundProjectile: Initializing new projectile")
	TargetActor = actors[targetIndex]
	if targetIndex == #actors then
		targetIndex = 0
	end

	local BinChildren = TargetActor:WaitForChild("Bin"):GetChildren()
	local activeFolder = TargetActor:WaitForChild("Active")

	local binFolder = TargetActor:WaitForChild("Bin")
	local partsMoved = 0

	for i = 1, PartWanted do
		local part = BinChildren[i]
		if not part then
			part = Instance.new("Part")
			part.Name = "PoolPart_Generated"
			part.Anchored = true
			part.CanCollide = false
			part.Transparency = 1
			part.CastShadow = false
			part.CanTouch = false
			part.CanQuery = false
			part.Massless = true
			part.Parent = binFolder
		end
		part.Parent = activeFolder
		partsMoved += 1
	end

	for _, part in TargetActor:WaitForChild("Active"):GetChildren() do
		local currentAttribute = part:GetAttribute("x")

		if currentAttribute == nil then
			part:SetAttribute("CurrentSound", Sound.Name)
			print("Attribute 'x' was missing. Successfully applied 'y'.")
		else
			print("Object already has attribute 'x' with value: " .. tostring(currentAttribute))
		end

		if not part:GetAttribute("Activated") then
			part:SetAttribute("Activated", true)

			self.rotation += self.speed

			part.Transparency = 0
			local baseCF = typeof(self.spawnLocation) == "CFrame" and self.spawnLocation
				or CFrame.new(self.spawnLocation)

			part.CFrame = baseCF * CFrame.Angles(0, math.rad(self.rotation), 0)
		end
	end

	return self
end

local Players = game:GetService("Players")
-- Inside SoundBounce Module
function SoundProjectile.CalculateSteps(part, dt, speed, params, lastData)
	if not part or not part.Parent then
		return nil
	end

	local state = lastData
		or {
			Runtime = 0,
			SoundVolume = 10,
			initialVolume = 10,
			BOOST_AMOUNT = 0,
			CurrentWet = 0,
		}

	local direction = part.CFrame.LookVector
	local frameSpeed = speed * (dt * 60)
	-- Calculate new position based on direction and frame speed
	local newPosition = part.Position + (direction * frameSpeed)

	-- This is our Localization block to save performance
	local Runtime = state.Runtime
	local initialVolume = state.initialVolume
	local SoundVolume = state.SoundVolume
	local CurrentWet = state.CurrentWet
	local BOOST_AMOUNT = state.BOOST_AMOUNT

	Runtime += dt

	local decayRate = 0.2
	-- Calculate volume decay over time using exponential decay formula
	local targetVolume = initialVolume * math.exp(-decayRate * Runtime)
	SoundVolume = SoundVolume + (targetVolume - SoundVolume) * 0.1

	local spreadFactor = 0.2
	local SpreadAddition = (Runtime * spreadFactor)
	local AdditionWet = math.clamp(CurrentWet + BOOST_AMOUNT, -80, 0)

	local raycastResult = workspace:Raycast(part.Position, direction * frameSpeed)

	-- [[ PROXIMITY "MISS PROTOCOL" LOGIC ]]
	local NearbyPlayers = {}
	local pA = part.Position
	local pB = newPosition
	local ab = pB - pA
	local abDotAb = ab:Dot(ab)

	-- We dynamically fetch Players here because this module might run before Players service is loaded globally
	for _, player in Players:GetPlayers() do
		local char = player.Character
		if char then
			local rootPart = char:FindFirstChild("HumanoidRootPart")
			if rootPart then
				local pP = rootPart.Position
				local ap = pP - pA

				local distanceToSegment
				if abDotAb == 0 then
					distanceToSegment = ap.Magnitude
				else
					local t = math.clamp(ap:Dot(ab) / abDotAb, 0, 1)
					local closestPoint = pA + t * ab
					distanceToSegment = (pP - closestPoint).Magnitude
				end

				-- WHIZZ RANGE: If player is within 15 studs of the bullet's path this frame
				if distanceToSegment <= 15 then
					table.insert(NearbyPlayers, {
						Player = player,
						Distance = distanceToSegment,
					})
				end
			end
		end
	end

	-- Sort the nearby players so the absolute closest one is at index 1
	table.sort(NearbyPlayers, function(a, b)
		return a.Distance < b.Distance
	end)
	-- [[ END PROXIMITY LOGIC ]]

	local CurrentCFrame = part.CFrame

	return {
		newPosition = newPosition,
		raycastResult = raycastResult,
		OriginSize = part.Size,
		direction = direction,

		Runtime = state.Runtime,
		SoundVolume = state.SoundVolume,
		initialVolume = state.initialVolume,
		BOOST_AMOUNT = state.BOOST_AMOUNT,
		CurrentWet = state.CurrentWet,

		SpreadAddition = SpreadAddition,
		AdditionWet = AdditionWet,
		RNG = math.random(1, 8),

		RayOrigin = CurrentCFrame,
		CurrentCFrame = part.CFrame,
		NearbyPlayers = NearbyPlayers,
	}
end

local players = game:GetService("Players")

function SoundProjectile:Movement(part: Part, speed: number, Sound: Sound, BinFolder, Data)
	if not part or not part.Parent then
		return false
	end

	if not Data or not Data.newPosition then
		return false
	end

	local PreviousPosition = part.Position
	part.Transparency = 1

	-- LOCALIZATION BLOCK (Checking the .Data table once)
	local newPosition = Data.newPosition
	local raycastResult = Data.raycastResult
	local OriginSize = Data.OriginSize
	local direction = Data.direction
	local RNG = Data.RNG
	local SpreadAddition = Data.SpreadAddition
	local SoundVolume = Data.SoundVolume
	local BOOST_AMOUNT = Data.BOOST_AMOUNT
	local Runtime = Data.Runtime

	local CurrentCFrame = Data.CurrentCFrame

	local DecayTime = 0

	-- Begin Logic using Local Variables
	if SoundVolume <= 0.2 then
		self.HasHit = false
		self.Destroy = false

		part:SetAttribute("Activated", false)

		if part == nil then
			warn("SoundProjectile: Attempted to deactivate a nil part!")
		else
			part:SetAttribute("Activated", false)
			print("SoundProjectile: Projectile returned to pool (volume low)")
		end

		return false
	end

	local EmptyCFrame = CurrentCFrame

	Sound.Volume = SoundVolume

	if raycastResult then
		-- Reflect the direction vector based on the surface normal
		direction = ModelMath.ReflectRotation(part, direction, raycastResult.Normal)
		EmptyCFrame = CFrame.lookAt(
			raycastResult.Position + (raycastResult.Normal * 0.1),
			raycastResult.Position + raycastResult.Normal + direction
		)

		-- Add a bit of instability to the rotation
		local instability = math.random(1, 10)
		EmptyCFrame = EmptyCFrame
			* CFrame.Angles(
				math.rad(math.random(-instability, instability)),
				math.rad(math.random(-instability, instability)),
				math.rad(math.random(-instability, instability))
			)

		local ObjectCol = raycastResult.Instance

		local hfAbsorption = 0
		local wetAdd = 0

		if CollectionService:HasTag(ObjectCol, "HardSurface") then
			SoundVolume *= 0.95
			hfAbsorption = 2
			wetAdd = 5
		elseif CollectionService:HasTag(ObjectCol, "SoftSurface") then
			BOOST_AMOUNT -= 1
			SoundVolume *= 0.10
			hfAbsorption = 35
			wetAdd = -10
		elseif CollectionService:HasTag(ObjectCol, "MediumSurface") then
			SoundVolume *= 0.50
			BOOST_AMOUNT += 1
			hfAbsorption = 15
			wetAdd = 2
		else
			SoundVolume *= 0.90
			BOOST_AMOUNT += 2
			DecayTime += 0.05
			hfAbsorption = 10
			wetAdd = 4
		end

		local hitPosition = raycastResult.Instance
		if hitPosition:IsA("Model") then
			local char = hitPosition:FindFirstChildOfClass("Model")
			if char then
				local Player = players:GetPlayerFromCharacter(char)
				if Player then
					local Position = raycastResult.Position
					SoundRemote:FireClient(
						Player,
						Runtime,
						DecayTime,
						BOOST_AMOUNT,
						Sound.Name,
						Position,
						SoundVolume,
						hfAbsorption,
						wetAdd
					)

					return false
				end
			end
		else
			local HitPostion = raycastResult.Position
			for _, player in players:GetPlayers() do
				local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
				if rootPart then
					local Dist = (rootPart.Position - HitPostion).magnitude
					if Dist < 20 then
						print("Hi guys")
						SoundProjectile:MissProtocol(
							PreviousPosition,
							CurrentCFrame.Position,
							rootPart.Position,
							player,
							Sound,
							Data
						)

						self.HasHit = true
						self.Destroy = true
					end
				end
			end
		end

		local char = ObjectCol:FindFirstAncestorOfClass("Model")
		if char and char:FindFirstChildOfClass("Humanoid") then
			self.HasHit = false
			self.Destroy = false

			Sound:Play()

			part:SetAttribute("Activated", false)

			if part == nil then
				warn("SoundProjectile: Hit humanoid but part is nil!")
			else
				print("SoundProjectile: Projectile returned to pool (hit humanoid)")
			end

			return false
		end
	else
		EmptyCFrame = CFrame.new(newPosition) * EmptyCFrame.Rotation
	end

	local LastCFrame = part.CFrame

	-- Syncing back updated values to the Data table for the next frame
	Data.SoundVolume = SoundVolume
	Data.BOOST_AMOUNT = BOOST_AMOUNT
	Data.initialVolume = SoundVolume

	-- [[ PROXIMITY TRIGGER (WHIZZ/SNAP) ]]

	-- [[ END PROXIMITY TRIGGER ]]

	return true, EmptyCFrame, Data.RayOrigin, LastCFrame
end

function SoundProjectile:MissProtocol(
	PreviousPosition: Vector3,
	CurrentPos: Vector3,
	TargetPosition: Vector3,
	Plr: Player,
	SoundEffect: Sound,
	Data
)
	-- 1. Fix the Raycast Direction Math

	SoundProxRemote:FireClient(Plr, TargetPosition, CurrentPos, Data, SoundEffect.Name)
end

return SoundProjectile
