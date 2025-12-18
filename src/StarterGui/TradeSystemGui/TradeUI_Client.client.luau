-- TradeUI_Client (Client Script)
-- Placement: StarterGui/TradeSystemGui/TradeUI_Client

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPack = game:GetService("StarterPack")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- [Added] Import GameConfig to read image configurations
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

-- ==========================================
-- 1. Safe Retrieval of RemoteEvents
-- ==========================================
local RemoteEventFolder = ReplicatedStorage:WaitForChild("RemoteEvent", 10)
if not RemoteEventFolder then
	warn("⚠️ [TradeUI] Critical Error: RemoteEvent folder not found!")
	return
end

local StartTradeEvent = RemoteEventFolder:WaitForChild("StartTradeUI", 10)
local HandleTradeActionEvent = RemoteEventFolder:WaitForChild("HandleTradeAction", 10)
local UpdateTradeUIEvent = RemoteEventFolder:WaitForChild("UpdateTradeUI", 10)

if not (StartTradeEvent and HandleTradeActionEvent and UpdateTradeUIEvent) then
	warn("⚠️ [TradeUI] Missing some RemoteEvents, trade functionality may fail!")
end

-- ==========================================
-- 2. Variables and Configuration
-- ==========================================
local currentOffer = {} 
local isTradeActive = false
local myLockStatus = false
local theirLockStatus = false
local isCountdownActive = false

-- [Core Fix] Prioritize reading images from GameConfig
local function getItemIcon(itemName)
	-- 1. Priority: Check configuration table (GameConfig) - Most accurate, universal for all players
	-- Check Weapons, Items, Skin tables in sequence
	local categoryList = {GameConfig.Weapons, GameConfig.Items, GameConfig.Skin}

	for _, category in pairs(categoryList) do
		if category and category[itemName] and category[itemName].ImageId then
			return category[itemName].ImageId
		end
	end

	-- 2. If not filled in configuration table, try to find Tool object from public areas
	local locations = {ReplicatedStorage, StarterPack, player.Backpack, player.Character}
	for _, loc in pairs(locations) do
		local tool = loc:FindFirstChild(itemName, true)
		if tool and tool:IsA("Tool") then
			return tool.TextureId
		end
	end

	-- 3. If really not found, return default question mark
	return "rbxassetid://13466488344" 
end

-- ==========================================
-- 3. UI Generation (Unchanged)
-- ==========================================
local screenGui = script.Parent
screenGui.Name = "TradeSystemGui"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true 
screenGui.DisplayOrder = 100 

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
mainFrame.Position = UDim2.fromScale(0.5, 0.5)
mainFrame.Size = UDim2.fromScale(0.6, 0.65)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
mainFrame.BorderSizePixel = 0
mainFrame.Visible = false
mainFrame.Parent = screenGui

local sizeConstraint = Instance.new("UISizeConstraint")
sizeConstraint.MinSize = Vector2.new(350, 300)
sizeConstraint.MaxSize = Vector2.new(700, 500)
sizeConstraint.Parent = mainFrame

local uiCorner = Instance.new("UICorner")
uiCorner.CornerRadius = UDim.new(0, 12)
uiCorner.Parent = mainFrame

-- Title
local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, 0, 0.1, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "Trade Center (TRADE)"
titleLabel.TextColor3 = Color3.new(1, 1, 1)
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 18
titleLabel.Parent = mainFrame

-- Close Button
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0.08, 0, 0.1, 0)
closeBtn.Position = UDim2.new(0.92, 0, 0, 0)
closeBtn.BackgroundTransparency = 1
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
closeBtn.Font = Enum.Font.FredokaOne
closeBtn.TextSize = 20
closeBtn.Parent = mainFrame

-- Container
local contentFrame = Instance.new("Frame")
contentFrame.Size = UDim2.new(0.96, 0, 0.7, 0)
contentFrame.Position = UDim2.new(0.02, 0, 0.12, 0)
contentFrame.BackgroundTransparency = 1
contentFrame.Parent = mainFrame

-- Left Panel (Me)
local myPanelFrame = Instance.new("Frame")
myPanelFrame.Size = UDim2.new(0.49, 0, 1, 0)
myPanelFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
myPanelFrame.Parent = contentFrame
Instance.new("UICorner", myPanelFrame).CornerRadius = UDim.new(0, 8)

local myHeader = Instance.new("TextLabel")
myHeader.Size = UDim2.new(1, 0, 0.1, 0)
myHeader.BackgroundTransparency = 1
myHeader.Text = "Your Items"
myHeader.TextColor3 = Color3.fromRGB(200, 200, 200)
myHeader.Font = Enum.Font.GothamBold
myHeader.Parent = myPanelFrame

local myScroll = Instance.new("ScrollingFrame")
myScroll.Size = UDim2.new(1, 0, 0.9, 0)
myScroll.Position = UDim2.new(0, 0, 0.1, 0)
myScroll.BackgroundTransparency = 1
myScroll.ScrollBarThickness = 4
myScroll.Parent = myPanelFrame

-- Right Panel (Partner)
local theirPanelFrame = myPanelFrame:Clone()
theirPanelFrame.Position = UDim2.new(0.51, 0, 0, 0)
theirPanelFrame.Parent = contentFrame
local theirHeader = theirPanelFrame:FindFirstChild("TextLabel")
theirHeader.Text = "Partner's Items"
local theirScroll = theirPanelFrame:FindFirstChild("ScrollingFrame")

-- Layout
local listLayout = Instance.new("UIListLayout")
listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
listLayout.Padding = UDim.new(0, 5)
listLayout.Parent = myScroll
listLayout:Clone().Parent = theirScroll

-- Bottom Action Area
local actionFrame = Instance.new("Frame")
actionFrame.Size = UDim2.new(1, 0, 0.15, 0)
actionFrame.Position = UDim2.new(0, 0, 0.85, 0)
actionFrame.BackgroundTransparency = 1
actionFrame.Parent = mainFrame

-- Main Button
local mainActionBtn = Instance.new("TextButton")
mainActionBtn.Name = "ActionButton"
mainActionBtn.Size = UDim2.new(0.5, 0, 0.7, 0)
mainActionBtn.AnchorPoint = Vector2.new(0.5, 0.5)
mainActionBtn.Position = UDim2.new(0.5, 0, 0.5, 0)
mainActionBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
mainActionBtn.Text = "Lock Trade (LOCK)"
mainActionBtn.TextColor3 = Color3.new(1, 1, 1)
mainActionBtn.Font = Enum.Font.GothamBold
mainActionBtn.TextSize = 16
mainActionBtn.AutoButtonColor = true
mainActionBtn.Parent = actionFrame
Instance.new("UICorner", mainActionBtn).CornerRadius = UDim.new(0, 8)

-- Status Text
local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, 0, 0.3, 0)
statusLabel.Position = UDim2.new(0, 0, -0.4, 0)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Trade in progress..."
statusLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 14
statusLabel.Parent = actionFrame

-- ==========================================
-- 4. Helper Function: Create Item Entry
-- ==========================================
local function createItemEntry(parent, name, amount, isInteractable)
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0.95, 0, 0, 50) 
	frame.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
	frame.Parent = parent
	Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)

	-- Image Display
	local icon = Instance.new("ImageLabel")
	icon.Size = UDim2.new(0, 40, 0, 40)
	icon.Position = UDim2.new(0, 5, 0.5, -20)
	icon.BackgroundTransparency = 1
	icon.Image = getItemIcon(name) -- Automatically retrieve from GameConfig
	icon.ScaleType = Enum.ScaleType.Fit
	icon.Parent = frame

	-- Item Name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(0.6, 0, 0.5, 0)
	nameLabel.Position = UDim2.new(0, 55, 0.1, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = name
	nameLabel.TextColor3 = Color3.new(1, 1, 1)
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 14
	nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	nameLabel.Parent = frame

	-- Quantity
	local amtLabel = Instance.new("TextLabel")
	amtLabel.Size = UDim2.new(0.6, 0, 0.4, 0)
	amtLabel.Position = UDim2.new(0, 55, 0.6, 0)
	amtLabel.BackgroundTransparency = 1
	amtLabel.Text = "x" .. amount
	amtLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
	amtLabel.TextXAlignment = Enum.TextXAlignment.Left
	amtLabel.Font = Enum.Font.Gotham
	amtLabel.TextSize = 12
	amtLabel.Parent = frame

	-- Interaction Logic
	if isInteractable then
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(1, 0, 1, 0)
		btn.BackgroundTransparency = 1
		btn.Text = ""
		btn.Parent = frame

		btn.MouseButton1Click:Connect(function()
			if myLockStatus then return end 
			if not currentOffer[name] then currentOffer[name] = 0 end

			local invItem = player.Inventory:FindFirstChild(name)
			local maxQty = invItem and invItem.Value or 0

			if currentOffer[name] < maxQty then
				currentOffer[name] = currentOffer[name] + 1
				if HandleTradeActionEvent then
					HandleTradeActionEvent:FireServer("UpdateItems", currentOffer)
				end
				refreshMyView()
			end
		end)

		btn.MouseButton2Click:Connect(function()
			if myLockStatus then return end
			if currentOffer[name] and currentOffer[name] > 0 then
				currentOffer[name] = currentOffer[name] - 1
				if currentOffer[name] <= 0 then currentOffer[name] = nil end
				if HandleTradeActionEvent then
					HandleTradeActionEvent:FireServer("UpdateItems", currentOffer)
				end
				refreshMyView()
			end
		end)
	end
end

-- Refresh View
function refreshMyView()
	for _, v in pairs(myScroll:GetChildren()) do
		if v:IsA("Frame") then v:Destroy() end
	end

	for name, qty in pairs(currentOffer) do
		createItemEntry(myScroll, name, qty, true)
	end

	local inventory = player:FindFirstChild("Inventory")
	if inventory then
		for _, item in pairs(inventory:GetChildren()) do
			if item:IsA("IntValue") then
				local offering = currentOffer[item.Name] or 0
				local remaining = item.Value - offering

				if remaining > 0 then
					local frame = Instance.new("Frame")
					frame.Size = UDim2.new(0.95, 0, 0, 40)
					frame.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
					frame.Parent = myScroll
					Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)

					local label = Instance.new("TextLabel")
					label.Size = UDim2.new(1, -10, 1, 0)
					label.Position = UDim2.new(0, 10, 0, 0)
					label.BackgroundTransparency = 1
					label.Text = "+ Add " .. item.Name .. " (Owned: " .. remaining .. ")"
					label.TextColor3 = Color3.fromRGB(120, 120, 120)
					label.TextXAlignment = Enum.TextXAlignment.Left
					label.Font = Enum.Font.Gotham
					label.TextSize = 12
					label.Parent = frame

					local btn = Instance.new("TextButton")
					btn.Size = UDim2.new(1,0,1,0)
					btn.BackgroundTransparency = 1
					btn.Text = ""
					btn.Parent = frame

					btn.MouseButton1Click:Connect(function()
						if myLockStatus then return end
						currentOffer[item.Name] = (currentOffer[item.Name] or 0) + 1
						if HandleTradeActionEvent then
							HandleTradeActionEvent:FireServer("UpdateItems", currentOffer)
						end
						refreshMyView()
					end)
				end
			end
		end
	end
end

-- ==========================================
-- 5. Core Logic: Countdown and Auto-Confirmation
-- ==========================================

local function updateMainButton()
	if isCountdownActive then
		mainActionBtn.BackgroundColor3 = Color3.fromRGB(241, 196, 15) -- Yellow
		mainActionBtn.AutoButtonColor = false
		return
	end

	if not myLockStatus then
		mainActionBtn.Text = "Lock Trade (LOCK)"
		mainActionBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113) -- Green
		mainActionBtn.AutoButtonColor = true
		statusLabel.Text = theirLockStatus and "Partner locked, waiting for you to lock..." or "Please select items and lock..."

	elseif myLockStatus and not theirLockStatus then
		mainActionBtn.Text = "Waiting for partner..."
		mainActionBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100) -- Gray
		mainActionBtn.AutoButtonColor = false
		statusLabel.Text = "Waiting for partner to lock..."

	elseif myLockStatus and theirLockStatus then
		-- Both locked -> Countdown coroutine is running at this time
		mainActionBtn.Text = "Preparing to exchange..."
		mainActionBtn.BackgroundColor3 = Color3.fromRGB(241, 196, 15)
		mainActionBtn.AutoButtonColor = false
	end
end

-- 5-second countdown -> Auto confirmation
local function startCountdown()
	if isCountdownActive then return end
	isCountdownActive = true

	mainActionBtn.AutoButtonColor = false
	mainActionBtn.BackgroundColor3 = Color3.fromRGB(230, 126, 34) -- Orange
	statusLabel.Text = "Trade locked, completing soon..."

	for i = 5, 1, -1 do
		if not isTradeActive or not myLockStatus or not theirLockStatus then
			isCountdownActive = false
			updateMainButton()
			return 
		end
		mainActionBtn.Text = "Confirmation Countdown: " .. i
		task.wait(1)
	end

	-- Countdown finished -> Auto send confirmation
	if HandleTradeActionEvent then
		HandleTradeActionEvent:FireServer("Confirm")
	end

	mainActionBtn.Text = "Exchanging..."
	mainActionBtn.BackgroundColor3 = Color3.fromRGB(39, 174, 96) -- Dark green
	isCountdownActive = false
end

-- ==========================================
-- 6. Event Listeners
-- ==========================================

StartTradeEvent.OnClientEvent:Connect(function(partnerName)
	if not partnerName then
		mainFrame.Visible = false
		isTradeActive = false
		return
	end

	isTradeActive = true
	currentOffer = {}
	myLockStatus = false
	theirLockStatus = false
	isCountdownActive = false

	mainFrame.Visible = true
	titleLabel.Text = "Trading with " .. partnerName
	refreshMyView()
	updateMainButton()

	for _, v in pairs(theirScroll:GetChildren()) do if v:IsA("Frame") then v:Destroy() end end
end)

UpdateTradeUIEvent.OnClientEvent:Connect(function(partnerItems, partnerAcc, partnerConf)
	if not isTradeActive then return end

	for _, v in pairs(theirScroll:GetChildren()) do if v:IsA("Frame") then v:Destroy() end end
	if partnerItems then
		for name, qty in pairs(partnerItems) do
			createItemEntry(theirScroll, name, qty, false)
		end
	end

	local oldTheirStatus = theirLockStatus
	theirLockStatus = partnerAcc

	if myLockStatus and theirLockStatus and not oldTheirStatus then
		task.spawn(startCountdown)
	end

	if partnerConf then
		statusLabel.Text = "Trade successful!"
		statusLabel.TextColor3 = Color3.fromRGB(46, 204, 113)
	end

	updateMainButton()
end)

-- ==========================================
-- 7. Button Clicks
-- ==========================================

mainActionBtn.MouseButton1Click:Connect(function()
	if isCountdownActive then return end 
	if not HandleTradeActionEvent then return end

	if not myLockStatus then
		-- Click to lock
		myLockStatus = true
		HandleTradeActionEvent:FireServer("Accept")

		-- If partner already locked, now both locked -> Start countdown
		if theirLockStatus then
			task.spawn(startCountdown)
		end
		updateMainButton()
	end
end)

closeBtn.MouseButton1Click:Connect(function()
	if HandleTradeActionEvent then
		HandleTradeActionEvent:FireServer("Cancel")
	end
	mainFrame.Visible = false
	isTradeActive = false
end)