-- TradeUI_Client - Placed in StarterGui.TradeSystemGui (Local Script)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService") 
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-- Require config to get rarity colors (Assuming GameConfig is in ReplicatedStorage)
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

local player = Players.LocalPlayer
local gui = script.Parent -- gui should be StarterGui.TradeSystemGui (ScreenGui)

-- Resource References
local RemoteEventFolder = ReplicatedStorage:WaitForChild("RemoteEvent")
local StartTradeEvent = RemoteEventFolder:WaitForChild("StartTradeUI")
local HandleTradeActionEvent = RemoteEventFolder:WaitForChild("HandleTradeAction")
local UpdateTradeUIEvent = RemoteEventFolder:WaitForChild("UpdateTradeUI")

local RemoteFunctionFolder = ReplicatedStorage:WaitForChild("RemoteFunction")
local getInvFunc = RemoteFunctionFolder:WaitForChild("GetInventoryData") 

-- State Variables
local isOpen = false
local CurrentTradePartnerName = nil 

local MyAccepted = false
local PartnerAccepted = false
local MyConfirmed = false
local PartnerConfirmed = false

local ItemsToOffer = {} -- { [RealName] = Qty }
local MockPlayerInventory = {} -- Dictionary format: { [RealName] = ItemData } (from server, contains all config info)

-- Trade UI Element References
local mainFrame
local MyItemsGrid, PartnerItemsGrid
local AcceptButton, CancelButton
local PartnerNameLabel, MyStatusLabel, PartnerStatusLabel
local leftPanel, rightPanel 
local isDragging = false 

-- Countdown/Confirmation UI Elements
local CountdownFrame
local CountdownLabel
local CountdownCancelButton

-- Countdown Control
local CountdownConnection = nil -- Used to store the RunService connection
local countdownRunning = false -- Flag if the countdown is currently running


-- ==========================================
-- 1. Trade Core State Management Functions
-- ==========================================

local function isItemInTrade(itemName)
	return ItemsToOffer[itemName] and ItemsToOffer[itemName] > 0
end

local function addItemToTrade(itemData)
	local itemName = itemData.RealName
	if MyAccepted or MyConfirmed or countdownRunning then return end

	local playerItem = MockPlayerInventory[itemName]
	local playerQty = playerItem and playerItem.Qty or 0
	local offeredQty = ItemsToOffer[itemName] or 0

	if playerQty > offeredQty then
		ItemsToOffer[itemName] = offeredQty + 1

		MyAccepted = false
		MyConfirmed = false
		refreshContent() 

		HandleTradeActionEvent:FireServer("UpdateItems", ItemsToOffer)
	end
end

local function removeItemFromTrade(itemData)
	local itemName = itemData.RealName
	if MyAccepted or MyConfirmed or countdownRunning then return end

	if isItemInTrade(itemName) then
		ItemsToOffer[itemName] = ItemsToOffer[itemName] - 1
		if ItemsToOffer[itemName] <= 0 then
			ItemsToOffer[itemName] = nil
		end

		MyAccepted = false
		MyConfirmed = false
		refreshContent() 

		HandleTradeActionEvent:FireServer("UpdateItems", ItemsToOffer)
	end
end

-- ==========================================
-- 2. UI Generator
-- ==========================================

local function createUI()
	if mainFrame then mainFrame:Destroy() end

	mainFrame = Instance.new("Frame")
	mainFrame.Name = "TradeMainFrame"
	mainFrame.Size = UDim2.new(0.8, 0, 0.9, 0)
	mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	mainFrame.BorderSizePixel = 3
	mainFrame.BorderColor3 = Color3.fromRGB(255, 200, 0)
	mainFrame.Parent = gui

	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(10, 10, 60)), 
		ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0))
	})
	gradient.Rotation = 45
	gradient.Parent = mainFrame

	-- Title
	PartnerNameLabel = Instance.new("TextLabel")
	PartnerNameLabel.Size = UDim2.new(0.9, 0, 0.1, 0)
	PartnerNameLabel.Position = UDim2.new(0.05, 0, 0, 0)
	PartnerNameLabel.BackgroundTransparency = 1
	PartnerNameLabel.Text = "Trading with [Partner]"
	PartnerNameLabel.Font = Enum.Font.Michroma
	PartnerNameLabel.TextSize = 28
	PartnerNameLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
	PartnerNameLabel.TextXAlignment = Enum.TextXAlignment.Left
	PartnerNameLabel.Parent = mainFrame

	-- Left Panel: My Offered Items
	leftPanel = Instance.new("Frame")
	leftPanel.Name = "MyTradePanel"
	leftPanel.Size = UDim2.new(0.48, 0, 0.7, 0)
	leftPanel.Position = UDim2.new(0.01, 0, 0.1, 0)
	leftPanel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	leftPanel.BackgroundTransparency = 0.6
	leftPanel.Parent = mainFrame

	MyItemsGrid = Instance.new("ScrollingFrame")
	MyItemsGrid.Name = "MyItemsGrid"
	MyItemsGrid.Size = UDim2.new(1, -10, 1, -10)
	MyItemsGrid.Position = UDim2.new(0, 5, 0, 5)
	MyItemsGrid.BackgroundTransparency = 1
	MyItemsGrid.Parent = leftPanel
	local myLayout = Instance.new("UIGridLayout", MyItemsGrid)
	myLayout.CellSize = UDim2.new(0.95, 0, 0, 80)
	myLayout.CellPadding = UDim2.new(0, 0, 0, 5)

	-- 关键修复 2: 状态文本大小优化，并精简文本区域
	MyStatusLabel = Instance.new("TextLabel")
	MyStatusLabel.Size = UDim2.new(0.48, 0, 0.05, 0)
	MyStatusLabel.Position = UDim2.new(0.01, 0, 0.82, 0)
	MyStatusLabel.BackgroundTransparency = 1
	MyStatusLabel.Text = "Status: Unaccepted" -- 简化文本
	MyStatusLabel.TextSize = 16 -- 缩小字体防止重叠
	MyStatusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	MyStatusLabel.Parent = mainFrame

	-- Right Panel: Partner's Offered Items
	rightPanel = leftPanel:Clone() 
	rightPanel.Name = "PartnerTradePanel"
	rightPanel.Position = UDim2.new(0.51, 0, 0.1, 0)
	rightPanel.Parent = mainFrame

	PartnerItemsGrid = rightPanel:WaitForChild("MyItemsGrid") 
	PartnerItemsGrid.Name = "PartnerItemsGrid"

	PartnerStatusLabel = MyStatusLabel:Clone()
	PartnerStatusLabel.Position = UDim2.new(0.51, 0, 0.82, 0)
	PartnerStatusLabel.Text = "Partner Status: Unaccepted" -- 简化文本
	PartnerStatusLabel.TextSize = 16 -- 缩小字体防止重叠
	PartnerStatusLabel.Parent = mainFrame

	-- Button Area
	AcceptButton = Instance.new("TextButton")
	AcceptButton.Name = "AcceptButton"
	AcceptButton.Size = UDim2.new(0.4, 0, 0.1, 0)
	AcceptButton.Position = UDim2.new(0.05, 0, 0.9, 0)
	AcceptButton.Text = "ACCEPT"
	AcceptButton.Font = Enum.Font.FredokaOne
	AcceptButton.TextSize = 22 -- ⬇️ 缩小字体
	AcceptButton.TextColor3 = Color3.new(0, 0, 0)
	AcceptButton.BackgroundColor3 = Color3.fromRGB(255, 255, 0)
	AcceptButton.Parent = mainFrame
	Instance.new("UICorner", AcceptButton)

	CancelButton = Instance.new("TextButton")
	CancelButton.Name = "CancelButton"
	CancelButton.Size = UDim2.new(0.4, 0, 0.1, 0)
	CancelButton.Position = UDim2.new(0.55, 0, 0.9, 0)
	CancelButton.Text = "CANCEL"
	CancelButton.Font = Enum.Font.FredokaOne
	CancelButton.TextSize = 22 -- ⬇️ 缩小字体
	CancelButton.TextColor3 = Color3.new(1, 1, 1)
	CancelButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
	CancelButton.Parent = mainFrame
	Instance.new("UICorner", CancelButton)

	-- Countdown Overlay UI Element
	CountdownFrame = Instance.new("Frame")
	CountdownFrame.Name = "CountdownOverlay"
	CountdownFrame.Size = UDim2.new(1, 0, 1, 0)
	CountdownFrame.BackgroundTransparency = 0.5
	CountdownFrame.BackgroundColor3 = Color3.new(0, 0, 0)
	CountdownFrame.ZIndex = 3
	CountdownFrame.Visible = false
	CountdownFrame.Parent = mainFrame

	CountdownLabel = Instance.new("TextLabel")
	CountdownLabel.Size = UDim2.new(0.6, 0, 0.2, 0)
	CountdownLabel.Position = UDim2.new(0.5, 0, 0.3, 0)
	CountdownLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	CountdownLabel.BackgroundTransparency = 1
	CountdownLabel.Text = "Trade Locking... 5"
	CountdownLabel.Font = Enum.Font.Michroma
	CountdownLabel.TextSize = 40
	CountdownLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
	CountdownLabel.Parent = CountdownFrame

	CountdownCancelButton = Instance.new("TextButton")
	CountdownCancelButton.Name = "CountdownCancel"
	CountdownCancelButton.Size = UDim2.new(0.4, 0, 0.15, 0)
	CountdownCancelButton.Position = UDim2.new(0.5, 0, 0.7, 0)
	CountdownCancelButton.AnchorPoint = Vector2.new(0.5, 0.5)
	CountdownCancelButton.Text = "Cancel Trade"
	CountdownCancelButton.Font = Enum.Font.FredokaOne
	CountdownCancelButton.TextSize = 28
	CountdownCancelButton.TextColor3 = Color3.new(1, 1, 1)
	CountdownCancelButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
	CountdownCancelButton.Parent = CountdownFrame
	Instance.new("UICorner", CountdownCancelButton)


	-- Bind Events
	AcceptButton.MouseButton1Click:Connect(function()
		if not isDragging and not countdownRunning then 
			if MyConfirmed then return end 

			if not MyAccepted then
				-- 1. Client accepts and notifies server.
				MyAccepted = true 
				HandleTradeActionEvent:FireServer("Accept") 
				refreshContent() -- Refresh status.

				-- ⚠️ CRITICAL CHANGE: Client no longer starts countdown here. 
				-- The countdown will ONLY be started when the server confirms PartnerAccepted=true 
				-- via the UpdateTradeUIEvent listener below (Section 5).
			end
		end
	end)

	-- Countdown Cancel Button Logic 
	CountdownCancelButton.MouseButton1Click:Connect(function()
		if CountdownConnection then
			CountdownConnection:Disconnect()
			CountdownConnection = nil
		end
		countdownRunning = false
		CountdownFrame.Visible = false

		-- Cancel lock state
		MyAccepted = false 
		HandleTradeActionEvent:FireServer("Cancel") -- Notify server to cancel and reset
		refreshContent() 
	end)

	CancelButton.MouseButton1Click:Connect(function()
		if not isDragging then
			-- If currently counting down, cancel the countdown first
			if CountdownConnection then
				CountdownConnection:Disconnect()
				CountdownConnection = nil
				countdownRunning = false
			end

			toggleUI(false)
			HandleTradeActionEvent:FireServer("Cancel")
		end
	end)

	-- Default hidden
	mainFrame.Visible = false
end

-- ==========================================
-- 3. Dynamic Card Generation (Adapted for Trade Mode)
-- ==========================================

local function createTradeCard(parent, itemData, isOwnInventory)
	local btn = Instance.new("TextButton")
	btn.Text = ""
	btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	btn.Size = UDim2.new(0.95, 0, 0, 80)
	btn.Parent = parent

	local qtyInTrade = ItemsToOffer[itemData.RealName] or 0
	local qtyTotal = itemData.Qty or 1
	local rarity = itemData.Rarity or "Common"

	-- Use rarity color from item configuration
	local rarityColor = itemData.RarityColor or GameConfig.RarityColors[rarity] or Color3.fromRGB(150, 150, 150)

	-- Side Bar
	local rarityBar = Instance.new("Frame")
	rarityBar.Size = UDim2.new(0.03, 0, 1, 0)
	rarityBar.BackgroundColor3 = rarityColor -- Apply rarity color
	rarityBar.BorderSizePixel = 0
	rarityBar.Parent = btn

	-- Icon
	local icon = Instance.new("ImageLabel")
	icon.Size = UDim2.new(0, 70, 0, 70)
	icon.Position = UDim2.new(0.05, 0, 0.5, 0)
	icon.AnchorPoint = Vector2.new(0, 0.5)
	icon.BackgroundTransparency = 1
	icon.Image = itemData.ImageId or ""
	icon.Parent = btn

	-- Item Name
	local nameLbl = Instance.new("TextLabel")
	nameLbl.Text = itemData.DisplayName .. (isOwnInventory and (" x" .. qtyTotal) or "") 
	nameLbl.Size = UDim2.new(0.6, 0, 0.4, 0)
	nameLbl.Position = UDim2.new(0.25, 0, 0.1, 0)
	nameLbl.BackgroundTransparency = 1
	nameLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLbl.TextXAlignment = Enum.TextXAlignment.Left
	nameLbl.Font = Enum.Font.Michroma
	nameLbl.TextSize = 20
	nameLbl.Parent = btn

	-- Trade Quantity or Status
	local tradeStatusLbl = Instance.new("TextLabel")
	tradeStatusLbl.Size = UDim2.new(0.6, 0, 0.4, 0)
	tradeStatusLbl.Position = UDim2.new(0.25, 0, 0.5, 0)
	tradeStatusLbl.BackgroundTransparency = 1
	tradeStatusLbl.TextXAlignment = Enum.TextXAlignment.Left
	tradeStatusLbl.Font = Enum.Font.SourceSansBold
	tradeStatusLbl.TextSize = 20
	tradeStatusLbl.Parent = btn

	if isOwnInventory then
		-- Player's Inventory: Show quantity being offered
		tradeStatusLbl.Text = "Offering: x" .. qtyInTrade
		tradeStatusLbl.TextColor3 = qtyInTrade > 0 and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(150, 150, 150)

		-- Highlight items currently in trade
		if qtyInTrade > 0 then
			btn.BackgroundColor3 = Color3.fromRGB(50, 50, 80)
		end
	else
		-- Partner's Offered Items: Show quantity
		tradeStatusLbl.Text = "Quantity: x" .. qtyTotal
		tradeStatusLbl.TextColor3 = Color3.fromRGB(255, 215, 0)
	end

	-- Double-click/Single-click logic (for adding/removing items)
	btn.MouseButton1Click:Connect(function()
		if not isOwnInventory then return end

		-- Trade lock (MyAccepted), Confirmed (MyConfirmed), or countdown running (countdownRunning) prevents item modification
		if MyAccepted or MyConfirmed or countdownRunning then return end 

		if itemData.CanTrade then 
			if isItemInTrade(itemData.RealName) then
				removeItemFromTrade(itemData)
			else
				addItemToTrade(itemData)
			end
		end
	end)
end

-- ==========================================
-- 4. Data Refresh Logic
-- ==========================================
local function clearGrid(scrollFrame)
	for _, c in pairs(scrollFrame:GetChildren()) do
		if c:IsA("TextButton") or c:IsA("Frame") then c:Destroy() end
	end
end

function refreshContent(partnerItems)
	if not mainFrame then return end

	-- Update UI Status and Name Display
	local partnerNameDisplay = CurrentTradePartnerName or "Partner"

	local myColor = Color3.fromRGB(255, 50, 50) -- Unaccepted
	local myStatusText = "Unaccepted"

	-- Determine player's own status display (Simplified Text for UI Fix)
	if MyConfirmed then
		myColor = Color3.fromRGB(0, 255, 255) 
		myStatusText = "CONFIRMED"
	elseif countdownRunning then
		myColor = Color3.fromRGB(255, 100, 0)
		myStatusText = "COUNTDOWN"
	elseif MyAccepted then
		myColor = Color3.fromRGB(0, 255, 0) 
		myStatusText = "ACCEPTED"
	end


	MyStatusLabel.Text = "Your Status: " .. myStatusText
	MyStatusLabel.TextColor3 = myColor

	local partnerColor = Color3.fromRGB(255, 50, 50)
	local partnerStatusText = "Unaccepted"

	-- Determine partner's status display (Simplified Text for UI Fix)
	if PartnerConfirmed then
		partnerColor = Color3.fromRGB(0, 255, 255)
		partnerStatusText = "CONFIRMED"
	elseif PartnerAccepted then
		partnerColor = Color3.fromRGB(0, 255, 0)
		partnerStatusText = "ACCEPTED"
	end

	PartnerStatusLabel.Text = partnerNameDisplay .. "'s Status: " .. partnerStatusText
	PartnerStatusLabel.TextColor3 = partnerColor

	-- Update Title
	PartnerNameLabel.Text = "Trading with " .. partnerNameDisplay

	-- Refresh Accept Button (Simplified Text for UI Fix)
	if MyConfirmed then
		AcceptButton.Text = "CONFIRMED" 
		AcceptButton.BackgroundColor3 = Color3.fromRGB(0, 150, 150)
		AcceptButton.TextColor3 = Color3.new(0, 0, 0)
	elseif countdownRunning then -- While countdown is running
		AcceptButton.Text = "LOCKED" 
		AcceptButton.BackgroundColor3 = Color3.fromRGB(200, 150, 0)
		AcceptButton.TextColor3 = Color3.new(1, 1, 1)
	elseif MyAccepted then
		-- MyAccepted is True, waiting for partner to accept or for countdown to start
		AcceptButton.Text = "WAITING" 
		AcceptButton.BackgroundColor3 = Color3.fromRGB(255, 255, 0)
		AcceptButton.TextColor3 = Color3.new(0, 0, 0)
	else
		-- Initial state or reset
		AcceptButton.Text = "ACCEPT"
		AcceptButton.BackgroundColor3 = Color3.fromRGB(255, 255, 0)
		AcceptButton.TextColor3 = Color3.new(0, 0, 0)
	end


	-- A. Clear and load Player Inventory (Left Side)
	clearGrid(MyItemsGrid)

	-- Get the latest inventory data from the server
	local success, inventory = pcall(function() return getInvFunc:InvokeServer() end)

	MockPlayerInventory = {} 

	if success and inventory and typeof(inventory) == "table" then
		for _, item in pairs(inventory) do
			if item and item.RealName then
				MockPlayerInventory[item.RealName] = item 

				-- Only tradeable items are shown in the left list
				if item.CanTrade then
					createTradeCard(MyItemsGrid, item, true) 
				end
			end
		end
	else
		warn("❌ Client failed to get inventory data or returned incorrect format!")
	end


	-- B. Clear and load Partner's Offered Items (Right Side)
	clearGrid(PartnerItemsGrid)
	if partnerItems then
		for itemName, qty in pairs(partnerItems) do

			-- Try to get item configuration from local inventory dictionary (if I have this item in my inventory)
			local itemData = MockPlayerInventory[itemName] 

			-- If not in my inventory, create a placeholder data structure
			if not itemData then
				local fallbackRarityColor = GameConfig.RarityColors["Rare"] or Color3.fromRGB(0, 200, 255)

				itemData = {
					RealName = itemName,
					DisplayName = itemName,
					Qty = qty,
					-- ⚠️ IMPORTANT: Need to use a valid generic Image ID here or fetch from config
					ImageId = "rbxassetid://63412345", -- << REPLACE with a valid generic Image ID for your project
					Rarity = "Rare",
					RarityColor = fallbackRarityColor,
					CanTrade = false
				}
			end

			itemData.Qty = qty -- Use partner's actual quantity
			createTradeCard(PartnerItemsGrid, itemData, false)
		end
	end
end

-- ==========================================
-- 5. Show/Hide Logic and Event Listeners
-- ==========================================

function toggleUI(show)
	isOpen = show

	-- Ensure the parent ScreenGui's Enabled property is set
	gui.Enabled = show 

	if mainFrame then
		mainFrame.Visible = show
		UserInputService.ModalEnabled = show 

		-- Ensure countdown/overlay is cleared and hidden when closing
		if CountdownConnection then
			CountdownConnection:Disconnect()
			CountdownConnection = nil
		end
		countdownRunning = false
		if CountdownFrame then CountdownFrame.Visible = false end
	end

	if show then
		-- Disable core UI elements like chat and backpack
		pcall(function() game.StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false) end)
		refreshContent()
	else
		-- Re-enable core UI elements
		pcall(function() game.StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, true) end)
	end
end

-- Client Event: Listen for server notification to open/close UI
StartTradeEvent.OnClientEvent:Connect(function(partnerName)
	if partnerName then
		CurrentTradePartnerName = partnerName
		ItemsToOffer = {}
		MyAccepted = false
		PartnerAccepted = false
		MyConfirmed = false 
		PartnerConfirmed = false
		countdownRunning = false -- Reset countdown state

		toggleUI(true)
	else
		-- Close trade (CleanUp from server)
		toggleUI(false)
	end
end)

-- 客户端事件：监听服务器通知更新对方物品和状态
-- 服务器会发送 partnerAccepted 和 partnerConfirmed 状态
UpdateTradeUIEvent.OnClientEvent:Connect(function(partnerItems, partnerAccepted, partnerConfirmed)
	PartnerAccepted = partnerAccepted
	PartnerConfirmed = partnerConfirmed or false 
	refreshContent(partnerItems)

	-- ⭐ 关键修复 3: 倒计时逻辑，仅在双方都接受且倒计时未运行时启动
	if MyAccepted and PartnerAccepted and (not MyConfirmed) and (not PartnerConfirmed) and (not countdownRunning) then

		-- 1. Start countdown overlay
		CountdownFrame.Visible = true
		countdownRunning = true

		local startTime = tick()
		local duration = 5 -- Countdown 5 seconds

		CountdownConnection = RunService.Heartbeat:Connect(function(dt)
			local timeElapsed = tick() - startTime
			local timeLeft = math.max(0, duration - timeElapsed)

			CountdownLabel.Text = "Trade Locking... " .. math.ceil(timeLeft)

			if timeLeft <= 0.1 then
				-- Countdown finished, execute final confirmation
				if CountdownConnection then
					CountdownConnection:Disconnect()
					CountdownConnection = nil
				end
				countdownRunning = false

				-- Automatically execute final confirmation logic
				MyConfirmed = true
				CountdownFrame.Visible = false
				HandleTradeActionEvent:FireServer("Confirm")
				refreshContent()
			end
		end)
	end

end)

-- Ensure the UI structure is created once at game start
createUI()

-- Ensure ScreenGui is closed by default
gui.Enabled = false