local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Require GameConfig for correct health calculation on level-up
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

-- Listen for players joining
Players.PlayerAdded:Connect(function(player)

	-- Listen for player chat messages
	player.Chatted:Connect(function(message)

		-- Split the message into words (e.g., "/lv 50" splits into "/lv" and "50")
		local args = string.split(message, " ")
		local command = string.lower(args[1]) -- Convert command to lowercase to prevent case errors
		local value = tonumber(args[2])      -- Convert the second word to a number

		-- Get the player's data folder
		local leaderstats = player:FindFirstChild("leaderstats")
		if not leaderstats then return end

		-- ============================
		-- Command 1: Set Level (/lv or /level)
		-- ============================
		if (command == "/lv" or command == "/level") and value then
			local levelStat = leaderstats:FindFirstChild("Level")
			if levelStat then
				levelStat.Value = value
				print("⚙️ Admin: Level set to " .. value)

				-- [Critical] Recalculate health after level-up (Keep logic consistent with PlayerManager)
				local character = player.Character
				local humanoid = character and character:FindFirstChild("Humanoid")

				if humanoid then
					local levelBonus = (value - 1) * GameConfig.Leveling.RewardsPerLevel.HealthBonus
					local newMaxHealth = GameConfig.DefaultPlayer.MaxHealth + levelBonus

					humanoid.MaxHealth = newMaxHealth
					humanoid.Health = newMaxHealth -- Also heal the player to full health
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
		-- Usage: /give "Iron Katana" (Use quotes if the name has spaces, or input the name without spaces)
		-- Simple Usage: /give IronKatana (The code will try to match by removing spaces, or you need exact input)
		-- ============================
		if command == "/give" then
			-- Concatenate all subsequent arguments as the item name (e.g., /give Iron Katana -> "Iron Katana")
			local itemName = string.sub(message, 7) -- Extract from the 7th character

			-- Check if the item exists in GameConfig
			local itemInfo = GameConfig.Weapons[itemName] or GameConfig.Items[itemName]

			if itemInfo then
				local inventory = player:FindFirstChild("Inventory")
				if inventory then
					-- 1. Add to Inventory data
					local itemValue = inventory:FindFirstChild(itemName)
					if not itemValue then
						itemValue = Instance.new("IntValue")
						itemValue.Name = itemName
						itemValue.Value = 0
						itemValue.Parent = inventory
					end
					itemValue.Value = itemValue.Value + 1

					-- 2. If it's a weapon, also give the physical Tool
					if GameConfig.Weapons[itemName] then
						local tool = game.ServerStorage.Tools:FindFirstChild(itemName)
						if tool then
							tool:Clone().Parent = player.Backpack
							tool:Clone().Parent = player.StarterGear
						end
					end

					print("🎁 Admin: Gave " .. itemName)
				end
			else
				warn("❌ Item configuration not found: " .. itemName .. " (Check spelling in GameConfig)")
			end
		end

	end)
end)