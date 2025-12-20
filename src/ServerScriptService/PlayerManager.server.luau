local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

-- 引入配置
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

-- [⚠️IMPORTANT] 修改版本号以重置数据 (测试用)
local PlayerDataStore = DataStoreService:GetDataStore("RPG_Data_v6_FixReward")

local JAPANESE_HOUSE_SPAWN = Vector3.new(-783.183, 36.304, 220.17)

-- ==========================================
-- 1. 自动确保 RemoteEvent 存在 (核心修复)
-- ==========================================
local function ensureFolder(name)
	local folder = ReplicatedStorage:FindFirstChild(name)
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = name
		folder.Parent = ReplicatedStorage
	end
	return folder
end

local RemoteEventFolder = ensureFolder("RemoteEvent")

local function ensureEvent(name)
	local ev = RemoteEventFolder:FindFirstChild(name)
	if not ev then
		ev = Instance.new("RemoteEvent")
		ev.Name = name
		ev.Parent = RemoteEventFolder
		print("🔨 [PlayerManager] 自动创建 RemoteEvent: " .. name)
	end
	return ev
end

local startTutorialEvent = ensureEvent("StartTutorial")
local finishTalkEvent = ensureEvent("FinishTutorialTalk") -- 修复点：确保它存在！
local UpdatePvPUIEvent = ensureEvent("UpdatePvPUI")

-- ==========================================
-- 2. 玩家加入逻辑
-- ==========================================
Players.PlayerAdded:Connect(function(player)
	print("[PlayerManager] Player joined: " .. player.Name)

	-- 1. 创建基础属性 (leaderstats)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local level = Instance.new("IntValue")
	level.Name = "Level"
	level.Parent = leaderstats

	local gold = Instance.new("IntValue")
	gold.Name = "Gold"
	gold.Parent = leaderstats

	local experience = Instance.new("IntValue")
	experience.Name = "Experience"
	experience.Value = 0
	experience.Parent = leaderstats

	-- [辅助函数] 更新血量
	local function updateHealthBasedOnLevel(humanoid, currentLevel)
		if not humanoid then return end
		local rewards = GameConfig.Leveling.RewardsPerLevel
		local baseHealth = GameConfig.DefaultPlayer.MaxHealth
		local newMaxHealth = baseHealth + ((currentLevel - 1) * rewards.HealthBonus)

		humanoid.MaxHealth = newMaxHealth
		humanoid.Health = newMaxHealth
		print("💪 [Stats] 血量已更新为 " .. newMaxHealth .. " (Lv." .. currentLevel .. ")")
	end

	-- 监听升级
	experience.Changed:Connect(function(newXp)
		local currentLevel = level.Value
		local xpRequired = GameConfig.Leveling.GetXpRequired(currentLevel)

		if newXp >= xpRequired then
			level.Value = currentLevel + 1
			experience.Value = newXp - xpRequired 
			print("🎉 [Server] " .. player.Name .. " 升级到了 Lv." .. level.Value .. "!")

			local char = player.Character
			if char then
				local hum = char:FindFirstChild("Humanoid")
				if hum then updateHealthBasedOnLevel(hum, level.Value) end
			end
		end
	end)

	local hiddenStats = Instance.new("Folder")
	hiddenStats.Name = "HiddenStats"
	hiddenStats.Parent = player

	-- 教程完成状态
	local tutorialCompleted = Instance.new("BoolValue")
	tutorialCompleted.Name = "TutorialCompleted"
	tutorialCompleted.Value = false 
	tutorialCompleted.Parent = hiddenStats

	local pvpMode = Instance.new("BoolValue") 
	pvpMode.Name = "PvPMode"
	pvpMode.Value = false
	pvpMode.Parent = hiddenStats 

	local cityPvPActive = Instance.new("BoolValue") 
	cityPvPActive.Name = "CityPvPActive"
	cityPvPActive.Value = false
	cityPvPActive.Parent = hiddenStats 

	-- Inventory 文件夹
	local inventory = Instance.new("Folder")
	inventory.Name = "Inventory"
	inventory.Parent = player

	-- 清理 StarterGear
	local function cleanStarterGear()
		local gear = player:WaitForChild("StarterGear", 10)
		if not gear then return end
		local seen = {}
		for _, child in pairs(gear:GetChildren()) do
			if child:IsA("Tool") then
				if seen[child.Name] then
					task.delay(0, function() child:Destroy() end)
				else
					seen[child.Name] = true
				end
			end
		end
	end
	cleanStarterGear()

	-- 3. 角色重生逻辑
	player.CharacterAdded:Connect(function(character)
		character:WaitForChild("HumanoidRootPart").CFrame = CFrame.new(JAPANESE_HOUSE_SPAWN)

		-- 应用等级血量
		local humanoid = character:WaitForChild("Humanoid")
		if level.Value > 1 then
			updateHealthBasedOnLevel(humanoid, level.Value)
		end

		-- 清理背包重复项
		local backpack = player:WaitForChild("Backpack")
		local seenTools = {}
		for _, child in pairs(backpack:GetChildren()) do
			if child:IsA("Tool") then
				if seenTools[child.Name] then
					task.delay(0, function() child:Destroy() end)
				else
					seenTools[child.Name] = true
				end
			end
		end

		-- 关闭 PvP
		if pvpMode.Value == true then
			pvpMode.Value = false 
			cityPvPActive.Value = false 
			if UpdatePvPUIEvent then UpdatePvPUIEvent:FireClient(player, false) end
		end
	end)

	-- 4. 加载数据
	local success, data = pcall(function()
		return PlayerDataStore:GetAsync(player.UserId)
	end)

	if success and data then
		level.Value = data.Level
		gold.Value = data.Gold
		experience.Value = data.Experience or 0

		if data.TutorialCompleted then
			tutorialCompleted.Value = true
			print("📘 [Data] 玩家已完成教程")
		end

		-- 再次检查血量 (防止竞态)
		local character = player.Character
		if character then
			local hum = character:FindFirstChild("Humanoid")
			if hum then updateHealthBasedOnLevel(hum, level.Value) end
		end

		-- 加载背包
		for itemName, qty in pairs(data.Inventory) do
			local itemConfig = GameConfig.Weapons[itemName] or GameConfig.Items[itemName] or GameConfig.Skin[itemName]
			local finalQty = qty
			if itemConfig and itemConfig.Category == "Weapons" then finalQty = 1 end

			local itemValue = Instance.new("IntValue")
			itemValue.Name = itemName
			itemValue.Value = finalQty
			itemValue.Parent = inventory

			-- 发放物品实体
			if itemConfig and (itemConfig.Category == "Weapons" or itemConfig.Category == "Tools") then
				local toolModel = ServerStorage:FindFirstChild("Tools") and ServerStorage.Tools:FindFirstChild(itemName)
				if toolModel then
					if not player.Backpack:FindFirstChild(itemName) then
						toolModel:Clone().Parent = player.Backpack
					end
					if not player.StarterGear:FindFirstChild(itemName) then
						toolModel:Clone().Parent = player.StarterGear
					end
				end
			end
		end
	else
		-- 新玩家默认值
		level.Value = GameConfig.DefaultPlayer.Level
		gold.Value = GameConfig.DefaultPlayer.Gold
	end
end)

-- 玩家退出保存
Players.PlayerRemoving:Connect(function(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	local inventory = player:FindFirstChild("Inventory")
	local hiddenStats = player:FindFirstChild("HiddenStats") 

	if leaderstats and inventory then
		local dataToSave = {
			Level = leaderstats.Level.Value,
			Gold = leaderstats.Gold.Value,
			Experience = leaderstats.Experience.Value,
			Inventory = {},
			TutorialCompleted = false
		}

		if hiddenStats and hiddenStats:FindFirstChild("TutorialCompleted") then
			dataToSave.TutorialCompleted = hiddenStats.TutorialCompleted.Value
		end

		for _, itemValue in pairs(inventory:GetChildren()) do
			if itemValue:IsA("IntValue") then
				dataToSave.Inventory[itemValue.Name] = itemValue.Value
			end
		end

		pcall(function() PlayerDataStore:SetAsync(player.UserId, dataToSave) end)
		print("💾 数据已保存: " .. player.Name)
	end
end)

-- ==========================================
-- 5. 处理新手任务完成 (核心修复)
-- ==========================================
finishTalkEvent.OnServerEvent:Connect(function(player)
	print("🎁 [Server] 收到新手完成请求: " .. player.Name)

	-- 1. 发放武器 (Bat)
	local weaponName = "Bat"
	local toolsFolder = ServerStorage:FindFirstChild("Tools")

	if toolsFolder then
		local weapon = toolsFolder:FindFirstChild(weaponName)
		if weapon then
			-- 检查是否已有
			local hasWeapon = player.Backpack:FindFirstChild(weaponName) or player.StarterGear:FindFirstChild(weaponName)

			if not hasWeapon then
				-- 给背包
				local w1 = weapon:Clone()
				w1.Parent = player.Backpack

				-- 给存档 (StarterGear)
				local w2 = weapon:Clone()
				w2.Parent = player.StarterGear

				print("    ⚔️ 武器 [Bat] 已发放给 " .. player.Name)

				-- 更新 Inventory 数据 (否则下线就没了)
				local inventory = player:FindFirstChild("Inventory")
				if inventory then
					local itemVal = inventory:FindFirstChild(weaponName)
					if not itemVal then
						itemVal = Instance.new("IntValue")
						itemVal.Name = weaponName
						itemVal.Value = 1
						itemVal.Parent = inventory
					end
				end
			else
				warn("    ⚠️ 玩家已有武器，跳过发放")
			end
		else
			warn("    ❌ 严重错误: 在 ServerStorage/Tools 里找不到 " .. weaponName)
		end
	else
		warn("    ❌ 严重错误: ServerStorage 下没有 Tools 文件夹!")
	end

	-- 2. 发放任务 & 标记完成
	local hiddenStats = player:FindFirstChild("HiddenStats")
	if hiddenStats then
		-- 标记教程已完成
		if hiddenStats:FindFirstChild("TutorialCompleted") then
			hiddenStats.TutorialCompleted.Value = true
			print("    ✅ 教程状态标记为: 完成")
		end

		-- 发放杀怪任务
		local questName = "Quest_SamuraiSlayer"
		if not hiddenStats:FindFirstChild(questName) then
			local qVal = Instance.new("IntValue")
			qVal.Name = questName
			qVal.Value = 0
			qVal.Parent = hiddenStats
			print("    📜 任务已接取: " .. questName)
		end
	end
end)