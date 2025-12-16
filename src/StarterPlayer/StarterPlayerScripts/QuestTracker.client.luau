local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local PathfindingService = game:GetService("PathfindingService") -- 引入寻路服务

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local hiddenStats = player:WaitForChild("HiddenStats")

-- 引入配置
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
-- 获取箭头原型
local protoArrow = ReplicatedStorage:WaitForChild("PathArrowProto")

print("✅ [QuestTracker] 任务追踪器(寻路版) 已启动...")

-- ==========================================
-- 1. UI 生成 (保持不变)
-- ==========================================
local screenGui = playerGui:FindFirstChild("QuestTrackerGui")
if not screenGui then
	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "QuestTrackerGui"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui
end

if screenGui:FindFirstChild("TrackerFrame") then screenGui.TrackerFrame:Destroy() end

local trackerFrame = Instance.new("Frame")
trackerFrame.Name = "TrackerFrame"
trackerFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
trackerFrame.BorderSizePixel = 0
trackerFrame.AnchorPoint = Vector2.new(1, 1) 
trackerFrame.Position = UDim2.new(1, -20, 1, -20)
trackerFrame.Size = UDim2.new(0, 220, 0, 80)
trackerFrame.Visible = false 
trackerFrame.Parent = screenGui

local line = Instance.new("Frame")
line.Size = UDim2.new(0, 4, 1, 0)
line.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
line.Parent = trackerFrame

local titleLabel = Instance.new("TextLabel")
titleLabel.Text = "CURRENT QUEST"
titleLabel.Font = Enum.Font.FredokaOne
titleLabel.TextSize = 16
titleLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Size = UDim2.new(1, -15, 0.4, 0)
titleLabel.Position = UDim2.new(0, 15, 0, 0)
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = trackerFrame

local contentLabel = Instance.new("TextLabel")
contentLabel.Text = "Loading..."
contentLabel.Font = Enum.Font.SourceSansBold
contentLabel.TextSize = 18
contentLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
contentLabel.BackgroundTransparency = 1
contentLabel.Size = UDim2.new(1, -15, 0.6, 0)
contentLabel.Position = UDim2.new(0, 15, 0.4, 0)
contentLabel.TextXAlignment = Enum.TextXAlignment.Left
contentLabel.Parent = trackerFrame

-- ==========================================
-- 2. 动态寻路导航系统 (核心升级)
-- ==========================================
local currentTargetPos = nil
local pathArrowsFolder = nil -- 用于存放生成的箭头
local lastPathUpdateTime = 0
local PATH_UPDATE_INTERVAL = 0.5 -- 每0.5秒更新一次路径，防止卡顿

-- 初始化或清理箭头文件夹
local function getArrowFolder()
	if not pathArrowsFolder or not pathArrowsFolder.Parent then
		pathArrowsFolder = Instance.new("Folder")
		pathArrowsFolder.Name = "QuestPathVisuals_Local"
		pathArrowsFolder.Parent = workspace
	end
	return pathArrowsFolder
end

-- 清理所有箭头
local function clearArrows()
	if pathArrowsFolder then
		pathArrowsFolder:ClearAllChildren()
	end
end

-- 核心：计算并绘制路径
local function drawPath()
	local now = tick()
	-- 节流控制：如果距离上次更新还没到时间，就跳过
	if now - lastPathUpdateTime < PATH_UPDATE_INTERVAL then return end
	lastPathUpdateTime = now

	-- 如果没有目标或玩家角色不存在，清理箭头并退出
	if not currentTargetPos or not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
		clearArrows()
		return
	end

	local rootPart = player.Character.HumanoidRootPart
	local folder = getArrowFolder()

	-- 1. 创建路径参数 (根据你的游戏角色大小调整)
	local path = PathfindingService:CreatePath({
		AgentRadius = 3,     -- 代理半径 (越大约容易避开障碍)
		AgentHeight = 5,     -- 代理高度
		AgentCanJump = true, -- 是否允许跳跃寻找路径
		WaypointSpacing = 4  -- 航点间距 (决定箭头的密度)
	})

	-- 2. 计算路径
	local success, errorMessage = pcall(function()
		path:ComputeAsync(rootPart.Position, currentTargetPos)
	end)

	if success and path.Status == Enum.PathStatus.Success then
		-- 计算成功，开始绘制
		folder:ClearAllChildren() -- 先清除旧的

		local waypoints = path:GetWaypoints()

		-- 从第2个航点开始遍历 (第1个是脚下，不需要)
		-- 步长为 2 (i = i + 2)，意味着每隔一个航点放一个箭头，避免太密集
		for i = 2, #waypoints, 2 do 
			local wp = waypoints[i]
			local nextWp = waypoints[i+1] -- 获取下一个航点用于确定朝向

			if wp.Action == Enum.PathWaypointAction.Walk then
				local arrow = protoArrow:Clone()
				-- 设置位置：在航点上方一点点，防止埋地里
				local pos = wp.Position + Vector3.new(0, 0.3, 0)

				-- 设置朝向
				if nextWp then
					-- 让箭头指向下一个航点，但保持水平 (忽略Y轴差异)
					local lookAtFlat = Vector3.new(nextWp.Position.X, pos.Y, nextWp.Position.Z)
					arrow.CFrame = CFrame.lookAt(pos, lookAtFlat)
				else
					-- 如果没有下一个航点 (已经是终点前最后一个)，指向最终目标
					local lookAtFlat = Vector3.new(currentTargetPos.X, pos.Y, currentTargetPos.Z)
					arrow.CFrame = CFrame.lookAt(pos, lookAtFlat)
				end

				arrow.Parent = folder
			end
		end
	else
		-- 寻路失败 (比如目标在墙里，或者太远)
		-- 可以在这里做一个简单的直线箭头作为后备，或者暂时清空
		clearArrows()
		-- warn("Pathfinding failed: " .. tostring(errorMessage)) 
	end
end

-- 绑定到心跳，但函数内部有节流控制
RunService.Heartbeat:Connect(drawPath)


-- ==========================================
-- 3. 任务更新逻辑 (适配新导航)
-- ==========================================

local function updateQuestUI(questName, currentVal)
	local realQuestID = string.gsub(questName, "Quest_", "")
	local config = GameConfig.Quests[realQuestID]

	if config then
		trackerFrame.Visible = true

		local val = tonumber(currentVal) or 0
		local target = tonumber(config.TargetCount) or 10

		-- [设置导航目标]
		if config.TargetPosition then
			currentTargetPos = config.TargetPosition
			-- 立即触发一次绘制，无需等待心跳
			lastPathUpdateTime = 0 
			drawPath()
		end

		if val >= target then
			-- 任务完成
			contentLabel.Text = "Challenge Success"
			contentLabel.TextColor3 = Color3.fromRGB(0, 255, 0)

			-- [关闭导航]
			currentTargetPos = nil
			clearArrows()

			task.wait(3)
			trackerFrame.Visible = false
		else
			-- 任务进行中
			contentLabel.Text = config.Name .. ": " .. val .. " / " .. target
			contentLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		end
	else
		warn("❌ [QuestTracker] 配置缺失: " .. realQuestID)
	end
end

local function trackQuestValue(questVal)
	updateQuestUI(questVal.Name, questVal.Value)
	questVal.Changed:Connect(function(newVal)
		updateQuestUI(questVal.Name, newVal)
	end)
end

-- 监听 HiddenStats
for _, child in pairs(hiddenStats:GetChildren()) do
	if string.sub(child.Name, 1, 6) == "Quest_" then
		trackQuestValue(child)
	end
end

hiddenStats.ChildAdded:Connect(function(child)
	if string.sub(child.Name, 1, 6) == "Quest_" then
		trackQuestValue(child)
	end
end)

-- 玩家重生时清理残留箭头
player.CharacterRemoving:Connect(function()
	clearArrows()
end)