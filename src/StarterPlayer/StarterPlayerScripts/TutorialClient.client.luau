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

-- 获取头顶图标 (如果有的话，没有也不影响运行)
local head = npc:WaitForChild("Head")
local questIcon = head:FindFirstChild("QuestIcon") or head:FindFirstChild("BillboardGui")

-- 📡 获取远程事件 (这是通知服务器发武器的关键)
local RemoteEventFolder = ReplicatedStorage:WaitForChild("RemoteEvent")
local finishTalkEvent = RemoteEventFolder:WaitForChild("FinishTutorialTalk") 

-- ==========================================
-- 2. 对话 UI 生成 (颜色修复版)
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
nameLabel.TextColor3 = Color3.fromRGB(255, 215, 0) -- 金色
nameLabel.BackgroundTransparency = 1
nameLabel.Font = Enum.Font.FredokaOne
nameLabel.TextSize = 24
nameLabel.TextXAlignment = Enum.TextXAlignment.Left
nameLabel.Parent = dialogFrame

local contentLabel = Instance.new("TextLabel")
contentLabel.Size = UDim2.new(0.95, 0, 0.8, 0)
contentLabel.Position = UDim2.new(0.025, 0, 0.1, 0)
contentLabel.TextColor3 = Color3.fromRGB(255, 255, 255) -- ✅ 修复：使用 fromRGB 避免 nil 报错
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
continueLabel.TextColor3 = Color3.fromRGB(150, 150, 150) -- 灰色
continueLabel.BackgroundTransparency = 1
continueLabel.Font = Enum.Font.SourceSansItalic
continueLabel.TextSize = 18
continueLabel.Parent = dialogFrame

-- ==========================================
-- 3. 逻辑控制
-- ==========================================
local isTalking = false
local QUEST_ID = "Quest_SamuraiSlayer" -- 必须和服务器发的任务名一致

-- 打字机效果
local function typeWrite(text)
	contentLabel.Text = text
	contentLabel.MaxVisibleGraphemes = 0
	for i = 1, #text do
		contentLabel.MaxVisibleGraphemes = i
		task.wait(0.02)
	end
end

-- 检查任务状态，决定是否显示头顶问号
local function checkQuestStatus()
	local qVal = hiddenStats:FindFirstChild(QUEST_ID)
	if qVal and qVal.Value >= 10 then
		prompt.Enabled = false -- 任务做完了就不能对话了(或者你可以改成交任务逻辑)
		if questIcon then questIcon.Enabled = false end
	else
		prompt.Enabled = true
		if questIcon then questIcon.Enabled = true end
	end
end

-- 开始对话
local function startDialog()
	if isTalking then return end
	isTalking = true

	dialogFrame.Visible = true

	local qVal = hiddenStats:FindFirstChild(QUEST_ID)

	if not qVal then
		-- A. 【未接任务】 第一次对话
		typeWrite("Hello traveler! The village is in danger.")
		dialogFrame.InputBegan:Wait()

		typeWrite("Here, take this weapon. It's dangerous out there.")
		dialogFrame.InputBegan:Wait()

		typeWrite("Defeat 10 Samurai for me, and I will reward you.")
		dialogFrame.InputBegan:Wait()

		-- 🟢 关键：告诉服务器对话结束，发武器，发任务！
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

-- 初始检查一次状态
task.wait(1)
checkQuestStatus()

-- 监听任务变化 (例如打完怪进度更新时)
if hiddenStats:FindFirstChild(QUEST_ID) then
	hiddenStats[QUEST_ID].Changed:Connect(checkQuestStatus)
end

hiddenStats.ChildAdded:Connect(function(child)
	if child.Name == QUEST_ID then
		checkQuestStatus()
		child.Changed:Connect(checkQuestStatus)
	end
end)