-- 位置: StarterPlayer -> StarterPlayerScripts -> RewardNotificationClient.client.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- 1. 获取或等待远程事件
local RemoteEventFolder = ReplicatedStorage:WaitForChild("RemoteEvent", 10)
if not RemoteEventFolder then return end

local notificationEvent = RemoteEventFolder:FindFirstChild("QuestCompleted") 
-- 如果还没有这个事件，请确保在服务器端创建，或者等下在 InventorySystem 里注册

-- ==========================================
-- UI 创建与动画函数
-- ==========================================
local function createRewardPopup(questName, goldReward, expReward)
	-- 1. 创建主 ScreenGui
	local gui = Instance.new("ScreenGui")
	gui.Name = "RewardNotification"
	gui.ResetOnSpawn = false
	gui.Parent = playerGui

	-- 2. 创建背景框 (MainFrame)
	local frame = Instance.new("Frame")
	frame.Name = "MainFrame"
	frame.Size = UDim2.new(0, 200, 0, 100)
	frame.Position = UDim2.new(0.5, 0, 0, 0) -- 初始位置 (屏幕中上方)
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
	frame.BackgroundTransparency = 1 -- 初始透明，用于淡入动画
	frame.BorderSizePixel = 0
	frame.Parent = gui

	-- 圆角
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = frame

	-- 金色描边
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(255, 215, 0)
	stroke.Thickness = 2
	stroke.Transparency = 1 -- 初始透明
	stroke.Parent = frame

	-- 3. 标题 (QUEST COMPLETE)
	local title = Instance.new("TextLabel")
	title.Text = "QUEST COMPLETE!"
	title.Size = UDim2.new(1, 0, 0.3, 0)
	title.Position = UDim2.new(0, 0, 0.05, 0)
	title.BackgroundTransparency = 1
	title.TextTransparency = 1
	title.TextColor3 = Color3.fromRGB(255, 215, 0) -- 金色
	title.Font = Enum.Font.FredokaOne
	title.TextSize = 24
	title.Parent = frame

	-- 4. 任务名称
	local subTitle = Instance.new("TextLabel")
	subTitle.Text = questName or "Mission"
	subTitle.Size = UDim2.new(1, 0, 0.2, 0)
	subTitle.Position = UDim2.new(0, 0, 0.3, 0)
	subTitle.BackgroundTransparency = 1
	subTitle.TextTransparency = 1
	subTitle.TextColor3 = Color3.fromRGB(200, 200, 200)
	subTitle.Font = Enum.Font.SourceSansBold
	subTitle.TextSize = 18
	subTitle.Parent = frame

	-- 5. 奖励显示区
	local rewardLabel = Instance.new("TextLabel")
	rewardLabel.Text = string.format("+$%d Gold   +%d EXP", goldReward or 0, expReward or 0)
	rewardLabel.Size = UDim2.new(1, 0, 0.3, 0)
	rewardLabel.Position = UDim2.new(0, 0, 0.55, 0)
	rewardLabel.BackgroundTransparency = 1
	rewardLabel.TextTransparency = 1
	rewardLabel.TextColor3 = Color3.fromRGB(46, 204, 113) -- 绿色
	rewardLabel.Font = Enum.Font.FredokaOne
	rewardLabel.TextSize = 22
	rewardLabel.Parent = frame

	-- ==========================
	-- 动画逻辑
	-- ==========================

	-- 进场动画 (淡入 + 稍微上浮)
	frame.Position = UDim2.new(0.5, 0, 0.35, 0) -- 从低一点的地方升上来

	local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

	TweenService:Create(frame, tweenInfo, {
		Position = UDim2.new(0.5, 0, 0.3, 0),
		BackgroundTransparency = 0.1
	}):Play()
	TweenService:Create(stroke, tweenInfo, {Transparency = 0}):Play()

	-- 文字逐个淡入
	task.delay(0.1, function()
		TweenService:Create(title, TweenInfo.new(0.4), {TextTransparency = 0}):Play()
	end)
	task.delay(0.2, function()
		TweenService:Create(subTitle, TweenInfo.new(0.4), {TextTransparency = 0}):Play()
	end)
	task.delay(0.3, function()
		TweenService:Create(rewardLabel, TweenInfo.new(0.4), {TextTransparency = 0}):Play()
	end)

	-- 停留 3 秒后消失
	task.delay(3.5, function()
		local outInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

		TweenService:Create(frame, outInfo, {
			Position = UDim2.new(0.5, 0, 0.2, 0), -- 向上飘走
			BackgroundTransparency = 1
		}):Play()
		TweenService:Create(stroke, outInfo, {Transparency = 1}):Play()
		TweenService:Create(title, outInfo, {TextTransparency = 1}):Play()
		TweenService:Create(subTitle, outInfo, {TextTransparency = 1}):Play()
		TweenService:Create(rewardLabel, outInfo, {TextTransparency = 1}):Play()

		-- 销毁 UI
		Debris:AddItem(gui, 0.6)
	end)
end

-- 2. 监听事件
if notificationEvent then
	notificationEvent.OnClientEvent:Connect(createRewardPopup)
	print("✅ Reward Notification Client Ready")
else
	warn("⚠️ RewardNotificationClient: RemoteEvent 'QuestCompleted' not found!")
end