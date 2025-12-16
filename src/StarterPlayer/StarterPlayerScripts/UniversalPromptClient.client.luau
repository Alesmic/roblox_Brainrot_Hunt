local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- 获取远程事件 (Boss墙和交易所墙都用这个)
local RemoteEventFolder = ReplicatedStorage:WaitForChild("RemoteEvent")
local bossEvent = RemoteEventFolder:WaitForChild("BossBattleEvent")

-- ================= UI 生成函数 =================
local function createConfirmUI(messageText)
	-- [颜色定义]
	local Color_White = Color3.fromRGB(255, 255, 255)
	local Color_Green = Color3.fromRGB(0, 170, 0)
	local Color_Red = Color3.fromRGB(170, 0, 0)
	local Color_Black = Color3.fromRGB(20, 20, 30)
	local Color_Gold = Color3.fromRGB(255, 215, 0)

	-- 1. 创建屏幕 UI
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "UniversalPromptUI"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui

	-- 2. 背景黑框
	local frame = Instance.new("Frame")
	frame.Name = "ConfirmFrame"
	frame.Size = UDim2.new(0, 0, 0, 0) -- 初始大小为0
	frame.Position = UDim2.new(0.5, 0, 0.5, 0)
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.BackgroundColor3 = Color_Black
	frame.BorderSizePixel = 2
	frame.BorderColor3 = Color_Gold
	frame.Parent = screenGui

	-- 弹窗动画
	TweenService:Create(frame, TweenInfo.new(0.3, Enum.EasingStyle.Back), {Size = UDim2.new(0, 400, 0, 200)}):Play()

	-- 3. 提示文字
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0.9, 0, 0.5, 0)
	label.Position = UDim2.new(0.05, 0, 0.1, 0)
	label.BackgroundTransparency = 1
	label.Text = messageText
	label.TextColor3 = Color_White

	-- [字体修复]
	label.Font = Enum.Font.GothamBold
	label.TextScaled = false          -- 关闭自动缩放
	label.TextSize = 24               -- 固定字体大小
	label.TextWrapped = true          -- 开启自动换行 (关键)
	label.Parent = frame

	-- 4. YES 按钮
	local yesBtn = Instance.new("TextButton")
	yesBtn.Size = UDim2.new(0.35, 0, 0.25, 0)
	yesBtn.Position = UDim2.new(0.1, 0, 0.65, 0)
	yesBtn.BackgroundColor3 = Color_Green
	yesBtn.Text = "YES"
	yesBtn.Font = Enum.Font.FredokaOne
	yesBtn.TextSize = 24
	yesBtn.TextColor3 = Color_White
	yesBtn.Parent = frame
	local corner1 = Instance.new("UICorner"); corner1.CornerRadius = UDim.new(0, 8); corner1.Parent = yesBtn

	-- 5. NO 按钮
	local noBtn = Instance.new("TextButton")
	noBtn.Size = UDim2.new(0.35, 0, 0.25, 0)
	noBtn.Position = UDim2.new(0.55, 0, 0.65, 0)
	noBtn.BackgroundColor3 = Color_Red
	noBtn.Text = "NO"
	noBtn.Font = Enum.Font.FredokaOne
	noBtn.TextSize = 24
	noBtn.TextColor3 = Color_White
	noBtn.Parent = frame
	local corner2 = Instance.new("UICorner"); corner2.CornerRadius = UDim.new(0, 8); corner2.Parent = noBtn

	-- ================= 点击事件 =================
	local function close()
		local tween = TweenService:Create(frame, TweenInfo.new(0.2), {Size = UDim2.new(0,0,0,0)})
		tween:Play()
		tween.Completed:Connect(function() screenGui:Destroy() end)
	end

	yesBtn.MouseButton1Click:Connect(function()
		bossEvent:FireServer("YES")
		close()
	end)

	noBtn.MouseButton1Click:Connect(function()
		bossEvent:FireServer("NO")
		close()
	end)
end

bossEvent.OnClientEvent:Connect(function(action, message)
	if action == "ASK_FIGHT" then
		createConfirmUI(message)
	end
end)