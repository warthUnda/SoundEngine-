local MovementMod = {}

local players = game:GetService("Players")
function MovementMod.Patrol(freddyModel, TableOfPositions, OfficeNode)
	-- SECURITY CHECK: Ensure Freddy is actually there
	if not freddyModel or not freddyModel.PrimaryPart then
		warn("SYSTEM ERROR: Freddy or PrimaryPart is missing!")
		return
	end

	local LastNode = nil
	local nodesFolder = TableOfPositions:GetChildren()
	local teleportCooldown = 1
	-- Track if Freddy is currently active in the patrol loop
	local isFreddyActive = true

	local LeftWindow = game.Workspace.PatrollingParts:FindFirstChild("LeftHallWindow")
	local RightWindow = game.Workspace.PatrollingParts:FindFirstChild("RightHallWindow")

	local function getNextNode(currentPos)
		local potentialNodes = {}
		local minJump, maxJump = 5, 60 -- Increased max slightly for better pathing

		for _, node in pairs(nodesFolder) do
			if node:IsA("BasePart") then
				local dist = (node.Position - currentPos).Magnitude
				if dist > minJump and dist < maxJump then
					table.insert(potentialNodes, node)
				end
			end
		end

		if #potentialNodes == 0 then
			print("MovementMod: No potential nodes found within range!")
			return nil
		end
		local selectedNode = potentialNodes[math.random(1, #potentialNodes)]
		print("MovementMod: Selected next node: " .. selectedNode.Name)
		return selectedNode
	end

	local function moveFreddy()
		print("Logic Engine: Starting Freddy AI...")

		while isFreddyActive do
			task.wait(teleportCooldown)

			local currentPos = freddyModel:GetPivot().Position
			local distToOffice = (OfficeNode.Position - currentPos).Magnitude
			local currentTarget = nil

			-- PUSH LOGIC: Only allow office entry if within 50 studs
			local chanceToPush = math.random(1, 10)
			if chanceToPush > 7 and distToOffice < 50 then
				-- Chance to push directly to the office if close enough
				currentTarget = OfficeNode
				print("MovementMod: Freddy is pushing to the office!")
			else
				currentTarget = getNextNode(currentPos)
			end

			local patrolFolder = game.Workspace.PatrollingParts

			if currentTarget == patrolFolder:FindFirstChild("LeftHallDistant") then
				-- Freddy is going left, block right hall
				patrolFolder:FindFirstChild("RightHallCorn"):SetAttribute("IsOpen", false)
				patrolFolder:FindFirstChild("RightHallWindow"):SetAttribute("IsOpen", false)
				patrolFolder:FindFirstChild("RightHallDistant"):SetAttribute("IsOpen", false)
				-- Ensure left hall is open
				patrolFolder:FindFirstChild("LeftHallCorner"):SetAttribute("IsOpen", true)
				patrolFolder:FindFirstChild("LeftHallWindow"):SetAttribute("IsOpen", true)
				patrolFolder:FindFirstChild("LeftHallDistant"):SetAttribute("IsOpen", true)

				patrolFolder:FindFirstChild("StorageRoom"):SetAttribute("IsOpen", true)
			end

			if currentTarget == patrolFolder:FindFirstChild("RightHallDistant") then
				-- Freddy is going right, block left hall
				patrolFolder:FindFirstChild("LeftHallCorner"):SetAttribute("IsOpen", false)
				patrolFolder:FindFirstChild("LeftHallWindow"):SetAttribute("IsOpen", false)
				patrolFolder:FindFirstChild("LeftHallDistant"):SetAttribute("IsOpen", false)

				patrolFolder:FindFirstChild("StorageRoom"):SetAttribute("IsOpen", false)
				-- Ensure right hall is open
				patrolFolder:FindFirstChild("RightHallCorn"):SetAttribute("IsOpen", true)
				patrolFolder:FindFirstChild("RightHallWindow"):SetAttribute("IsOpen", true)
				patrolFolder:FindFirstChild("RightHallDistant"):SetAttribute("IsOpen", true)
			end

			if currentTarget == patrolFolder:FindFirstChild("PlayRoom") then
				-- Freddy is in PlayRoom, open all halls
				patrolFolder:FindFirstChild("RightHallCorn"):SetAttribute("IsOpen", true)
				patrolFolder:FindFirstChild("RightHallWindow"):SetAttribute("IsOpen", true)
				patrolFolder:FindFirstChild("RightHallDistant"):SetAttribute("IsOpen", true)
				patrolFolder:FindFirstChild("LeftHallCorner"):SetAttribute("IsOpen", true)
				patrolFolder:FindFirstChild("LeftHallWindow"):SetAttribute("IsOpen", true)
				patrolFolder:FindFirstChild("LeftHallDistant"):SetAttribute("IsOpen", true)

				patrolFolder:FindFirstChild("StorageRoom"):SetAttribute("IsOpen", true)
			end

			if currentTarget:GetAttribute("IsOpen") == true then
				-- We use PivotTo on the MODEL, not the Part
				-- PivotTo is the modern way to move models while keeping their relative assembly
				freddyModel:PivotTo(currentTarget.CFrame + Vector3.new(0, 3, 0))
				LastNode = currentTarget
				print("MovementMod: Freddy relocated to: " .. currentTarget.Name)

				if currentTarget == OfficeNode then
					print("MovementMod: Freddy reached the office! Game over.")
					for _, player in pairs(players:GetPlayers()) do
						task.delay(1, function()
							local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
							hum.Health = 0

							game.ReplicatedStorage.Jumpscare:Play()
						end)
					end
				end
			else
				warn("Freddy is stuck! No valid nodes in range.")
			end
		end
	end

	-- Using task.defer ensures it doesn't hang the script that called it
	task.defer(moveFreddy)
end

return MovementMod
