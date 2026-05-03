local CoreCount = 3
local Workerscript = script.Parent:WaitForChild("WorkerScript")

local FolderGuy = workspace:FindFirstChild("FolderGuy") or Instance.new("Folder")
FolderGuy.Name = "FolderGuy"
FolderGuy.Parent = workspace
FolderGuy:ClearAllChildren()
print("MasterScript: Initialized FolderGuy for actors")

local SoundFolder = workspace:FindFirstChild("SoundFolder") or Instance.new("Folder")
SoundFolder.Name = "SoundFolder"
SoundFolder.Parent = workspace
print("MasterScript: Initialized SoundFolder for pooled sounds")

for i = 1, CoreCount do
	local actor = Instance.new("Actor")
	actor.Parent = FolderGuy

	actor.Name = "Actor_" .. i
	print("MasterScript: Spawned " .. actor.Name)

	local Binfold = Instance.new("Folder")
	Binfold.Parent = actor
	Binfold.Name = "Bin"

	local Activefold = Instance.new("Folder")
	Activefold.Parent = actor
	Activefold.Name = "Active"

	local NewWorker = Workerscript:Clone()
	NewWorker.Name = "WorkerScript_" .. i
	NewWorker.Enabled = true
	NewWorker.Parent = actor
	print("MasterScript: Initialized " .. NewWorker.Name .. " in " .. actor.Name)
end

local ServicesToScan = { workspace, game.ReplicatedStorage, game.ServerStorage }

-- Run this ONCE at start
for _, service in ServicesToScan do
	for _, item in service:GetDescendants() do
		-- Check if it's a Sound and NOT already in the SoundFolder
		-- This logic ensures we don't index sounds that are already part of the pool
		if item:IsA("Sound") and not item:IsDescendantOf(SoundFolder) then
			if item:GetAttribute("Indexed") == nil or item:GetAttribute("Indexed") == false then
				local NewSound = item:Clone()
				-- Strip the sound of its current play state to save memory
				NewSound.Playing = false
				NewSound.Parent = SoundFolder
				NewSound:SetAttribute("Indexed", true)

				print("Successfully Indexed & Pooled: " .. item.Name)
			end
		end
	end
end

local SoundEffect = game.ReplicatedStorage.BLASTAWAY
local SoundPart = game.Workspace.SoundPart

local SoundBounce = require(game.ReplicatedStorage.Shared.Sound.SoundBounce)

SoundBounce.PartCreation()
for i = 1, 20 do
	task.wait(2)
	SoundBounce.new(3, SoundPart, SoundPart.CFrame, SoundEffect, 100)
end

print("DOMAIN EXPANSION COMPLETE: All sounds pooled.")
