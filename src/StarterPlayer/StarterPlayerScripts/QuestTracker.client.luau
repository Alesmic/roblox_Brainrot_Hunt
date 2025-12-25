local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

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

-- A. 按钮
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

-- B. 主面板
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

-- C. 通关弹窗 (Victory Popup)
local victoryFrame = Instance.new("Frame")
victoryFrame.Name = "VictoryFrame"
victoryFrame.Size = UDim2.new(0, 400, 0, 200)
victoryFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
victoryFrame.AnchorPoint = Vector2.new(0.5, 0.5)
victoryFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
victoryFrame.BackgroundTransparency = 0.1
victoryFrame.Visible = false -- 默认隐藏
victoryFrame.Parent = screenGui

local vCorner = Instance.new("UICorner")
vCorner.CornerRadius = UDim.new(0, 16)
vCorner.Parent = victoryFrame

local vStroke = Instance.new("UIStroke")
vStroke.Color = Color3.fromRGB(255, 215, 0)
vStroke.Thickness = 3
vStroke.Parent = victoryFrame

local vTitle = Instance.new("TextLabel")
vTitle.Size = UDim2.new(1, 0, 0.5, 0)
vTitle.Position = UDim2.new(0, 0, 0.1, 0)
vTitle.BackgroundTransparency = 1
vTitle.Text = "Level complete!"
vTitle.Font = Enum.Font.FredokaOne
vTitle.TextSize = 48
vTitle.TextColor3 = Color3.fromRGB(255, 215, 0)
vTitle.Parent = victoryFrame

local vSub = Instance.new("TextLabel")
vSub.Size = UDim2.new(1, 0, 0.2, 0)
vSub.Position = UDim2.new(0, 0, 0.5, 0)
vSub.BackgroundTransparency = 1
vSub.Text = "Thanks for playing"
vSub.Font = Enum.Font.SourceSansBold
vSub.TextSize = 24
vSub.TextColor3 = Color3.fromRGB(255, 255, 255)
vSub.Parent = victoryFrame

-- [新增] 关闭按钮
local closeBtn = Instance.new("TextButton")
closeBtn.Name = "CloseButton"
closeBtn.Size = UDim2.new(0, 120, 0, 35)
closeBtn.Position = UDim2.new(0.5, 0, 0.8, 0)
closeBtn.AnchorPoint = Vector2.new(0.5, 0.5)
closeBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
closeBtn.Text = "Close"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Font = Enum.Font.FredokaOne
closeBtn.TextSize = 20
closeBtn.Parent = victoryFrame

local cCorner = Instance.new("UICorner")
cCorner.CornerRadius = UDim.new(0, 8)
cCorner.Parent = closeBtn

local cStroke = Instance.new("UIStroke")
cStroke.Color = Color3.fromRGB(255, 215, 0)
cStroke.Thickness = 2
cStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
cStroke.Parent = closeBtn

-- 关闭按钮事件
closeBtn.MouseButton1Click:Connect(function()
	victoryFrame.Visible = false
end)

-- ==========================================
-- 2. 交互逻辑
-- ==========================================
local isExpanded = false

local function autoExpand()
	if not isExpanded then
		isExpanded = true
		mainFrame.Visible = true
		mainFrame.Size = UDim2.new(0, 0, 0, 130)
		mainFrame.BackgroundTransparency = 1
		TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = UDim2.new(0, 220, 0, 130), BackgroundTransparency = 0.2
		}):Play()
		statusIcon.Text = "<" 
	end
end

toggleBtn.MouseButton1Click:Connect(function()
	isExpanded = not isExpanded
	if isExpanded then
		mainFrame.Visible = true
		mainFrame.Size = UDim2.new(0, 0, 0, 130)
		mainFrame.BackgroundTransparency = 1
		TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = UDim2.new(0, 220, 0, 130), BackgroundTransparency = 0.2
		}):Play()
		statusIcon.Text = "<" 
	else
		local tween = TweenService:Create(mainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Size = UDim2.new(0, 0, 0, 130), BackgroundTransparency = 1
		})
		tween:Play()
		tween.Completed:Connect(function() if not isExpanded then mainFrame.Visible = false end end)
		statusIcon.Text = "!" 
	end
end)

-- ==========================================
-- 3. 光束指引系统
-- ==========================================
local currentBeam = nil
local targetAttachment = nil
local guidanceLoop = nil

local reachedTargets = {
	["Task1"] = false, 
	["Task2"] = false,
	["Task3"] = false,          -- 新增 Task3
	["SaharanMaster"] = false, 
	["WolfBoss"] = false,       -- 新增 WolfBoss
	["DesertKing"] = false      -- 新增 DesertKing
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

	if currentBeam and targetAttachment and (targetAttachment.WorldPosition - position).Magnitude < 1 then return end
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
	if guidanceLoop then guidanceLoop:Disconnect() guidanceLoop = nil end
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

		if not currentBeam or not currentBeam.Parent then showGuideTo(targetPos) end
		if (root.Position - targetPos).Magnitude < 15 then 
			reachedTargets[targetKey] = true 
			stopGuidanceLoop()
			clearGuide()
		end
	end)
end

-- ==========================================
-- 4. 任务逻辑处理
-- ==========================================

local newbieQuestCompleteTime = nil 
local bossQuestCompleteTime = nil
local wolfQuestCompleteTime = nil

-- 模块 1: 新手任务 (Kill 10 Samurai)
local function processNewbieQuest(hiddenStats)
	local newbieQuest = hiddenStats:FindFirstChild("Quest_SamuraiSlayer")
	if not newbieQuest then return false end 

	local currentVal = newbieQuest.Value
	local targetVal = 10

	if currentVal < targetVal then
		taskNameLabel.Text = "Kill 10 Samurai"
		progressLabel.Text = "Kills: " .. currentVal .. " / " .. targetVal
		progressLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
		stroke.Color = Color3.fromRGB(255, 215, 0)
		toggleBtn.Visible = true

		local targetPart = workspace:FindFirstChild("task1")
		if targetPart and not reachedTargets["Task1"] then startGuidanceLoop(targetPart.Position, "Task1")
		else stopGuidanceLoop() clearGuide() end

		newbieQuestCompleteTime = nil
		return true 
	end

	if currentVal >= targetVal then
		if newbieQuestCompleteTime == nil then newbieQuestCompleteTime = os.clock() autoExpand() end
		if os.clock() - newbieQuestCompleteTime < 3 then
			taskNameLabel.Text = "Kill 10 Samurai"
			progressLabel.Text = "COMPLETED!"
			progressLabel.TextColor3 = Color3.fromRGB(0, 255, 100)
			stroke.Color = Color3.fromRGB(0, 255, 0)
			toggleBtn.Visible = true
			stopGuidanceLoop() clearGuide()
			return true 
		end
	end
	return false 
end

-- 模块 2: Saharan Master (Level 20 -> Kill Boss)
local function processSaharanMasterQuest(currentLevel, hiddenStats)
	local newbieQuest = hiddenStats:FindFirstChild("Quest_SamuraiSlayer")
	if not newbieQuest or newbieQuest.Value < 10 then return false end

	local bossQuest = hiddenStats:FindFirstChild("Quest_KillDesertBoss")
	local isBossDefeated = (bossQuest and bossQuest.Value >= 1) or false

	if isBossDefeated then
		if bossQuestCompleteTime == nil then bossQuestCompleteTime = os.clock() autoExpand() end
		if os.clock() - bossQuestCompleteTime < 3 then
			taskNameLabel.Text = "Defeat Saharan Master"
			progressLabel.Text = "COMPLETED!"
			progressLabel.TextColor3 = Color3.fromRGB(0, 255, 100)
			stroke.Color = Color3.fromRGB(0, 255, 0)
			toggleBtn.Visible = true
			stopGuidanceLoop() clearGuide()
			return true 
		end
		return false 
	end

	bossQuestCompleteTime = nil
	if currentLevel < 20 then
		taskNameLabel.Text = "Reach Level 20"
		progressLabel.Text = "Level: " .. currentLevel .. " / 20"
		progressLabel.TextColor3 = Color3.fromRGB(255, 170, 0) 
		stroke.Color = Color3.fromRGB(255, 170, 0)
		toggleBtn.Visible = true
		stopGuidanceLoop() clearGuide()
	else
		taskNameLabel.Text = "Defeat Saharan Master"
		progressLabel.Text = "Go to the Desert Arena!"
		progressLabel.TextColor3 = Color3.fromRGB(255, 80, 80) 
		stroke.Color = Color3.fromRGB(255, 80, 80)
		toggleBtn.Visible = true

		local bossArea = workspace:FindFirstChild("Boss Area") 
		local bossTrigger = bossArea and bossArea:FindFirstChild("BossTrigger") 
		if bossTrigger and bossTrigger:IsA("Folder") then bossTrigger = bossTrigger:FindFirstChild("BossTrigger") end 

		if bossTrigger and not reachedTargets["SaharanMaster"] then startGuidanceLoop(bossTrigger.Position, "SaharanMaster")
		else stopGuidanceLoop() clearGuide() end
	end
	return true 
end

-- 模块 3: 森林篇章 (Level 50 -> Kill Wolf Boss)
local function processForestArc(currentLevel, hiddenStats, isSaharanMasterDefeated)
	if not isSaharanMasterDefeated then return false end

	-- A. 检查 Wolf Boss 是否击败
	local wolfQuest = hiddenStats:FindFirstChild("Quest_KillWolfBoss")
	local isWolfDefeated = (wolfQuest and wolfQuest.Value >= 1) or false

	if isWolfDefeated then
		if wolfQuestCompleteTime == nil then wolfQuestCompleteTime = os.clock() autoExpand() end
		if os.clock() - wolfQuestCompleteTime < 3 then
			taskNameLabel.Text = "Defeat Wolf Boss"
			progressLabel.Text = "COMPLETED!"
			progressLabel.TextColor3 = Color3.fromRGB(0, 255, 100)
			stroke.Color = Color3.fromRGB(0, 255, 0)
			toggleBtn.Visible = true
			stopGuidanceLoop() clearGuide()
			return true 
		end
		return false -- 进入下一阶段
	end

	wolfQuestCompleteTime = nil

	-- B. 如果未击败 Wolf Boss，检查等级
	if currentLevel < 50 then
		-- 阶段 1: 升级到 50
		taskNameLabel.Text = "Enter Forest & Reach Level 50"
		progressLabel.Text = "Level: " .. currentLevel .. " / 50"
		progressLabel.TextColor3 = Color3.fromRGB(0, 255, 255) -- 青色
		stroke.Color = Color3.fromRGB(0, 255, 255)
		toggleBtn.Visible = true

		local targetPart = workspace:FindFirstChild("task2")
		if targetPart and not reachedTargets["Task2"] then startGuidanceLoop(targetPart.Position, "Task2")
		else stopGuidanceLoop() clearGuide() end
	else
		-- 阶段 2: 击败 Wolf Boss
		taskNameLabel.Text = "Defeat Wolf Boss"
		progressLabel.Text = "Go to Forest Boss Area!"
		progressLabel.TextColor3 = Color3.fromRGB(255, 50, 50) -- 深红
		stroke.Color = Color3.fromRGB(255, 50, 50)
		toggleBtn.Visible = true

		local bossArea = workspace:FindFirstChild("Forest Boss Area")
		local targetPart = nil

		if bossArea then
			local barrier = bossArea:FindFirstChild("BossBarrier")
			if barrier and barrier:IsA("BasePart") then
				targetPart = barrier
			elseif barrier and barrier:IsA("Model") and barrier.PrimaryPart then
				targetPart = barrier.PrimaryPart
			end
		end

		if targetPart and not reachedTargets["WolfBoss"] then 
			startGuidanceLoop(targetPart.Position, "WolfBoss")
		else 
			stopGuidanceLoop() 
			clearGuide() 
		end
	end
	return true
end

-- 模块 4: 终局篇章 (Level 99 -> Desert King)
local cachedTask3 = nil 

local function processEndgameArc(currentLevel, hiddenStats, isWolfDefeated)
	if not isWolfDefeated then return false end

	local kingQuest = hiddenStats:FindFirstChild("Quest_KillDesertKing")
	local isKingDefeated = (kingQuest and kingQuest.Value >= 1) or false

	-- 1. 击败 Boss 后显示通关弹窗
	if isKingDefeated then
		if not victoryFrame.Visible and not reachedTargets["GameClear"] then
			victoryFrame.Visible = true
			reachedTargets["GameClear"] = true 
		end

		taskNameLabel.Text = "Game Cleared"
		progressLabel.Text = "You are the Champion!"
		progressLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
		stroke.Color = Color3.fromRGB(255, 215, 0)
		toggleBtn.Visible = true

		stopGuidanceLoop() 
		clearGuide()
		return true
	end

	-- 辅助函数：静默获取位置
	local function getTargetPos()
		-- 1. 优先读缓存
		if cachedTask3 and cachedTask3.Parent then
			if cachedTask3:IsA("BasePart") then return cachedTask3.Position end
			if cachedTask3:IsA("Model") then return cachedTask3:GetPivot().Position end
		end

		-- 2. 尝试查找 (区分大小写 + 0.1秒缓冲)
		local obj = workspace:FindFirstChild("task3") or workspace:FindFirstChild("Task3")

		-- 3. 如果不在根目录，尝试在 Boss 区域找备用点
		if not obj then
			local bossArea = workspace:FindFirstChild("Desert Boss Area")
			if bossArea then
				obj = bossArea:FindFirstChild("BossBarrier") or bossArea
			end
		end

		-- 4. 结果处理
		if obj then
			cachedTask3 = obj -- 存入缓存
			if obj:IsA("BasePart") then return obj.Position end
			if obj:IsA("Model") then return obj:GetPivot().Position end
		else
			-- [修改] 找不到时不报错，返回 nil，静默等待流式加载载入
			return nil
		end
		return nil
	end

	local targetPos = getTargetPos()

	-- 2. 未满 99 级
	if currentLevel < 99 then
		taskNameLabel.Text = "Reach Level 99"
		progressLabel.Text = "Level: " .. currentLevel .. " / 99"
		progressLabel.TextColor3 = Color3.fromRGB(170, 0, 255) 
		stroke.Color = Color3.fromRGB(170, 0, 255)
		toggleBtn.Visible = true

		-- [新增] 哪怕是指引到task3，如果未满级也需要task3的位置来显示光束(如果设计需要的话)
		-- 但根据需求，未满级不显示指引：
		stopGuidanceLoop() 
		clearGuide() 
	else
		-- 3. 达到 99 级：开启指引
		taskNameLabel.Text = "Challenge Desert King"
		progressLabel.Text = "Defeat the Final Boss!"
		progressLabel.TextColor3 = Color3.fromRGB(255, 0, 0) 
		stroke.Color = Color3.fromRGB(255, 0, 0)
		toggleBtn.Visible = true

		if targetPos and not reachedTargets["DesertKing"] then 
			startGuidanceLoop(targetPos, "DesertKing")
		else 
			-- 如果 targetPos 为 nil (还没加载出来)，就暂停指引，不报错
			stopGuidanceLoop() 
			clearGuide() 
		end
	end
	return true
end
-- ==========================================
-- 5. 数据监听与刷新
-- ==========================================
local function updateQuestDisplay()
	local leaderstats = player:FindFirstChild("leaderstats")
	local hiddenStats = player:FindFirstChild("HiddenStats")
	if not leaderstats or not hiddenStats then return end

	local levelStat = leaderstats:FindFirstChild("Level")
	local currentLevel = levelStat and levelStat.Value or 1

	-- 状态预判 (nil 视为 false)
	local bossQuest = hiddenStats:FindFirstChild("Quest_KillDesertBoss")
	local isSaharanMasterDefeated = (bossQuest and bossQuest.Value >= 1) or false

	local wolfQuest = hiddenStats:FindFirstChild("Quest_KillWolfBoss")
	local isWolfDefeated = (wolfQuest and wolfQuest.Value >= 1) or false

	-- 1. 新手任务
	if processNewbieQuest(hiddenStats) then return end

	-- 2. Saharan Master 任务
	if processSaharanMasterQuest(currentLevel, hiddenStats) then return end

	-- 3. 森林篇章 (50级 & Wolf Boss)
	if processForestArc(currentLevel, hiddenStats, isSaharanMasterDefeated) then return end

	-- 4. 终局篇章 (99级 & Desert King)
	if processEndgameArc(currentLevel, hiddenStats, isWolfDefeated) then return end

	-- 5. 常规任务
	stopGuidanceLoop()
	clearGuide()
	taskNameLabel.Text = "No Active Quest"
	progressLabel.Text = ""
	stroke.Color = Color3.fromRGB(150, 150, 150)
end

local function setupHiddenStats()
	local hs = player:WaitForChild("HiddenStats", 10)
	if hs then
		hs.ChildAdded:Connect(function(child) child.Changed:Connect(updateQuestDisplay) updateQuestDisplay() end)
		hs.ChildRemoved:Connect(updateQuestDisplay)
		for _, c in pairs(hs:GetChildren()) do c.Changed:Connect(updateQuestDisplay) end

		local leaderstats = player:WaitForChild("leaderstats", 10)
		if leaderstats then
			local level = leaderstats:WaitForChild("Level", 10)
			if level then level.Changed:Connect(updateQuestDisplay) end
		end

		RunService.Heartbeat:Connect(function()
			-- [修改] 增加了检测条件：如果正处于 99级任务阶段 但还没找到路标(reachedTargets["DesertKing"]为false)，
			-- 也要保持刷新，以便 task3 一加载出来就能捕捉到。
			local leaderstats = player:FindFirstChild("leaderstats")
			local level = leaderstats and leaderstats:FindFirstChild("Level")
			local currentLevel = level and level.Value or 1

			if newbieQuestCompleteTime 
				or bossQuestCompleteTime 
				or wolfQuestCompleteTime 
				or (currentLevel >= 99 and not reachedTargets["DesertKing"]) -- 新增这一行
			then
				updateQuestDisplay()
			end
		end)
		updateQuestDisplay()
	end
end

setupHiddenStats()

setupHiddenStats()