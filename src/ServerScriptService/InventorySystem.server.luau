local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

-- ==========================================
-- 1. 远程接口初始化
-- ==========================================
local function ensureFolder(name, parent)
	local folder = parent:FindFirstChild(name)
	if not folder then
		folder = Instance.new("Folder"); folder.Name = name; folder.Parent = parent
	end
	return folder
end

local RemoteFunctionFolder = ensureFolder("RemoteFunction", ReplicatedStorage)
local RemoteEventFolder = ensureFolder("RemoteEvent", ReplicatedStorage)

local function ensureRemoteFunc(name)
	local rf = RemoteFunctionFolder:FindFirstChild(name)
	if not rf then rf = Instance.new("RemoteFunction"); rf.Name = name; rf.Parent = RemoteFunctionFolder end
	return rf
end

local function ensureRemoteEvent(name)
	local re = RemoteEventFolder:FindFirstChild(name)
	if not re then re = Instance.new("RemoteEvent"); re.Name = name; re.Parent = RemoteEventFolder end
	return re
end

-- 初始化所有接口
local buyItemFunc = ensureRemoteFunc("BuyItem")
local getInvFunc = ensureRemoteFunc("GetInventoryData")
local sellEvent = ensureRemoteEvent("SellItem")

ensureRemoteEvent("StartTradeUI")
ensureRemoteEvent("HandleTradeAction")
ensureRemoteEvent("UpdateTradeUI")
ensureRemoteEvent("BossBattleEvent")

-- [新增] 商店开启信号
ensureRemoteEvent("OpenShopUI") 

print("✅ [InventorySystem] 远程接口加载完毕 (含 OpenShopUI)")

-- ==========================================
-- 2. [核心修复] 实体道具完全同步器 (Observer)
-- ==========================================
-- 这个函数负责让 实体道具 永远等于 数据数值
local function syncPhysicalTool(player, itemName, dataQty)
	-- 确保 ServerStorage 有这个道具模型
	local toolModel = ServerStorage:FindFirstChild("Tools") and ServerStorage.Tools:FindFirstChild(itemName)
	if not toolModel then return end -- 如果模型库里没这个东西，忽略

	local backpack = player:WaitForChild("Backpack")
	local character = player.Character or player.CharacterAdded:Wait()

	-- 计算当前玩家身上实际有几个这个道具 (背包 + 手持)
	local currentPhysicalCount = 0
	local toolsToRemove = {}

	-- 检查背包
	for _, t in pairs(backpack:GetChildren()) do
		if t.Name == itemName then
			currentPhysicalCount = currentPhysicalCount + 1
			table.insert(toolsToRemove, t)
		end
	end
	-- 检查手上
	local handTool = character:FindFirstChild(itemName)
	if handTool then
		currentPhysicalCount = currentPhysicalCount + 1
		table.insert(toolsToRemove, handTool)
	end

	-- [同步逻辑]
	if dataQty > currentPhysicalCount then
		-- 数据比实体多，需要补发
		local need = dataQty - currentPhysicalCount
		-- 限制：如果是武器(Weapons)，无论数据多少，实体最多只给1把，防止Bug
		local conf = GameConfig.Weapons[itemName]
		if conf and currentPhysicalCount >= 1 then 
			return -- 武器有一把就够了
		end

		-- 补发道具
		for i = 1, need do
			toolModel:Clone().Parent = backpack
		end

	elseif dataQty < currentPhysicalCount then
		-- 实体比数据多 (比如卖掉了)，需要删除
		local removeCount = currentPhysicalCount - dataQty
		for i = 1, removeCount do
			if toolsToRemove[i] then
				toolsToRemove[i]:Destroy()
			end
		end
	end
end

-- 监听玩家库存变化
local function bindInventorySync(player)
	local inv = player:WaitForChild("Inventory", 10)
	if not inv then return end

	-- 1. 监听现有物品的变化
	for _, item in pairs(inv:GetChildren()) do
		-- 初始同步
		syncPhysicalTool(player, item.Name, item.Value)
		-- 变化监听
		item.Changed:Connect(function(newVal)
			syncPhysicalTool(player, item.Name, newVal)
		end)
	end

	-- 2. 监听新物品添加
	inv.ChildAdded:Connect(function(child)
		if child:IsA("IntValue") then
			syncPhysicalTool(player, child.Name, child.Value)
			child.Changed:Connect(function(newVal)
				syncPhysicalTool(player, child.Name, newVal)
			end)
		end
	end)
end

-- ==========================================
-- 3. 规则校验 (CanReceiveItem)
-- ==========================================
local function canPlayerReceiveItem(player, itemName, addQty)
	local inv = player:FindFirstChild("Inventory")
	if not inv then return false, "Inventory Error" end

	local conf = GameConfig.Weapons[itemName] or GameConfig.Items[itemName] or GameConfig.Skin[itemName]
	if not conf then return false, "Invalid Item" end

	-- 武器唯一性
	if conf.Category == "Weapons" then
		if inv:FindFirstChild(itemName) or player.Backpack:FindFirstChild(itemName) then
			return false, "Item Limit: Weapon Unique"
		end
	end

	-- 医疗包上限 (Max 3)
	if itemName == "Medpack" then
		local currentQty = inv:FindFirstChild(itemName) and inv:FindFirstChild(itemName).Value or 0
		if currentQty + addQty > 3 then
			return false, "Item Limit: Max 3 Medpacks"
		end
	end

	return true, ""
end
_G.CanReceiveItem = canPlayerReceiveItem

-- ==========================================
-- 4. 交易与购买逻辑 (只改数据，不碰道具)
-- ==========================================
buyItemFunc.OnServerInvoke = function(player, itemName)
	local conf = GameConfig.Weapons[itemName] or GameConfig.Items[itemName] or GameConfig.Skin[itemName]
	if not conf then return false, "No Config" end

	local can, reason = canPlayerReceiveItem(player, itemName, 1)
	if not can then return false, reason end

	local gold = player.leaderstats.Gold
	if gold.Value < (conf.Price or 0) then return false, "No Gold" end

	gold.Value = gold.Value - (conf.Price or 0)

	-- [关键] 只修改数据！监听器会自动发道具
	local inv = player:FindFirstChild("Inventory")
	local itemVal = inv:FindFirstChild(itemName)
	if itemVal then
		itemVal.Value = itemVal.Value + 1
	else
		local newVal = Instance.new("IntValue")
		newVal.Name = itemName
		newVal.Value = 1
		newVal.Parent = inv
	end

	return true, "Success"
end

sellEvent.OnServerEvent:Connect(function(player, itemName, _, qty)
	local inv = player:FindFirstChild("Inventory")
	local itemVal = inv and inv:FindFirstChild(itemName)
	local conf = GameConfig.Weapons[itemName] or GameConfig.Items[itemName] or GameConfig.Skin[itemName]

	if itemVal and itemVal.Value >= qty then
		-- [关键] 只修改数据！监听器会自动删除道具
		itemVal.Value = itemVal.Value - qty

		local gain = math.floor((conf.Price or 0) * 0.5) * qty
		player.leaderstats.Gold.Value = player.leaderstats.Gold.Value + gain

		if itemVal.Value <= 0 then
			itemVal:Destroy()
			-- 此时监听器会捕捉到 Value=0 (或对象移除前瞬间)，并执行清理
			-- 如果直接 Destroy 导致 Changed 没触发，syncPhysicalTool 会在下次校验时修正
			-- 显式调用一次清理以防万一
			syncPhysicalTool(player, itemName, 0)
		end
	end
end)

getInvFunc.OnServerInvoke = function(player)
	local inv = player:FindFirstChild("Inventory")
	local data = {}
	if inv then
		for _, item in pairs(inv:GetChildren()) do
			local conf = GameConfig.Weapons[item.Name] or GameConfig.Items[item.Name] or GameConfig.Skin[item.Name]
			if conf then
				table.insert(data, {
					RealName = item.Name,
					DisplayName = conf.DisplayName or item.Name,
					Qty = item.Value,
					Category = conf.Category or "Items",
					ImageId = conf.ImageId,
					Price = conf.Price
				})
			end
		end
	end
	return data
end

-- ==========================================
-- 5. 初始化流程
-- ==========================================
Players.PlayerAdded:Connect(function(player)
	-- 创建 Inventory 文件夹
	local inv = Instance.new("Folder")
	inv.Name = "Inventory"
	inv.Parent = player

	player.CharacterAdded:Connect(function(char)
		-- 每次重生，开启监听器并进行一次全量同步
		task.wait(1) 
		bindInventorySync(player)
	end)
end)

print("✅ [InventorySystem] 数据驱动模式已启动 (数据与实体强制同步)")