local HalucinationMovement = {}

export type HalucinationMovement = {
	owner: Part,
	HasHit: boolean,

	Destroy: boolean,

	rotationSpawn: Vector3,
	spawnLocation: Vector3,
}

local TableOfPositions = game.Workspace.PatrollingParts:GetChildren()
function HalucinationMovement.Creation(npc: Model): HalucinationMovement
	local Controller = require(game.ReplicatedStorage.Shared.NpcUtils.StateFred)

	local self = setmetatable({}, HalucinationMovement)

	local NpcCloned = npc:Clone()
	NpcCloned.Name = "HallucinationNPC_" .. npc.Name
	NpcCloned.Parent = workspace
	print("MovementHals: Cloned hallucination NPC: " .. NpcCloned.Name)

	self.owner = NpcCloned
	self.spawnLocation = NpcCloned.HumanoidRootPart.CFrame

	print("MovementHals: Initialized hallucination at " .. tostring(self.spawnLocation))
	return self
end

function HalucinationMovement:StopHal()
	-- Teleport the hallucination back to its original spawn point
	self.owner.CFrame = self.spawnLocation
	print("MovementHals: Hallucination stopped and reset to spawn")
end

function HalucinationMovement:Patrol()
	local Movement = require(game.ReplicatedStorage.Shared.NpcUtils.MovementMod)

	-- Start the patrol behavior loop for the hallucination
	Movement.Patrol(self.owner, TableOfPositions)
	print("MovementHals: Hallucination patrol started")
end

return HalucinationMovement
