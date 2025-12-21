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
-- 2. 初始化 UI (极简紧凑布局)
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

	-- B. 创建圆形背包按钮 (如果不存在)
	local openBtn = gui:FindFirstChild("OpenButton")
	if not openBtn then
		openBtn = Instance.new("ImageButton")
		openBtn.Name = "OpenButton"
		openBtn.Image = "rbxassetid://120000874590886" -- 背包图标
		openBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		openBtn.BackgroundTransparency = 0.4
		openBtn.Parent = gui

		Instance.new("UICorner", openBtn).CornerRadius = UDim.new(1, 0)
		local stroke = Instance.new("UIStroke")
		stroke.Color = Color3.fromRGB(150, 150, 150)
		stroke.Thickness = 2
		stroke.Parent = openBtn
	end

	-- 调整按钮位置 (左侧，避开任务栏)
	if isSmallScreen() then
		openBtn.Size = UDim2.new(0, 40, 0, 40) 
		openBtn.Position = UDim2.new(0, 10, 0.35, 0) 
		openBtn.AnchorPoint = Vector2.new(0, 0.5) 
	else
		openBtn.Size = UDim2.new(0, 70, 0, 70)
		openBtn.Position = UDim2.new(0, 15, 0.45, 0)
		openBtn.AnchorPoint = Vector2.new(0, 0.5)
	end

	-- C. 重建主窗口 (MainFrame)
	if gui:FindFirstChild("MainFrame") then gui.MainFrame:Destroy() end

	local main = Instance.new("Frame")
	main.Name = "MainFrame"
	main.Visible = false
	main.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
	main.BorderSizePixel = 0
	main.ClipsDescendants = true 
	main.Parent = gui

	-- [布局] 窗口尺寸与定位
	if isSmallScreen() then
		-- 📱 移动端：全屏，留出极小边距防止贴边
		main.Size = UDim2.new(1, -10, 1, -10) -- 左右各留 5px
		main.Position = UDim2.new(0.5, 0, 0.5, 0)
		main.AnchorPoint = Vector2.new(0.5, 0.5)
		main.BackgroundTransparency = 0.05
		-- 移动端也加一点圆角，更精致
		Instance.new("UICorner", main).CornerRadius = UDim.new(0, 8)
	else
		-- 💻 PC端：居中悬浮窗
		main.Size = UDim2.new(0, 650, 0, 500)
		main.Position = UDim2.new(0.5, 0, 0.5, 0)
		main.AnchorPoint = Vector2.new(0.5, 0.5)
		main.BackgroundTransparency = 0
		Instance.new("UICorner", main).CornerRadius = UDim.new(0, 12)
	end

	-- ==============================
	-- 3. 窗口内部布局 (极限压缩)
	-- ==============================

	-- [关闭按钮] 放在最右上角，独立存在
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

	-- [标签页] 顶部左侧
	local tabFrame = Instance.new("Frame")
	tabFrame.Name = "TabFrame"
	tabFrame.BackgroundTransparency = 1
	tabFrame.Parent = main

	if isSmallScreen() then
		-- [优化] 移动端标签栏放在顶部左侧，高度仅 35px
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

		-- [优化] 按钮宽度更窄
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

	createTab("Backpack", "WEAPONS") -- 简短名称
	createTab("Wardrobe", "SKIN")

	-- [底部出售栏] 极限压缩
	local sellArea = Instance.new("Frame")
	sellArea.Name = "SellArea"
	sellArea.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
	sellArea.Parent = main

	if isSmallScreen() then
		-- [优化] 底部仅占 45px，稍微留一点底边距
		sellArea.Size = UDim2.new(1, -10, 0, 45)
		sellArea.Position = UDim2.new(0, 5, 1, -50) -- 留出一点底部空隙
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

	-- [中间滚动列表] 占据所有剩余空间
	scrollingFrame = Instance.new("ScrollingFrame")
	scrollingFrame.Name = "Container"
	scrollingFrame.BackgroundTransparency = 1
	scrollingFrame.ScrollBarThickness = 4
	scrollingFrame.Parent = main

	if isSmallScreen() then
		-- Top: Tab(35) + Pad(5) = 40 (起始)
		-- Bottom: SellArea(45) + Pad(5) = 50 (底部留空)
		scrollingFrame.Position = UDim2.new(0, 5, 0, 45) 
		scrollingFrame.Size = UDim2.new(1, -10, 1, -100) -- 给底部留足够空间
	else
		scrollingFrame.Position = UDim2.new(0, 15, 0, 70)
		scrollingFrame.Size = UDim2.new(1, -30, 1, -140)
	end

	local grid = Instance.new("UIGridLayout")
	grid.HorizontalAlignment = Enum.HorizontalAlignment.Left
	grid.Parent = scrollingFrame

	if isSmallScreen() then
		-- [优化] 70x70 小圆角正方形，更密集的展示
		grid.CellSize = UDim2.new(0, 70, 0, 70)
		grid.CellPadding = UDim2.new(0, 6, 0, 6)
	else
		grid.CellSize = UDim2.new(0, 100, 0, 100)
		grid.CellPadding = UDim2.new(0, 12, 0, 12)
	end

	-- ==============================
	-- 4. 事件绑定
	-- ==============================

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
			sellEvent:FireServer(selectedItemName, math.floor(selectedItemPrice * 0.5), 1)
			selectedItemName = nil
			task.wait(0.2)
			refreshInventory()
		end
	end)
end

-- ==========================================
-- 5. 刷新库存数据 (含出售逻辑)
-- ==========================================
function refreshInventory()
	-- [修复] 增加判空逻辑，防止报错
	if not scrollingFrame or not scrollingFrame.Parent then return end

	local main = scrollingFrame.Parent
	local sellArea = main:FindFirstChild("SellArea")
	local sellBtn = sellArea and sellArea:FindFirstChild("SellButton")
	local infoLabel = sellArea and sellArea:FindFirstChild("InfoLabel")

	if sellBtn then sellBtn.Visible = false end
	if infoLabel then infoLabel.Text = selectedItemName and ("Select: " .. selectedItemName) or "Select item" end

	for _, child in pairs(scrollingFrame:GetChildren()) do
		if child:IsA("GuiButton") then child:Destroy() end
	end

	local invFolder = player:FindFirstChild("Inventory")
	if not invFolder then return end

	scrollingFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)

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
				-- [优化] 物品块圆角 (与按钮一致的小圆角)
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

				card.MouseButton1Click:Connect(function()
					selectedItemName = itemName
					selectedItemPrice = conf.Price or 0
					if infoLabel then infoLabel.Text = conf.DisplayName or itemName end

					-- [新增] 出售判断逻辑
					if sellBtn then
						local canSell = false
						-- 只允许出售 Weapon 或 Items(通常包含雕像)
						if category == "Weapons" or category == "Items" then
							canSell = true
						end

						-- 特殊：禁止出售 Bat (初始武器)
						if itemName == "Bat" then
							canSell = false
						end

						local sellPrice = math.floor((conf.Price or 0) * 0.5)

						if canSell and sellPrice > 0 then
							sellBtn.Visible = true
							-- 显示出售价格
							sellBtn.Text = "SELL ($".. sellPrice ..")"
						else
							sellBtn.Visible = false
						end
					end

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
print("✅ ItemsInventoryHandler 极简布局 + 出售功能版")