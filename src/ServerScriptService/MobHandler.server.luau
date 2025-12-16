local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Import Configuration
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

local MobHandler = {}

-- ==========================================
-- Helper Function: Give Item
-- ==========================================
local function giveItemToPlayer(player, itemName)
	-- 1. Try to find in ServerStorage.Tools
	local tool = ServerStorage:FindFirstChild("Tools") and ServerStorage.Tools:FindFirstChild(itemName)

	-- 2. If not found, try ServerStorage.Items (Assuming you have this folder for non-weapon items)
	if not tool then
		tool = ServerStorage:FindFirstChild("Items") and ServerStorage.Items:FindFirstChild(itemName)
	end

	if tool then
		-- Clone and give to player backpack
		local clone = tool:Clone()
		clone.Parent = player.Backpack
		-- Optional: Also give to StarterGear so they have it after respawn
		-- tool:Clone().Parent = player.StarterGear 

		-- 3. Write Inventory Data (Used for saving/loading)
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
		warn("❌ [MobHandler] Drop configured for item '"..itemName.."' but not found in ServerStorage!")
		return false
	end
end

-- ==========================================
-- Core Logic: Handle Mob Death
-- ==========================================
local function onMobDied(mobModel, killerPlayer)
	local mobName = mobModel.Name
	local config = GameConfig.Mobs[mobName]

	if not config then return end

	print("💀 [MobHandler] Mob Died: " .. mobName)

	if killerPlayer then
		print("    🗡️ Killer: " .. killerPlayer.Name)

		-- 1. Give Experience
		local leaderstats = killerPlayer:FindFirstChild("leaderstats")
		if leaderstats and leaderstats:FindFirstChild("Experience") then
			leaderstats.Experience.Value = leaderstats.Experience.Value + config.Exp
		end

		-- 2. Quest Progress Update (Keep original logic)
		local hiddenStats = killerPlayer:FindFirstChild("HiddenStats")
		if hiddenStats then
			for questID, questData in pairs(GameConfig.Quests) do
				if questData.TargetMob == mobName then
					local questStatName = "Quest_" .. questID
					local questVal = hiddenStats:FindFirstChild(questStatName)
					if questVal and questVal.Value < questData.TargetCount then
						questVal.Value = questVal.Value + 1
						-- Quest completion reward logic...
						if questVal.Value == questData.TargetCount and questData.GoldReward then
							if leaderstats and leaderstats:FindFirstChild("Gold") then
								leaderstats.Gold.Value = leaderstats.Gold.Value + questData.GoldReward
							end
						end
					end
				end
			end
		end

		-- ==========================================
		-- [New] 3. Item Drop System
		-- ==========================================
		if config.Drops then
			for _, dropData in pairs(config.Drops) do
				-- Calculate probability (math.random() returns 0.0 to 1.0)
				local roll = math.random()

				if roll <= dropData.Chance then
					local success = giveItemToPlayer(killerPlayer, dropData.ItemName)
					if success then
						-- Notify player (You can add a UI notification later)
						print("    🎁 Dropped Item: " .. dropData.ItemName .. " (Chance: " .. (dropData.Chance*100) .. "%)")
					end
				end
			end
		end

	end

	-- 4. Destroy Model
	task.wait(3)
	mobModel:Destroy()
end

-- ==========================================
-- Listener Setup (Keep unchanged)
-- ==========================================
function MobHandler.setupMob(mobModel)
	local humanoid = mobModel:FindFirstChild("Humanoid")
	if not humanoid then return end

	local lastAttacker = nil
	local lastAttackTime = 0

	humanoid.HealthChanged:Connect(function(health)
		if health <= 0 then
			if humanoid:GetState() ~= Enum.HumanoidStateType.Dead then
				if lastAttacker and (os.time() - lastAttackTime < 5) then
					onMobDied(mobModel, lastAttacker)
				else
					onMobDied(mobModel, nil)
				end
			end
		end
	end)

	humanoid.ChildAdded:Connect(function(child)
		if child.Name == "creator" and child:IsA("ObjectValue") then
			local player = child.Value
			if player and player:IsA("Player") then
				lastAttacker = player
				lastAttackTime = os.time()
				task.delay(0.5, function() child:Destroy() end)
			end
		end
	end)
end

-- Auto Scan
local npcFolder = workspace:WaitForChild("NPCs")
for _, obj in pairs(npcFolder:GetChildren()) do
	if GameConfig.Mobs[obj.Name] then
		MobHandler.setupMob(obj)
	end
end
npcFolder.ChildAdded:Connect(function(child)
	if GameConfig.Mobs[child.Name] then
		MobHandler.setupMob(child)
	end
end)

return MobHandler