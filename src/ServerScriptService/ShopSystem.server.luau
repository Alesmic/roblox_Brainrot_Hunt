local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")

-- 1. 获取资源
-- [注意] 改为从 RemoteFunction 文件夹获取，因为 InventorySystem 已将其升级
local RemoteFunctionFolder = ReplicatedStorage:WaitForChild("RemoteFunction") 
local buyItemFunc = RemoteFunctionFolder:WaitForChild("BuyItem") 

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

-- 2. 构建 ProductID -> ItemName 查找表
local ProductMap = {}
if GameConfig.Weapons then
	for name, data in pairs(GameConfig.Weapons) do
		if data.ProductId then ProductMap[data.ProductId] = name end
	end
end
if GameConfig.Items then
	for name, data in pairs(GameConfig.Items) do
		if data.ProductId then ProductMap[data.ProductId] = name end
	end
end
if GameConfig.Skin then
	for name, data in pairs(GameConfig.Skin) do
		if data.ProductId then ProductMap[data.ProductId] = name end
	end
end

-- ==========================================
-- A. 处理 Robux 购买
-- ==========================================
MarketplaceService.ProcessReceipt = function(receiptInfo)
	local playerId = receiptInfo.PlayerId
	local productId = receiptInfo.ProductId
	local player = Players:GetPlayerByUserId(playerId)

	if not player then return Enum.ProductPurchaseDecision.NotProcessedYet end

	local itemName = ProductMap[productId]

	if itemName then
		print("💎 [ShopSystem] 玩家 Robux 购买: " .. itemName)

		local itemConfig = GameConfig.Weapons[itemName] or GameConfig.Items[itemName] or GameConfig.Skin[itemName]
		local isWeapon = (itemConfig and itemConfig.Category == "Weapons")

		-- 检查唯一性
		if isWeapon then
			if player.Backpack:FindFirstChild(itemName) or player.StarterGear:FindFirstChild(itemName) then
				print("⚠️ 玩家已有该武器，跳过发放。")
				return Enum.ProductPurchaseDecision.PurchaseGranted
			end
		end

		-- 写入数据
		local inventory = player:FindFirstChild("Inventory")
		if inventory then
			local itemVal = inventory:FindFirstChild(itemName) or Instance.new("IntValue", inventory)
			itemVal.Name = itemName
			if isWeapon then itemVal.Value = 1 else itemVal.Value = itemVal.Value + 1 end
		end

		-- 发放道具
		local tool = ServerStorage:FindFirstChild("Tools") and ServerStorage.Tools:FindFirstChild(itemName)
		if tool then
			if not player.Backpack:FindFirstChild(itemName) then tool:Clone().Parent = player.Backpack end
			if not player.StarterGear:FindFirstChild(itemName) then tool:Clone().Parent = player.StarterGear end
		end

		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

-- ==========================================
-- B. 处理金币购买 (核心修复: 使用 OnServerInvoke)
-- ==========================================
buyItemFunc.OnServerInvoke = function(player, itemName)
	print("🛒 [ShopSystem] 收到购买请求: " .. tostring(itemName))

	local itemInfo = GameConfig.Items[itemName] or GameConfig.Skin[itemName] or GameConfig.Weapons[itemName]
	if not itemInfo then return false end -- 物品不存在

	-- 防作弊：禁止金币买 Robux 物品
	if itemInfo.ProductId then return false end

	local leaderstats = player:FindFirstChild("leaderstats")
	local goldStat = leaderstats and leaderstats:FindFirstChild("Gold")
	local inventory = player:FindFirstChild("Inventory")

	if not goldStat or not inventory then return false end

	-- 检查重复武器
	if itemInfo.Category == "Weapons" then
		local owned = inventory:FindFirstChild(itemName)
		if (owned and owned.Value >= 1) or player.StarterGear:FindFirstChild(itemName) then
			warn("❌ 玩家已拥有此武器")
			return false -- 购买失败
		end
	end

	local price = itemInfo.Price or 999999
	if goldStat.Value >= price then
		goldStat.Value = goldStat.Value - price

		-- 更新库存
		local itemValue = inventory:FindFirstChild(itemName) or Instance.new("IntValue", inventory)
		itemValue.Name = itemName

		if itemInfo.Category == "Weapons" then
			itemValue.Value = 1
		else
			itemValue.Value = itemValue.Value + 1
		end

		-- 发放道具
		local tool = ServerStorage:FindFirstChild("Tools") and ServerStorage.Tools:FindFirstChild(itemName)
		if tool then
			if not player.Backpack:FindFirstChild(itemName) then
				tool:Clone().Parent = player.Backpack
			end
			-- 只有武器才存入 StarterGear，消耗品不存
			if itemInfo.Category == "Weapons" then
				if not player.StarterGear:FindFirstChild(itemName) then
					tool:Clone().Parent = player.StarterGear
				end
			end
		end

		return true -- 购买成功
	end

	return false -- 金币不足
end