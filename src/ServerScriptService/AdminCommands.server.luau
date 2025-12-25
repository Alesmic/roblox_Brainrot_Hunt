local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Require GameConfig for correct health calculation on level-up
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

-- 👑 管理员列表 (可选：如果你只想让自己能用，填入 UserID)
local ADMINS = {
	-- 12345678, -- 替换为你的 UserId
}

-- 简单的权限检查函数
local function isAdmin(player)
	-- 目前默认允许所有人使用方便测试
	-- 如果需要开启权限，取消下面注释并把 true 改为 false
	-- for _, id in pairs(ADMINS) do if player.UserId == id then return true end end
	return true 
end

-- ==========================================
-- 🛠️ 数据擦除逻辑 (原 /reset 逻辑，现改名为 /wipe)
-- ==========================================
local function wipePlayerData(targetPlayer)
	print("⚠️ [Admin] 正在擦除玩家数据: " .. targetPlayer.Name)

	-- 1. 重置基础属性 (Level, Gold, Experience)
	local leaderstats = targetPlayer:FindFirstChild("leaderstats")
	if leaderstats then
		if leaderstats:FindFirstChild("Level") then 
			leaderstats.Level.Value = GameConfig.DefaultPlayer.Level or 1 
		end
		if leaderstats:FindFirstChild("Gold") then 
			leaderstats.Gold.Value = GameConfig.DefaultPlayer.Gold or 0 
		end
		if leaderstats:FindFirstChild("Experience") then
			leaderstats.Experience.Value = GameConfig.DefaultPlayer.Experience or 0
		end
	end

	-- 2. 重置隐藏属性 (教程状态, 任务)
	local hiddenStats = targetPlayer:FindFirstChild("HiddenStats")
	if hiddenStats then
		-- 重置教程状态
		if hiddenStats:FindFirstChild("TutorialCompleted") then
			hiddenStats.TutorialCompleted.Value = false
			print("    📘 教程状态已重置")
		end

		-- 删除所有任务
		for _, child in pairs(hiddenStats:GetChildren()) do
			if string.find(child.Name, "Quest") then
				child:Destroy()
				print("    🗑️ 已移除任务: " .. child.Name)
			end
		end
	end

	-- 3. 清空背包数据
	local inventory = targetPlayer:FindFirstChild("Inventory")
	if inventory then
		inventory:ClearAllChildren()
		print("    🎒 背包数据已清空")
	end

	-- 4. 清空实体道具
	targetPlayer.Backpack:ClearAllChildren()
	targetPlayer.StarterGear:ClearAllChildren()

	-- 5. 重生
	if targetPlayer.Character then
		local humanoid = targetPlayer.Character:FindFirstChild("Humanoid")
		if humanoid then
			humanoid.Health = 0 
		end
	end

	print("✅ " .. targetPlayer.Name .. " 的数据已擦除！")
end

-- ==========================================
-- 🔄 角色重置逻辑 (新版 /reset - 仅重生，不删数据)
-- ==========================================
local function resetCharacter(targetPlayer)
	if targetPlayer.Character then
		local humanoid = targetPlayer.Character:FindFirstChild("Humanoid")
		if humanoid then
			humanoid.Health = 0 -- 仅赐死玩家，触发重生流程
			print("🔄 [Admin] 玩家已重置 (位置/状态): " .. targetPlayer.Name)
		end
	else
		targetPlayer:LoadCharacter() -- 如果没有角色，强制加载
		print("🔄 [Admin] 玩家已重新加载: " .. targetPlayer.Name)
	end
end


-- Listen for players joining
Players.PlayerAdded:Connect(function(player)

	-- Listen for player chat messages
	player.Chatted:Connect(function(message)
		-- 权限检查
		if not isAdmin(player) then return end

		-- Split the message
		local args = string.split(message, " ")
		local command = string.lower(args[1]) 
		local value = tonumber(args[2])      

		local leaderstats = player:FindFirstChild("leaderstats")
		if not leaderstats then return end

		-- ============================
		-- Command 0: Reset Character (/reset) [已修改]
		-- ============================
		if command == "/reset" then
			-- 现在只重置角色，不擦除数据
			resetCharacter(player)
		end

		-- 重置指定玩家: /resetplayer 或 /resetall
		if command == "/resetplayer" or command == "/resetall" then
			local targetName = args[2]
			if targetName then
				local target = Players:FindFirstChild(targetName)
				if target then
					resetCharacter(target)
				else
					print("❌ 找不到玩家: " .. targetName)
				end
			else
				resetCharacter(player)
			end
		end

		-- ============================
		-- Command: Wipe Data (/wipe) [新增 - 用于测试删档]
		-- ============================
		if command == "/wipe" then
			wipePlayerData(player)
		end

		-- ============================
		-- Command 1: Set Level (/lv or /level)
		-- ============================
		if (command == "/lv" or command == "/level") and value then
			local levelStat = leaderstats:FindFirstChild("Level")
			if levelStat then
				levelStat.Value = value
				print("⚙️ Admin: Level set to " .. value)

				-- Recalculate health
				local character = player.Character
				local humanoid = character and character:FindFirstChild("Humanoid")

				if humanoid then
					local rewards = GameConfig.Leveling and GameConfig.Leveling.RewardsPerLevel or {HealthBonus = 10}
					local levelBonus = (value - 1) * rewards.HealthBonus
					local newMaxHealth = GameConfig.DefaultPlayer.MaxHealth + levelBonus

					humanoid.MaxHealth = newMaxHealth
					humanoid.Health = newMaxHealth
					print("    - Max Health updated to: " .. newMaxHealth)
				end
			end
		end

		-- ============================
		-- Command 2: Set Gold (/gold or /money)
		-- ============================
		if (command == "/gold" or command == "/money") and value then
			local goldStat = leaderstats:FindFirstChild("Gold")
			if goldStat then
				goldStat.Value = value
				print("⚙️ Admin: Gold set to " .. value)
			end
		end

		-- ============================
		-- Command 3: Set Speed (/speed)
		-- ============================
		if command == "/speed" and value then
			local character = player.Character
			local humanoid = character and character:FindFirstChild("Humanoid")
			if humanoid then
				humanoid.WalkSpeed = value
				print("⚙️ Admin: Speed set to " .. value)
			end
		end

		-- ============================
		-- Command 4: Give Item (/give ItemName)
		-- ============================
		if command == "/give" then
			local itemName = string.sub(message, 7)
			itemName = itemName:match("^%s*(.-)%s*$")

			local itemInfo = nil
			if GameConfig.Weapons then itemInfo = GameConfig.Weapons[itemName] end
			if not itemInfo and GameConfig.Items then itemInfo = GameConfig.Items[itemName] end
			if not itemInfo and GameConfig.Skin then itemInfo = GameConfig.Skin[itemName] end

			if itemInfo then
				local inventory = player:FindFirstChild("Inventory")
				if inventory then
					local itemValue = inventory:FindFirstChild(itemName)
					if not itemValue then
						itemValue = Instance.new("IntValue")
						itemValue.Name = itemName
						itemValue.Value = 0
						itemValue.Parent = inventory
					end
					itemValue.Value = itemValue.Value + 1

					if GameConfig.Weapons and GameConfig.Weapons[itemName] then
						local tool = game.ServerStorage.Tools:FindFirstChild(itemName)
						if tool then
							if not player.Backpack:FindFirstChild(itemName) then
								tool:Clone().Parent = player.Backpack
							end
							if not player.StarterGear:FindFirstChild(itemName) then
								tool:Clone().Parent = player.StarterGear
							end
						end
					end
					print("🎁 Admin: Gave " .. itemName)
				end
			else
				warn("❌ Item configuration not found: " .. itemName)
			end
		end

	end)
end)