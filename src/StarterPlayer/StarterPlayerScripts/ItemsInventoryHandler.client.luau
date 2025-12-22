local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local RemoteEventFolder = ReplicatedStorage:WaitForChild("RemoteEvent")
local sellEvent = RemoteEventFolder:WaitForChild("SellItem")

-- ==========================================
-- 配置区
-- ==========================================
local GUI_NAME = "CyberInventory" 
local currentTab = "Backpack" 
local selectedItemName = nil
local selectedItemPrice = 0
local scrollingFrame = nil

-- ==========================================
-- 1. 核心工具：检测移动端
-- ==========================================
local function isSmallScreen()
	local camera = workspace.CurrentCamera
	local screenSize = camera and camera.ViewportSize or Vector2.new(1920, 1080)
	return UserInputService.TouchEnabled or screenSize.X < 800
end

-- ==========================================
-- 价格计算辅助函数
-- ==========================================
local function calculateSellPrice(itemName, conf)
	if conf.SellPrice then return conf.SellPrice end

	local basePrice = conf.Price or 0
	local finalSellPrice = math.floor(basePrice * 0.5)

	-- 针对 Price=0 但 CanSell=true 的物品给予保底价
	if finalSellPrice <= 0 and conf.CanSell then
		if conf.Rarity == "Legendary" then return 200
		elseif conf.Rarity == "Epic" then return 100
		elseif conf.Rarity == "Rare" then return 50
		else return 10 end
	end

	return finalSellPrice
end

-- ==========================================
-- 2. 初始化 UI
-- ==========================================
local function initInterface()
	-- A. 确保 ScreenGui 存在
	local gui = playerGui:FindFirstChild(GUI_NAME)
	if not gui then
		gui = Instance.new("ScreenGui")
		gui.Name = GUI_NAME
		gui.ResetOnSpawn = false
		gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		gui.DisplayOrder = 1000
		gui.Parent = playerGui
	end

	-- B. 创建圆形背包按钮
	local openBtn = gui:FindFirstChild("OpenButton")
	if not openBtn then
		openBtn = Instance.new("ImageButton")
		openBtn.Name = "OpenButton"
		openBtn.Image = "rbxassetid://120000874590886" 
		openBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		openBtn.BackgroundTransparency = 0.4
		openBtn.Parent = gui

		Instance.new("UICorner", openBtn).CornerRadius = UDim.new(1, 0)
		local stroke = Instance.new("UIStroke")
		stroke.Color = Color3.fromRGB(150, 150, 150)
		stroke.Thickness = 2
		stroke.Parent = openBtn
	end

	-- 调整按钮位置
	if isSmallScreen() then
		openBtn.Size = UDim2.new(0, 40, 0, 40) 
		openBtn.Position = UDim2.new(0, 10, 0.35, 0) 
		openBtn.AnchorPoint = Vector2.new(0, 0.5) 
	else
		openBtn.Size = UDim2.new(0, 70, 0, 70)
		openBtn.Position = UDim2.new(0, 15, 0.45, 0)
		openBtn.AnchorPoint = Vector2.new(0, 0.5)
	end

	-- C. 重建主窗口
	if gui:FindFirstChild("MainFrame") then gui.MainFrame:Destroy() end

	local main = Instance.new("Frame")
	main.Name = "MainFrame"
	main.Visible = false
	main.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
	main.BorderSizePixel = 0
	main.ClipsDescendants = true 
	main.Parent = gui

	-- 窗口适配
	if isSmallScreen() then
		main.Size = UDim2.new(1, -10, 1, -10)
		main.Position = UDim2.new(0.5, 0, 0.5, 0)
		main.AnchorPoint = Vector2.new(0.5, 0.5)
		main.BackgroundTransparency = 0.05
		Instance.new("UICorner", main).CornerRadius = UDim.new(0, 8)
	else
		main.Size = UDim2.new(0, 650, 0, 500)
		main.Position = UDim2.new(0.5, 0, 0.5, 0)
		main.AnchorPoint = Vector2.new(0.5, 0.5)
		main.BackgroundTransparency = 0
		Instance.new("UICorner", main).CornerRadius = UDim.new(0, 12)
	end

	-- 关闭按钮
	local closeBtn = Instance.new("TextButton")
	closeBtn.Name = "CloseButton"
	closeBtn.Text = "X"
	closeBtn.Font = Enum.Font.FredokaOne
	closeBtn.TextColor3 = Color3.new(1, 1, 1)
	closeBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
	closeBtn.Parent = main 
	closeBtn.ZIndex = 200 
	Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)

	if isSmallScreen() then
		closeBtn.Size = UDim2.new(0, 32, 0, 32) 
		closeBtn.AnchorPoint = Vector2.new(1, 0)
		closeBtn.Position = UDim2.new(1, -5, 0, 5) 
	else
		closeBtn.Size = UDim2.new(0, 35, 0, 35)
		closeBtn.Position = UDim2.new(1, -15, 0, 15)
	end

	-- 标签页
	local tabFrame = Instance.new("Frame")
	tabFrame.Name = "TabFrame"
	tabFrame.BackgroundTransparency = 1
	tabFrame.Parent = main

	if isSmallScreen() then
		tabFrame.Size = UDim2.new(0.7, 0, 0, 35) 
		tabFrame.Position = UDim2.new(0, 5, 0, 5)
	else
		tabFrame.Size = UDim2.new(1, -60, 0, 45)
		tabFrame.Position = UDim2.new(0, 15, 0, 15)
	end

	local tabLayout = Instance.new("UIListLayout")
	tabLayout.FillDirection = Enum.FillDirection.Horizontal
	tabLayout.Padding = UDim.new(0, 5)
	tabLayout.Parent = tabFrame

	local function createTab(id, text)
		local btn = Instance.new("TextButton")
		btn.Name = id
		btn.Text = text
		btn.Font = Enum.Font.FredokaOne
		btn.TextColor3 = Color3.new(1, 1, 1)
		btn.BackgroundColor3 = (currentTab == id) and Color3.fromRGB(80, 80, 90) or Color3.fromRGB(50, 50, 55)
		btn.Parent = tabFrame
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
		btn.Size = UDim2.new(0.48, 0, 1, 0) 
		btn.TextSize = isSmallScreen() and 14 or 18

		btn.MouseButton1Click:Connect(function()
			currentTab = id
			selectedItemName = nil
			for _, child in pairs(tabFrame:GetChildren()) do
				if child:IsA("TextButton") then
					child.BackgroundColor3 = (child.Name == currentTab) and Color3.fromRGB(80, 80, 90) or Color3.fromRGB(50, 50, 55)
				end
			end
			refreshInventory()
		end)
	end

	createTab("Backpack", "WEAPONS") 
	createTab("Wardrobe", "SKIN")

	-- 底部出售栏
	local sellArea = Instance.new("Frame")
	sellArea.Name = "SellArea"
	sellArea.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
	sellArea.Parent = main

	if isSmallScreen() then
		sellArea.Size = UDim2.new(1, -10, 0, 45)
		sellArea.Position = UDim2.new(0, 5, 1, -50) 
		Instance.new("UICorner", sellArea).CornerRadius = UDim.new(0, 6)
	else
		sellArea.Size = UDim2.new(1, -30, 0, 50)
		sellArea.Position = UDim2.new(0, 15, 1, -65)
		Instance.new("UICorner", sellArea).CornerRadius = UDim.new(0, 8)
	end

	local sellBtn = Instance.new("TextButton")
	sellBtn.Name = "SellButton"
	sellBtn.Text = "SELL"
	sellBtn.Font = Enum.Font.FredokaOne
	sellBtn.TextColor3 = Color3.new(1, 1, 1)
	sellBtn.BackgroundColor3 = Color3.fromRGB(46, 139, 87)
	sellBtn.Visible = false
	sellBtn.Parent = sellArea
	Instance.new("UICorner", sellBtn).CornerRadius = UDim.new(0, 6)

	local infoLabel = Instance.new("TextLabel")
	infoLabel.Name = "InfoLabel"
	infoLabel.Text = "Select item"
	infoLabel.Font = Enum.Font.FredokaOne
	infoLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	infoLabel.BackgroundTransparency = 1
	infoLabel.TextXAlignment = Enum.TextXAlignment.Left
	infoLabel.Parent = sellArea

	if isSmallScreen() then
		sellBtn.Size = UDim2.new(0.3, 0, 0.8, 0)
		sellBtn.Position = UDim2.new(0.68, 0, 0.1, 0)
		sellBtn.TextSize = 16
		infoLabel.Size = UDim2.new(0.65, 0, 1, 0)
		infoLabel.Position = UDim2.new(0.02, 0, 0, 0)
		infoLabel.TextSize = 14
	else
		sellBtn.Size = UDim2.new(0.3, 0, 0.7, 0)
		sellBtn.Position = UDim2.new(0.65, 0, 0.15, 0)
		sellBtn.TextSize = 18
		infoLabel.Size = UDim2.new(0.6, 0, 1, 0)
		infoLabel.Position = UDim2.new(0.05, 0, 0, 0)
		infoLabel.TextSize = 16
	end

	-- 物品滚动列表
	scrollingFrame = Instance.new("ScrollingFrame")
	scrollingFrame.Name = "Container"
	scrollingFrame.BackgroundTransparency = 1
	scrollingFrame.ScrollBarThickness = 4
	scrollingFrame.Parent = main

	if isSmallScreen() then
		scrollingFrame.Position = UDim2.new(0, 5, 0, 45) 
		scrollingFrame.Size = UDim2.new(1, -10, 1, -100) 
	else
		scrollingFrame.Position = UDim2.new(0, 15, 0, 70)
		scrollingFrame.Size = UDim2.new(1, -30, 1, -140)
	end

	local grid = Instance.new("UIGridLayout")
	grid.HorizontalAlignment = Enum.HorizontalAlignment.Left
	grid.Parent = scrollingFrame

	if isSmallScreen() then
		grid.CellSize = UDim2.new(0, 70, 0, 70)
		grid.CellPadding = UDim2.new(0, 6, 0, 6)
	else
		grid.CellSize = UDim2.new(0, 100, 0, 100)
		grid.CellPadding = UDim2.new(0, 12, 0, 12)
	end

	-- 事件绑定
	local function toggleUI()
		main.Visible = not main.Visible
		if main.Visible then
			refreshInventory()
		end
	end

	openBtn.MouseButton1Click:Connect(toggleUI)
	closeBtn.MouseButton1Click:Connect(function() main.Visible = false end)

	sellBtn.MouseButton1Click:Connect(function()
		if selectedItemName then
			sellEvent:FireServer(selectedItemName, selectedItemPrice, 1)
			selectedItemName = nil
			task.wait(0.2)
			refreshInventory()
		end
	end)
end

-- ==========================================
-- 5. 刷新库存数据 (逻辑修复)
-- ==========================================
function refreshInventory()
	if not scrollingFrame or not scrollingFrame.Parent then return end

	local main = scrollingFrame.Parent
	local sellArea = main:FindFirstChild("SellArea")
	local sellBtn = sellArea and sellArea:FindFirstChild("SellButton")
	local infoLabel = sellArea and sellArea:FindFirstChild("InfoLabel")

	-- 1. 重置界面状态
	if sellBtn then sellBtn.Visible = false end
	if infoLabel then infoLabel.Text = selectedItemName and ("Select: " .. selectedItemName) or "Select item" end

	-- 2. [关键] 在刷新时，如果已选中物品，检查是否显示出售按钮
	if selectedItemName and sellBtn then
		local conf = GameConfig.Weapons[selectedItemName] or GameConfig.Items[selectedItemName] or GameConfig.Skin[selectedItemName]

		if conf then
			local category = conf.Category
			local canSell = false

			-- 规则：只卖 Weapon, Items, Misc
			if category == "Weapons" or category == "Items" or category == "Misc" then
				canSell = true
			end
			-- 规则：初始武器 Bat 不可卖
			if selectedItemName == "Bat" then canSell = false end
			-- 规则：配置明确禁止
			if conf.CanSell == false then canSell = false end

			-- 计算价格
			local finalSellPrice = calculateSellPrice(selectedItemName, conf)
			selectedItemPrice = finalSellPrice -- 更新全局价格

			-- 显示按钮条件：可卖 且 价格>0
			if canSell and finalSellPrice > 0 then
				sellBtn.Visible = true
				sellBtn.Text = "SELL ($".. finalSellPrice ..")"
			end
		end
	end

	-- 3. 清理旧列表
	for _, child in pairs(scrollingFrame:GetChildren()) do
		if child:IsA("GuiButton") then child:Destroy() end
	end

	local invFolder = player:FindFirstChild("Inventory")
	if not invFolder then return end

	scrollingFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)

	-- 4. 生成新列表
	for _, itemVal in ipairs(invFolder:GetChildren()) do
		local itemName = itemVal.Name
		local qty = itemVal.Value
		local conf = GameConfig.Weapons[itemName] or GameConfig.Items[itemName] or GameConfig.Skin[itemName]

		if conf and qty > 0 then
			local category = conf.Category or "Items"
			local show = false

			if currentTab == "Backpack" then
				if category ~= "Skins" and category ~= "Skin" and category ~= "Aura Skin" then show = true end
			elseif currentTab == "Wardrobe" then
				if category == "Skins" or category == "Skin" or category == "Aura Skin" then show = true end
			end

			if show then
				local card = Instance.new("ImageButton")
				card.Name = itemName
				card.BackgroundColor3 = (selectedItemName == itemName) and Color3.fromRGB(70, 70, 80) or Color3.fromRGB(45, 45, 50)
				card.Parent = scrollingFrame
				Instance.new("UICorner", card).CornerRadius = UDim.new(0, 6)

				if selectedItemName == itemName then
					local s = Instance.new("UIStroke")
					s.Color = Color3.fromRGB(255, 215, 0)
					s.Thickness = 2
					s.Parent = card
				end

				local icon = Instance.new("ImageLabel")
				icon.Size = UDim2.new(0.8, 0, 0.8, 0)
				icon.Position = UDim2.new(0.5, 0, 0.5, 0)
				icon.AnchorPoint = Vector2.new(0.5, 0.5)
				icon.BackgroundTransparency = 1
				icon.Image = conf.ImageId or ""
				icon.Parent = card

				local qtyLabel = Instance.new("TextLabel")
				qtyLabel.Size = UDim2.new(0.4, 0, 0.3, 0)
				qtyLabel.Position = UDim2.new(0.6, 0, 0.7, 0)
				qtyLabel.BackgroundTransparency = 1
				qtyLabel.Text = "x"..qty
				qtyLabel.TextColor3 = Color3.new(1, 1, 1)
				qtyLabel.Font = Enum.Font.FredokaOne
				qtyLabel.TextSize = isSmallScreen() and 14 or 18
				qtyLabel.Parent = card

				-- 点击逻辑：只更新状态，然后刷新界面
				card.MouseButton1Click:Connect(function()
					selectedItemName = itemName
					refreshInventory()
				end)
			end
		end
	end
end

-- ==========================================
-- 6. 启动
-- ==========================================
initInterface()

player:WaitForChild("Inventory").ChildAdded:Connect(refreshInventory)
player.Inventory.ChildRemoved:Connect(refreshInventory)
for _, item in pairs(player.Inventory:GetChildren()) do
	item.Changed:Connect(refreshInventory)
end

workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
	if playerGui:FindFirstChild(GUI_NAME) then
		local main = playerGui[GUI_NAME]:FindFirstChild("MainFrame")
		local wasVisible = main and main.Visible
		initInterface()
		if wasVisible and playerGui[GUI_NAME]:FindFirstChild("MainFrame") then 
			playerGui[GUI_NAME].MainFrame.Visible = true 
			refreshInventory()
		end
	end
end)

refreshInventory()
print("✅ ItemsInventoryHandler：Sell按钮显示逻辑修复完毕")