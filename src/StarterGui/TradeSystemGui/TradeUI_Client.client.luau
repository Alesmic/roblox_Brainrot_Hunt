local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

local player = Players.LocalPlayer
local gui = script.Parent -- TradeSystemGui

-- ==========================================
-- 1. 资源引用
-- ==========================================
local RemoteEventFolder = ReplicatedStorage:WaitForChild("RemoteEvent")

-- 引用交易事件
local tradeEvent = RemoteEventFolder:FindFirstChild("TradeEvent") or RemoteEventFolder:FindFirstChild("TradeAction")
if not tradeEvent then
	-- 临时创建一个空引用防止报错，等待服务器创建
	tradeEvent = Instance.new("RemoteEvent") 
	warn("⚠️ [TradeUI] 尚未找到 TradeEvent (等待服务器创建)")
end

-- 引用 BossBattleEvent
local bossEvent = RemoteEventFolder:FindFirstChild("BossBattleEvent")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

-- 状态
local myOffer = {}
local isLocked = false
local isTradingActive = false 
local activePromptSource = nil -- "Trade" 或 "Wall"

-- UI 变量
local mainFrame
local inventoryScroll
local offerScroll
local confirmBtn
local statusLabel
local waitingOverlay
local promptFrame

-- 预声明函数
local updateUI -- 提前声明，以便在 createResponsiveUI 里调用

-- ==========================================
-- 2. 响应式 UI 生成器
-- ==========================================
local function createResponsiveUI()
	if gui:FindFirstChild("MainFrame") then gui.MainFrame:Destroy() end
	if gui:FindFirstChild("PromptFrame") then gui.PromptFrame:Destroy() end

	-- A. 主交易窗口
	mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
	mainFrame.BorderSizePixel = 0
	mainFrame.Visible = false
	mainFrame.Parent = gui

	Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 10)
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(60, 60, 60)
	stroke.Thickness = 2
	stroke.Parent = mainFrame

	if UserInputService.TouchEnabled and not UserInputService.MouseEnabled then
		mainFrame.Size = UDim2.new(0.95, 0, 0.8, 0) -- 移动端
	else
		mainFrame.Size = UDim2.new(0.6, 0, 0.6, 0) -- PC端
	end

	-- 标题栏
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0.1, 0)
	title.BackgroundTransparency = 1
	title.Text = "TRADE SYSTEM"
	title.Font = Enum.Font.FredokaOne
	title.TextColor3 = Color3.fromRGB(255, 215, 0)
	title.TextScaled = true
	title.Parent = mainFrame

	-- 左侧：背包
	local invFrame = Instance.new("Frame")
	invFrame.Name = "InventoryFrame"
	invFrame.Size = UDim2.new(0.46, 0, 0.75, 0)
	invFrame.Position = UDim2.new(0.02, 0, 0.12, 0)
	invFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
	invFrame.Parent = mainFrame
	Instance.new("UICorner", invFrame).CornerRadius = UDim.new(0, 6)

	local invTitle = Instance.new("TextLabel")
	invTitle.Size = UDim2.new(1, 0, 0.1, 0)
	invTitle.BackgroundTransparency = 1
	invTitle.Text = "My Inventory"
	invTitle.TextColor3 = Color3.fromRGB(150, 150, 150)
	invTitle.Font = Enum.Font.SourceSansBold
	invTitle.TextSize = 18
	invTitle.Parent = invFrame

	inventoryScroll = Instance.new("ScrollingFrame")
	inventoryScroll.Size = UDim2.new(1, -10, 0.88, 0)
	inventoryScroll.Position = UDim2.new(0, 5, 0.12, 0)
	inventoryScroll.BackgroundTransparency = 1
	inventoryScroll.ScrollBarThickness = 4
	inventoryScroll.Parent = invFrame

	local gridInv = Instance.new("UIGridLayout")
	gridInv.CellSize = UDim2.new(0.3, 0, 0.3, 0)
	gridInv.CellPadding = UDim2.new(0.02, 0, 0.02, 0)
	gridInv.Parent = inventoryScroll
	local aspectInv = Instance.new("UIAspectRatioConstraint")
	aspectInv.Parent = gridInv

	-- 右侧：交易栏
	local offerFrame = Instance.new("Frame")
	offerFrame.Name = "MyOfferFrame"
	offerFrame.Size = UDim2.new(0.46, 0, 0.75, 0)
	offerFrame.Position = UDim2.new(0.52, 0, 0.12, 0)
	offerFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
	offerFrame.Parent = mainFrame
	Instance.new("UICorner", offerFrame).CornerRadius = UDim.new(0, 6)

	local offerStroke = Instance.new("UIStroke")
	offerStroke.Color = Color3.fromRGB(255, 215, 0)
	offerStroke.Transparency = 0.8
	offerStroke.Parent = offerFrame

	local offerTitle = Instance.new("TextLabel")
	offerTitle.Size = UDim2.new(1, 0, 0.1, 0)
	offerTitle.BackgroundTransparency = 1
	offerTitle.Text = "My Offer"
	offerTitle.TextColor3 = Color3.fromRGB(255, 215, 0)
	offerTitle.Font = Enum.Font.SourceSansBold
	offerTitle.TextSize = 18
	offerTitle.Parent = offerFrame

	offerScroll = Instance.new("ScrollingFrame")
	offerScroll.Size = UDim2.new(1, -10, 0.88, 0)
	offerScroll.Position = UDim2.new(0, 5, 0.12, 0)
	offerScroll.BackgroundTransparency = 1
	offerScroll.ScrollBarThickness = 4
	offerScroll.Parent = offerFrame

	local gridOffer = Instance.new("UIGridLayout")
	gridOffer.CellSize = UDim2.new(0.3, 0, 0.3, 0)
	gridOffer.CellPadding = UDim2.new(0.02, 0, 0.02, 0)
	gridOffer.Parent = offerScroll
	local aspectOffer = Instance.new("UIAspectRatioConstraint")
	aspectOffer.Parent = gridOffer

	-- 底部：确认按钮
	confirmBtn = Instance.new("TextButton")
	confirmBtn.Name = "ConfirmButton"
	confirmBtn.Size = UDim2.new(0.4, 0, 0.1, 0)
	confirmBtn.Position = UDim2.new(0.3, 0, 0.88, 0)
	confirmBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
	confirmBtn.Text = "CONFIRM TRADE"
	confirmBtn.Font = Enum.Font.FredokaOne
	confirmBtn.TextColor3 = Color3.new(1,1,1)
	confirmBtn.TextScaled = true
	confirmBtn.Parent = mainFrame
	Instance.new("UICorner", confirmBtn).CornerRadius = UDim.new(0, 8)

	-- [核心修复] 将监听移到这里，确保按钮已创建
	confirmBtn.MouseButton1Click:Connect(function()
		if isLocked then return end
		isLocked = true
		confirmBtn.Text = "WAITING..."
		confirmBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
		tradeEvent:FireServer("ConfirmTrade", myOffer)
	end)

	statusLabel = Instance.new("TextLabel")
	statusLabel.Size = UDim2.new(1, 0, 0.05, 0)
	statusLabel.Position = UDim2.new(0, 0, 1.02, 0)
	statusLabel.BackgroundTransparency = 1
	statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	statusLabel.Text = "Ready to trade"
	statusLabel.TextScaled = true
	statusLabel.Parent = mainFrame

	-- 等待遮罩
	waitingOverlay = Instance.new("Frame")
	waitingOverlay.Name = "WaitingOverlay"
	waitingOverlay.Size = UDim2.new(1, 0, 1, 0)
	waitingOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	waitingOverlay.BackgroundTransparency = 0.3
	waitingOverlay.ZIndex = 10
	waitingOverlay.Visible = false
	waitingOverlay.Parent = mainFrame

	local waitText = Instance.new("TextLabel")
	waitText.Text = "Waiting for Player..."
	waitText.Size = UDim2.new(1, 0, 0.2, 0)
	waitText.Position = UDim2.new(0, 0, 0.4, 0)
	waitText.BackgroundTransparency = 1
	waitText.TextColor3 = Color3.fromRGB(255, 255, 255)
	waitText.Font = Enum.Font.FredokaOne
	waitText.TextScaled = true
	waitText.ZIndex = 11
	waitText.Parent = waitingOverlay


	-- F. 识别墙确认弹窗 (PromptFrame)
	promptFrame = Instance.new("Frame")
	promptFrame.Name = "PromptFrame"
	promptFrame.Size = UDim2.new(0.4, 0, 0.3, 0)
	if UserInputService.TouchEnabled and not UserInputService.MouseEnabled then
		promptFrame.Size = UDim2.new(0.7, 0, 0.35, 0)
	end
	promptFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	promptFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	promptFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
	promptFrame.Visible = false
	promptFrame.Parent = gui

	Instance.new("UICorner", promptFrame).CornerRadius = UDim.new(0, 12)
	local pStroke = Instance.new("UIStroke")
	pStroke.Color = Color3.fromRGB(255, 215, 0)
	pStroke.Thickness = 2
	pStroke.Parent = promptFrame

	local pTitle = Instance.new("TextLabel")
	pTitle.Name = "Title"
	pTitle.Size = UDim2.new(1, 0, 0.3, 0)
	pTitle.BackgroundTransparency = 1
	pTitle.Text = "NOTIFICATION"
	pTitle.Font = Enum.Font.FredokaOne
	pTitle.TextColor3 = Color3.fromRGB(255, 215, 0)
	pTitle.TextScaled = true
	pTitle.Parent = promptFrame

	local pDesc = Instance.new("TextLabel")
	pDesc.Name = "Description"
	pDesc.Size = UDim2.new(0.9, 0, 0.3, 0)
	pDesc.Position = UDim2.new(0.05, 0, 0.3, 0)
	pDesc.BackgroundTransparency = 1
	pDesc.Text = "Do you want to enter?"
	pDesc.Font = Enum.Font.SourceSans
	pDesc.TextColor3 = Color3.fromRGB(200, 200, 200)
	pDesc.TextScaled = true
	pDesc.Parent = promptFrame

	local yesBtn = Instance.new("TextButton")
	yesBtn.Name = "YesButton"
	yesBtn.Size = UDim2.new(0.4, 0, 0.25, 0)
	yesBtn.Position = UDim2.new(0.05, 0, 0.65, 0)
	yesBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
	yesBtn.Text = "YES"
	yesBtn.Font = Enum.Font.FredokaOne
	yesBtn.TextColor3 = Color3.new(1,1,1)
	yesBtn.TextScaled = true
	yesBtn.Parent = promptFrame
	Instance.new("UICorner", yesBtn).CornerRadius = UDim.new(0, 6)

	local noBtn = Instance.new("TextButton")
	noBtn.Name = "NoButton"
	noBtn.Size = UDim2.new(0.4, 0, 0.25, 0)
	noBtn.Position = UDim2.new(0.55, 0, 0.65, 0)
	noBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
	noBtn.Text = "NO"
	noBtn.Font = Enum.Font.FredokaOne
	noBtn.TextColor3 = Color3.new(1,1,1)
	noBtn.TextScaled = true
	noBtn.Parent = promptFrame
	Instance.new("UICorner", noBtn).CornerRadius = UDim.new(0, 6)

	yesBtn.MouseButton1Click:Connect(function()
		promptFrame.Visible = false
		if activePromptSource == "Wall" and bossEvent then
			bossEvent:FireServer("YES")
		else
			tradeEvent:FireServer("ConfirmEnter")
		end
	end)

	noBtn.MouseButton1Click:Connect(function()
		promptFrame.Visible = false
		if activePromptSource == "Wall" and bossEvent then
			bossEvent:FireServer("NO")
		else
			tradeEvent:FireServer("CancelEnter")
		end
	end)
end

-- ==========================================
-- 3. 卡片渲染
-- ==========================================
local function createCard(itemName, parentContainer, isOfferSide)
	local itemInfo = GameConfig.Weapons[itemName] or GameConfig.Items[itemName]
	if not itemInfo then return end

	local btn = Instance.new("ImageButton")
	btn.Name = itemName
	btn.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
	btn.Parent = parentContainer
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0.1, 0)

	local icon = Instance.new("ImageLabel")
	icon.Size = UDim2.new(0.8, 0, 0.8, 0)
	icon.Position = UDim2.new(0.1, 0, 0.1, 0)
	icon.BackgroundTransparency = 1
	icon.Image = "rbxassetid://80988936453816"
	icon.Parent = btn

	btn.MouseButton1Click:Connect(function()
		if isLocked or not isTradingActive then return end 

		if isOfferSide then
			for i, name in ipairs(myOffer) do
				if name == itemName then
					table.remove(myOffer, i)
					break
				end
			end
		else
			if #myOffer < 9 then
				table.insert(myOffer, itemName)
			end
		end
		updateUI()
	end)
end

function updateUI()
	if not mainFrame then return end

	for _, c in pairs(inventoryScroll:GetChildren()) do if c:IsA("GuiObject") then c:Destroy() end end
	for _, c in pairs(offerScroll:GetChildren()) do if c:IsA("GuiObject") then c:Destroy() end end

	local myInventory = {}
	local invFolder = player:FindFirstChild("Inventory")
	if invFolder then
		for _, itemVal in pairs(invFolder:GetChildren()) do
			local countInTrade = 0
			for _, offerName in ipairs(myOffer) do
				if offerName == itemVal.Name then countInTrade = countInTrade + 1 end
			end
			if itemVal.Value > countInTrade then
				table.insert(myInventory, itemVal.Name)
			end
		end
	end

	for _, name in ipairs(myInventory) do createCard(name, inventoryScroll, false) end
	for _, name in ipairs(myOffer) do createCard(name, offerScroll, true) end
end

-- ==========================================
-- 4. 监听与初始化
-- ==========================================
createResponsiveUI()

-- 监听普通交易事件
if tradeEvent then
	tradeEvent.OnClientEvent:Connect(function(action, data)
		if action == "Open" then
			mainFrame.Visible = true
			isTradingActive = false 
			waitingOverlay.Visible = true
		elseif action == "Start" then
			waitingOverlay.Visible = false
			isTradingActive = true
			statusLabel.Text = "Trading with: " .. tostring(data or "Player")
		elseif action == "Close" then
			mainFrame.Visible = false
			promptFrame.Visible = false 
		elseif action == "Prompt" or action == "ShowPrompt" then
			activePromptSource = "Trade" 
			promptFrame.Visible = true
			if data and type(data) == "string" then
				promptFrame.Description.Text = data
			end
		end
	end)
end

-- 监听 BossBattleEvent (交易所墙壁)
if bossEvent then
	bossEvent.OnClientEvent:Connect(function(action, data)
		if action == "ASK_FIGHT" then
			activePromptSource = "Wall" 
			promptFrame.Visible = true
			promptFrame.Title.Text = "EXCHANGE AREA"
			promptFrame.Description.Text = data or "Enter Exchange?"
		end
	end)
else
	-- 如果 bossEvent 为空，尝试重新获取一次 (延迟绑定)
	task.spawn(function()
		bossEvent = RemoteEventFolder:WaitForChild("BossBattleEvent", 10)
		if bossEvent then
			bossEvent.OnClientEvent:Connect(function(action, data)
				if action == "ASK_FIGHT" then
					activePromptSource = "Wall" 
					promptFrame.Visible = true
					promptFrame.Title.Text = "EXCHANGE AREA"
					promptFrame.Description.Text = data or "Enter Exchange?"
				end
			end)
		end
	end)
end

-- 监听背包变化
if player:FindFirstChild("Inventory") then
	player.Inventory.ChildAdded:Connect(updateUI)
	player.Inventory.ChildRemoved:Connect(updateUI)
end