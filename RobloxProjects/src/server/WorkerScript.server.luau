--!optimize 2
--!native

local SounbounceMod = require(game.ReplicatedStorage.Shared.Sound.SoundBounce)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local soundClient = ReplicatedStorage:FindFirstChild("SoundClient")
if not soundClient then
	soundClient = Instance.new("RemoteEvent")
	soundClient.Name = "SoundClient"
	soundClient.Parent = ReplicatedStorage
end

local SoundEffect = game.ReplicatedStorage.BLASTAWAY

local runservice = game:GetService("RunService")

local BinFold = script.Parent:WaitForChild("Active")
local BinfoldReal = script.Parent:WaitForChild("Bin")

-- This code looks ugly so i added comments to isolate it :D

local children = BinFold:GetChildren()
task.spawn(function()
	while true do
		task.wait(1)
		-- Periodically update the children list to include new parts added to the Active folder
		children = BinFold:GetChildren()
		print("WorkerScript: Updated active children list, count: " .. #children)
	end
end)

-- This code looks ugly so i added comments to isolate it :D

local ProjectileData = {}

runservice.Heartbeat:Connect(function(dt)
	local currentProjectiles = children

	local partsToMove = {}
	local targetCFrames = {}

	-- Desynchronize to perform heavy calculations in parallel
	task.desynchronize()
	for _, projectile in currentProjectiles do
		if projectile:IsA("BasePart") then
			local oldData = ProjectileData[projectile]
			-- Calculate next step data (raycasts, volume decay, etc.)
			ProjectileData[projectile] = SounbounceMod.CalculateSteps(projectile, dt, 3, nil, oldData)
		end
	end

	-- Synchronize back to the main thread to perform property changes and physics interactions
	task.synchronize()

	for _, projectile in currentProjectiles do
		local data = ProjectileData[projectile]

		if not data then
			ProjectileData[projectile] = nil
			projectile.Parent = BinfoldReal
		else
			local alive, NextCFrame = SounbounceMod:Movement(projectile, 3, SoundEffect, BinfoldReal, data)

			if not alive then
				ProjectileData[projectile] = nil
				projectile.Parent = BinfoldReal
			elseif NextCFrame then
				table.insert(partsToMove, projectile)
				table.insert(targetCFrames, NextCFrame)
			end
		end
	end

	if #partsToMove > 0 then
		-- Use BulkMoveTo for optimized performance when moving multiple parts at once
		workspace:BulkMoveTo(partsToMove, targetCFrames, Enum.BulkMoveMode.FireAllEvents)
	end
end)
