local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local BossEvent = ReplicatedStorage:WaitForChild("RemoteEvent"):WaitForChild("BossEvent")

-- ==========================================
-- Create UI (Confirmation Window + Result Text + Countdown Window)
-- ==========================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "BossRoomUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- 1. Confirmation Popup (Challenge?)
local confirmFrame = Instance.new("Frame")
confirmFrame.Size = UDim2.new(0, 300, 0, 150)
confirmFrame.Position = UDim2.new(0.5, -150, 0.5, -75)
confirmFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
confirmFrame.Visible = false
confirmFrame.Parent = screenGui
Instance.new("UICorner", confirmFrame).CornerRadius = UDim.new(0, 10)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0.4, 0)
title.BackgroundTransparency = 1
title.Text = "Do you want to challenge the BOSS?"
title.TextColor3 = Color3.new(1,1,1)
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.TextWrapped = true
title.Parent = confirmFrame

local yesBtn = Instance.new("TextButton")
yesBtn.Size = UDim2.new(0.4, 0, 0.3, 0)
yesBtn.Position = UDim2.new(0.05, 0, 0.6, 0)
yesBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
yesBtn.Text = "YES"
yesBtn.TextColor3 = Color3.new(1,1,1)
yesBtn.Font = Enum.Font.GothamBold
yesBtn.Parent = confirmFrame
Instance.new("UICorner", yesBtn).CornerRadius = UDim.new(0, 6)

local noBtn = Instance.new("TextButton")
noBtn.Size = UDim2.new(0.4, 0, 0.3, 0)
noBtn.Position = UDim2.new(0.55, 0, 0.6, 0)
noBtn.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
noBtn.Text = "NO"
noBtn.TextColor3 = Color3.new(1,1,1)
noBtn.Font = Enum.Font.GothamBold
noBtn.Parent = confirmFrame
Instance.new("UICorner", noBtn).CornerRadius = UDim.new(0, 6)

-- 2. Result Display (Victory / Defeat)
local resultLabel = Instance.new("TextLabel")
resultLabel.Size = UDim2.new(1, 0, 0.2, 0)
resultLabel.Position = UDim2.new(0, 0, 0.3, 0)
resultLabel.BackgroundTransparency = 1
resultLabel.Font = Enum.Font.FredokaOne
resultLabel.TextSize = 80
resultLabel.TextStrokeTransparency = 0
resultLabel.Visible = false
resultLabel.Parent = screenGui

-- [Added] 3. Respawn Countdown Popup (Respawn Timer)
local respawnFrame = Instance.new("Frame")
respawnFrame.Size = UDim2.new(0, 300, 0, 120)
respawnFrame.Position = UDim2.new(0.5, -150, 0.5, -60)
respawnFrame.BackgroundColor3 = Color3.fromRGB(44, 62, 80) -- Deep blue-gray
respawnFrame.Visible = false
respawnFrame.Parent = screenGui
Instance.new("UICorner", respawnFrame).CornerRadius = UDim.new(0, 10)

local respawnTitle = Instance.new("TextLabel")
respawnTitle.Size = UDim2.new(1, 0, 0.4, 0)
respawnTitle.BackgroundTransparency = 1
respawnTitle.Text = "Boss Respawning..."
respawnTitle.TextColor3 = Color3.fromRGB(236, 240, 241)
respawnTitle.Font = Enum.Font.GothamBold
respawnTitle.TextSize = 18
respawnTitle.Parent = respawnFrame

local timerLabel = Instance.new("TextLabel")
timerLabel.Size = UDim2.new(1, 0, 0.4, 0)
timerLabel.Position = UDim2.new(0, 0, 0.4, 0)
timerLabel.BackgroundTransparency = 1
timerLabel.Text = "00:00"
timerLabel.TextColor3 = Color3.fromRGB(231, 76, 60) -- Red timer
timerLabel.Font = Enum.Font.FredokaOne
timerLabel.TextSize = 36
timerLabel.Parent = respawnFrame

-- Close button
local closeRespawnBtn = Instance.new("TextButton")
closeRespawnBtn.Size = UDim2.new(0.08, 0, 0.2, 0)
closeRespawnBtn.Position = UDim2.new(0.9, 0, 0, 0)
closeRespawnBtn.BackgroundTransparency = 1
closeRespawnBtn.Text = "X"
closeRespawnBtn.TextColor3 = Color3.fromRGB(189, 195, 199)
closeRespawnBtn.Font = Enum.Font.GothamBold
closeRespawnBtn.Parent = respawnFrame

-- ==========================================
-- Logic Handling
-- ==========================================
local currentTargetBossName = "Saharan Master"
-- Confirmation window
yesBtn.MouseButton1Click:Connect(function()
	confirmFrame.Visible = false
	-- [Core Fix] 2. Send current Boss name back to server
	BossEvent:FireServer("EnterBossRoom", currentTargetBossName)
end)

noBtn.MouseButton1Click:Connect(function()
	confirmFrame.Visible = false
end)

-- Close countdown window
closeRespawnBtn.MouseButton1Click:Connect(function()
	respawnFrame.Visible = false
end)

local countdownCoroutine = nil -- For managing countdown coroutine

-- Listen for server events
BossEvent.OnClientEvent:Connect(function(action, data)
	if action == "ShowConfirm" then
		-- [Core Fix] 3. Receive Boss name from server (e.g. "AntBoss")
		currentTargetBossName = data 

		confirmFrame.Visible = true
		respawnFrame.Visible = false
		title.Text = "Challenge " .. data .. "?"

	elseif action == "ShowResult" then
		resultLabel.Text = string.upper(data) -- "VICTORY" or "DEFEAT"
		if data == "Victory" then
			resultLabel.TextColor3 = Color3.fromRGB(241, 196, 15)
		else
			resultLabel.TextColor3 = Color3.fromRGB(231, 76, 60)
		end

		resultLabel.Visible = true
		resultLabel.Position = UDim2.new(0, 0, 0.4, 0)
		resultLabel.TextTransparency = 0
		TweenService:Create(resultLabel, TweenInfo.new(0.5), {Position = UDim2.new(0,0,0.3,0)}):Play()

		task.delay(3, function()
			TweenService:Create(resultLabel, TweenInfo.new(0.5), {TextTransparency = 1}):Play()
			task.wait(0.5)
			resultLabel.Visible = false
		end)

	elseif action == "ShowRespawnCountDown" then
		-- [Added] Show countdown
		-- data = {Name = "BossName", Time = Remaining seconds}
		respawnFrame.Visible = true
		confirmFrame.Visible = false
		respawnTitle.Text = data.Name .. " Respawns in:"

		-- Reset previous countdown
		if countdownCoroutine then task.cancel(countdownCoroutine) end

		local timeLeft = data.Time

		countdownCoroutine = task.spawn(function()
			while timeLeft > 0 and respawnFrame.Visible do
				local mins = math.floor(timeLeft / 60)
				local secs = timeLeft % 60
				timerLabel.Text = string.format("%02d:%02d", mins, secs)

				task.wait(1)
				timeLeft = timeLeft - 1
			end

			if respawnFrame.Visible then
				timerLabel.Text = "Spawned!"
				task.wait(2)
				respawnFrame.Visible = false
			end
		end)

	elseif action == "Error" then
		game.StarterGui:SetCore("SendNotification", {
			Title = "Boss Room";
			Text = data;
			Duration = 3;
		})
	end
end)