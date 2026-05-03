local module = {}

local stomp = game.ReplicatedStorage.BLASTAWAY
function module.FakeRunAway(freddy)
	print("DeceptionTactics: Activating FakeRunAway for " .. freddy.Name)
	local Controller = require(game.ReplicatedStorage.Shared.NpcUtils.StateFred)
	local SoundBounce = require(game.ReplicatedStorage.Shared.Sound.SoundBounce)
	local PData = Controller.GET(freddy)

	local hum = freddy:FindFirstChild("Humanoid")
	if not hum then
		warn("DeceptionTactics: Humanoid missing for " .. freddy.Name)
		return
	end

	-- Identify the foot to attach sounds or effects to
	local Foot = freddy:WaitForChild("RightFoot")
	local SoundPart = game.Workspace.SoundPart
	print("DeceptionTactics: Setup complete for FakeRunAway")
end

return module
