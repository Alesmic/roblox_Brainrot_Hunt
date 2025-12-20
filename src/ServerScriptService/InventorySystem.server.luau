local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- 引入配置
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

-- ==========================================
-- 1. 远程接口初始化 (自动修复缺失的 Remote)
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

local RemoteFunctionFolder = ensureFolder("RemoteFunction")
local RemoteEventFolder = ensureFolder("RemoteEvent")

local function ensureRemoteFunc(name)
	local rf = RemoteFunctionFolder:FindFirstChild(name)
	if not rf then
		rf = Instance.new("RemoteFunction")
		rf.Name = name
		rf.Parent = RemoteFunctionFolder
		print("🔨 [InventorySystem] 自动创建 RemoteFunction: " .. name)
	end
	-- 兼容性处理：如果存在同名的 RemoteEvent，将其删除并替换（防止冲突）
	if rf:IsA("RemoteEvent") then
		rf:Destroy()
		rf = Instance.new("RemoteFunction")
		rf.Name = name
		rf.Parent = RemoteFunctionFolder
		print("♻️ [InventorySystem] 将旧 RemoteEvent 升级为 RemoteFunction: " .. name)
	end
	return rf
end

local function ensureRemoteEvent(name)
	local re = RemoteEventFolder:FindFirstChild(name)
	if not re then
		re = Instance.new("RemoteEvent")
		re.Name = name
		re.Parent = RemoteEventFolder
		print("🔨 [InventorySystem] 自动创建 RemoteEvent: " .. name)
	end
	return re
end

-- [核心修复] 在这里统一创建 ShopSystem 和 InventorySystem 需要的所有接口
-- 这样 ShopSystem 启动时就能直接找到它们，不会报错 Infinite Yield
ensureRemoteFunc("BuyItem")          -- 商店购买 (RemoteFunction)
local getInvFunc = ensureRemoteFunc("GetInventoryData") -- 获取背包 (RemoteFunction)
local sellEvent = ensureRemoteEvent("SellItem")         -- 出售物品 (RemoteEvent)


-- ==========================================
-- 2. 获取背包数据 (核心逻辑)
-- ==========================================
getInvFunc.OnServerInvoke = function(player)
	local inventory = player:FindFirstChild("Inventory")
	local data = {}

	if inventory then
		for _, itemObj in pairs(inventory:GetChildren()) do
			local itemName = itemObj.Name

			-- 搜索所有配置表 (武器、物品、皮肤)
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
					-- 必须发送给客户端的数据：图片和稀有度
					ImageId = itemInfo.ImageId, 
					Rarity = itemInfo.Rarity
				})
			end
		end
	end
	return data
end

-- ==========================================
-- 3. 处理出售请求
-- ==========================================
sellEvent.OnServerEvent:Connect(function(player, itemName, price, qty)
	local inventory = player:FindFirstChild("Inventory")
	local itemObj = inventory and inventory:FindFirstChild(itemName)

	-- 再次搜索配置
	local itemInfo = GameConfig.Weapons[itemName] 
		or GameConfig.Items[itemName] 
		or GameConfig.Skin[itemName]

	if itemObj and itemInfo then
		if itemInfo.CanSell then
			if itemObj.Value >= qty then
				-- 1. 扣除物品
				itemObj.Value = itemObj.Value - qty

				-- 2. 加钱 (安全起见，价格由服务器重新计算，取原价的 50%)
				local realSellPrice = math.floor((itemInfo.Price or 0) * 0.5) * qty

				local leaderstats = player:FindFirstChild("leaderstats")
				if leaderstats and leaderstats:FindFirstChild("Gold") then
					leaderstats.Gold.Value = leaderstats.Gold.Value + realSellPrice
					print("💰 [Server] " .. player.Name .. " 出售了 " .. itemName .. " 获得金币: " .. realSellPrice)
				end

				-- 3. 如果数量归零，删除数据对象
				if itemObj.Value <= 0 then
					itemObj:Destroy()
					-- 如果是武器，同时从背包移除实体工具
					if player.Backpack:FindFirstChild(itemName) then
						player.Backpack[itemName]:Destroy()
					end
				end
			else
				warn("❌ 数量不足，无法出售")
			end
		else
			warn("❌ 此物品不可出售")
		end
	end
end)

print("✅ InventorySystem 已启动，所有 Remote 接口已就绪。")