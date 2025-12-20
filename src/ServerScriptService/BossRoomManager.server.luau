local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

-- ==========================================
-- 0. Auto-create required events
-- ==========================================
local RemoteEventFolder = ReplicatedStorage:FindFirstChild("RemoteEvent") or Instance.new("Folder", ReplicatedStorage)
RemoteEventFolder.Name = "RemoteEvent"

local BossEvent = RemoteEventFolder:FindFirstChild("BossEvent") or Instance.new("RemoteEvent", RemoteEventFolder)
BossEvent.Name = "BossEvent"

local BossDeathNotify = ServerStorage:FindFirstChild("BossDeathNotify") or Instance.new("BindableEvent", ServerStorage)
BossDeathNotify.Name = "BossDeathNotify"

-- ==========================================
-- Configuration Area (No longer hardcoded to single Boss)
-- ==========================================
-- State record: { [UserId] = {BossName = "xxx", RoomFolder = Folder} }
local playersInBossFight = {}

-- Helper function: Find corresponding room configuration by Boss name
-- Assumed map structure: Workspace -> Boss Area (Saharan Master) -> BossArenaSpawn
--                       Workspace -> Boss Area (New Boss) -> BossArenaSpawn
-- Recommend giving each Boss room folder a unique name, or create a mapping table here
local BOSS_LOCATIONS = {
	["Saharan Master"] = "Boss Area", -- Corresponding to Workspace["Boss Area"]
	["WolfBoss"] = "Forest Boss Area", -- <--- [Added] Your new Boss room folder name
	["DesertBoss"] = "Desert Boss Area",
	-- Add more Bosses here...
}

local function getLocations(bossName)
	local areaName = BOSS_LOCATIONS[bossName] or "Boss Area" -- Default value
	local area = Workspace:FindFirstChild(areaName)

	if not area then 
		-- Try to find folder named with Boss name directly in Workspace
		area = Workspace:FindFirstChild(bossName .. " Room") 
	end

	if not area then return nil, nil end
	return area:FindFirstChild("BossArenaSpawn"), area:FindFirstChild("BossRoomExitPoint")
end

-- ==========================================
-- 1. Player entry logic
-- ==========================================
BossEvent.OnServerEvent:Connect(function(player, action, arg1)
	if action == "EnterBossRoom" then
		-- Client should now send Boss name: BossEvent:FireServer("EnterBossRoom", "Saharan Master")
		local bossName = arg1 or "Saharan Master" -- Backward compatibility with old code, default to Saharan Master

		print("👉 [BossRoom] Player " .. player.Name .. " requests to challenge: " .. bossName)

		local spawnPoint, exitPoint = getLocations(bossName)
		if not spawnPoint then 
			warn("❌ [BossRoom] Teleport points not found, please check BOSS_LOCATIONS configuration")
			return 
		end

		-- Check if Boss exists (anti-cheat)
		local boss = Workspace:WaitForChild("NPCs"):FindFirstChild(bossName)
		if not boss then
			BossEvent:FireClient(player, "Error", "Boss is respawning (Cooldown 5min)")
			return
		end

		-- Teleport player
		local char = player.Character
		if char and char:FindFirstChild("HumanoidRootPart") then
			char.HumanoidRootPart.CFrame = spawnPoint.CFrame + Vector3.new(0, 3, 0)

			-- Record which Boss the player is fighting
			playersInBossFight[player.UserId] = {
				Name = bossName,
				ExitPoint = exitPoint
			}

			-- Listen for death (defeat condition)
			local humanoid = char:FindFirstChild("Humanoid")
			if humanoid then
				humanoid.Died:Connect(function()
					local fightInfo = playersInBossFight[player.UserId]
					if fightInfo then
						print("💀 [BossRoom] Player defeated: " .. player.Name)
						playersInBossFight[player.UserId] = nil 

						BossEvent:FireClient(player, "ShowResult", "Defeat")
						player:SetAttribute("RespawnAtBossExit", true)
						-- Temporarily store exit point name for respawn script to find
						player:SetAttribute("ExitTargetName", fightInfo.Name) 
					end
				end)
			end
		end
	end
end)

-- ==========================================
-- 2. Player respawn handling
-- ==========================================
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(char)
		if player:GetAttribute("RespawnAtBossExit") then
			player:SetAttribute("RespawnAtBossExit", nil) 
			local bossName = player:GetAttribute("ExitTargetName") or "Saharan Master"

			local _, exitPoint = getLocations(bossName)
			if exitPoint then
				task.wait(0.5) 
				local root = char:WaitForChild("HumanoidRootPart")
				if root then
					root.CFrame = exitPoint.CFrame + Vector3.new(0, 3, 0)
				end
			end
		end
	end)
end)

-- ==========================================
-- 3. Boss death logic (Victory handling)
-- ==========================================
BossDeathNotify.Event:Connect(function(deadBossName)
	print("⚔️ [BossRoom] Received death notification: " .. tostring(deadBossName))

	for userId, fightInfo in pairs(playersInBossFight) do
		-- Only players fighting this Boss count as victorious
		if fightInfo.Name == deadBossName then
			local player = Players:GetPlayerByUserId(userId)
			if player then
				print("🏆 [BossRoom] Victory: " .. player.Name)
				BossEvent:FireClient(player, "ShowResult", "Victory")

				-- Kick player out after 3 seconds
				task.delay(3, function()
					local char = player.Character
					if char and char:FindFirstChild("HumanoidRootPart") and fightInfo.ExitPoint then
						char.HumanoidRootPart.CFrame = fightInfo.ExitPoint.CFrame + Vector3.new(0, 3, 0)
					end
				end)
			end
			-- Clear state
			playersInBossFight[userId] = nil
		end
	end
end)