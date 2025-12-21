-- 位置: StarterGui -> DoctorGui -> DoctorShop_Local
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local gui = script.Parent
local frame = gui:WaitForChild("MainFrame")
local closeBtn = frame:WaitForChild("CloseButton")
local Buy = frame:WaitForChild("BuyTextButton")
local LimitLabel = frame:WaitForChild("LimitLabel")

-- 物品配置
local ITEM_NAME = "Medpack" 
local ITEM_COST = 20
local MAX_LIMIT = 3

-- 引用 RemoteEvents
local RemoteEventFolder = ReplicatedStorage:WaitForChild("RemoteEvent")
local ToggleWindow = RemoteEventFolder:WaitForChild("ToggleHealerWindow") 
local PurchaseItem = RemoteEventFolder:WaitForChild("PurchaseItem") 

-- ==========================================
-- 1. 核心工具：检测屏幕尺寸 (独立函数)
-- ==========================================
local function checkIsSmallScreen()
	local camera = workspace.CurrentCamera
	if not camera then return false end
	local viewportSize = camera.ViewportSize
	-- 判定标准：触摸屏 或 屏幕宽度小于 800
	return UserInputService.TouchEnabled or viewportSize.X < 800
end

-- ==========================================
-- 2. UI 自适应执行逻辑
-- ==========================================
local function adaptUI()
	local isSmall = checkIsSmallScreen()

	-- 确保 SizeConstraint 存在 (用于限制 PC 端最大最小尺寸)
	local sizeConstraint = frame:FindFirstChild("UISizeConstraint") or Instance.new("UISizeConstraint", frame)

	-- [关键修复] 强制提升层级，防止文字被遮挡
	LimitLabel.ZIndex = 100 
	LimitLabel.Visible = true
	LimitLabel.BackgroundTransparency = 1 

	Buy.ZIndex = 100
	closeBtn.ZIndex = 101

	if isSmall then
		-- 📱 [移动端模式]：全屏沉浸
		frame.Size = UDim2.new(1, 0, 1, 0)
		frame.Position = UDim2.new(0, 0, 0, 0)
		frame.AnchorPoint = Vector2.new(0, 0)
		frame.BackgroundTransparency = 0.05

		sizeConstraint.MaxSize = Vector2.new(9999, 9999)
		sizeConstraint.MinSize = Vector2.new(0, 0)

		if frame:FindFirstChild("UICorner") then frame.UICorner:Destroy() end

		-- 关闭按钮
		closeBtn.Size = UDim2.new(0, 55, 0, 55)
		closeBtn.Position = UDim2.new(1, -15, 0, 15)
		closeBtn.AnchorPoint = Vector2.new(1, 0)

		-- 购买按钮
		Buy.Size = UDim2.new(0.6, 0, 0.15, 0)
		Buy.Position = UDim2.new(0.5, 0, 0.85, 0)
		Buy.AnchorPoint = Vector2.new(0.5, 0.5)
		Buy.TextSize = 24

		-- 限购标签
		LimitLabel.Size = UDim2.new(0.8, 0, 0.08, 0)
		LimitLabel.Position = UDim2.new(0.5, 0, 0.75, 0)
		LimitLabel.AnchorPoint = Vector2.new(0.5, 0.5)
		LimitLabel.TextScaled = true

	else
		-- 💻 [PC 端模式]：自适应居中窗口
		frame.Size = UDim2.new(0.45, 0, 0.55, 0) 
		frame.Position = UDim2.new(0.5, 0, 0.5, 0)
		frame.AnchorPoint = Vector2.new(0.5, 0.5)
		frame.BackgroundTransparency = 0

		sizeConstraint.MinSize = Vector2.new(400, 300)
		sizeConstraint.MaxSize = Vector2.new(800, 600)

		local uic = frame:FindFirstChild("UICorner") or Instance.new("UICorner", frame)
		uic.CornerRadius = UDim.new(0, 12)

		-- 按钮
		closeBtn.Size = UDim2.new(0.08, 0, 0.08, 0)
		closeBtn.Position = UDim2.new(0.98, 0, 0.02, 0)
		closeBtn.AnchorPoint = Vector2.new(1, 0)

		Buy.Size = UDim2.new(0.6, 0, 0.15, 0)
		Buy.Position = UDim2.new(0.5, 0, 0.85, 0)
		Buy.AnchorPoint = Vector2.new(0.5, 0.5)
		Buy.TextSize = 20

		-- 限购标签
		LimitLabel.Size = UDim2.new(0.8, 0, 0.1, 0)
		LimitLabel.Position = UDim2.new(0.5, 0, 0.7, 0)
		LimitLabel.AnchorPoint = Vector2.new(0.5, 0.5)
		LimitLabel.TextScaled = true
	end
end

-- ==========================================
-- 3. 更新限购显示文字
-- ==========================================
local function updateLimitDisplay()
	local inventory = player:FindFirstChild("Inventory")
	local count = 0

	if inventory then
		local itemData = inventory:FindFirstChild(ITEM_NAME)
		if itemData then
			count = itemData.Value
		end
	end

	LimitLabel.Text = "Limit: " .. count .. "/" .. MAX_LIMIT

	if count >= MAX_LIMIT then
		LimitLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
		Buy.Text = "MAX LIMIT REACHED"
		Buy.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
		Buy.AutoButtonColor = false
	else
		LimitLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
		Buy.Text = "Purchase " .. ITEM_NAME .. " ($" .. ITEM_COST .. ")"
		Buy.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
		Buy.AutoButtonColor = true
	end
end

-- ==========================================
-- 4. 事件连接
-- ==========================================
ToggleWindow.OnClientEvent:Connect(function()
	print("✅ Doctor Shop Opened")

	adaptUI() 
	frame.Visible = true 
	updateLimitDisplay()

	-- 动画
	frame.Size = UDim2.new(0,0,0,0)
	local targetSize
	if checkIsSmallScreen() then 
		targetSize = UDim2.new(1, 0, 1, 0)
	else
		targetSize = UDim2.new(0.45, 0, 0.55, 0)
	end
	TweenService:Create(frame, TweenInfo.new(0.3, Enum.EasingStyle.Back), {Size = targetSize}):Play()

	-- 监听
	local inventory = player:WaitForChild("Inventory")
	local itemData = inventory:FindFirstChild(ITEM_NAME)

	if not itemData then
		local conn
		conn = inventory.ChildAdded:Connect(function(child)
			if child.Name == ITEM_NAME then
				updateLimitDisplay()
				child.Changed:Connect(updateLimitDisplay)
				if conn then conn:Disconnect() end
			end
		end)
	else
		itemData.Changed:Connect(updateLimitDisplay)
	end

	pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false) end)
end)

closeBtn.MouseButton1Click:Connect(function()
	frame.Visible = false
	pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, true) end)
end)

Buy.MouseButton1Click:Connect(function()
	if Buy.Text == "MAX LIMIT REACHED" then return end
	PurchaseItem:FireServer(ITEM_NAME, ITEM_COST)
end)

workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
	if frame.Visible then
		adaptUI()
	end
end)