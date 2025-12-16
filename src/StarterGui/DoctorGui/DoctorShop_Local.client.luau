-- 位置: StarterGui -> DoctorGui -> DoctorShop_Local
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer
local gui = script.Parent
local frame = gui:WaitForChild("MainFrame")
local closeBtn = frame:WaitForChild("CloseButton")
local Buy = frame:WaitForChild("BuyTextButton")
local LimitLabel = frame:WaitForChild("LimitLabel") -- [新增] 获取限购标签

-- 物品配置
local ITEM_NAME = "Medpack" 
local ITEM_COST = 20
local MAX_LIMIT = 3

-- 引用 RemoteEvents
local RemoteEventFolder = ReplicatedStorage:WaitForChild("RemoteEvent")
local ToggleWindow = RemoteEventFolder:WaitForChild("ToggleHealerWindow") 
local PurchaseItem = RemoteEventFolder:WaitForChild("PurchaseItem") 

-- ==========================================
-- [核心功能] 更新限购显示文字
-- ==========================================
local function updateLimitDisplay()
	-- 1. 查找玩家背包数据
	local inventory = player:FindFirstChild("Inventory")
	local count = 0

	if inventory then
		local itemData = inventory:FindFirstChild(ITEM_NAME)
		if itemData then
			count = itemData.Value
		end
	end

	-- 2. 更新文字
	LimitLabel.Text = "限 " .. count .. "/" .. MAX_LIMIT .. " 个"

	-- 3. (可选) 如果满了，把按钮变灰或变红
	if count >= MAX_LIMIT then
		LimitLabel.TextColor3 = Color3.fromRGB(255, 0, 0) -- 红色警告
		Buy.Text = "已达上限"
		Buy.BackgroundColor3 = Color3.fromRGB(100, 100, 100) -- 灰色按钮
	else
		LimitLabel.TextColor3 = Color3.fromRGB(0, 0, 0) -- 正常颜色
		Buy.Text = "Buy " .. ITEM_NAME .. " ($" .. ITEM_COST .. ")"
		Buy.BackgroundColor3 = Color3.fromRGB(46, 204, 113) -- 绿色按钮
	end
end

-- ==========================================
-- 1. 收到打开信号
-- ==========================================
ToggleWindow.OnClientEvent:Connect(function()
	print("✅ 医生商店已开启！") 
	frame.Visible = true

	-- [关键] 打开时立即更新一次数量显示
	updateLimitDisplay()

	-- [关键] 开启实时监听：一旦 inventory 里的 Medpack 数量变化，立即刷新 UI
	-- 这样无论是刚买完，还是用掉了一个，UI 都会自动变
	local inventory = player:WaitForChild("Inventory")
	local itemData = inventory:FindFirstChild(ITEM_NAME)

	-- 如果还没有这个物品数据(还没买过)，就监听 Inventory 文件夹的添加事件
	if not itemData then
		local conn
		conn = inventory.ChildAdded:Connect(function(child)
			if child.Name == ITEM_NAME then
				updateLimitDisplay()
				-- 找到后，转为监听这个 Value 的变化
				child.Changed:Connect(updateLimitDisplay)
				conn:Disconnect() -- 断开 ChildAdded 监听
			end
		end)
	else
		-- 如果已经有了，直接监听数值变化
		itemData.Changed:Connect(updateLimitDisplay)
	end

	pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false) end)
	UserInputService.MouseBehavior = Enum.MouseBehavior.Default
end)

-- ==========================================
-- 2. 点击关闭按钮
-- ==========================================
closeBtn.MouseButton1Click:Connect(function()
	frame.Visible = false
	pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, true) end)
end)

-- ==========================================
-- 3. 点击购买按钮
-- ==========================================
Buy.MouseButton1Click:Connect(function()
	-- 前端先做个简单判断，防止手滑
	if Buy.Text == "已达上限" then return end

	print("🖥️ [客户端] 请求购买: " .. ITEM_NAME)
	PurchaseItem:FireServer(ITEM_NAME, ITEM_COST)
end)