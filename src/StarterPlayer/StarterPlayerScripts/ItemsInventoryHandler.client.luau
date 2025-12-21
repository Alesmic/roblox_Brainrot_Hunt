local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local RemoteEventFolder = ReplicatedStorage:WaitForChild("RemoteEvent")
local sellEvent = RemoteEventFolder:WaitForChild("SellItem")

-- 状态管理
local currentTab = "Weapons" 
local selectedItemName = nil
local scrollingFrame = nil

-- ==========================================
-- 1. UI 结构初始化 (经典样式 + 智能尺寸)
-- ==========================================
local function setupInventoryUI()
	local gui = playerGui:WaitForChild("InventoryGui", 10)
	if not gui then return end

	local main = gui:WaitForChild("MainFrame")

	-- 检测是否为移动端
	local isMobile = UserInputService.TouchEnabled and not UserInputService.MouseEnabled

	-- [核心调整] 恢复原来的宽敞布局，但针对移动端放大窗口本身
	if isMobile then
		-- 移动端：窗口占屏幕 95% 宽，85% 高 (解决显示不全问题)
		main.Size = UDim2.new(0.95, 0, 0.85, 0)
	else
		-- PC端：保持经典的 70% 宽，80% 高
		main.Size = UDim2.new(0.7, 0, 0.8, 0) 
	end

	main.AnchorPoint = Vector2.new(0.5, 0.5)
	main.Position = UDim2.new(0.5, 0, 0.5, 0)

	scrollingFrame = main:WaitForChild("Container")

	-- [恢复样式] 恢复之前的间距设置 (顶部 100，底部预留 165)
	-- 不再压缩内部空间，保持美观
	scrollingFrame.Position = UDim2.new(0, 10, 0, 100) 
	scrollingFrame.Size = UDim2.new(1, -20, 1, -165)   

	-- A. 创建分类按钮容器
	local tabFrame = main:FindFirstChild("TabFrame")
	if not tabFrame then
		tabFrame = Instance.new("Frame")
		tabFrame.Name = "TabFrame"
		tabFrame.Size = UDim2.new(1, -20, 0, 45) -- 保持 45 高度
		tabFrame.Position = UDim2.new(0, 10, 0, 50) -- 保持 50 偏移
		tabFrame.BackgroundTransparency = 1
		tabFrame.Parent = main

		local layout = Instance.new("UIListLayout")
		layout.FillDirection = Enum.FillDirection.Horizontal
		layout.Padding = UDim.new(0, 12) -- 恢复宽间距
		layout.Parent = tabFrame
	end

	-- B. 创建出售区域
	local sellArea = main:FindFirstChild("SellArea")
	if not sellArea then
		sellArea = Instance.new("Frame")
		sellArea.Name = "SellArea"
		sellArea.Size = UDim2.new(1, -20, 0, 50) -- 恢复 50 高度
		sellArea.Position = UDim2.new(0, 10, 1, -55) -- 恢复底部位置
		sellArea.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
		sellArea.Parent = main
		Instance.new("UICorner", sellArea)

		local sellBtn = Instance.new("TextButton")
		sellBtn.Name = "SellButton"
		sellBtn.Size = UDim2.new(0.4, 0, 0.8, 0)
		sellBtn.Position = UDim2.new(0.55, 0, 0.1, 0)
		sellBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
		sellBtn.Text = "SELL (50%)"
		sellBtn.Font = Enum.Font.FredokaOne
		sellBtn.TextColor3 = Color3.new(1,1,1)
		sellBtn.TextSize = 18 
		sellBtn.Parent = sellArea
		Instance.new("UICorner", sellBtn)

		local infoLabel = Instance.new("TextLabel")
		infoLabel.Name = "InfoLabel"
		infoLabel.Size = UDim2.new(0.5, 0, 1, 0)
		infoLabel.Position = UDim2.new(0, 15, 0, 0)
		infoLabel.BackgroundTransparency = 1
		infoLabel.Text = "Select item"
		infoLabel.TextColor3 = Color3.new(1,1,1)
		infoLabel.Font = Enum.Font.FredokaOne
		infoLabel.TextSize = 16
		infoLabel.TextXAlignment = Enum.TextXAlignment.Left
		infoLabel.Parent = sellArea

		sellBtn.MouseButton1Click:Connect(function()
			if selectedItemName then
				sellEvent:FireServer(selectedItemName, 0, 1)
				selectedItemName = nil
				task.wait(0.1)
				refreshInventory()
			end
		end)
	end

	-- C. 生成分类按钮 (恢复大字体样式)
	local tabs = {
		{Id = "Weapons", Name = "Weapons"},
		{Id = "Items", Name = "Items"},
		{Id = "Skins", Name = "Skins"}
	}

	for _, t in ipairs(tabs) do
		if not tabFrame:FindFirstChild(t.Id) then
			local btn = Instance.new("TextButton")
			btn.Name = t.Id
			-- [恢复] 按钮宽度 120
			btn.Size = UDim2.new(0, 120, 1, 0) 
			btn.BackgroundColor3 = (currentTab == t.Id) and Color3.fromRGB(70, 70, 80) or Color3.fromRGB(40, 40, 45)
			btn.Text = t.Name
			btn.TextColor3 = Color3.new(1,1,1)
			btn.Font = Enum.Font.FredokaOne
			-- [恢复] 大字体 25
			btn.TextSize = 25 
			btn.Parent = tabFrame
			Instance.new("UICorner", btn)

			btn.MouseButton1Click:Connect(function()
				currentTab = t.Id
				selectedItemName = nil
				for _, b in pairs(tabFrame:GetChildren()) do
					if b:IsA("TextButton") then
						b.BackgroundColor3 = (b.Name == currentTab) and Color3.fromRGB(70, 70, 80) or Color3.fromRGB(40, 40, 45)
					end
				end
				refreshInventory()
			end)
		end
	end
end

-- ==========================================
-- 2. 刷新库存
-- ==========================================
function refreshInventory()
	if not scrollingFrame then return end

	-- 清理旧图标
	for _, child in pairs(scrollingFrame:GetChildren()) do
		if child:IsA("ImageButton") then child:Destroy() end
	end

	local main = scrollingFrame.Parent
	if main:FindFirstChild("SellArea") then
		main.SellArea.InfoLabel.Text = selectedItemName and ("Selected: "..selectedItemName) or "Select item"
	end

	local invFolder = player:WaitForChild("Inventory", 5)
	if not invFolder then return end

	-- [恢复] 格子大小设置为标准的 100x100
	local gridLayout = scrollingFrame:FindFirstChildOfClass("UIGridLayout") or Instance.new("UIGridLayout", scrollingFrame)
	gridLayout.CellSize = UDim2.new(0, 100, 0, 100) 
	gridLayout.CellPadding = UDim2.new(0, 15, 0, 15)

	-- 确保能滚动 (防止移动端高度不够时被切断)
	scrollingFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)

	for _, itemVal in ipairs(invFolder:GetChildren()) do
		local itemName = itemVal.Name
		local realQty = itemVal.Value 

		local itemConfig = GameConfig.Weapons[itemName] or GameConfig.Items[itemName] or GameConfig.Skin[itemName]

		if itemConfig and realQty > 0 then
			local itemCategory = itemConfig.Category or "Items"
			local isMatch = (itemCategory == currentTab)
			if currentTab == "Items" and (itemCategory == "Medical" or itemCategory == "Consumable" or itemCategory == "Items") then
				isMatch = true
			end

			if isMatch then
				local card = Instance.new("ImageButton")
				card.Name = itemName
				card.BackgroundColor3 = (selectedItemName == itemName) and Color3.fromRGB(60, 60, 80) or Color3.fromRGB(40, 40, 40)
				card.Parent = scrollingFrame
				Instance.new("UICorner", card)

				if selectedItemName == itemName then
					local stroke = Instance.new("UIStroke")
					stroke.Color = Color3.fromRGB(255, 215, 0)
					stroke.Thickness = 3
					stroke.Parent = card
				end

				local icon = Instance.new("ImageLabel")
				icon.Size = UDim2.new(0.7, 0, 0.7, 0)
				icon.Position = UDim2.new(0.15, 0, 0.1, 0)
				icon.BackgroundTransparency = 1
				icon.Image = itemConfig.ImageId or ""
				icon.Parent = card

				local qty = Instance.new("TextLabel")
				qty.Size = UDim2.new(0.4, 0, 0.3, 0)
				qty.Position = UDim2.new(0.55, 0, 0.65, 0)
				qty.BackgroundTransparency = 1
				qty.TextColor3 = Color3.new(1,1,1)
				qty.Text = "x"..realQty
				qty.Font = Enum.Font.FredokaOne
				-- [恢复] 数量字体大小 20
				qty.TextSize = 20 
				qty.Parent = card

				card.MouseButton1Click:Connect(function()
					selectedItemName = itemName
					refreshInventory()
				end)
			end
		end
	end
end

-- ==========================================
-- 3. 监听与启动
-- ==========================================
setupInventoryUI()

player:WaitForChild("Inventory").ChildAdded:Connect(refreshInventory)
player.Inventory.ChildRemoved:Connect(refreshInventory)
for _, item in pairs(player.Inventory:GetChildren()) do
	item.Changed:Connect(refreshInventory)
end

playerGui:WaitForChild("InventoryGui").MainFrame:GetPropertyChangedSignal("Visible"):Connect(function()
	if playerGui.InventoryGui.MainFrame.Visible then
		setupInventoryUI()
		refreshInventory()
	end
end)

refreshInventory()
print("✅ ItemsInventoryHandler 已恢复经典样式 (含移动端全屏适配)")