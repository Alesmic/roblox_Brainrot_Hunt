local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

-- ==========================================
-- 1. 创建 UI (侧边栏 + 胜利大字)
-- ==========================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "QuestTrackerUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- A. 侧边栏 (任务追踪 - 保持原有风格但优化)
local trackerFrame = Instance.new("Frame")
trackerFrame.Name = "TrackerFrame"
trackerFrame.Size = UDim2.new(0, 220, 0, 100)
trackerFrame.Position = UDim2.new(1, -240, 0.4, 0) -- 屏幕右侧
trackerFrame.BackgroundTransparency = 0.5
trackerFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
trackerFrame.BorderSizePixel = 0
trackerFrame.Parent = screenGui
-- 给侧边栏加个圆角
local uiCorner = Instance.new("UICorner")
uiCorner.CornerRadius = UDim.new(0, 8)
uiCorner.Parent = trackerFrame

local trackerTitle = Instance.new("TextLabel")
trackerTitle.Size = UDim2.new(1, -10, 0, 25)
trackerTitle.Position = UDim2.new(0, 10, 0, 5)
trackerTitle.BackgroundTransparency = 1
trackerTitle.Text = "Current Quest"
trackerTitle.TextColor3 = Color3.new(1, 1, 1)
trackerTitle.Font = Enum.Font.GothamBold
trackerTitle.TextSize = 16
trackerTitle.TextXAlignment = Enum.TextXAlignment.Left
trackerTitle.Parent = trackerFrame

local questLabel = Instance.new("TextLabel")
questLabel.Name = "QuestText"
questLabel.Size = UDim2.new(1, -20, 1, -35)
questLabel.Position = UDim2.new(0, 10, 0, 30)
questLabel.BackgroundTransparency = 1
questLabel.Text = "Loading..."
questLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
questLabel.Font = Enum.Font.Gotham
questLabel.TextSize = 14
questLabel.TextWrapped = true
questLabel.TextXAlignment = Enum.TextXAlignment.Left
questLabel.TextYAlignment = Enum.TextYAlignment.Top
questLabel.Parent = trackerFrame

-- B. [新增] 胜利大字 UI (仿照 Boss 胜利)
local victoryLabel = Instance.new("TextLabel")
victoryLabel.Name = "QuestVictoryLabel"
victoryLabel.Size = UDim2.new(1, 0, 0.2, 0)
victoryLabel.Position = UDim2.new(0, 0, 0.3, 0) -- 屏幕中央偏上
victoryLabel.BackgroundTransparency = 1
victoryLabel.Text = "QUEST COMPLETED!"
victoryLabel.TextColor3 = Color3.fromRGB(255, 215, 0) -- 金色
victoryLabel.Font = Enum.Font.FredokaOne -- 卡通粗体，很醒目
victoryLabel.TextSize = 60
victoryLabel.TextStrokeTransparency = 0 -- 黑色描边
victoryLabel.TextStrokeColor3 = Color3.new(0,0,0)
victoryLabel.Visible = false -- 默认隐藏
victoryLabel.ZIndex = 10 -- 保证在最上层
victoryLabel.Parent = screenGui

-- ==========================================
-- 2. 逻辑处理
-- ==========================================
local completedQuestsCache = {} -- 缓存表：记录哪些任务已经弹过窗了

-- 显示大字动画函数
local function showVictoryAnimation(text)
	victoryLabel.Text = text
	victoryLabel.Visible = true
	victoryLabel.TextTransparency = 0
	victoryLabel.TextStrokeTransparency = 0
	victoryLabel.Position = UDim2.new(0, 0, 0.4, 0) -- 起始位置 (稍低一点)

	-- 1. 向上浮动 + 弹性进入
	local tweenIn = TweenService:Create(victoryLabel, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0, 0, 0.3, 0)
	})
	tweenIn:Play()

	-- 播放个简单的音效 (通用提示音)
	local sound = Instance.new("Sound", workspace)
	sound.SoundId = "rbxassetid://12221967" -- 欢呼/提示音效
	sound.Volume = 1
	sound:Play()
	task.delay(2, function() sound:Destroy() end)

	-- 2. 停留 3 秒后 -> 淡出 + 继续上浮
	task.delay(3, function()
		local tweenOut = TweenService:Create(victoryLabel, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			TextTransparency = 1,
			TextStrokeTransparency = 1,
			Position = UDim2.new(0, 0, 0.2, 0) 
		})
		tweenOut:Play()

		tweenOut.Completed:Connect(function()
			victoryLabel.Visible = false
		end)
	end)
end

-- 更新任务追踪器
local function updateQuestTracker()
	local hiddenStats = player:FindFirstChild("HiddenStats")
	if not hiddenStats then 
		questLabel.Text = "No data..."
		return 
	end

	local activeQuestText = "No active quests."
	local hasActive = false

	-- 遍历配置中的所有任务
	if GameConfig.Quests then
		for questID, questData in pairs(GameConfig.Quests) do
			local questStatName = "Quest_" .. questID
			local statValue = hiddenStats:FindFirstChild(questStatName)

			-- 如果玩家有这个任务的进度数据
			if statValue then
				local current = statValue.Value
				local target = questData.TargetCount

				-- 检查是否完成
				if current >= target then
					-- [关键] 如果是第一次检测到完成，就弹窗
					if not completedQuestsCache[questID] then
						completedQuestsCache[questID] = true
						print("🎉 Quest Completed: " .. questID)
						showVictoryAnimation("QUEST COMPLETED!")
					end
				else
					-- 如果还没完成，并且还没显示其他任务，就显示在这个侧边栏
					-- (如果你想显示所有任务，可以拼接字符串)
					if not hasActive then
						-- 只有没完成的任务才显示在侧边栏
						activeQuestText = string.format("%s\n\n🎯 Progress: %d / %d\n💰 Reward: %d Gold", 
							questData.Name or "Unknown Quest", 
							current, 
							target,
							questData.GoldReward or 0
						)
						hasActive = true
						-- 这里不return，继续循环，以免漏掉其他任务的完成检测
					end
					-- 标记这个任务未完成，防止以后重复弹窗逻辑出错
					completedQuestsCache[questID] = false 
				end
			end
		end
	end

	questLabel.Text = activeQuestText
end

-- ==========================================
-- 3. 启动监听
-- ==========================================
task.spawn(function()
	local hiddenStats = player:WaitForChild("HiddenStats", 10)
	if hiddenStats then
		print("✅ [QuestTracker] Connected to HiddenStats")

		-- 监听新任务添加
		hiddenStats.ChildAdded:Connect(function(child)
			if child:IsA("IntValue") then
				child.Changed:Connect(updateQuestTracker)
				updateQuestTracker()
			end
		end)

		-- 监听现有任务变化
		for _, child in pairs(hiddenStats:GetChildren()) do
			if child:IsA("IntValue") then
				child.Changed:Connect(updateQuestTracker)
			end
		end

		-- 初始刷新
		updateQuestTracker()
	else
		warn("❌ [QuestTracker] Could not find HiddenStats")
	end
end)