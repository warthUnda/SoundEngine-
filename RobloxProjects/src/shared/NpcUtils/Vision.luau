--!nolint CircularDependency

local VisionMod = {}

local Players = game:GetService("Players")

function VisionMod.Vision(npc)
	local npchrp = npc:FindFirstChild("HumanoidRootPart")
	if not npchrp then
		return
	end

	local NpcHumanoid = npc:FindFirstChild("Humanoid")
	if not NpcHumanoid then
		return
	end

	-- Initialize variables to track the nearest player detected
	local nearestPlayer = nil
	local shortestDistance = math.huge

	local Controller = require(game.ReplicatedStorage.Shared.NpcUtils.StateFred)

	local Pdata = Controller.GET(npc)

	for _, player in pairs(Players:GetPlayers()) do
		if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			local hrp = player.Character.HumanoidRootPart
			local distance = (hrp.Position - npchrp.Position).Magnitude

			local PlrHum = player.Character:FindFirstChild("Humanoid")

			if distance < shortestDistance then
				shortestDistance = distance
				nearestPlayer = player
				-- Check if player is within sensory range (50 studs)
				if distance < 50 then
					local head = npc:FindFirstChild("Head")

					local PlrChar = player.Character

					if head then
						local size = Vector3.new(50, 50, 50)

						local forwardOffset = head.CFrame.LookVector * 5
						local boxCFrame = head.CFrame + forwardOffset

						-- Define a box area in front of the NPC to check for players
						local parts = workspace:GetPartBoundsInBox(boxCFrame, size)
						print("VisionMod: Scanning box area for players")

						for _, part in ipairs(parts) do
							if part and part.Parent and part.Parent:FindFirstChild("Humanoid") then
								if part.Parent == nearestPlayer.Character then
									local direction = (hrp.Position - head.Position).Unit * 100

									local RaycastParams = RaycastParams.new()
									RaycastParams.FilterDescendantsInstances = { npc }
									RaycastParams.FilterType = Enum.RaycastFilterType.Exclude

									local RayResult = workspace:Raycast(head.Position, direction, RaycastParams)

									-- If the raycast hits something, check if it's the player
									if RayResult then
										local hitPart = RayResult.Instance

										local character = hitPart:FindFirstAncestorOfClass("Model")

										if character then
											local player = Players:GetPlayerFromCharacter(character)

											if player then
												print("Freddy sees: " .. player.Name)

												local playerLook = hrp.CFrame.LookVector
												local toFreddy = (npchrp.Position - hrp.Position).Unit
												local dot = playerLook:Dot(toFreddy)

												if dot < 0 then
													-- Player is looking away, Freddy creeps up
													Pdata.Behavior = "Creep"
													print("VisionMod: Freddy behavior set to Creep (Player looking away)")
												else
													-- Player is looking towards Freddy, Freddy chases
													Pdata.Behavior = "Chase"
													print("VisionMod: Freddy behavior set to Chase (Player looking towards)")
												end
											else
											end
										end
									else
									end
								end
							end
						end
					end
				end
			end
		end
	end

	return nearestPlayer, shortestDistance
end

return VisionMod
