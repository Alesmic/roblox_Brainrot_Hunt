-- Location: ServerScriptService -> DoctorShop_Server
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

-- 1. Get Events
local RemoteEventFolder = ReplicatedStorage:WaitForChild("RemoteEvent")
-- Automatically create PurchaseItem to prevent errors
local PurchaseItem = RemoteEventFolder:FindFirstChild("PurchaseItem")
if not PurchaseItem then
	PurchaseItem = Instance.new("RemoteEvent")
	PurchaseItem.Name = "PurchaseItem"
	PurchaseItem.Parent = RemoteEventFolder
end

-- 2. Configuration (Server-side config required for security)
local SHOP_ITEMS = {
	["Medpack"] = {
		Price = 20,
		MaxLimit = 3
	}
}

-- ==========================================
-- 3. Handle Purchase Requests
-- ==========================================
PurchaseItem.OnServerEvent:Connect(function(player, itemName, clientSentCost)
	print("🛒 [Server] Received purchase request: " .. player.Name .. " -> " .. tostring(itemName))

	-- A. Verify item existence
	local itemConfig = SHOP_ITEMS[itemName]
	if not itemConfig then
		warn("❌ Item does not exist or not configured: " .. tostring(itemName))
		return
	end

	-- B. Verify Price (Anti-cheat: Ignore client-sent price, use server price)
	-- Although the client sent itemCost, hackers can modify it to 0, so we must use the server's Price
	local realPrice = itemConfig.Price

	-- C. Check Gold
	local leaderstats = player:FindFirstChild("leaderstats")
	local gold = leaderstats and leaderstats:FindFirstChild("Gold")
	if not gold or gold.Value < realPrice then
		warn("❌ Not enough Gold")
		return
	end

	-- D. Check/Create Inventory Data
	local inventory = player:FindFirstChild("Inventory")
	if not inventory then
		inventory = Instance.new("Folder")
		inventory.Name = "Inventory"
		inventory.Parent = player
	end

	local itemData = inventory:FindFirstChild(itemName)
	if not itemData then
		itemData = Instance.new("IntValue")
		itemData.Name = itemName
		itemData.Value = 0
		itemData.Parent = inventory
	end

	-- E. Check Purchase Limit (Server-side secondary verification)
	if itemData.Value >= itemConfig.MaxLimit then
		warn("❌ Purchase limit reached, transaction cancelled")
		return
	end

	-- ==========================
	-- F. Execute Transaction
	-- ==========================

	-- 1. Deduct Money
	gold.Value = gold.Value - realPrice

	-- 2. Increase Data Count
	itemData.Value = itemData.Value + 1

	-- 3. Give Physical Item (Tool)
	-- Try to find in ServerStorage's Tools or Items folder
	local toolModel = nil
	if ServerStorage:FindFirstChild("Tools") then
		toolModel = ServerStorage.Tools:FindFirstChild(itemName)
	end
	if not toolModel and ServerStorage:FindFirstChild("Items") then
		toolModel = ServerStorage.Items:FindFirstChild(itemName)
	end

	if toolModel then
		local clone = toolModel:Clone()
		clone.Parent = player.Backpack
		-- Optional: If you want it to persist after respawn, uncomment the line below
		-- toolModel:Clone().Parent = player.StarterGear 
		print("✅ [Server] Transaction successful! Gave " .. itemName)
	else
		warn("⚠️ Purchase successful but model not found: " .. itemName .. " (Please check ServerStorage)")
	end
end)