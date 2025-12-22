local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

-- 引入配置文件
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

-- ==========================================
-- 1. 远程接口自动初始化
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

-- 初始化接口
local buyItemFunc = ensureRemoteFunc("BuyItem")
local getInvFunc = ensureRemoteFunc("GetInventoryData")
local sellEvent = ensureRemoteEvent("SellItem")

ensureRemoteEvent("StartTradeUI")
ensureRemoteEvent("QuestCompleted") -- [新增] 用于通知客户端显示奖励弹窗
ensureRemoteEvent("HandleTradeAction")
ensureRemoteEvent("UpdateTradeUI")
ensureRemoteEvent("BossBattleEvent")
ensureRemoteEvent("OpenShopUI") 
ensureRemoteEvent("OpenDoctorUI")

print("✅ [InventorySystem] 远程接口加载完毕")

-- ==========================================
-- 2. 实体道具同步器 (核心修复：含 StarterGear)
-- ==========================================
local function syncPhysicalTool(player, itemName, dataQty)
	-- 尝试从 ServerStorage 获取道具模型
	local toolModel = nil
	if ServerStorage:FindFirstChild("Tools") then
		toolModel = ServerStorage.Tools:FindFirstChild(itemName)
	end
	-- 兼容旧结构
	if not toolModel and ServerStorage:FindFirstChild("Items") then
		toolModel = ServerStorage.Items:FindFirstChild(itemName)
	end

	-- 如果服务器没有这个道具模型，就只管数据，不管实体
	if not toolModel then return end

	local backpack = player:WaitForChild("Backpack")
	local starterGear = player:WaitForChild("StarterGear") -- [新增] 获取 StarterGear
	local character = player.Character

	-- A. 统计当前持有的实体数量
	local currentPhysicalCount = 0
	local toolsToRemove = {}

	-- 检查背包
	for _, t in pairs(backpack:GetChildren()) do
		if t.Name == itemName then
			currentPhysicalCount += 1
			table.insert(toolsToRemove, t)
		end
	end
	-- 检查手上 (Character)
	if character then
		local handTool = character:FindFirstChild(itemName)
		if handTool then
			currentPhysicalCount += 1
			table.insert(toolsToRemove, handTool)
		end
	end

	-- B. 同步逻辑
	if dataQty > 0 then
		-- [获得物品]

		-- 1. 确保背包里有 (如果是武器且只能持有一把，确保不重复)
		local conf = GameConfig.Weapons[itemName]
		if conf and currentPhysicalCount >= 1 then 
			-- 武器已有，不再发放
		else
			-- 需要发放 (比如消耗品堆叠，或者还没武器)
			if currentPhysicalCount < dataQty then
				local need = dataQty - currentPhysicalCount
				for i = 1, need do
					toolModel:Clone().Parent = backpack
				end
			end
		end

		-- 2. [关键] 同步到 StarterGear (确保重生后还有)
		if not starterGear:FindFirstChild(itemName) then
			toolModel:Clone().Parent = starterGear
		end

	else
		-- [失去/出售物品] -> dataQty <= 0

		-- 1. 删除背包和手上的
		for _, t in pairs(toolsToRemove) do
			t:Destroy()
		end

		-- 2. [核心修复] 删除 StarterGear 里的备份 (防止无法再次购买)
		local sgTool = starterGear:FindFirstChild(itemName)
		if sgTool then
			sgTool:Destroy()
			print("♻️ [InventorySystem] 已清除 StarterGear 中的: " .. itemName)
		end
	end
end

local function bindInventorySync(player)
	local inv = player:WaitForChild("Inventory", 10)
	if not inv then return end

	-- 初始同步
	for _, item in pairs(inv:GetChildren()) do
		syncPhysicalTool(player, item.Name, item.Value)
		item.Changed:Connect(function(newVal)
			syncPhysicalTool(player, item.Name, newVal)
		end)
	end

	-- 监听新物品
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
-- 3. 规则校验与购买逻辑
-- ==========================================
local function canPlayerReceiveItem(player, itemName, addQty)
	local inv = player:FindFirstChild("Inventory")
	if not inv then return false, "Inventory Error" end

	local conf = GameConfig.Weapons[itemName] or GameConfig.Items[itemName] or GameConfig.Skin[itemName]
	if not conf then return false, "Invalid Item" end

	if conf.Category == "Weapons" then
		-- 武器唯一性检查
		if inv:FindFirstChild(itemName) then
			return false, "Item Limit: Weapon Unique"
		end
	end

	if itemName == "Medpack" then
		local currentQty = inv:FindFirstChild(itemName) and inv:FindFirstChild(itemName).Value or 0
		if currentQty + addQty > 3 then
			return false, "Item Limit: Max 3 Medpacks"
		end
	end

	return true, ""
end
_G.CanReceiveItem = canPlayerReceiveItem

-- 购买处理 (InventorySystem 版)
buyItemFunc.OnServerInvoke = function(player, itemName)
	local conf = GameConfig.Weapons[itemName] or GameConfig.Items[itemName] or GameConfig.Skin[itemName]
	if not conf then return false, "No Config" end

	local can, reason = canPlayerReceiveItem(player, itemName, 1)
	if not can then return false, reason end

	local gold = player.leaderstats.Gold
	if gold.Value < (conf.Price or 0) then return false, "No Gold" end

	gold.Value = gold.Value - (conf.Price or 0)

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

-- [出售处理] 核心逻辑
sellEvent.OnServerEvent:Connect(function(player, itemName, _, qty)
	local inv = player:FindFirstChild("Inventory")
	local itemVal = inv and inv:FindFirstChild(itemName)
	local conf = GameConfig.Weapons[itemName] or GameConfig.Items[itemName] or GameConfig.Skin[itemName]

	if itemVal and itemVal.Value >= qty then
		-- 1. 扣除数量
		itemVal.Value = itemVal.Value - qty

		-- 2. 加钱
		local gain = math.floor((conf.Price or 0) * 0.5) * qty
		-- 特殊保底逻辑 (防止0元物品卖出0元)
		if gain <= 0 and conf.CanSell then
			if conf.Rarity == "Legendary" then gain = 200
			elseif conf.Rarity == "Rare" then gain = 50
			else gain = 10 end
		end
		player.leaderstats.Gold.Value = player.leaderstats.Gold.Value + gain

		-- 3. 如果数量归零，销毁数据
		-- 这会触发 itemVal.Changed 或 ChildRemoved，进而触发 syncPhysicalTool(..., 0)
		-- 从而清理 Backpack 和 StarterGear
		if itemVal.Value <= 0 then
			-- 显式调用一次清理，确保万无一失
			syncPhysicalTool(player, itemName, 0)
			itemVal:Destroy()
		end

		print("💰 [Server] 玩家出售了 " .. itemName .. " 获得 " .. gain)
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
					Price = conf.Price,
					CanSell = conf.CanSell,
					Rarity = conf.Rarity
				})
			end
		end
	end
	return data
end

-- ==========================================
-- 4. 初始化流程
-- ==========================================
Players.PlayerAdded:Connect(function(player)
	local inv = player:FindFirstChild("Inventory") or Instance.new("Folder")
	inv.Name = "Inventory"
	inv.Parent = player

	player.CharacterAdded:Connect(function(char)
		task.wait(1) 
		bindInventorySync(player)
	end)

	-- 初次进入也绑定
	bindInventorySync(player)
end)

print("✅ [InventorySystem] 服务端逻辑就绪 (StarterGear 同步修复版)")