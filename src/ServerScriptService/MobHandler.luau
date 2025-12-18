local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

local MobHandler = {}

-- ==========================================
-- 配置区
-- ==========================================
local RESPAWN_TIME = 300       -- 复活冷却: 5分钟
local CORPSE_LIFETIME = 3      -- 尸体保留时间

-- 存储怪物模板
local MobRegistry = {} 
local mobTemplateFolder = ServerStorage:FindFirstChild("MobTemplates")
if not mobTemplateFolder then
	mobTemplateFolder = Instance.new("Folder")
	mobTemplateFolder.Name = "MobTemplates"
	mobTemplateFolder.Parent = ServerStorage
end

-- 记录复活时间
MobHandler.DeadBosses = {} 

function MobHandler.getRespawnTime(mobName)
	return MobHandler.DeadBosses[mobName]
end

-- ==========================================
-- 辅助功能：给予物品 (保留你的掉落逻辑)
-- ==========================================
local function giveItemToPlayer(player, itemName)
	local tool = ServerStorage:FindFirstChild("Tools") and ServerStorage.Tools:FindFirstChild(itemName)
	if not tool then
		tool = ServerStorage:FindFirstChild("Items") and ServerStorage.Items:FindFirstChild(itemName)
	end

	if tool then
		local clone = tool:Clone()
		clone.Parent = player.Backpack

		-- 写入库存数据
		local inventory = player:FindFirstChild("Inventory")
		if inventory then
			local itemVal = inventory:FindFirstChild(itemName)
			if not itemVal then
				itemVal = Instance.new("IntValue")
				itemVal.Name = itemName
				itemVal.Value = 0
				itemVal.Parent = inventory
			end
			itemVal.Value = itemVal.Value + 1
		end
		return true
	else
		warn("❌ [MobHandler] 掉落物 '"..itemName.."' 在 ServerStorage 中找不到！")
		return false
	end
end

-- ==========================================
-- 核心逻辑：处理怪物死亡周期
-- ==========================================
local function handleMobLifecycle(mob, originCFrame)
	local humanoid = mob:WaitForChild("Humanoid", 10)
	if not humanoid then return end

	-- 监听死亡
	humanoid.Died:Connect(function()
		print("💀 [MobHandler] " .. mob.Name .. " 已死亡")

		-- [新增] 1. 记录复活时间 (防止还没复活就被识别为存在)
		MobHandler.DeadBosses[mob.Name] = os.time() + RESPAWN_TIME

		-- 获取击杀者
		local creatorTag = humanoid:FindFirstChild("creator")
		local killerPlayer = creatorTag and creatorTag.Value

		if killerPlayer then
			print("    🗡️ 击杀者: " .. killerPlayer.Name)
			local mobConfig = GameConfig.Mobs[mob.Name]

			if mobConfig then
				-- A. 给予经验
				local leaderstats = killerPlayer:FindFirstChild("leaderstats")
				if leaderstats and leaderstats:FindFirstChild("Experience") then
					leaderstats.Experience.Value = leaderstats.Experience.Value + mobConfig.Exp
				end

				-- B. 给予金币 (如果配置有)
				if leaderstats and leaderstats:FindFirstChild("Gold") and mobConfig.GoldReward then
					leaderstats.Gold.Value = leaderstats.Gold.Value + mobConfig.GoldReward
				end

				-- C. 更新任务进度 (Quest)
				local hiddenStats = killerPlayer:FindFirstChild("HiddenStats")
				if hiddenStats and GameConfig.Quests then
					for questID, questData in pairs(GameConfig.Quests) do
						if questData.TargetMob == mob.Name then
							local questStat = hiddenStats:FindFirstChild("Quest_" .. questID)
							if questStat and questStat.Value < questData.TargetCount then
								questStat.Value = questStat.Value + 1
								-- 简单的任务完成即时奖励
								if questStat.Value == questData.TargetCount and questData.GoldReward then
									if leaderstats and leaderstats.Gold then
										leaderstats.Gold.Value = leaderstats.Gold.Value + questData.GoldReward
									end
								end
							end
						end
					end
				end

				-- D. 物品掉落 (Drops)
				if mobConfig.Drops then
					for _, dropData in pairs(mobConfig.Drops) do
						if math.random() <= dropData.Chance then
							local success = giveItemToPlayer(killerPlayer, dropData.ItemName)
							if success then
								print("    🎁 掉落物品: " .. dropData.ItemName)
							end
						end
					end
				end
			end
		end

		-- [关键] 2. 通知 BossRoomManager (胜利结算)
		local notifyEvent = ServerStorage:FindFirstChild("BossDeathNotify")
		if notifyEvent then
			print("📡 [MobHandler] 发送 Boss 死亡通知: " .. mob.Name)
			notifyEvent:Fire(mob.Name)
		else
			-- 为了防止首次运行找不到事件，尝试去 _G 找 (备用方案)
			if _G.BossRoomManager then
				_G.BossRoomManager.onBossDeath(mob.Name)
			else
				warn("⚠️ [MobHandler] 找不到 BossDeathNotify 事件，也找不到 _G.BossRoomManager！")
			end
		end

		-- 3. 尸体清理
		task.delay(CORPSE_LIFETIME, function()
			if mob and mob.Parent then mob:Destroy() end
		end)

		-- 4. 复活倒计时
		task.delay(RESPAWN_TIME, function()
			MobHandler.respawnMob(mob.Name, originCFrame)
		end)
	end)
end

-- ==========================================
-- 复活与初始化功能
-- ==========================================
function MobHandler.respawnMob(mobName, spawnCFrame)
	local template = MobRegistry[mobName]
	if template then
		MobHandler.DeadBosses[mobName] = nil -- 清除死亡记录

		local newMob = template:Clone()
		newMob.Name = mobName
		local root = newMob:FindFirstChild("HumanoidRootPart") or newMob:FindFirstChild("Torso")
		if root then root.CFrame = spawnCFrame else newMob:PivotTo(spawnCFrame) end

		newMob.Parent = Workspace:WaitForChild("NPCs")

		-- 重新绑定生命周期
		handleMobLifecycle(newMob, spawnCFrame)
		MobHandler.setupMob(newMob)

		print("✨ " .. mobName .. " 已复活！")
	end
end

function MobHandler.setupMob(mob)
	local config = GameConfig.Mobs[mob.Name]
	if not config then return end

	local humanoid = mob:WaitForChild("Humanoid", 10)
	if humanoid then
		humanoid.MaxHealth = config.MaxHealth
		humanoid.Health = config.MaxHealth
		humanoid.WalkSpeed = config.WalkSpeed or 12
	end
end

-- ==========================================
-- 初始化：扫描现有怪物并建立模板
-- ==========================================
local npcFolder = Workspace:WaitForChild("NPCs")

for _, mob in pairs(npcFolder:GetChildren()) do
	if GameConfig.Mobs[mob.Name] then
		local root = mob:FindFirstChild("HumanoidRootPart") or mob:FindFirstChild("Torso")
		local originCF = root and root.CFrame or mob:GetPivot()

		-- 创建备份模板 (用于复活)
		if not MobRegistry[mob.Name] then
			local template = mob:Clone()
			for _, script in pairs(template:GetDescendants()) do
				if script:IsA("Script") then script:Destroy() end
			end
			template.Parent = mobTemplateFolder
			MobRegistry[mob.Name] = template
		end

		handleMobLifecycle(mob, originCF)
		MobHandler.setupMob(mob)
	end
end

return MobHandler