local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local gui = script.Parent 

-- ==========================================
-- 1. Resource References
-- ==========================================
local RemoteEventFolder = ReplicatedStorage:WaitForChild("RemoteEvent")
local StartTradeEvent = RemoteEventFolder:WaitForChild("StartTradeUI", 10)
local HandleTradeActionEvent = RemoteEventFolder:WaitForChild("HandleTradeAction", 10)
local UpdateTradeUIEvent = RemoteEventFolder:WaitForChild("UpdateTradeUI", 10)
local bossEvent = RemoteEventFolder:WaitForChild("BossBattleEvent", 10)
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

-- State Variables
local myOffer = {} 
local partnerOffer = {}
local isLocked = false 
local partnerLocked = false 
local isConfirmed = false 
local countdownActive = false
local hasConflict = false 
local activePromptSource = nil -- Record the current prompt source (Wall or others)

-- UI Components
local mainFrame
local inventoryScroll   
local myOfferScroll     
local partnerOfferScroll 
local confirmBtn
local closeBtn
local statusLabel
local promptFrame
local promptTitle
local promptDesc
local promptYesBtn
local promptNoBtn

-- ==========================================
-- 2. Core Validation Logic (Uniqueness & Limit)
-- ==========================================
local function validateTradeLegality(offerItems)
	local conflict = false
	local reason = ""

	for itemName, qty in pairs(offerItems) do
		local conf = GameConfig.Weapons[itemName] or GameConfig.Items[itemName] or GameConfig.Skin[itemName]
		if not conf then continue end

		-- 1. Weapon Uniqueness Check
		if conf.Category == "Weapons" then
			if player.Inventory:FindFirstChild(itemName) or player.Backpack:FindFirstChild(itemName) then
				conflict = true
				reason = "You already own this weapon: " .. (conf.DisplayName or itemName)
				break
			end
		end

		-- 2. Medpack Quantity Limit (Max 3)
		if itemName == "Medpack" then
			local myCurrent = player.Inventory:FindFirstChild(itemName) and player.Inventory:FindFirstChild(itemName).Value or 0
			if myCurrent + qty > 3 then
				conflict = true
				reason = "Medpack holding limit is 3 units"
				break
			end
		end
	end

	return conflict, reason
end

-- ==========================================
-- 3. UI Generator
-- ==========================================
local function createResponsiveUI()
	if gui:FindFirstChild("MainFrame") then gui.MainFrame:Destroy() end
	if gui:FindFirstChild("PromptFrame") then gui.PromptFrame:Destroy() end

	-- A. Main Trade Window
	mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.AnchorPoint = Vector2.new(0.5, 0) 
	mainFrame.Position = UDim2.new(0.5, 0, 0, 0) -- Stick to the top
	mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
	mainFrame.Size = UDim2.new(0.7, 0, 0.65, 0)
	mainFrame.Visible = false
	mainFrame.Parent = gui
	Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 10)

	-- Title
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0.08, 0)
	title.Text = "TRADE SYSTEM"
	title.TextColor3 = Color3.new(1, 0.8, 0)
	title.Font = Enum.Font.FredokaOne
	title.TextScaled = true
	title.BackgroundTransparency = 1
	title.Parent = mainFrame

	-- Close Button
	closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.new(0, 30, 0, 30)
	closeBtn.Position = UDim2.new(1, -35, 0, 5)
	closeBtn.BackgroundColor3 = Color3.new(0.8, 0.2, 0.2)
	closeBtn.Text = "X"
	closeBtn.TextColor3 = Color3.new(1,1,1)
	closeBtn.Font = Enum.Font.FredokaOne
	closeBtn.TextSize = 20
	closeBtn.Parent = mainFrame
	Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)

	closeBtn.MouseButton1Click:Connect(function()
		HandleTradeActionEvent:FireServer("Cancel")
	end)

	-- Three-Column Layout Function
	local function createSection(name, pos, titleText)
		local f = Instance.new("Frame")
		f.Name = name
		f.Size = UDim2.new(0.31, 0, 0.78, 0)
		f.Position = pos
		f.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
		f.Parent = mainFrame
		Instance.new("UICorner", f).CornerRadius = UDim.new(0, 6)

		local t = Instance.new("TextLabel")
		t.Size = UDim2.new(1,0,0.1,0)
		t.Text = titleText
		t.TextColor3 = Color3.new(0.6,0.6,0.6)
		t.Font = Enum.Font.FredokaOne
		t.TextScaled = true
		t.BackgroundTransparency=1
		t.Parent=f

		local s = Instance.new("ScrollingFrame")
		s.Size = UDim2.new(1,-6,0.88,0)
		s.Position=UDim2.new(0,3,0.12,0)
		s.BackgroundTransparency=1
		s.Parent=f
		Instance.new("UIGridLayout", s).CellSize = UDim2.new(0, 70, 0, 70)
		return s
	end

	inventoryScroll = createSection("Inv", UDim2.new(0.015,0,0.1,0), "My Inventory")
	myOfferScroll = createSection("MyOffer", UDim2.new(0.345,0,0.1,0), "My Offer")
	partnerOfferScroll = createSection("PartnerOffer", UDim2.new(0.675,0,0.1,0), "Partner's Offer")

	-- Confirm Button
	confirmBtn = Instance.new("TextButton")
	confirmBtn.Size = UDim2.new(0.3, 0, 0.08, 0)
	confirmBtn.Position = UDim2.new(0.35, 0, 0.9, 0)
	confirmBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
	confirmBtn.Font = Enum.Font.FredokaOne
	confirmBtn.TextScaled = true
	confirmBtn.TextColor3 = Color3.new(1,1,1)
	confirmBtn.Parent = mainFrame
	Instance.new("UICorner", confirmBtn).CornerRadius = UDim.new(0, 8)

	statusLabel = Instance.new("TextLabel")
	statusLabel.Size = UDim2.new(1, 0, 0.02, 0)
	statusLabel.Position = UDim2.new(0, 0, 0.98, 0)
	statusLabel.BackgroundTransparency = 1
	statusLabel.TextColor3 = Color3.new(0.8,0.8,0.8)
	statusLabel.TextScaled = true
	statusLabel.Parent = mainFrame

	-- B. [Critical Fix] Wall Recognition Prompt Frame
	promptFrame = Instance.new("Frame")
	promptFrame.Name = "PromptFrame"
	promptFrame.Visible = false
	promptFrame.Size = UDim2.new(0.4, 0, 0.3, 0)
	promptFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	promptFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	promptFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
	promptFrame.ZIndex = 100 -- Ensure it's on the top layer
	promptFrame.Parent = gui
	Instance.new("UICorner", promptFrame).CornerRadius = UDim.new(0, 12)

	promptTitle = Instance.new("TextLabel", promptFrame)
	promptTitle.Name = "Title"
	promptTitle.Size = UDim2.new(1,0,0.3,0)
	promptTitle.BackgroundTransparency = 1
	promptTitle.Text = "NOTIFICATION"
	promptTitle.TextColor3 = Color3.new(1,0.8,0)
	promptTitle.Font = Enum.Font.FredokaOne
	promptTitle.TextScaled = true

	promptDesc = Instance.new("TextLabel", promptFrame)
	promptDesc.Name = "Description"
	promptDesc.Size = UDim2.new(0.9,0,0.3,0)
	promptDesc.Position = UDim2.new(0.05,0,0.3,0)
	promptDesc.BackgroundTransparency = 1
	promptDesc.Text = "Enter Exchange?"
	promptDesc.TextColor3 = Color3.new(0.8,0.8,0.8)
	promptDesc.TextScaled = true

	promptYesBtn = Instance.new("TextButton", promptFrame)
	promptYesBtn.Name = "YesButton"
	promptYesBtn.Text = "YES"
	promptYesBtn.Size = UDim2.new(0.4,0,0.25,0)
	promptYesBtn.Position = UDim2.new(0.05,0,0.65,0)
	promptYesBtn.BackgroundColor3 = Color3.fromRGB(0,200,100)
	promptYesBtn.Font = Enum.Font.FredokaOne
	Instance.new("UICorner", promptYesBtn).CornerRadius = UDim.new(0,6)

	promptNoBtn = Instance.new("TextButton", promptFrame)
	promptNoBtn.Name = "NoButton"
	promptNoBtn.Text = "NO"
	promptNoBtn.Size = UDim2.new(0.4,0,0.25,0)
	promptNoBtn.Position = UDim2.new(0.55,0,0.65,0)
	promptNoBtn.BackgroundColor3 = Color3.fromRGB(200,50,50)
	promptNoBtn.Font = Enum.Font.FredokaOne
	Instance.new("UICorner", promptNoBtn).CornerRadius = UDim.new(0,6)

	-- [Fix] Prompt Button Event Binding
	promptYesBtn.MouseButton1Click:Connect(function()
		promptFrame.Visible = false -- Hide immediately to prevent freezing
		if activePromptSource == "Wall" and bossEvent then
			bossEvent:FireServer("YES")
		end
		activePromptSource = nil
	end)

	promptNoBtn.MouseButton1Click:Connect(function()
		promptFrame.Visible = false -- Hide immediately to prevent freezing
		if activePromptSource == "Wall" and bossEvent then
			bossEvent:FireServer("NO")
		end
		activePromptSource = nil
	end)
end

-- ==========================================
-- 4. Trade Logic
-- ==========================================
function updateButtonState()
	if hasConflict then 
		confirmBtn.Text = "Trade Unavailable (Rule Conflict)"
		confirmBtn.BackgroundColor3 = Color3.new(0.3,0.3,0.3)
		confirmBtn.AutoButtonColor = false
		return 
	end
	confirmBtn.AutoButtonColor = true

	if countdownActive then return end -- Button text controlled by countdown function during countdown

	if isLocked then
		if partnerLocked then
			if isConfirmed then
				confirmBtn.Text = "Waiting for Server..."
				confirmBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
			else
				startCountdown() -- Both sides locked, start countdown
			end
		else
			confirmBtn.Text = "Waiting for Partner (Click to Cancel)"
			confirmBtn.BackgroundColor3 = Color3.fromRGB(200, 150, 0)
		end
	else
		confirmBtn.Text = "Lock and Accept"
		confirmBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
	end
end

function startCountdown()
	if countdownActive then return end
	countdownActive = true

	task.spawn(function()
		local t = 5
		while t > 0 do
			-- Stop immediately if status changes midway (e.g., partner cancels lock)
			if not isLocked or not partnerLocked or hasConflict then
				countdownActive = false
				updateButtonState()
				return
			end

			confirmBtn.Text = "Confirming ("..t.."s) Click to Cancel"
			confirmBtn.BackgroundColor3 = Color3.new(0.8, 0.2, 0.2)
			task.wait(1)
			t = t - 1
		end

		-- Countdown finished, send confirmation
		if isLocked and partnerLocked and not hasConflict then
			confirmBtn.Text = "Trading..."
			confirmBtn.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
			isConfirmed = true
			HandleTradeActionEvent:FireServer("Confirm")

			-- [Anti-Freezing Mechanism] If UI is still active after 5s, server is unresponsive
			task.delay(5, function()
				if isConfirmed and mainFrame.Visible then
					isConfirmed = false
					statusLabel.Text = "Server response timed out, please try again"
					confirmBtn.Text = "Frozen? Click to Reset"
					confirmBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
				end
			end)
		else
			countdownActive = false
			updateButtonState()
		end
	end)
end

local function createCard(name, container, isMyInv)
	local conf = GameConfig.Weapons[name] or GameConfig.Items[name] or GameConfig.Skin[name]
	if not conf then return end

	local btn = Instance.new("ImageButton", container)
	btn.BackgroundColor3 = Color3.fromRGB(40,40,45)
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0.1, 0)

	local img = Instance.new("ImageLabel", btn)
	img.Size = UDim2.new(0.8,0,0.8,0)
	img.Position = UDim2.new(0.1,0,0.1,0)
	img.Image = conf.ImageId or ""
	img.BackgroundTransparency = 1

	-- Quantity Display
	local qtyText = "x" .. (isMyInv and (myOffer[name] or 1) or (partnerOffer[name] or 1))
	if container == inventoryScroll then
		-- If it's inventory, display remaining quantity
		local total = player.Inventory:FindFirstChild(name) and player.Inventory[name].Value or 0
		local offering = myOffer[name] or 0
		qtyText = "x" .. (total - offering)
	end

	local qty = Instance.new("TextLabel", btn)
	qty.Size = UDim2.new(0.5,0,0.4,0)
	qty.Position = UDim2.new(0.5,0,0.6,0)
	qty.Text = qtyText
	qty.TextColor3 = Color3.new(1,1,1)
	qty.BackgroundTransparency = 1
	qty.TextScaled = true
	qty.Font = Enum.Font.FredokaOne

	-- Click Logic
	if container ~= partnerOfferScroll then
		btn.MouseButton1Click:Connect(function()
			if isLocked or countdownActive then return end

			local invQty = player.Inventory:FindFirstChild(name) and player.Inventory[name].Value or 0
			local currentOffer = myOffer[name] or 0

			if container == inventoryScroll then
				-- Add to trade slot
				if currentOffer < invQty then
					myOffer[name] = currentOffer + 1
				end
			elseif container == myOfferScroll then
				-- Remove from trade slot
				if currentOffer > 0 then
					myOffer[name] = currentOffer - 1
					if myOffer[name] <= 0 then myOffer[name] = nil end
				end
			end
			updateUI()
			HandleTradeActionEvent:FireServer("UpdateItems", myOffer)
		end)
	end
end

function updateUI()
	-- Clear lists
	for _, s in pairs({inventoryScroll, myOfferScroll, partnerOfferScroll}) do
		if s then
			for _, c in pairs(s:GetChildren()) do if c:IsA("GuiObject") then c:Destroy() end end
		end
	end

	-- Populate inventory
	if player:FindFirstChild("Inventory") then
		for _, item in pairs(player.Inventory:GetChildren()) do
			if item.Value > 0 then createCard(item.Name, inventoryScroll, true) end
		end
	end

	-- Populate trade slots
	for name, q in pairs(myOffer) do createCard(name, myOfferScroll, true) end
	for name, q in pairs(partnerOffer) do createCard(name, partnerOfferScroll, false) end
end

-- ==========================================
-- 5. Initialization & Event Listening
-- ==========================================
createResponsiveUI()

confirmBtn.MouseButton1Click:Connect(function()
	if hasConflict or isConfirmed then return end

	-- Button click logic: If in countdown or locked state, click to cancel
	if isLocked or countdownActive then
		isLocked = false
		countdownActive = false
		HandleTradeActionEvent:FireServer("UpdateItems", myOffer) -- Refresh status
	else
		isLocked = true
		HandleTradeActionEvent:FireServer("Accept")
	end
	updateButtonState()
end)

StartTradeEvent.OnClientEvent:Connect(function(partnerName)
	if partnerName then
		mainFrame.Visible = true
		myOffer = {}
		partnerOffer = {}
		isLocked = false
		partnerLocked = false
		isConfirmed = false
		countdownActive = false
		hasConflict = false
		statusLabel.Text = "Trading with: " .. partnerName
		updateUI()
		updateButtonState()
	else
		mainFrame.Visible = false
		promptFrame.Visible = false
	end
end)

UpdateTradeUIEvent.OnClientEvent:Connect(function(items, accepted, confirmed)
	partnerOffer = items or {}
	partnerLocked = accepted

	-- If partner cancels lock, force cancel my countdown
	if not partnerLocked and countdownActive then
		countdownActive = false
		isLocked = false -- Optional: Whether to force unlock my side as well
	end

	local conflict, reason = validateTradeLegality(partnerOffer)
	hasConflict = conflict

	if hasConflict then
		statusLabel.Text = "⚠ Error: " .. reason
		statusLabel.TextColor3 = Color3.new(1,0,0)
	else
		if accepted then
			statusLabel.Text = "Partner has locked"
			statusLabel.TextColor3 = Color3.new(0,1,0)
		else
			statusLabel.Text = "Partner is selecting..."
			statusLabel.TextColor3 = Color3.new(0.8,0.8,0.8)
		end
	end

	updateUI()
	updateButtonState()
end)

-- [Critical Fix] Wall Recognition Prompt Listener
if bossEvent then
	bossEvent.OnClientEvent:Connect(function(action, data)
		if action == "ASK_FIGHT" then
			activePromptSource = "Wall"
			promptFrame.Visible = true
			if promptTitle then promptTitle.Text = "EXCHANGE REQUEST" end
			if promptDesc then promptDesc.Text = data or "Enter Exchange Area?" end
		end
	end)
end

-- Listen for inventory changes to refresh in real-time
if player:FindFirstChild("Inventory") then
	player.Inventory.ChildAdded:Connect(updateUI)
	player.Inventory.ChildRemoved:Connect(updateUI)
	for _, item in pairs(player.Inventory:GetChildren()) do
		item.Changed:Connect(updateUI)
	end
end