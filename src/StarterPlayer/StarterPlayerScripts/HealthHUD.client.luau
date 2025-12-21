local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ==========================================
-- 1. UI 创建与布局 (极简贴底版)
-- ==========================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CustomHUD_BottomLeft"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = -10 -- 保证在最上层
screenGui.Parent = playerGui

-- 主容器
local container = Instance.new("Frame")
container.Name = "StatsContainer"
container.BackgroundTransparency = 1
-- [核心修改] 锚点 (0, 1) 左下角，位置 (0, 1) 绝对贴底
container.AnchorPoint = Vector2.new(0, 1) 
container.Position = UDim2.new(0, 5, 1, -5) -- 留 5px 边距防止手机圆角裁切
container.Size = UDim2.new(0.4, 0, 0.15, 0) -- 宽度 40%，高度自适应
container.Parent = screenGui

-- 适配逻辑：如果是 PC，稍微缩短一点宽度
if not UserInputService.TouchEnabled then
	container.Size = UDim2.new(0.25, 0, 0.15, 0)
end

-- ==========================================
-- 2. 布局结构 (从下往上堆叠)
-- ==========================================

-- A. 经验条 (最底层，细长)
local expBg = Instance.new("Frame")
expBg.Name = "ExpBg"
expBg.Size = UDim2.new(1, 0, 0.15, 0) -- 高度占比 15%
expBg.Position = UDim2.new(0, 0, 0.85, 0) -- 贴底
expBg.BackgroundColor3 = Color3.fromRGB(10, 10, 30)
expBg.BorderSizePixel = 1
expBg.BorderColor3 = Color3.fromRGB(0, 0, 0)
expBg.Parent = container

local expFill = Instance.new("Frame")
expFill.Name = "Fill"
expFill.Size = UDim2.new(0, 0, 1, 0)
expFill.BackgroundColor3 = Color3.fromRGB(255, 215, 0) -- 金色
expFill.BorderSizePixel = 0
expFill.Parent = expBg

-- B. 血条 (中间，较粗)
local healthBg = Instance.new("Frame")
healthBg.Name = "HealthBg"
healthBg.Size = UDim2.new(1, 0, 0.35, 0) -- 高度占比 35%
healthBg.Position = UDim2.new(0, 0, 0.45, 0) -- 位于经验条上方 (留 5% 间隙)
healthBg.BackgroundColor3 = Color3.fromRGB(40, 10, 10)
healthBg.BorderSizePixel = 1
healthBg.BorderColor3 = Color3.fromRGB(0, 0, 0)
healthBg.Parent = container

local healthFill = Instance.new("Frame")
healthFill.Name = "Fill"
healthFill.Size = UDim2.new(1, 0, 1, 0)
healthFill.BackgroundColor3 = Color3.fromRGB(220, 50, 50) -- 鲜红
healthFill.BorderSizePixel = 0
healthFill.Parent = healthBg

local healthTextLabel = Instance.new("TextLabel")
healthTextLabel.Size = UDim2.new(1, -10, 1, 0)
healthTextLabel.Position = UDim2.new(0, 5, 0, 0)
healthTextLabel.BackgroundTransparency = 1
healthTextLabel.Font = Enum.Font.FredokaOne
healthTextLabel.TextSize = 14 -- 固定字号，防止缩放过小
healthTextLabel.TextColor3 = Color3.new(1, 1, 1)
healthTextLabel.TextStrokeTransparency = 0.5
healthTextLabel.TextXAlignment = Enum.TextXAlignment.Left
healthTextLabel.Text = "HP 100/100"
healthTextLabel.Parent = healthBg

-- C. 金币与等级 (最上方)
local topInfoFrame = Instance.new("Frame")
topInfoFrame.Name = "TopInfo"
topInfoFrame.Size = UDim2.new(1, 0, 0.35, 0)
topInfoFrame.Position = UDim2.new(0, 0, 0.05, 0) -- 位于血条上方
topInfoFrame.BackgroundTransparency = 1
topInfoFrame.Parent = container

-- 等级 (左)
local levelText = Instance.new("TextLabel")
levelText.Size = UDim2.new(0.3, 0, 1, 0)
levelText.Position = UDim2.new(0, 0, 0, 0)
levelText.BackgroundTransparency = 1
levelText.Font = Enum.Font.FredokaOne
levelText.TextScaled = true
levelText.TextColor3 = Color3.fromRGB(255, 255, 255)
levelText.TextXAlignment = Enum.TextXAlignment.Left
levelText.Text = "Lv.1"
levelText.Parent = topInfoFrame

-- 金币 (紧挨等级)
local goldIcon = Instance.new("ImageLabel")
goldIcon.Size = UDim2.new(0.8, 0, 0.8, 0)
goldIcon.SizeConstraint = Enum.SizeConstraint.RelativeYY
goldIcon.Position = UDim2.new(0.3, 0, 0.1, 0)
goldIcon.BackgroundTransparency = 1
goldIcon.Image = "http://www.roblox.com/asset/?id=163851446" -- 这里换成你的金币图
goldIcon.Parent = topInfoFrame

local goldText = Instance.new("TextLabel")
goldText.Size = UDim2.new(0.5, 0, 1, 0)
goldText.Position = UDim2.new(0.32, 25, 0, 0) -- 图标宽度偏移
goldText.BackgroundTransparency = 1
goldText.Font = Enum.Font.FredokaOne
goldText.TextScaled = true
goldText.TextColor3 = Color3.fromRGB(255, 215, 0)
goldText.TextXAlignment = Enum.TextXAlignment.Left
goldText.Text = "0"
goldText.Parent = topInfoFrame


-- ==========================================
-- 3. 数据绑定逻辑 (保持不变)
-- ==========================================
local function updateHealth()
	local char = player.Character
	if not char then return end
	local hum = char:FindFirstChild("Humanoid")
	if not hum then return end

	local hp = math.clamp(hum.Health, 0, hum.MaxHealth)
	local maxHp = hum.MaxHealth

	TweenService:Create(healthFill, TweenInfo.new(0.3), {Size = UDim2.new(hp/maxHp, 0, 1, 0)}):Play()
	healthTextLabel.Text = string.format("%d / %d", math.floor(hp), math.floor(maxHp))
end

local function updateStats()
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then return end

	local lvl = leaderstats:FindFirstChild("Level")
	local xp = leaderstats:FindFirstChild("Experience")
	local g = leaderstats:FindFirstChild("Gold")
	local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

	if lvl and xp then
		levelText.Text = "Lv." .. lvl.Value
		local req = GameConfig.Leveling.GetXpRequired(lvl.Value)
		local pct = math.clamp(xp.Value / req, 0, 1)
		TweenService:Create(expFill, TweenInfo.new(0.5), {Size = UDim2.new(pct, 0, 1, 0)}):Play()
	end
	if g then
		goldText.Text = tostring(g.Value)
	end
end

-- 监听
local function setupChar(char)
	local hum = char:WaitForChild("Humanoid", 10)
	if hum then hum.HealthChanged:Connect(updateHealth); updateHealth() end
end
if player.Character then setupChar(player.Character) end
player.CharacterAdded:Connect(setupChar)

local function setupStats()
	local ls = player:WaitForChild("leaderstats", 10)
	if ls then
		ls:WaitForChild("Level").Changed:Connect(updateStats)
		ls:WaitForChild("Experience").Changed:Connect(updateStats)
		ls:WaitForChild("Gold").Changed:Connect(updateStats)
		updateStats()
	end
end
setupStats()
task.delay(1, setupStats)