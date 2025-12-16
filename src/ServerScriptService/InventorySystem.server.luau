local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Import Configuration
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

-- Adapt to RemoteFunction folder structure
local RemoteFunctionFolder = ReplicatedStorage:WaitForChild("RemoteFunction")
local getInvFunc = RemoteFunctionFolder:WaitForChild("GetInventoryData")

local RemoteEventFolder = ReplicatedStorage:WaitForChild("RemoteEvent")
local sellEvent = RemoteEventFolder:WaitForChild("SellItem")

-- ==========================================
-- 1. Get Inventory Data (Core Fix)
-- ==========================================
getInvFunc.OnServerInvoke = function(player)
	local inventory = player:FindFirstChild("Inventory")
	local data = {}

	if inventory then
		for _, itemObj in pairs(inventory:GetChildren()) do
			local itemName = itemObj.Name

			-- [Fix] Search all configuration tables, including the new Skin table
			local itemInfo = GameConfig.Weapons[itemName] 
				or GameConfig.Items[itemName] 
				or GameConfig.Skin[itemName]

			if itemInfo then
				table.insert(data, {
					RealName = itemName,
					DisplayName = itemInfo.DisplayName or itemName,
					Qty = itemObj.Value,
					Price = itemInfo.Price,
					CanSell = itemInfo.CanSell,
					Category = itemInfo.Category or "Item",

					-- [Critical Fix] Must send image and rarity to the client
					ImageId = itemInfo.ImageId, 
					Rarity = itemInfo.Rarity
				})
			end
		end
	end
	return data
end

-- ==========================================
-- 2. Handle Sell Request
-- ==========================================
sellEvent.OnServerEvent:Connect(function(player, itemName, price, qty)
	-- For security, price should be recalculated here to prevent exploit tampering
	-- However, for demonstration purposes, we temporarily trust the client's intent and only check inventory

	local inventory = player:FindFirstChild("Inventory")
	local itemObj = inventory and inventory:FindFirstChild(itemName)

	-- [Fix] Search all tables again
	local itemInfo = GameConfig.Weapons[itemName] 
		or GameConfig.Items[itemName] 
		or GameConfig.Skin[itemName]

	if itemObj and itemInfo then
		if itemInfo.CanSell then
			if itemObj.Value >= qty then
				-- 1. Deduct Item
				itemObj.Value = itemObj.Value - qty

				-- 2. Add Money (Read original price from config * 0.5 to ensure security)
				local realSellPrice = math.floor(itemInfo.Price * 0.5) * qty

				local leaderstats = player:FindFirstChild("leaderstats")
				if leaderstats and leaderstats:FindFirstChild("Gold") then
					leaderstats.Gold.Value = leaderstats.Gold.Value + realSellPrice
					print("💰 [Server] " .. player.Name .. " Sold " .. itemName .. " for " .. realSellPrice)
				end

				-- 3. Remove if quantity is zero
				if itemObj.Value <= 0 then
					itemObj:Destroy()
					-- If it's a weapon, remove the Tool from Backpack
					if player.Backpack:FindFirstChild(itemName) then
						player.Backpack[itemName]:Destroy()
					end
				end
			else
				warn("❌ Not enough quantity")
			end
		else
			warn("❌ This item cannot be sold")
		end
	end
end)