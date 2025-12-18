local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

local boss = script.Parent
local humanoid = boss:WaitForChild("Humanoid")
local head = boss:WaitForChild("Head")

-- 1. 获取基础配置
-- [重要] 我们使用原始名字去查配置，绝对不要修改 boss.Name
local originalName = boss.Name 
local config = GameConfig.Mobs[originalName]

-- 如果配置里没写等级，默认给个 300
local level = config and config.Level or 300 
local maxHealth = config and config.MaxHealth or humanoid.MaxHealth

-- 2. 创建头顶 UI (BillboardGui)
-- 如果以前有旧的 GUI，先清理掉
if head:FindFirstChild("BossStatusGUI") then
	head.BossStatusGUI:Destroy()
end

local billboardGui = Instance.new("BillboardGui")
billboardGui.Name = "BossStatusGUI"
billboardGui.Adornee = head
billboardGui.Size = UDim2.new(0, 200, 0, 50)
billboardGui.StudsOffset = Vector3.new(0, 3, 0) -- 显示在头顶上方 3 米
billboardGui.AlwaysOnTop = true
billboardGui.Parent = head

local nameLabel = Instance.new("TextLabel")
nameLabel.Size = UDim2.new(1, 0, 0.6, 0)
nameLabel.BackgroundTransparency = 1
nameLabel.TextColor3 = Color3.fromRGB(231, 76, 60) -- 红色名字
nameLabel.TextStrokeTransparency = 0
nameLabel.Font = Enum.Font.GothamBlack
nameLabel.TextScaled = true
nameLabel.Parent = billboardGui

local hpLabel = Instance.new("TextLabel")
hpLabel.Size = UDim2.new(1, 0, 0.4, 0)
hpLabel.Position = UDim2.new(0, 0, 0.6, 0)
hpLabel.BackgroundTransparency = 1
hpLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
hpLabel.TextStrokeTransparency = 0
hpLabel.Font = Enum.Font.GothamBold
hpLabel.TextScaled = true
hpLabel.Parent = billboardGui

-- 3. 更新函数
local function updateStatus()
	local currentHp = math.floor(humanoid.Health)
	local maxHp = math.floor(humanoid.MaxHealth)

	-- 更新名字显示 (但不改模型名字!)
	nameLabel.Text = string.format("[BOSS] %s (Lv. %d)", originalName, level)

	-- 更新血量显示
	hpLabel.Text = string.format("Health: %d / %d", currentHp, maxHp)
end

-- 4. 监听血量变化
humanoid.HealthChanged:Connect(updateStatus)

-- 初始化一次
updateStatus()

-- [关键] 确保 Humanoid 的名字不显示，只显示我们的 GUI
humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None