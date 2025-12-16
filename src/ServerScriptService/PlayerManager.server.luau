local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

-- Import Configuration
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

-- [⚠️IMPORTANT] Changed version number to force reset everyone's data for new inventory testing
local PlayerDataStore = DataStoreService:GetDataStore("RPG_Data_v5")

local JAPANESE_HOUSE_SPAWN = Vector3.new(-783.183, 36.304, 220.17)

local RemoteEventFolder = ReplicatedStorage:WaitForChild("RemoteEvent")

local startTutorialEvent = RemoteEventFolder:WaitForChild("StartTutorial")
local finishTalkEvent = RemoteEventFolder:WaitForChild("FinishTutorialTalk")

-- [New] PvP Related RemoteEvent
local UpdatePvPUIEvent = RemoteEventFolder:WaitForChild("UpdatePvPUI")

Players.PlayerAdded:Connect(function(player)
	print("[PlayerManager] Player joined: " .. player.Name)

	-- 1. Create Base Attributes Folder
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local level = Instance.new("IntValue")
	level.Name = "Level"
	level.Parent = leaderstats

	local gold = Instance.new("IntValue")
	gold.Name = "Gold"
	gold.Parent = leaderstats
	-- [New] Create Experience
	local experience = Instance.new("IntValue")
	experience.Name = "Experience"
	experience.Value = 0
	experience.Parent = leaderstats

	-- [New] Listen for experience changes to handle leveling up
	experience.Changed:Connect(function(newXp)
		local currentLevel = level.Value
		-- Get required XP for current level (Referencing GameConfig)
		local xpRequired = GameConfig.Leveling.GetXpRequired(currentLevel)

		if newXp >= xpRequired then
			-- 1. Execute Level Up
			level.Value = currentLevel + 1
			experience.Value = newXp - xpRequired -- Deduct required XP, keep overflow

			print("🎉 [Server] " .. player.Name .. " Leveled up to Level " .. level.Value .. "!")

			-- 2. Increase Max Health (Keep consistent with AdminCommands logic)
			local character = player.Character
			local humanoid = character and character:FindFirstChild("Humanoid")

			if humanoid then
				local rewards = GameConfig.Leveling.RewardsPerLevel
				-- Formula: Base Health + (Level-1 * Bonus)
				local newMaxHealth = GameConfig.DefaultPlayer.MaxHealth + ((level.Value - 1) * rewards.HealthBonus)

				humanoid.MaxHealth = newMaxHealth
				humanoid.Health = newMaxHealth -- Heal to full on level up
			end
		end
	end)

	local hiddenStats = Instance.new("Folder")
	hiddenStats.Name = "HiddenStats"
	hiddenStats.Parent = player

	-- [New] PvP Mode Switch (Controls if player can be damaged by others)
	local pvpMode = Instance.new("BoolValue") 
	pvpMode.Name = "PvPMode"
	pvpMode.Value = false -- Default to false
	pvpMode.Parent = hiddenStats 

	-- [New] City PvP Active State (Used to disable NPC interaction)
	local cityPvPActive = Instance.new("BoolValue") 
	cityPvPActive.Name = "CityPvPActive"
	cityPvPActive.Value = false -- Default to false
	cityPvPActive.Parent = hiddenStats 

	-- 2. Create Inventory Data Folder (For UI Display)
	local inventory = Instance.new("Folder")
	inventory.Name = "Inventory"
	inventory.Parent = player

	-- 3. Character First Load, Set Initial Position
	player.CharacterAdded:Connect(function(character)
		-- Set player default spawn point
		character:WaitForChild("HumanoidRootPart").CFrame = CFrame.new(JAPANESE_HOUSE_SPAWN)

		-- [New] Protection Logic after Death (PvP Mode OFF)
		local currentPvPMode = pvpMode.Value

		-- Only execute protection logic if death occurred while PvPMode was ON
		if currentPvPMode == true then
			pvpMode.Value = false 
			cityPvPActive.Value = false -- Disable City PvP tag upon leaving arena or respawning
			print(player.Name .. " Respawned, PvP Mode automatically disabled for protection.")

			-- Notify Client to Update UI State
			if UpdatePvPUIEvent then
				UpdatePvPUIEvent:FireClient(player, false)
			end
		end
	end)

	-- 4. Data Loading (DataStore)
	local success, data = pcall(function()
		return PlayerDataStore:GetAsync(player.UserId)
	end)

	if success and data then
		-- Load successful, apply data
		level.Value = data.Level
		gold.Value = data.Gold
		experience.Value = data.Experience or 0 -- [New] Load Experience
		-- ... Other attributes

		-- Load Inventory
		for itemName, qty in pairs(data.Inventory) do
			local itemValue = Instance.new("IntValue")
			itemValue.Name = itemName
			itemValue.Value = qty
			itemValue.Parent = inventory

			-- If item is a tool, ensure tool model is in player's Backpack and StarterGear
			local itemConfig = GameConfig.Weapons[itemName] or GameConfig.Items[itemName] or GameConfig.Skin[itemName]
			if itemConfig and (itemConfig.Category == "Weapons" or itemConfig.Category == "Tools") then
				local toolModel = ServerStorage:FindFirstChild("Tools") and ServerStorage.Tools:FindFirstChild(itemName)
				if toolModel and not player.Backpack:FindFirstChild(itemName) then
					toolModel:Clone().Parent = player.Backpack
					toolModel:Clone().Parent = player.StarterGear
				end
			end
		end

	else
		-- First join or load failed, apply default data
		level.Value = GameConfig.DefaultPlayer.Level
		gold.Value = GameConfig.DefaultPlayer.Gold
		-- ... Other attributes
	end
end)

-- Save data when player leaves
Players.PlayerRemoving:Connect(function(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	local goldStat = leaderstats and leaderstats:FindFirstChild("Gold")
	local levelStat = leaderstats and leaderstats:FindFirstChild("Level")
	local inventory = player:FindFirstChild("Inventory")

	if goldStat and levelStat and inventory then
		local dataToSave = {
			Level = levelStat.Value,
			Gold = goldStat.Value,
			Experience = leaderstats.Experience.Value,
			Inventory = {},
			-- ... Other attributes to save
		}

		-- Collect Inventory Data
		for _, itemValue in pairs(inventory:GetChildren()) do
			if itemValue:IsA("IntValue") then
				dataToSave.Inventory[itemValue.Name] = itemValue.Value
			end
		end

		local success, err = pcall(function()
			PlayerDataStore:SetAsync(player.UserId, dataToSave)
		end)

		if success then
			print("[DataStore] Player data saved successfully: " .. player.Name)
		else
			warn("[DataStore] Failed to save player data: " .. player.Name .. ", Error: " .. tostring(err))
		end
	end
end)


-- ==========================================
-- 5. Tutorial Finished: Give Weapon + Give Quest
-- ==========================================
local finishTalkEvent = ReplicatedStorage.RemoteEvent:WaitForChild("FinishTutorialTalk")

finishTalkEvent.OnServerEvent:Connect(function(player)
	print("🎁 [Server] Received tutorial finish signal: " .. player.Name)

	-- 1. Give Weapon (Bat)
	local weaponName = "Bat"
	local toolsFolder = game.ServerStorage:FindFirstChild("Tools")
	if toolsFolder then
		local weapon = toolsFolder:FindFirstChild(weaponName)
		if weapon then
			-- Give to Backpack
			weapon:Clone().Parent = player.Backpack
			-- Give to StarterGear (Persists after respawn)
			weapon:Clone().Parent = player.StarterGear
			print("    ⚔️ Weapon given")
		else
			warn("    ❌ Could not find " .. weaponName .. " in ServerStorage/Tools")
		end
	end

	-- 2. Give Quest (Trigger client's QuestTracker)
	local hiddenStats = player:FindFirstChild("HiddenStats")
	if hiddenStats then
		local questName = "Quest_SamuraiSlayer" -- Corresponds to QuestID in Config

		if not hiddenStats:FindFirstChild(questName) then
			local qVal = Instance.new("IntValue")
			qVal.Name = questName
			qVal.Value = 0
			qVal.Parent = hiddenStats
			print("    📜 Quest assigned: " .. questName)
		else
			print("    ⚠️ Player already has this quest")
		end
	end
end)