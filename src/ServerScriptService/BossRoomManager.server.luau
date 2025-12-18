local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

-- ==========================================
-- 0. 自动补全必要的事件
-- ==========================================
local RemoteEventFolder = ReplicatedStorage:FindFirstChild("RemoteEvent") or Instance.new("Folder", ReplicatedStorage)
RemoteEventFolder.Name = "RemoteEvent"

local BossEvent = RemoteEventFolder:FindFirstChild("BossEvent") or Instance.new("RemoteEvent", RemoteEventFolder)
BossEvent.Name = "BossEvent"

local BossDeathNotify = ServerStorage:FindFirstChild("BossDeathNotify") or Instance.new("BindableEvent", ServerStorage)
BossDeathNotify.Name = "BossDeathNotify"

-- ==========================================
-- 配置区 (不再写死单一 Boss)
-- ==========================================
-- 状态记录: { [UserId] = {BossName = "xxx", RoomFolder = Folder} }
local playersInBossFight = {}

-- 辅助函数：根据 Boss 名字找到对应的房间配置
-- 假设你的地图结构是: Workspace -> Boss Area (Saharan Master) -> BossArenaSpawn
--                     Workspace -> Boss Area (New Boss) -> BossArenaSpawn
-- 建议给每个 Boss 房间的文件夹起个独特的名字，或者在这里做个映射表
local BOSS_LOCATIONS = {
	["Saharan Master"] = "Boss Area", -- 对应 Workspace["Boss Area"]
	["Forest King"] = "Forest Boss Area", -- <--- [新增] 你的新 Boss 房间文件夹名字
	-- 在这里添加更多 Boss...
}

local function getLocations(bossName)
	local areaName = BOSS_LOCATIONS[bossName] or "Boss Area" -- 默认值
	local area = Workspace:FindFirstChild(areaName)

	if not area then 
		-- 尝试直接在 Workspace 找以 Boss 名字命名的文件夹
		area = Workspace:FindFirstChild(bossName .. " Room") 
	end

	if not area then return nil, nil end
	return area:FindFirstChild("BossArenaSpawn"), area:FindFirstChild("BossRoomExitPoint")
end

-- ==========================================
-- 1. 玩家进入逻辑
-- ==========================================
BossEvent.OnServerEvent:Connect(function(player, action, arg1)
	if action == "EnterBossRoom" then
		-- 客户端现在应该发送 Boss 名字: BossEvent:FireServer("EnterBossRoom", "Saharan Master")
		local bossName = arg1 or "Saharan Master" -- 兼容旧代码，默认为 Saharan Master

		print("👉 [BossRoom] 玩家 " .. player.Name .. " 请求挑战: " .. bossName)

		local spawnPoint, exitPoint = getLocations(bossName)
		if not spawnPoint then 
			warn("❌ [BossRoom] 找不到传送点，请检查 BOSS_LOCATIONS 配置")
			return 
		end

		-- 检查 Boss 是否存在 (防作弊)
		local boss = Workspace:WaitForChild("NPCs"):FindFirstChild(bossName)
		if not boss then
			BossEvent:FireClient(player, "Error", "Boss is respawning (Cooldown 5min)")
			return
		end

		-- 传送
		local char = player.Character
		if char and char:FindFirstChild("HumanoidRootPart") then
			char.HumanoidRootPart.CFrame = spawnPoint.CFrame + Vector3.new(0, 3, 0)

			-- 记录玩家正在打哪个 Boss
			playersInBossFight[player.UserId] = {
				Name = bossName,
				ExitPoint = exitPoint
			}

			-- 监听死亡 (失败判定)
			local humanoid = char:FindFirstChild("Humanoid")
			if humanoid then
				humanoid.Died:Connect(function()
					local fightInfo = playersInBossFight[player.UserId]
					if fightInfo then
						print("💀 [BossRoom] 玩家失败: " .. player.Name)
						playersInBossFight[player.UserId] = nil 

						BossEvent:FireClient(player, "ShowResult", "Defeat")
						player:SetAttribute("RespawnAtBossExit", true)
						-- 临时存一下出口位置名，以便复活脚本找到
						player:SetAttribute("ExitTargetName", fightInfo.Name) 
					end
				end)
			end
		end
	end
end)

-- ==========================================
-- 2. 玩家复活处理
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
-- 3. Boss 死亡逻辑 (胜利处理)
-- ==========================================
BossDeathNotify.Event:Connect(function(deadBossName)
	print("⚔️ [BossRoom] 收到死亡通知: " .. tostring(deadBossName))

	for userId, fightInfo in pairs(playersInBossFight) do
		-- 只有正在打这个 Boss 的玩家才算赢
		if fightInfo.Name == deadBossName then
			local player = Players:GetPlayerByUserId(userId)
			if player then
				print("🏆 [BossRoom] 胜利: " .. player.Name)
				BossEvent:FireClient(player, "ShowResult", "Victory")

				-- 3秒后踢出
				task.delay(3, function()
					local char = player.Character
					if char and char:FindFirstChild("HumanoidRootPart") and fightInfo.ExitPoint then
						char.HumanoidRootPart.CFrame = fightInfo.ExitPoint.CFrame + Vector3.new(0, 3, 0)
					end
				end)
			end
			-- 清除状态
			playersInBossFight[userId] = nil
		end
	end
end)