local ModelMath = {}

function ModelMath.DotProduct(Watcher: Part, ObservePart: Part)
	-- Use the Dot Product to determine if the Watcher is facing the ObservePart
	local playerLook = Watcher.CFrame.LookVector
	local toFreddy = (Watcher.Position - ObservePart.Position).Unit
	local dot = playerLook:Dot(toFreddy)

	if dot < 0 then
		print("ModelMath: DotProduct result - NotFacing")
		return "NotFacing"
	else
		print("ModelMath: DotProduct result - Facing")
		return "Facing"
	end
end

function ModelMath.ReflectRotation(Projectile: Part, direction: Vector3, HitNormal: Vector3): Vector3
	-- Standard reflection formula: R = D - 2 * (D . N) * N
	local n = HitNormal.Unit
	local newDirection = direction - 2 * (direction:Dot(n)) * n

	-- Update the projectile's CFrame to look towards the new reflected direction
	Projectile.CFrame = CFrame.lookAt(Projectile.Position, Projectile.Position + newDirection)

	return newDirection
end

return ModelMath
