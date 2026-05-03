local Players = game:GetService("Players")

local NpcData = {}
local Data = {}

local TotalWeight = 0

local TacticModules = {
	deception = require(game.ReplicatedStorage.Shared.NpcUtils.Tactics.DeceptionTactics),
}

local Tactics = {
	["FakeRunAway"] = {
		Speed = 24,
		functionComp = TacticModules.deception.FakeRunAway,
		Chance = 0.5,
	},
}

function Data.GET(npcInstance)
	-- Initialize NPC state data if it doesn't already exist
	if not NpcData[npcInstance] then
		print("StateFred: Initializing state data for " .. npcInstance.Name)
		NpcData[npcInstance] = {
			Speed = 0,

			Behavior = "",
			lastBehaviour = nil,

			Interrupted = false,

			ElapsedTime = 0,
			ElapsedCount = 0,

			PlayerOnCam = false,

			DurationWalk = 0,
			NumberInTable = 5,
		}
	end
	return NpcData[npcInstance]
end

function Data.REM(npcInstance)
	-- Clean up NPC state data from memory
	print("StateFred: Removing state data for " .. npcInstance.Name)
	NpcData[npcInstance] = nil
end

function Data.Controller(Freddy, hum, Root)
	local PData = Data.GET(Freddy)

	Tactics.FakeRunAway.functionComp(Freddy)

	game.ReplicatedStorage.Remotes.CamTimer.OnServerEvent:Connect(function(player, elapsedTime)
		-- Update elapsed time based on camera usage reported by client
		PData.ElapsedTime = elapsedTime
		print("StateFred: Updated ElapsedTime for " .. player.Name .. ": " .. elapsedTime)
	end)

	game.ReplicatedStorage.Remotes.CamActivation.OnServerEvent:Connect(function(player)
		-- Set flag when player activates camera view
		PData.PlayerOnCam = true
		print("StateFred: Player " .. player.Name .. " is now viewing cameras")
	end)

	game.ReplicatedStorage.Remotes.CamActivation.OnServerEvent:Connect(function(player)
		-- Set flag when player deactivates camera view
		PData.PlayerOnCam = false
		print("StateFred: Player " .. player.Name .. " stopped viewing cameras")
	end)

	local Visions = require(game.ReplicatedStorage.Shared.NpcUtils.Vision)
	local Movement = require(game.ReplicatedStorage.Shared.NpcUtils.MovementMod)

	local Deceptions = require(game.ReplicatedStorage.Shared.NpcUtils.Tactics.DeceptionTactics)

	local patrolPoints = game.Workspace.PatrollingParts

	local officeNode = workspace.PatrollingParts:FindFirstChild("OfficeNode")
	-- Initiate the patrol behavior loop
	Movement.Patrol(Freddy, patrolPoints, officeNode)
	print("StateFred: Patrol loop started for Freddy")
end

return Data
