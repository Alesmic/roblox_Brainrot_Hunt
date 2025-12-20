local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local MarketplaceService = game:GetService("MarketplaceService")

local player = Players.LocalPlayer
local gui = script.Parent

-- 资源引用
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local RemoteEventFolder = ReplicatedStorage:WaitForChild("RemoteEvent")
local RemoteFunctionFolder = ReplicatedStorage:WaitForChild("RemoteFunction") -- [新增] 获取函数文件夹

local toggleEvent = RemoteEventFolder:WaitForChild("ToggleWindow")
local sellEvent = RemoteEventFolder:WaitForChild("SellItem")

-- [修复 1] 购买现在是 RemoteFunction，不是 RemoteEvent
local buyFunc = RemoteFunctionFolder:WaitForChild("BuyItem") 
local getInvFunc = RemoteFunctionFolder:WaitForChild("GetInventoryData")

-- 状态变量
local isOpen = false
local currentVendorName = "Merchant"
local currentNPC_Type = ""
local ROBUX_ICON = "rbxasset://textures/ui/common/robux_small.png"

-- ==========================================
-- 1. UI 变量定义
-- ==========================================
local mainFrame
local leftScroll
local rightScroll
local playerMoneyText

-- ==========================================
-- 2. UI 生成器 (赛博朋克配色)
-- ==========================================
local function createUI()
	-- 1. 主背景 (深红黑色)
	mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.Size = UDim2.new(1, 0, 1, 0)
	mainFrame.BackgroundColor3 = Color3.fromRGB(20, 5, 5) -- [配色] 深红底
	mainFrame.BorderSizePixel = 0
	mainFrame.Parent = gui

	-- 2. 渐变效果 (暗红 -> 纯黑)
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(60, 0, 10)), -- [配色] 顶部稍亮
		ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 0, 0))  -- [配色] 底部深黑
	})
	gradient.Rotation = 45
	gradient.Parent = mainFrame

	-- 3. 顶部导航栏
	local header = Instance.new("Frame")
	header.Size = UDim2.new(1, 0, 0.1, 0)
	header.BackgroundTransparency = 1
	header.Parent = mainFrame

	-- 左标题 (霓虹红)
	local playerInfo = Instance.new("TextLabel")
	playerInfo.Size = UDim2.new(0.45, 0, 1, 0)
	playerInfo.Position = UDim2.new(0.05, 0, 0, 0)
	playerInfo.BackgroundTransparency = 1
	playerInfo.Text = player.Name .. "'s INVENTORY"
	playerInfo.Font = Enum.Font.SciFi -- 科幻字体
	playerInfo.TextSize = 28
	playerInfo.TextColor3 = Color3.fromRGB(255, 50, 50) -- [配色] 霓虹红
	playerInfo.TextXAlignment = Enum.TextXAlignment.Left
	playerInfo.Parent = header

	-- 金币显示 (金色)
	playerMoneyText = Instance.new("TextLabel")
	playerMoneyText.Size = UDim2.new(0.45, 0, 0.5, 0)
	playerMoneyText.Position = UDim2.new(0.05, 0, 0.6, 0)
	playerMoneyText.BackgroundTransparency = 1
	playerMoneyText.Font = Enum.Font.SourceSansBold
	playerMoneyText.TextSize = 24
	playerMoneyText.TextColor3 = Color3.fromRGB(255, 215, 0) -- [配色] 金色
	playerMoneyText.TextXAlignment = Enum.TextXAlignment.Left
	playerMoneyText.Text = "Loading..."
	playerMoneyText.Parent = header

	-- 右标题 (霓虹红)
	local vendorInfo = Instance.new("TextLabel")
	vendorInfo.Size = UDim2.new(0.45, 0, 1, 0)
	vendorInfo.Position = UDim2.new(0.5, 0, 0, 0)
	vendorInfo.BackgroundTransparency = 1
	vendorInfo.Text = "VENDOR STOCK"
	vendorInfo.Font = Enum.Font.SciFi
	vendorInfo.TextSize = 28
	vendorInfo.TextColor3 = Color3.fromRGB(255, 50, 50) -- [配色] 霓虹红
	vendorInfo.TextXAlignment = Enum.TextXAlignment.Left
	vendorInfo.Parent = header

	-- 关闭按钮 (鲜红)
	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.new(0, 50, 0, 50)
	closeBtn.Position = UDim2.new(1, -60, 0, 10)
	closeBtn.Text = "X"
	closeBtn.BackgroundColor3 = Color3.fromRGB(200, 0, 0) -- [配色] 鲜红按钮
	closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeBtn.Font = Enum.Font.FredokaOne
	closeBtn.TextSize = 24
	closeBtn.Parent = mainFrame

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = closeBtn

	closeBtn.MouseButton1Click:Connect(function()
		toggleUI(false)
	end)

	-- 4. 左右面板 (半透明黑)
	local leftPanel = Instance.new("Frame")
	leftPanel.Size = UDim2.new(0.48, 0, 0.85, 0)
	leftPanel.Position = UDim2.new(0.01, 0, 0.12, 0)
	leftPanel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	leftPanel.BackgroundTransparency = 0.5 -- [配色] 半透明黑底
	leftPanel.Parent = mainFrame

	leftScroll = Instance.new("ScrollingFrame")
	leftScroll.Size = UDim2.new(1, -10, 1, -10)
	leftScroll.Position = UDim2.new(0, 5, 0, 5)
	leftScroll.BackgroundTransparency = 1
	leftScroll.Parent = leftPanel

	local leftLayout = Instance.new("UIGridLayout")
	leftLayout.CellSize = UDim2.new(0.95, 0, 0, 80)
	leftLayout.CellPadding = UDim2.new(0, 0, 0, 5)
	leftLayout.Parent = leftScroll

	local rightPanel = Instance.new("Frame")
	rightPanel.Size = UDim2.new(0.48, 0, 0.85, 0)
	rightPanel.Position = UDim2.new(0.51, 0, 0.12, 0)
	rightPanel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	rightPanel.BackgroundTransparency = 0.5
	rightPanel.Parent = mainFrame

	rightScroll = Instance.new("ScrollingFrame")
	rightScroll.Size = UDim2.new(1, -10, 1, -10)
	rightScroll.Position = UDim2.new(0, 5, 0, 5)
	rightScroll.BackgroundTransparency = 1
	rightScroll.Parent = rightPanel

	local rightLayout = Instance.new("UIGridLayout")
	rightLayout.CellSize = UDim2.new(0.95, 0, 0, 80)
	rightLayout.CellPadding = UDim2.new(0, 0, 0, 5)
	rightLayout.Parent = rightScroll
end

-- ==========================================
-- 3. 卡片生成 (修复版 + 赛博朋克配色)
-- ==========================================
local function createItemCard(parent, itemData, isSelling)
	if not parent or not itemData then return end

	local btn = Instance.new("TextButton")
	btn.Text = ""
	btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30) -- [配色] 深灰卡片底色
	btn.Parent = parent

	-- 安全颜色定义
	local Text_White = Color3.fromRGB(240, 240, 240)
	local Price_Gold = Color3.fromRGB(255, 215, 0)
	local Price_Green = Color3.fromRGB(0, 255, 100) -- Robux 专属绿

	-- 稀有度
	local rarityColor = Color3.fromRGB(100, 100, 100)
	if itemData.Rarity and GameConfig.RarityColors and GameConfig.RarityColors[itemData.Rarity] then
		rarityColor = GameConfig.RarityColors[itemData.Rarity]
	end

	local rarityBar = Instance.new("Frame")
	rarityBar.Size = UDim2.new(0.03, 0, 1, 0)
	rarityBar.BackgroundColor3 = rarityColor
	rarityBar.BorderSizePixel = 0
	rarityBar.Parent = btn

	-- 图标
	local icon = Instance.new("ImageLabel")
	icon.Size = UDim2.new(0, 70, 0, 70)
	icon.Position = UDim2.new(0.05, 0, 0.5, 0)
	icon.AnchorPoint = Vector2.new(0, 0.5)
	icon.BackgroundTransparency = 1
	icon.Image = itemData.ImageId or ""
	icon.Parent = btn

	-- 名字
	local nameLbl = Instance.new("TextLabel")
	local dName = itemData.DisplayName or itemData.RealName or "Unknown"
	local qty = isSelling and (" x" .. (itemData.Qty or 1)) or ""
	nameLbl.Text = dName .. qty
	nameLbl.Size = UDim2.new(0.6, 0, 0.4, 0)
	nameLbl.Position = UDim2.new(0.25, 0, 0.1, 0)
	nameLbl.BackgroundTransparency = 1
	nameLbl.TextColor3 = Text_White
	nameLbl.TextXAlignment = Enum.TextXAlignment.Left
	nameLbl.Font = Enum.Font.SciFi
	nameLbl.TextSize = 22
	nameLbl.Parent = btn

	-- 价格容器
	local priceContainer = Instance.new("Frame")
	priceContainer.Size = UDim2.new(0.6, 0, 0.4, 0)
	priceContainer.Position = UDim2.new(0.25, 0, 0.5, 0)
	priceContainer.BackgroundTransparency = 1
	priceContainer.Parent = btn

	local priceIcon = Instance.new("ImageLabel")
	priceIcon.Size = UDim2.new(0, 20, 0, 20)
	priceIcon.BackgroundTransparency = 1
	priceIcon.Parent = priceContainer

	local priceLbl = Instance.new("TextLabel")
	priceLbl.Size = UDim2.new(1, -25, 1, 0)
	priceLbl.Position = UDim2.new(0, 25, 0, 0)
	priceLbl.BackgroundTransparency = 1
	priceLbl.TextXAlignment = Enum.TextXAlignment.Left
	priceLbl.Font = Enum.Font.SourceSansBold
	priceLbl.TextSize = 20
	priceLbl.Parent = priceContainer

	-- 价格显示逻辑 (绿色Robux，金色金币)
	if not isSelling and itemData.ProductId then
		priceIcon.Image = ROBUX_ICON
		priceLbl.Text = tostring(itemData.RobuxPrice or "??")
		priceLbl.TextColor3 = Price_Green
	else
		priceIcon.Image = "" 
		local val = itemData.Price or 0
		if isSelling then val = math.floor(val * 0.5) end
		priceLbl.Text = "€$ " .. val
		priceLbl.TextColor3 = Price_Gold
	end

	-- 点击逻辑
	local lastClick = 0 
	btn.MouseButton1Click:Connect(function()
		local now = tick()
		if now - lastClick < 0.5 then
			if isSelling then
				if itemData.RealName then
					sellEvent:FireServer(itemData.RealName, math.floor((itemData.Price or 0) * 0.5), 1)
					-- 卖出后延迟刷新
					task.wait(0.2)
					if _G.RefreshShopUI then _G.RefreshShopUI() end
				end
			else
				if itemData.ProductId then
					MarketplaceService:PromptProductPurchase(player, itemData.ProductId)
				elseif itemData.RealName then
					-- [修复 2] 使用 InvokeServer 调用购买函数
					local success = buyFunc:InvokeServer(itemData.RealName)

					if success then
						print("✅ 购买成功: " .. itemData.RealName)
						-- 购买成功后立即刷新，显示已购买状态/更新金币
						if _G.RefreshShopUI then _G.RefreshShopUI() end
					else
						warn("❌ 购买失败: 金币不足或已拥有该物品")
						-- 这里可以添加一个红色的报错提示动画
						btn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
						task.wait(0.2)
						btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
						return -- 失败不播放点击成功动画
					end
				end
			end

			-- 点击反馈动画 (只有成功才播放深灰闪烁)
			btn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
			task.wait(0.1)
			btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)

		else
			lastClick = now
		end
	end)
end

-- ==========================================
-- 4. 刷新逻辑
-- ==========================================
local function refreshContent()
	if not mainFrame then 
		createUI() 
		task.wait()
	end

	if not leftScroll or not rightScroll then return end

	-- 更新玩家金币
	local leaderstats = player:FindFirstChild("leaderstats")
	local goldVal = 0
	if leaderstats then
		local g = leaderstats:FindFirstChild("Gold")
		if g then goldVal = g.Value end
	end
	if playerMoneyText then
		playerMoneyText.Text = "€$ " .. goldVal
	end

	-- 清理旧按钮
	for _, c in pairs(leftScroll:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
	for _, c in pairs(rightScroll:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end

	task.spawn(function()
		-- 加载商店物品
		local allShopItems = {}
		local loadTarget = {}

		if currentNPC_Type == "SkinSeller" then
			loadTarget = GameConfig.Skin or {}
			for k,v in pairs(loadTarget) do 
				local item = v
				item.RealName = k
				table.insert(allShopItems, item)
			end
		else
			if GameConfig.Weapons then
				for k,v in pairs(GameConfig.Weapons) do 
					local item = v
					item.RealName = k
					table.insert(allShopItems, item)
				end
			end
			if GameConfig.Items then
				for k,v in pairs(GameConfig.Items) do 
					if not v.HideInShop then 
						local item = v
						item.RealName = k
						table.insert(allShopItems, item)
					end
				end
			end
		end

		for _, item in pairs(allShopItems) do
			createItemCard(rightScroll, item, false)
		end

		-- 加载背包
		local success, inventory = pcall(function() return getInvFunc:InvokeServer() end)
		if success and inventory then
			if leftScroll and leftScroll.Parent then
				for _, item in pairs(inventory) do
					if item.CanSell then
						createItemCard(leftScroll, item, true)
					end
				end
			end
		end
	end)
end

_G.RefreshShopUI = refreshContent

-- ==========================================
-- 5. 开关控制
-- ==========================================
function toggleUI(show, vendorName, npcType)
	if not mainFrame then createUI() end
	isOpen = show
	gui.Enabled = show

	if show then
		currentVendorName = vendorName or "Merchant"
		currentNPC_Type = npcType or ""
		pcall(function() game.StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false) end)
		refreshContent()
	else
		pcall(function() game.StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, true) end)
	end
end

toggleEvent.OnClientEvent:Connect(function(vendorType, npcName)
	toggleUI(true, npcName, vendorType)
end)