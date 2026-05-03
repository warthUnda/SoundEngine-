local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Hitbox = {}
Hitbox.__index = Hitbox

export type HitboxObject = {
	Damage: number,
	Size: Vector3,
	Active: boolean,

	DelayDestroy: number,

	Part: Part,

	Start: (self: HitboxObject) -> (),
	Stop: (self: HitboxObject) -> (),
}

function Hitbox.New(dmg: number, Vector3Param: Vector3, DelayNum: number): HitboxObject
	local self = setmetatable({}, Hitbox)

	self.Damage = dmg
	self.Size = Vector3.new(Vector3Param.X, Vector3Param.Y, Vector3Param.Z)
	self.Active = false

	self.DelayDestroy = DelayNum

	local HitboxPart = Instance.new("Part")
	HitboxPart.Name = "ActiveHitboxPart"
	HitboxPart.Size = self.Size
	HitboxPart.Anchored = true
	HitboxPart.CanCollide = false
	HitboxPart.Transparency = 0.7
	HitboxPart.Parent = workspace

	self.Part = HitboxPart

	print("Hitbox: Created new hitbox with " .. dmg .. " damage")
	self:Start()

	return self
end

function Hitbox:Start()
	local HasHit = false
	self.Active = true

	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {}

	local size = Vector3.new(self.Size.X, self.Size.Y, self.Size.Z)

	task.spawn(function()
		task.delay(self.DelayDestroy, function()
			self:Stop()
		end)

		while true do
			task.wait(0.1)
			if not self.Active then
				-- Clean up the hitbox part when it is no longer active
				self.Part:Destroy()
				print("Hitbox: Hitbox deactivated and part destroyed")
				break
			end

			local pos = self.Owner.PrimaryPart.CFrame * CFrame.new(0, 0, -3)
			-- Check for intersections within the hitbox volume
			local parts = workspace:GetPartBoundsInBox(pos, size, params)

			for _, part in parts do
				local model = part:FindFirstAncestorOfClass("Model")
				if not model then
					continue
				end

				local hum = model:FindFirstChildOfClass("Humanoid")
				if not hum or hum.Health <= 0 then
					continue
				end

				if model:GetAttribute("Invulnerable") == true then
					continue
				end

				local isOwner = (model == self.Owner)

				if RunService:IsClient() then
					HasHit = true

					print("Hitbox: Client detected hit on " .. model.Name)

					Hitbox:Stop()
					return HasHit
				elseif RunService:IsServer() then
					-- Apply invulnerability frame on server to prevent multiple hits
					model:SetAttribute("Invulnerable", true)

					HasHit = true
					print("Hitbox: Server detected hit on " .. model.Name)

					task.delay(1, function()
						model:SetAttribute("Invulnerable", false)
					end)

					Hitbox:Stop()
					return HasHit
				end
			end
		end
	end)
end

function Hitbox:Stop()
	self.Active = false
end

return Hitbox
