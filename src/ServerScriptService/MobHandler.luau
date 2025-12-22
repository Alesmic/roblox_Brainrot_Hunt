local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

local MobHandler = {}

-- ==========================================
-- 配置区
-- ==========================================
local RESPAWN_TIME = 300       -- 默认重生时间 (5分钟)
local CORPSE_LIFETIME = 3      -- 尸体保留时间 (秒)

-- [新增] Boss 识别关键词 (名字里带这些的都算 Boss)
local BOSS_KEYWORDS = {"Boss", "Guardian", "Master"}

-- [新增] Boss 白名单 (名字里没关键词，但你想算作 Boss 的可以加在这里)
local BOSS_WHITELIST = {
	["WolfBoss"] = true, -- 示例
	["DesertKing"] = true,
}

-- 存储怪物模板
local MobRegistry = {} 
local mobTemplateFolder = ServerStorage:FindFirstChild("MobTemplates")
if not mobTemplateFolder then
	mobTemplateFolder = Instance.new("Folder")
	mobTemplateFolder.Name = "MobTemplates"
	mobTemplateFolder.Parent = ServerStorage
end

-- 记录重生时间
MobHandler.DeadBosses = {} 

function MobHandler.getRespawnTime(mobName)
	return MobHandler.DeadBosses[mobName]
end

-- ==========================================
-- 辅助功能：判断是否为 Boss
-- ==========================================
local function isBoss(mobName)
	-- 1. 检查白名单
	if BOSS_WHITELIST[mobName] then return true end

	-- 2. 检查关键词匹配
	for _, keyword in ipairs(BOSS_KEYWORDS) do
		if string.find(mobName, keyword) then
			return true
		end
	end

	return false
end

-- ==========================================
-- 辅助功能：触发客户端弹窗
-- ==========================================
local function notifyClient(player, title, gold, exp)
	local RemoteEventFolder = ReplicatedStorage:FindFirstChild("RemoteEvent")
	if RemoteEventFolder then
		local notifyEvent = RemoteEventFolder:FindFirstChild("QuestCompleted")
		if notifyEvent then
			notifyEvent:FireClient(player, title, gold, exp)
		end
	end
end

-- ==========================================
-- 辅助功能：给玩家发放物品 (防重复逻辑)
-- ==========================================
local function giveItemToPlayer(player, itemName)
	-- 1. 获取物品配置
	local itemConfig = GameConfig.Weapons[itemName] or GameConfig.Items[itemName]

	-- 如果是武器，执行唯一性检查
	if itemConfig and itemConfig.Category == "Weapons" then
		-- 检查背包或初始装备
		if player.Backpack:FindFirstChild(itemName) or player.StarterGear:FindFirstChild(itemName) then
			print("⚠️ [MobHandler] 玩家已有武器: " .. itemName .. "，跳过掉落。")
			return false
		end

		-- 检查数据层
		local inv = player:FindFirstChild("Inventory")
		if inv and inv:FindFirstChild(itemName) and inv[itemName].Value >= 1 then
			return false
		end
	end

	-- 查找物品模型
	local tool = ServerStorage:FindFirstChild("Tools") and ServerStorage.Tools:FindFirstChild(itemName)
	if not tool then
		tool = ServerStorage:FindFirstChild("Items") and ServerStorage.Items:FindFirstChild(itemName)
	end

	if tool then
		-- 发放到背包
		if not player.Backpack:FindFirstChild(itemName) then
			local clone = tool:Clone()
			clone.Parent = player.Backpack
		end

		-- 发放到 StarterGear (确保重生不丢)
		if not player.StarterGear:FindFirstChild(itemName) then
			tool:Clone().Parent = player.StarterGear
		end

		-- 更新 Inventory 数据
		local inventory = player:FindFirstChild("Inventory")
		if inventory then
			local itemVal = inventory:FindFirstChild(itemName)
			if not itemVal then
				itemVal = Instance.new("IntValue")
				itemVal.Name = itemName
				itemVal.Value = 0
				itemVal.Parent = inventory
			end

			if itemConfig and itemConfig.Category == "Weapons" then
				itemVal.Value = 1
			else
				itemVal.Value = itemVal.Value + 1
			end
		end
		return true
	else
		warn("❌ [MobHandler] Loot item '"..itemName.."' not found in ServerStorage!")
		return false
	end
end

-- ==========================================
-- 核心逻辑：怪物生命周期管理
-- ==========================================
local function handleMobLifecycle(mob, originCFrame)
	local humanoid = mob:WaitForChild("Humanoid", 10)
	if not humanoid then return end

	-- 监听死亡
	humanoid.Died:Connect(function()
		print("💀 [MobHandler] " .. mob.Name .. " has died")

		-- 1. 记录死亡时间
		MobHandler.DeadBosses[mob.Name] = os.time() + RESPAWN_TIME

		-- 获取击杀者
		local creatorTag = humanoid:FindFirstChild("creator")
		local killerPlayer = creatorTag and creatorTag.Value

		if killerPlayer then
			print("    🗡️ Killer: " .. killerPlayer.Name)
			local mobConfig = GameConfig.Mobs[mob.Name]

			if mobConfig then
				-- A. 给予经验
				local leaderstats = killerPlayer:FindFirstChild("leaderstats")
				if leaderstats and leaderstats:FindFirstChild("Experience") then
					leaderstats.Experience.Value = leaderstats.Experience.Value + mobConfig.Exp
				end

				-- B. 给予金币
				if leaderstats and leaderstats:FindFirstChild("Gold") and mobConfig.GoldReward then
					leaderstats.Gold.Value = leaderstats.Gold.Value + mobConfig.GoldReward
				end

				-- [修改] 仅当是 Boss 时，才触发击杀奖励弹窗
				if isBoss(mob.Name) then
					notifyClient(killerPlayer, "Defeated " .. mob.Name, mobConfig.GoldReward or 0, mobConfig.Exp)
				end

				-- C. 更新任务进度
				local hiddenStats = killerPlayer:FindFirstChild("HiddenStats")
				if hiddenStats and GameConfig.Quests then
					for questID, questData in pairs(GameConfig.Quests) do
						if questData.TargetMob == mob.Name then
							local questStat = hiddenStats:FindFirstChild("Quest_" .. questID)

							if questStat and questStat.Value < questData.TargetCount then
								questStat.Value = questStat.Value + 1

								-- 任务完成逻辑
								if questStat.Value == questData.TargetCount then
									-- 发放任务奖励
									if questData.GoldReward and leaderstats and leaderstats.Gold then
										leaderstats.Gold.Value = leaderstats.Gold.Value + questData.GoldReward
									end
									if questData.ExpReward and leaderstats and leaderstats.Experience then
										leaderstats.Experience.Value = leaderstats.Experience.Value + questData.ExpReward
									end

									-- [保留] 任务完成总是弹窗
									notifyClient(killerPlayer, "Completed: " .. questData.Name, questData.GoldReward, questData.ExpReward)
								end
							end
						end
					end
				end

				-- D. 物品掉落
				if mobConfig.Drops then
					for _, dropData in pairs(mobConfig.Drops) do
						if math.random() <= dropData.Chance then
							local success = giveItemToPlayer(killerPlayer, dropData.ItemName)
							if success then
								print("    🎁 Dropped item: " .. dropData.ItemName)
							end
						end
					end
				end
			end
		end

		-- 2. 通知 Boss 房间管理器 (如果存在)
		local notifyEvent = ServerStorage:FindFirstChild("BossDeathNotify")
		if notifyEvent then
			notifyEvent:Fire(mob.Name)
		end

		-- 3. 尸体清理
		task.delay(CORPSE_LIFETIME, function()
			if mob and mob.Parent then mob:Destroy() end
		end)

		-- 4. 启动重生倒计时
		task.delay(RESPAWN_TIME, function()
			MobHandler.respawnMob(mob.Name, originCFrame)
		end)
	end)
end

-- ==========================================
-- 重生与初始化函数
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

		handleMobLifecycle(newMob, spawnCFrame)
		MobHandler.setupMob(newMob)

		print("✨ " .. mobName .. " has respawned!")
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
-- 初始化：扫描现有怪物
-- ==========================================
local npcFolder = Workspace:WaitForChild("NPCs")

for _, mob in pairs(npcFolder:GetChildren()) do
	if GameConfig.Mobs[mob.Name] then
		local root = mob:FindFirstChild("HumanoidRootPart") or mob:FindFirstChild("Torso")
		local originCF = root and root.CFrame or mob:GetPivot()

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