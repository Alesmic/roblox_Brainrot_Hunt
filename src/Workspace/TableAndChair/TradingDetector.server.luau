-- TradingDetector 脚本 - 放置于 TableAndChair 模型内 (Server Script)
-- 负责检测玩家就座、启动、管理交易会话，并处理两阶段接受/确认逻辑。

local TradingModel = script.Parent
local Chair1Seat = TradingModel:WaitForChild("Chair1"):WaitForChild("Seat") 
local Chair2Seat = TradingModel:WaitForChild("Chair2"):WaitForChild("Seat")

-- =========================================================
-- 1. 初始化和路径定义
-- =========================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage") -- 引用 ServerStorage 用于存放工具模型
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

-- RemoteEvent 引用
local RemoteEventFolder = ReplicatedStorage:WaitForChild("RemoteEvent", 10)
local StartTradeEvent = RemoteEventFolder:WaitForChild("StartTradeUI", 10)
local HandleTradeActionEvent = RemoteEventFolder:WaitForChild("HandleTradeAction", 10)
local UpdateTradeUIEvent = RemoteEventFolder:WaitForChild("UpdateTradeUI", 10) 

-- 存储正在交易的玩家状态 
-- 结构: Player -> {Partner, Items = {}, Accepted = false, Confirmed = false}
local PlayersInTrade = {} 
local isTradingActive = false 

print("交易检测器已启动。等待玩家就座...")

-- 声明 CheckIfBothChairsOccupied，用于递归调用
local CheckIfBothChairsOccupied 

-- 辅助函数：根据物品名称查找物品配置 (兼容所有配置表)
local function getItemConfig(itemName)
	return GameConfig.Weapons[itemName] 
		or GameConfig.Skin[itemName] 
		or GameConfig.Items[itemName]
end

-- =========================================================
-- 2. 交易流程控制函数
-- =========================================================

-- 交易取消/完成后的清理函数
local function CleanUpTrade(playerA, playerB)
	isTradingActive = false

	-- 1. 解锁椅子，允许玩家站立
	Chair1Seat.Locked = false
	Chair2Seat.Locked = false

	-- 2. 强制让玩家解除坐姿
	if playerA and playerA.Character and playerA.Character:FindFirstChild("Humanoid") then
		playerA.Character.Humanoid.Sit = false 
	end
	if playerB and playerB.Character and playerB.Character:FindFirstChild("Humanoid") then
		playerB.Character.Humanoid.Sit = false
	end

	-- 3. 清理交易状态
	PlayersInTrade[playerA] = nil
	PlayersInTrade[playerB] = nil

	-- 4. 通知客户端关闭UI
	if StartTradeEvent then
		StartTradeEvent:FireClient(playerA, nil)
		StartTradeEvent:FireClient(playerB, nil)
	end

	print("[Trade] 交易会话清理完毕。")

	-- 交易结束，重新运行检查
	spawn(CheckIfBothChairsOccupied)
end

-- 交易取消函数
local function CancelTrade(player)
	if not PlayersInTrade[player] then return end
	local partner = PlayersInTrade[player].Partner

	print("[Trade] 交易取消:", player.Name, "或其伙伴站起/点击取消。")
	CleanUpTrade(player, partner)
end


-- 核心功能：物品交换 (A -> B 和 B -> A)
local function executeItemTransfer(giver, receiver, itemsList)
	local giverInventory = giver:FindFirstChild("Inventory")
	local receiverInventory = receiver:FindFirstChild("Inventory")
	local toolsFolder = ServerStorage:FindFirstChild("Tools") -- 假设工具模型在 ServerStorage/Tools

	if not giverInventory or not receiverInventory then
		warn("❌ [交易失败] 找不到玩家的 Inventory 文件夹。")
		return false
	end

	for itemName, qty in pairs(itemsList) do
		local itemConfig = getItemConfig(itemName)
		if not itemConfig then
			warn("❌ [交易失败] 找不到物品配置: " .. itemName)
			return false -- 找不到配置，终止交易
		end

		-- 1. 减少 Giver 的物品数量 (Inventory IntValue)
		local giverItemValue = giverInventory:FindFirstChild(itemName)
		if giverItemValue and giverItemValue.Value >= qty then
			giverItemValue.Value = giverItemValue.Value - qty
			if giverItemValue.Value <= 0 then
				giverItemValue:Destroy()
			end
		else
			warn("❌ [交易失败] Giver物品数量不足或不存在: " .. itemName)
			return false -- 数量不足，终止交易
		end

		-- 2. 增加 Receiver 的物品数量 (Inventory IntValue)
		local receiverItemValue = receiverInventory:FindFirstChild(itemName)
		if receiverItemValue then
			receiverItemValue.Value = receiverItemValue.Value + qty
		else
			receiverItemValue = Instance.new("IntValue")
			receiverItemValue.Name = itemName
			receiverItemValue.Value = qty
			receiverItemValue.Parent = receiverInventory
		end

		-- 3. 处理工具模型 (如果物品是工具/武器)
		if itemConfig.Category == "Weapons" or itemConfig.Category == "Tools" then
			local toolModel = toolsFolder and toolsFolder:FindFirstChild(itemName)
			if toolModel then
				-- 从 Giver 移除所有工具实例 (Backpack和StarterGear)
				if giver.Backpack:FindFirstChild(itemName) then
					giver.Backpack:FindFirstChild(itemName):Destroy()
				end
				if giver.StarterGear:FindFirstChild(itemName) then
					giver.StarterGear:FindFirstChild(itemName):Destroy()
				end

				-- 给 Receiver 发放工具模型
				toolModel:Clone().Parent = receiver.Backpack
				toolModel:Clone().Parent = receiver.StarterGear
			end
		end
	end
	return true
end

-- 最终交换物品函数 (实际执行交易)
local function FinalizeTrade(playerA, playerB)
	print("双方已最终确认，开始执行交易...")

	local itemsA = PlayersInTrade[playerA].Items -- A给B的物品 {Name=Qty}
	local itemsB = PlayersInTrade[playerB].Items -- B给A的物品 {Name=Qty}

	-- 执行交易 A -> B
	local successA = executeItemTransfer(playerA, playerB, itemsA) 

	-- 只有当 A -> B 成功后，才执行 B -> A，确保原子性（部分成功后需要更复杂的事务回滚）
	local successB = false
	if successA then
		successB = executeItemTransfer(playerB, playerA, itemsB)
	end

	if successA and successB then
		print("✅ [Trade] 交易成功！物品已交换。")
		CleanUpTrade(playerA, playerB)
	else
		warn("⚠️ [Trade] 交易执行失败！由于数据验证不通过或物品处理错误，交易已终止。")
		-- 实际游戏中，如果发生错误，应尝试回滚所有已执行的操作。
		CleanUpTrade(playerA, playerB)
	end
end

-- =========================================================
-- 3. 核心检测和启动函数
-- =========================================================

function CheckIfBothChairsOccupied()
	if isTradingActive and Chair1Seat.Occupant and Chair2Seat.Occupant then return end 

	local occupant1 = Chair1Seat.Occupant
	local occupant2 = Chair2Seat.Occupant

	local isChair1Occupied = occupant1 and occupant1:IsA("Humanoid")
	local isChair2Occupied = occupant2 and occupant2:IsA("Humanoid")

	-- --- A. 启动交易逻辑 ---
	if isChair1Occupied and isChair2Occupied and not isTradingActive then
		local player1 = game.Players:GetPlayerFromCharacter(occupant1.Parent)
		local player2 = game.Players:GetPlayerFromCharacter(occupant2.Parent)

		if player1 and player2 and (player1 ~= player2) then
			isTradingActive = true

			print("====================================")
			print("✅ [Trade] 交易会话启动！")

			-- 1. 锁定椅子
			Chair1Seat.Locked = true 
			Chair2Seat.Locked = true

			-- 2. 初始化交易状态
			PlayersInTrade[player1] = {Partner = player2, Items = {}, Accepted = false, Confirmed = false}
			PlayersInTrade[player2] = {Partner = player1, Items = {}, Accepted = false, Confirmed = false}

			-- 3. 通知客户端打开交易界面
			if StartTradeEvent then
				StartTradeEvent:FireClient(player1, player2.Name)
				StartTradeEvent:FireClient(player2, player1.Name)
			end

			return
		end
	end

	-- --- B. 取消交易逻辑 (有人站起来) ---
	if isTradingActive and (not isChair1Occupied or not isChair2Occupied) then
		local playerToCancel = nil
		if next(PlayersInTrade) then
			for p, _ in pairs(PlayersInTrade) do
				playerToCancel = p
				break
			end
		end

		if playerToCancel then
			CancelTrade(playerToCancel)
		end
		return
	end
end

-- =========================================================
-- 4. RemoteEvent 监听 (处理客户端操作)
-- =========================================================

HandleTradeActionEvent.OnServerEvent:Connect(function(player, action, itemsData)
	if not PlayersInTrade[player] or not isTradingActive then return end

	local partner = PlayersInTrade[player].Partner
	local myTradeState = PlayersInTrade[player]
	local partnerTradeState = PlayersInTrade[partner]

	if not partnerTradeState then 
		CleanUpTrade(player, partner)
		return
	end

	if action == "Accept" then
		-- 阶段 1: 接受/锁定物品列表
		myTradeState.Accepted = true
		myTradeState.Confirmed = false -- 重置确认状态

		-- 通知伙伴客户端更新他们的状态 UI 
		UpdateTradeUIEvent:FireClient(partner, myTradeState.Items, true, false)

	elseif action == "Confirm" then
		-- 阶段 2: 最终确认
		if not myTradeState.Accepted then
			warn("[Trade] 玩家在未接受状态下发送了 Confirm 请求，忽略。")
			return
		end

		myTradeState.Confirmed = true

		-- 通知伙伴客户端更新他们的最终确认状态 UI
		UpdateTradeUIEvent:FireClient(partner, myTradeState.Items, true, true)

		-- 检查双方是否都最终确认
		if myTradeState.Confirmed and partnerTradeState.Confirmed then
			FinalizeTrade(player, partner)
		end

	elseif action == "Cancel" then
		CancelTrade(player)

	elseif action == "UpdateItems" then
		myTradeState.Items = itemsData 

		-- 任何物品变化都会取消双方的所有接受和确认状态
		myTradeState.Accepted = false 
		myTradeState.Confirmed = false
		partnerTradeState.Accepted = false 
		partnerTradeState.Confirmed = false

		-- 通知伙伴客户端更新他们的交易列表和未接受状态
		UpdateTradeUIEvent:FireClient(partner, itemsData, false, false) 
	end
end)

-- =========================================================
-- 5. 初始事件绑定
-- =========================================================

Chair1Seat:GetPropertyChangedSignal("Occupant"):Connect(CheckIfBothChairsOccupied)
Chair2Seat:GetPropertyChangedSignal("Occupant"):Connect(CheckIfBothChairsOccupied)

spawn(CheckIfBothChairsOccupied)