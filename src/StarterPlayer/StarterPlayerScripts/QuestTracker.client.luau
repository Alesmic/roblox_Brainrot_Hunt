local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

-- ==========================================
-- 1. UI 创建
-- ==========================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "QuestTrackerUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui
screenGui.DisplayOrder = -10

-- A. 任务折叠/展开按钮 (圆形)
local toggleBtn = Instance.new("ImageButton")
toggleBtn.Name = "QuestToggle"
toggleBtn.Size = UDim2.new(0, 60, 0, 60)
-- 位置：贴左边 (X=0)，背包按钮(0.4)的下方 (Y=0.55)
toggleBtn.Position = UDim2.new(0, 10, 0.55, 0)
toggleBtn.AnchorPoint = Vector2.new(0, 0.5)
toggleBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
toggleBtn.BackgroundTransparency = 0.4
-- 任务图标 (卷轴/感叹号)
toggleBtn.Image = "rbxassetid://84218746173192" 
toggleBtn.Parent = screenGui

-- 变成圆形
local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(1, 0)
btnCorner.Parent = toggleBtn

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(255, 215, 0)
stroke.Thickness = 2
stroke.Parent = toggleBtn

-- 状态图标 (用来显示 ! 或 <)
local statusIcon = Instance.new("TextLabel")
statusIcon.Size = UDim2.new(0.5, 0, 0.5, 0)
statusIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
statusIcon.AnchorPoint = Vector2.new(0.5, 0.5)
statusIcon.BackgroundTransparency = 1
statusIcon.Text = "!" 
statusIcon.TextColor3 = Color3.fromRGB(255, 215, 0)
statusIcon.Font = Enum.Font.FredokaOne
statusIcon.TextSize = 32
statusIcon.Parent = toggleBtn


-- B. 任务详情窗口 (默认隐藏)
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 220, 0, 130)
-- 位于按钮右侧 (X偏移 80px), 垂直对齐按钮
mainFrame.Position = UDim2.new(0, 80, 0.55, 0) 
mainFrame.AnchorPoint = Vector2.new(0, 0.5)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
mainFrame.BackgroundTransparency = 0.2
mainFrame.Visible = false
mainFrame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = mainFrame

local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "Title"
titleLabel.Size = UDim2.new(1, -10, 0, 25)
titleLabel.Position = UDim2.new(0, 10, 0, 10)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "CURRENT QUEST"
titleLabel.Font = Enum.Font.FredokaOne
titleLabel.TextSize = 16
titleLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = mainFrame

local taskNameLabel = Instance.new("TextLabel")
taskNameLabel.Name = "TaskName"
taskNameLabel.Size = UDim2.new(1, -20, 0, 25)
taskNameLabel.Position = UDim2.new(0, 10, 0, 35)
taskNameLabel.BackgroundTransparency = 1
taskNameLabel.Text = "No Active Quest"
taskNameLabel.Font = Enum.Font.SourceSansBold
taskNameLabel.TextSize = 18
taskNameLabel.TextColor3 = Color3.new(1, 1, 1)
taskNameLabel.TextXAlignment = Enum.TextXAlignment.Left
taskNameLabel.TextWrapped = true
taskNameLabel.Parent = mainFrame

local progressLabel = Instance.new("TextLabel")
progressLabel.Name = "Progress"
progressLabel.Size = UDim2.new(1, -20, 0, 25)
progressLabel.Position = UDim2.new(0, 10, 0, 80)
progressLabel.BackgroundTransparency = 1
progressLabel.Text = "- / -"
progressLabel.Font = Enum.Font.SourceSans
progressLabel.TextSize = 16
progressLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
progressLabel.TextXAlignment = Enum.TextXAlignment.Left
progressLabel.Parent = mainFrame

-- ==========================================
-- 2. 交互逻辑
-- ==========================================
local isExpanded = false

toggleBtn.MouseButton1Click:Connect(function()
	isExpanded = not isExpanded

	if isExpanded then
		-- 展开
		mainFrame.Visible = true
		mainFrame.Size = UDim2.new(0, 0, 0, 130)
		mainFrame.BackgroundTransparency = 1

		TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = UDim2.new(0, 220, 0, 130),
			BackgroundTransparency = 0.2
		}):Play()
		statusIcon.Text = "<" 
	else
		-- 折叠
		local tween = TweenService:Create(mainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Size = UDim2.new(0, 0, 0, 130),
			BackgroundTransparency = 1
		})
		tween:Play()
		tween.Completed:Connect(function()
			if not isExpanded then mainFrame.Visible = false end
		end)
		statusIcon.Text = "!" 
	end
end)

-- ==========================================
-- 3. 数据监听
-- ==========================================
local function updateQuestDisplay()
	local hiddenStats = player:FindFirstChild("HiddenStats")
	if not hiddenStats then return end

	local currentQuestId = nil
	local currentProgress = 0

	for _, child in pairs(hiddenStats:GetChildren()) do
		if string.sub(child.Name, 1, 6) == "Quest_" then
			currentQuestId = child.Name
			currentProgress = child.Value
			break
		end
	end

	if currentQuestId then
		local questInfo = GameConfig.Quests and GameConfig.Quests[currentQuestId]

		if questInfo then
			taskNameLabel.Text = questInfo.Title or currentQuestId
			progressLabel.Text = string.format("Progress: %d / %d", currentProgress, questInfo.TargetAmount or 10)

			if currentProgress >= (questInfo.TargetAmount or 10) then
				progressLabel.TextColor3 = Color3.fromRGB(0, 255, 100)
				progressLabel.Text = "COMPLETED!"
				stroke.Color = Color3.fromRGB(0, 255, 0) -- 边框变绿
				if not isExpanded then
					-- 简单的跳动提醒
					toggleBtn.Size = UDim2.new(0, 70, 0, 70)
					TweenService:Create(toggleBtn, TweenInfo.new(0.5, Enum.EasingStyle.Bounce), {Size = UDim2.new(0, 60, 0, 60)}):Play()
				end
			else
				progressLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
				stroke.Color = Color3.fromRGB(255, 215, 0) -- 边框金色
			end
			toggleBtn.Visible = true
		else
			taskNameLabel.Text = "Unknown Quest"
		end
	else
		taskNameLabel.Text = "No Active Quest"
		progressLabel.Text = ""
		stroke.Color = Color3.fromRGB(150, 150, 150)
		-- 无任务时，如果不想显示按钮，可以设为 false
		-- toggleBtn.Visible = false 
	end
end

local function setupHiddenStats()
	local hs = player:WaitForChild("HiddenStats", 10)
	if hs then
		hs.ChildAdded:Connect(updateQuestDisplay)
		hs.ChildRemoved:Connect(updateQuestDisplay)
		for _, c in pairs(hs:GetChildren()) do
			c.Changed:Connect(updateQuestDisplay)
		end
		updateQuestDisplay()
	end
end
setupHiddenStats()