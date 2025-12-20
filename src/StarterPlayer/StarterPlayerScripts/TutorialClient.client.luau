local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local hiddenStats = player:WaitForChild("HiddenStats")

-- ==========================================
-- 1. 资源引用
-- ==========================================
-- 确保 NPC 名字和 Workspace 里的完全一致
local npcFolder = workspace:WaitForChild("NPCs") 
local npc = npcFolder:WaitForChild("Tung Tung Sahur") 
local rootPart = npc:WaitForChild("HumanoidRootPart")
local prompt = npc:WaitForChild("ProximityPrompt") 

-- 获取头部
local head = npc:WaitForChild("Head")

-- [核心修复] 准确获取 3D 感叹号部件 (QuestMarker/Union)
local questMarkerModel = head:WaitForChild("QuestMarker", 5) -- 等待最多5秒
local questUnion = nil

if questMarkerModel then
	questUnion = questMarkerModel:FindFirstChild("Union")
	if not questUnion then
		warn("⚠️ [TutorialClient] 找到了 QuestMarker 但没找到 Union，请检查命名！")
	end
else
	warn("⚠️ [TutorialClient] 在 Head 下没找到 QuestMarker 文件夹/模型")
end

-- 兼容旧逻辑：如果有名为 QuestIcon 的 BillboardGui 也获取一下
local guiIcon = head:FindFirstChild("QuestIcon") or head:FindFirstChild("BillboardGui")

-- 📡 获取远程事件
local RemoteEventFolder = ReplicatedStorage:WaitForChild("RemoteEvent")
local finishTalkEvent = RemoteEventFolder:WaitForChild("FinishTutorialTalk") 

-- ==========================================
-- 2. 对话 UI 生成
-- ==========================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DialogueUI"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 100
screenGui.Parent = playerGui

local dialogFrame = Instance.new("Frame")
dialogFrame.Name = "DialogFrame"
dialogFrame.Size = UDim2.new(0.6, 0, 0.25, 0)
dialogFrame.Position = UDim2.new(0.2, 0, 0.7, 0)
dialogFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
dialogFrame.BorderSizePixel = 2
dialogFrame.BorderColor3 = Color3.fromRGB(255, 215, 0)
dialogFrame.Visible = false
dialogFrame.Parent = screenGui

local nameLabel = Instance.new("TextLabel")
nameLabel.Text = "Tung Tung Sahur"
nameLabel.Size = UDim2.new(0.3, 0, 0.3, 0)
nameLabel.Position = UDim2.new(0, 10, -0.35, 0)
nameLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
nameLabel.BackgroundTransparency = 1
nameLabel.Font = Enum.Font.FredokaOne
nameLabel.TextSize = 24
nameLabel.TextXAlignment = Enum.TextXAlignment.Left
nameLabel.Parent = dialogFrame

local contentLabel = Instance.new("TextLabel")
contentLabel.Size = UDim2.new(0.95, 0, 0.8, 0)
contentLabel.Position = UDim2.new(0.025, 0, 0.1, 0)
contentLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
contentLabel.BackgroundTransparency = 1
contentLabel.Font = Enum.Font.SourceSans
contentLabel.TextSize = 22
contentLabel.TextXAlignment = Enum.TextXAlignment.Left
contentLabel.TextYAlignment = Enum.TextYAlignment.Top
contentLabel.TextWrapped = true
contentLabel.Parent = dialogFrame

local continueLabel = Instance.new("TextLabel")
continueLabel.Text = "[Click to Continue]"
continueLabel.Size = UDim2.new(0.2, 0, 0.2, 0)
continueLabel.Position = UDim2.new(0.8, 0, 0.8, 0)
continueLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
continueLabel.BackgroundTransparency = 1
continueLabel.Font = Enum.Font.SourceSansItalic
continueLabel.TextSize = 18
continueLabel.Parent = dialogFrame

-- ==========================================
-- 3. 逻辑控制
-- ==========================================
local isTalking = false
local QUEST_ID = "Quest_SamuraiSlayer"

local function typeWrite(text)
	contentLabel.Text = text
	contentLabel.MaxVisibleGraphemes = 0
	for i = 1, #text do
		contentLabel.MaxVisibleGraphemes = i
		task.wait(0.02)
	end
end

-- [辅助函数] 控制图标显示/隐藏
local function setIconVisible(isVisible)
	-- 1. 处理 3D 部件 (Union)
	if questUnion then
		-- 如果是部件，用 Transparency 控制 (0=显示, 1=隐藏)
		questUnion.Transparency = isVisible and 0 or 1
	end

	-- 2. 处理 GUI (兼容旧版)
	if guiIcon then
		guiIcon.Enabled = isVisible
	end
end

-- 检查任务状态
local function checkQuestStatus()
	local qVal = hiddenStats:FindFirstChild(QUEST_ID)

	-- 检查“教程完成”标记
	local isTutorialDone = false
	if hiddenStats:FindFirstChild("TutorialCompleted") and hiddenStats.TutorialCompleted.Value == true then
		isTutorialDone = true
	end

	-- 1. 如果教程已完成 -> 彻底关闭
	if isTutorialDone then
		prompt.Enabled = false
		setIconVisible(false) -- 隐藏感叹号
		return
	end

	-- 2. 如果任务已完成 (但教程状态可能还没更新) -> 暂时关闭
	if qVal and qVal.Value >= 10 then
		prompt.Enabled = false 
		setIconVisible(false) -- 隐藏感叹号
	else
		-- 3. 其他情况 (新玩家/任务进行中) -> 开启
		prompt.Enabled = true
		setIconVisible(true)  -- 显示感叹号
	end
end

-- 开始对话
local function startDialog()
	if isTalking then return end

	-- [双重保险] 如果教程做完了，禁止开始对话
	if hiddenStats:FindFirstChild("TutorialCompleted") and hiddenStats.TutorialCompleted.Value == true then
		return
	end

	isTalking = true
	dialogFrame.Visible = true

	local qVal = hiddenStats:FindFirstChild(QUEST_ID)

	if not qVal then
		-- A. 【新玩家】
		typeWrite("Hello traveler! The village is in danger.")
		dialogFrame.InputBegan:Wait()

		typeWrite("Here, take this weapon. It's dangerous out there.")
		dialogFrame.InputBegan:Wait()

		typeWrite("Defeat 10 Samurai for me, and I will reward you.")
		dialogFrame.InputBegan:Wait()

		print("📡 [客户端] 请求服务器发放奖励...")
		finishTalkEvent:FireServer()

	elseif qVal.Value < 10 then
		-- B. 【任务进行中】
		typeWrite("You have defeated " .. qVal.Value .. " / 10 Samurai.")
		dialogFrame.InputBegan:Wait()
		typeWrite("Keep going! I need them gone.")
		dialogFrame.InputBegan:Wait()
	else
		-- C. 【任务已完成】
		typeWrite("You are a true hero! Thank you!")
		dialogFrame.InputBegan:Wait()
	end

	dialogFrame.Visible = false
	isTalking = false
end

-- ==========================================
-- 4. 监听与初始化
-- ==========================================
prompt.Triggered:Connect(startDialog)

-- 初始检查
task.wait(1)
checkQuestStatus()

-- 监听 HiddenStats
hiddenStats.ChildAdded:Connect(function(child)
	if child.Name == QUEST_ID or child.Name == "TutorialCompleted" then
		checkQuestStatus()
		child.Changed:Connect(checkQuestStatus)
	end
end)

if hiddenStats:FindFirstChild(QUEST_ID) then
	hiddenStats[QUEST_ID].Changed:Connect(checkQuestStatus)
end

if hiddenStats:FindFirstChild("TutorialCompleted") then
	hiddenStats.TutorialCompleted.Changed:Connect(checkQuestStatus)
end