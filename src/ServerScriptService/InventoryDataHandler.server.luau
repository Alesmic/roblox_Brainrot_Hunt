-- InventoryDataHandler - Located in ServerScriptService or a server script startup location
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RemoteFunctionFolder = ReplicatedStorage:WaitForChild("RemoteFunction")
local getInvFunc = RemoteFunctionFolder:WaitForChild("GetInventoryData")

-- Import Config
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

-- Create a unified item lookup table for quick access to item details
local ItemDatabase = {}

local function initializeItemDatabase()
	-- Merge all item configurations into one table
	for _, itemTable in pairs({GameConfig.Weapons, GameConfig.Skin, GameConfig.Items}) do
		for name, data in pairs(itemTable) do
			-- Automatically add RarityColor
			local rarity = data.Rarity or "Common"
			data.RarityColor = GameConfig.RarityColors[rarity] or Color3.fromRGB(255, 255, 255)

			-- Automatically add CanTrade field (defaults to true if not defined in config)
			if data.CanTrade == nil then
				data.CanTrade = true
			end

			ItemDatabase[name] = data
		end
	end
end
initializeItemDatabase()


local function getPlayerInventory(player)
	print("[Server] Sending inventory data to:", player.Name)

	local playerItems = {}
	local inventoryFolder = player:FindFirstChild("Inventory")

	if not inventoryFolder then
		warn("[InventoryDataHandler] Could not find player's Inventory folder.")
		return {}
	end

	-- Iterate through IntValues (item quantity) in the player's Inventory folder
	for _, itemValue in pairs(inventoryFolder:GetChildren()) do
		local itemName = itemValue.Name
		local qty = itemValue.Value
		local itemConfig = ItemDatabase[itemName]

		if itemConfig and qty > 0 then
			-- Construct the complete data structure required by the client
			local itemData = {
				RealName = itemName,
				DisplayName = itemConfig.DisplayName,
				Category = itemConfig.Category,
				Qty = qty,
				Price = itemConfig.Price,
				ImageId = itemConfig.ImageId,
				CanSell = itemConfig.CanSell,
				CanTrade = itemConfig.CanTrade, -- Determines if it can be placed in the trade slot
				Rarity = itemConfig.Rarity,
				RarityColor = itemConfig.RarityColor
			}
			table.insert(playerItems, itemData)
		end
	end

	return playerItems -- Return the formatted array
end

getInvFunc.OnServerInvoke = getPlayerInventory

print("✅ Inventory Data Handler Loaded and initialized.")