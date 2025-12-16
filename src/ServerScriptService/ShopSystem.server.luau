local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")

-- 1. Get Resources
local RemoteEventFolder = ReplicatedStorage:WaitForChild("RemoteEvent")
local buyItemEvent = RemoteEventFolder:WaitForChild("BuyItem")
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

-- 2. Build ProductID -> ItemName Lookup Table
local ProductMap = {}
if GameConfig.Weapons then
	for name, data in pairs(GameConfig.Weapons) do
		if data.ProductId then
			ProductMap[data.ProductId] = name
		end
	end
end

-- ==========================================
-- A. Handle Robux Purchase (Weapons)
-- ==========================================
MarketplaceService.ProcessReceipt = function(receiptInfo)
	local playerId = receiptInfo.PlayerId
	local productId = receiptInfo.ProductId

	local player = Players:GetPlayerByUserId(playerId)
	if not player then
		-- Player disconnected, do not process yet, Roblox will retry later
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local itemName = ProductMap[productId]
	if itemName then
		print("💎 [ShopSystem] Player " .. player.Name .. " bought with Robux: " .. itemName)

		-- 1. Write to Inventory (Permanent ownership)
		local inventory = player:FindFirstChild("Inventory")
		if inventory then
			-- Check if already owned
			if not inventory:FindFirstChild(itemName) then
				local itemVal = Instance.new("IntValue")
				itemVal.Name = itemName
				itemVal.Value = 1
				itemVal.Parent = inventory
			end
		end

		-- 2. Give Physical Item (Tool)
		local toolsFolder = ServerStorage:FindFirstChild("Tools")
		local toolAsset = toolsFolder and toolsFolder:FindFirstChild(itemName)

		if toolAsset then
			toolAsset:Clone().Parent = player.Backpack
			toolAsset:Clone().Parent = player.StarterGear -- Ensure persistence after respawn
			print("    ⚔️ Weapon given")
		else
			warn("    ❌ Critical Error: " .. itemName .. " not found in ServerStorage/Tools")
		end

		return Enum.ProductPurchaseDecision.PurchaseGranted
	else
		warn("❌ Unknown ProductId: " .. productId)
		-- Mark as complete even if error occurs to prevent pending purchase issues
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
end

-- ==========================================
-- B. Handle Gold Purchase (Consumables/Regular Items)
-- ==========================================
buyItemEvent.OnServerEvent:Connect(function(player, itemName)
	print("🛒 [ShopSystem] Received Gold purchase request: " .. tostring(itemName))

	local itemInfo = GameConfig.Items[itemName] or GameConfig.Skin[itemName] or GameConfig.Weapons[itemName]

	if not itemInfo then return end

	-- If this item has a ProductId, strictly forbid purchasing via Gold interface (Anti-Cheat)
	if itemInfo.ProductId then
		warn("⚠️ [Cheat Warning] Player attempted to buy Robux item with Gold: " .. itemName)
		return
	end

	-- Below is the original gold deduction logic...
	local leaderstats = player:FindFirstChild("leaderstats")
	local goldStat = leaderstats and leaderstats:FindFirstChild("Gold")
	local inventory = player:FindFirstChild("Inventory")

	if not goldStat or not inventory then return end

	local price = itemInfo.Price or 999999

	if goldStat.Value >= price then
		goldStat.Value = goldStat.Value - price

		local itemValue = inventory:FindFirstChild(itemName)
		if not itemValue then
			itemValue = Instance.new("IntValue")
			itemValue.Name = itemName
			itemValue.Value = 0
			itemValue.Parent = inventory
		end
		itemValue.Value = itemValue.Value + 1

		if itemInfo.Category == "Consumables" then
			local tool = ServerStorage.Tools:FindFirstChild(itemName)
			if tool then
				tool:Clone().Parent = player.Backpack
				tool:Clone().Parent = player.StarterGear
			end
		end
		print("✅ Gold transaction successful: " .. itemName)
	else
		warn("❌ Not enough Gold")
	end
end)