local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local pvpEvent = ReplicatedStorage:WaitForChild("PvPEvent")

-- ==========================================
-- 1. 自动生成 UI
-- ==========================================
local screenGui = script.Parent
screenGui.ResetOnSpawn = false 
screenGui.IgnoreGuiInset = true

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 160, 0, 80)
mainFrame.Position = UDim2.new(1, -180, 0.5, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
mainFrame.BackgroundTransparency = 0.2
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

local uiCorner = Instance.new("UICorner")
uiCorner.CornerRadius = UDim.new(0, 10)
uiCorner.Parent = mainFrame

local statusLabel = Instance.new("TextLabel")
statusLabel.Name = "StatusLabel"
statusLabel.Size = UDim2.new(1, 0, 0.4, 0)
statusLabel.Position = UDim2.new(0, 0, 0, 5)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "PvP: 安全区"
statusLabel.TextColor3 = Color3.fromRGB(0, 255, 100)
statusLabel.Font = Enum.Font.GothamBold
statusLabel.TextSize = 14
statusLabel.Parent = mainFrame

local toggleBtn = Instance.new("TextButton")
toggleBtn.Name = "ToggleButton"
toggleBtn.Size = UDim2.new(0.8, 0, 0.4, 0)
toggleBtn.Position = UDim2.new(0.1, 0, 0.5, 0)
toggleBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
toggleBtn.Text = "开启 PvP"
toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.TextSize = 14
toggleBtn.TextWrapped = true -- 允许文字换行以显示长警告
toggleBtn.Parent = mainFrame

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0, 8)
btnCorner.Parent = toggleBtn

-- ==========================================
-- 2. 按钮逻辑
-- ==========================================
local debounce = false

toggleBtn.MouseButton1Click:Connect(function()
	if debounce then return end
	debounce = true

	pvpEvent:FireServer("TogglePvP")

	task.wait(1)
	debounce = false
end)

-- ==========================================
-- 3. 反馈处理
-- ==========================================
pvpEvent.OnClientEvent:Connect(function(action, value)
	if action == "UpdateState" then
		local isPvP = value

		if isPvP then
			statusLabel.Text = "PvP: 已开启"
			statusLabel.TextColor3 = Color3.fromRGB(231, 76, 60)

			toggleBtn.Text = "关闭 PvP"
			toggleBtn.BackgroundColor3 = Color3.fromRGB(192, 57, 43)
		else
			statusLabel.Text = "PvP: 安全模式"
			statusLabel.TextColor3 = Color3.fromRGB(46, 204, 113)

			toggleBtn.Text = "开启 PvP"
			toggleBtn.BackgroundColor3 = Color3.fromRGB(39, 174, 96)
		end

	elseif action == "Error" then
		-- [核心修改] 收到安全区警告时的弹窗效果
		local oldText = toggleBtn.Text
		local oldColor = toggleBtn.BackgroundColor3

		toggleBtn.Text = value -- 显示 "此为安全区，禁止开启PvP"
		toggleBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80) -- 变灰提示不可用

		task.wait(2.5) -- 提示显示 2.5 秒

		toggleBtn.Text = oldText
		toggleBtn.BackgroundColor3 = oldColor
	end
end)