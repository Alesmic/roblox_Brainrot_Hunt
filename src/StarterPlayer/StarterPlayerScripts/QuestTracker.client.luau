local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

-- ==========================================
-- 1. UI 创建 (保持不变)
-- ==========================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "QuestTrackerUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui
screenGui.DisplayOrder = -10

-- A. 任务折叠/展开按钮
local toggleBtn = Instance.new("ImageButton")
toggleBtn.Name = "QuestToggle"
toggleBtn.Size = UDim2.new(0, 40, 0, 40)
toggleBtn.Position = UDim2.new(0, 10, 0.55, 0)
toggleBtn.AnchorPoint = Vector2.new(0, 0.5)
toggleBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
toggleBtn.BackgroundTransparency = 0.4
toggleBtn.Image = "rbxassetid://84218746173192" 
toggleBtn.Parent = screenGui

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(1, 0)
btnCorner.Parent = toggleBtn

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(74, 74, 74)
stroke.Thickness = 2
stroke.Parent = toggleBtn

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

-- B. 任务详情窗口
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 220, 0, 130)
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
taskNameLabel.Size = UDim2.new(1, -20, 0, 45)
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
progressLabel.Position = UDim2.new(0, 10, 0, 85)
progressLabel.BackgroundTransparency = 1
progressLabel.Text = "- / -"
progressLabel.Font = Enum.Font.SourceSans
progressLabel.TextSize = 16
progressLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
progressLabel.TextXAlignment = Enum.TextXAlignment.Left
progressLabel.Parent = mainFrame

-- ==========================================
-- 2. 交互逻辑 (保持不变)
-- ==========================================
local isExpanded = false

toggleBtn.MouseButton1Click:Connect(function()
	isExpanded = not isExpanded

	if isExpanded then
		mainFrame.Visible = true
		mainFrame.Size = UDim2.new(0, 0, 0, 130)
		mainFrame.BackgroundTransparency = 1

		TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = UDim2.new(0, 220, 0, 130),
			BackgroundTransparency = 0.2
		}):Play()
		statusIcon.Text = "<" 
	else
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
-- 3. 光束指引系统 (含状态管理)
-- ==========================================
local currentBeam = nil
local targetAttachment = nil
local guidanceLoop = nil

-- 到达状态记录表
local reachedTargets = {
	["Task2"] = false,          -- 森林练级点
	["SaharanMaster"] = false   -- 20级Boss点
}

local function clearGuide()
	if currentBeam then currentBeam:Destroy() currentBeam = nil end
	if targetAttachment then targetAttachment:Destroy() targetAttachment = nil end
end

local function showGuideTo(position)
	local character = player.Character
	if not character then return end
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then return end

	if currentBeam and targetAttachment and (targetAttachment.WorldPosition - position).Magnitude < 1 then
		return
	end

	clearGuide() 

	targetAttachment = Instance.new("Attachment")
	targetAttachment.Name = "QuestTargetAtt"
	targetAttachment.WorldPosition = position
	targetAttachment.Parent = workspace.Terrain

	local rootAtt = root:FindFirstChild("RootRigAttachment") or Instance.new("Attachment", root)

	currentBeam = Instance.new("Beam")
	currentBeam.Texture = "rbxassetid://446111271" 
	currentBeam.TextureMode = Enum.TextureMode.Wrap
	currentBeam.TextureLength = 10
	currentBeam.TextureSpeed = 2
	currentBeam.FaceCamera = true
	currentBeam.Width0 = 1.5
	currentBeam.Width1 = 1.5
	currentBeam.Attachment0 = rootAtt
	currentBeam.Attachment1 = targetAttachment
	currentBeam.Color = ColorSequence.new(Color3.fromRGB(255, 215, 0))
	currentBeam.Parent = root
end

local function stopGuidanceLoop()
	if guidanceLoop then
		guidanceLoop:Disconnect()
		guidanceLoop = nil
	end
end

local function startGuidanceLoop(targetPos, targetKey)
	if guidanceLoop then return end 
	if reachedTargets[targetKey] == true then return end 

	showGuideTo(targetPos)

	guidanceLoop = RunService.Heartbeat:Connect(function()
		local character = player.Character
		if not character then return end
		local root = character:FindFirstChild("HumanoidRootPart")
		if not root then return end

		if not currentBeam or not currentBeam.Parent then
			showGuideTo(targetPos)
		end

		local dist = (root.Position - targetPos).Magnitude

		if dist < 15 then 
			reachedTargets[targetKey] = true -- 标记已到达
			stopGuidanceLoop()
			clearGuide()
		end
	end)
end

-- ==========================================
-- 4. [模块化] 任务逻辑处理
-- ==========================================

-- 模块 1: 森林练级任务 (Level < 20)
local function processForestGrindQuest(isNewbieDone, currentLevel)
	-- 条件：新手任务完成 且 等级 < 20
	if isNewbieDone and currentLevel < 20 then
		taskNameLabel.Text = "Grind in the Forest to reach Level 20 and challenge the Saharan Master!"
		progressLabel.Text = "Level: " .. currentLevel .. " / 20"
		progressLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
		stroke.Color = Color3.fromRGB(255, 215, 0)
		toggleBtn.Visible = true

		-- 指引逻辑
		local targetPart = workspace:FindFirstChild("task2")
		if targetPart and not reachedTargets["Task2"] then
			startGuidanceLoop(targetPart.Position, "Task2")
		else
			stopGuidanceLoop()
			clearGuide()
		end

		return true -- 任务激活
	end
	return false -- 任务未激活
end

-- 模块 2: Saharan Master 挑战任务 (Level >= 20)
local function processSaharanMasterQuest(isNewbieDone, currentLevel, hiddenStats)
	-- 条件：新手任务完成 且 等级 >= 20
	if isNewbieDone and currentLevel >= 20 then
		local bossQuest = hiddenStats:FindFirstChild("Quest_KillDesertBoss")
		local isBossDefeated = (bossQuest and bossQuest.Value >= 1)

		-- 如果还没打赢 Boss
		if not isBossDefeated then
			taskNameLabel.Text = "Defeat Saharan Master"
			progressLabel.Text = "Target: Saharan Master"
			progressLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
			stroke.Color = Color3.fromRGB(255, 80, 80)
			toggleBtn.Visible = true

			-- 指引逻辑
			local bossArea = workspace:FindFirstChild("Boss Area") 
			local bossTrigger = bossArea and bossArea:FindFirstChild("BossTrigger") 
			if bossTrigger and bossTrigger:IsA("Folder") then bossTrigger = bossTrigger:FindFirstChild("BossTrigger") end 

			if bossTrigger and not reachedTargets["SaharanMaster"] then
				startGuidanceLoop(bossTrigger.Position, "SaharanMaster")
			else
				stopGuidanceLoop()
				clearGuide()
			end

			return true -- 任务激活
		end
	end
	return false -- 任务未激活
end

-- ==========================================
-- 5. 数据监听与刷新
-- ==========================================
local function updateQuestDisplay()
	local leaderstats = player:FindFirstChild("leaderstats")
	local hiddenStats = player:FindFirstChild("HiddenStats")

	if not leaderstats or not hiddenStats then return end

	-- 准备公共数据
	local newbieQuest = hiddenStats:FindFirstChild("Quest_SamuraiSlayer")
	local isNewbieDone = (newbieQuest and newbieQuest.Value >= 10)
	local levelStat = leaderstats:FindFirstChild("Level")
	local currentLevel = levelStat and levelStat.Value or 1

	-- [执行模块检查] 优先级从上到下

	-- 1. 检查森林练级任务
	if processForestGrindQuest(isNewbieDone, currentLevel) then
		return 
	end

	-- 2. 检查 Boss 挑战任务
	if processSaharanMasterQuest(isNewbieDone, currentLevel, hiddenStats) then
		return
	end

	-- 3. 如果没有特殊任务激活，清理指引并检查常规任务
	stopGuidanceLoop()
	clearGuide()

	-- --- 常规任务检查逻辑 ---
	local currentQuestId = nil
	local currentProgress = 0

	for _, child in pairs(hiddenStats:GetChildren()) do
		if string.sub(child.Name, 1, 6) == "Quest_" then
			-- 过滤掉已经作为特殊任务处理过的任务 ID
			if child.Name ~= "Quest_SamuraiSlayer" and child.Name ~= "Quest_KillDesertBoss" then
				currentQuestId = child.Name
				currentProgress = child.Value
				break
			end
		end
	end

	if currentQuestId then
		local questKey = string.sub(currentQuestId, 7) 
		local questInfo = GameConfig.Quests and GameConfig.Quests[questKey]

		if questInfo then
			taskNameLabel.Text = questInfo.Name or questKey 
			local target = questInfo.TargetCount or 1
			progressLabel.Text = string.format("Progress: %d / %d", currentProgress, target)

			if currentProgress >= target then
				progressLabel.TextColor3 = Color3.fromRGB(0, 255, 100)
				progressLabel.Text = "COMPLETED!"
				stroke.Color = Color3.fromRGB(0, 255, 0)
				if not isExpanded then
					toggleBtn.Size = UDim2.new(0, 70, 0, 70)
					TweenService:Create(toggleBtn, TweenInfo.new(0.5, Enum.EasingStyle.Bounce), {Size = UDim2.new(0, 60, 0, 60)}):Play()
				end
			else
				progressLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
				stroke.Color = Color3.fromRGB(255, 215, 0)
			end
			toggleBtn.Visible = true
		else
			taskNameLabel.Text = currentQuestId
			progressLabel.Text = "Progress: " .. currentProgress
		end
	else
		taskNameLabel.Text = "No Active Quest"
		progressLabel.Text = ""
		stroke.Color = Color3.fromRGB(150, 150, 150)
	end
end

local function setupHiddenStats()
	local hs = player:WaitForChild("HiddenStats", 10)
	if hs then
		hs.ChildAdded:Connect(function(child)
			child.Changed:Connect(updateQuestDisplay)
			updateQuestDisplay()
		end)

		hs.ChildRemoved:Connect(updateQuestDisplay)

		for _, c in pairs(hs:GetChildren()) do
			c.Changed:Connect(updateQuestDisplay)
		end

		local leaderstats = player:WaitForChild("leaderstats", 10)
		if leaderstats then
			local level = leaderstats:WaitForChild("Level", 10)
			if level then
				level.Changed:Connect(updateQuestDisplay)
			end
		end

		updateQuestDisplay()
	end
end

setupHiddenStats()