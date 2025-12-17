local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

print("🔵 [HealthHUD] UI 脚本开始运行...")

-- ==========================================
-- 1. 创建主 ScreenGui
-- ==========================================
local screenGui = playerGui:FindFirstChild("StatusHUD")
if screenGui then screenGui:Destroy() end -- 防止重复，先删旧的

screenGui = Instance.new("ScreenGui")
screenGui.Name = "StatusHUD"
screenGui.ResetOnSpawn = false -- 死亡不重置
screenGui.DisplayOrder = 100
screenGui.Parent = playerGui

-- ==========================================
-- 2. 辅助函数：创建进度条 (UI 工厂)
-- ==========================================
local function createBar(name, position, color, defaultText)
	-- 背景容器
	local bgFrame = Instance.new("Frame")
	bgFrame.Name = name .. "Background"
	bgFrame.Size = UDim2.new(0, 300, 0, 22) --稍微变细一点
	bgFrame.Position = position
	bgFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20) -- 深黑背景
	bgFrame.BorderSizePixel = 0
	bgFrame.Parent = screenGui

	-- 圆角
	local uicorner = Instance.new("UICorner")
	uicorner.CornerRadius = UDim.new(0, 6)
	uicorner.Parent = bgFrame

	-- 填充条
	local fillFrame = Instance.new("Frame")
	fillFrame.Name = "Fill"
	fillFrame.Size = UDim2.new(0, 0, 1, 0) -- 初始 0
	fillFrame.BackgroundColor3 = color
	fillFrame.BorderSizePixel = 0
	fillFrame.ZIndex = 2
	fillFrame.Parent = bgFrame

	local fillCorner = uicorner:Clone()
	fillCorner.Parent = fillFrame

	-- 文本标签
	local textLabel = Instance.new("TextLabel")
	textLabel.Name = "Text"
	textLabel.Size = UDim2.new(1, 0, 1, 0)
	textLabel.BackgroundTransparency = 1
	textLabel.TextColor3 = Color3.new(1, 1, 1)
	textLabel.Font = Enum.Font.GothamBold
	textLabel.TextSize = 12
	textLabel.TextStrokeTransparency = 0.5
	textLabel.Text = defaultText or "Loading..."
	textLabel.ZIndex = 3
	textLabel.Parent = bgFrame

	return bgFrame, fillFrame, textLabel
end

-- ==========================================
-- 3. 创建血条 (Health Bar)
-- ==========================================
-- [修改] 位置向上提：从 0.85 改为 0.82 (防止被底部遮挡)
local healthPos = UDim2.new(0.5, -150, 0.82, 0) 
local healthBg, healthFill, healthText = createBar("HealthBar", healthPos, Color3.fromRGB(231, 76, 60), "HP: -- / --") 

-- ==========================================
-- 4. 创建经验条 (Experience Bar)
-- ==========================================
-- [修改] 位置紧贴血条下方：Y轴偏移 26 像素
local expPos = UDim2.new(0.5, -150, 0.82, 26) 
-- 浅蓝色
local expBg, expFill, expText = createBar("ExpBar", expPos, Color3.fromRGB(52, 152, 219), "LV. 1 | 0 / 100") 

-- ==========================================
-- 5. 更新逻辑
-- ==========================================

-- A. 更新血量
local function updateHealth()
	local char = player.Character
	local humanoid = char and char:FindFirstChild("Humanoid")

	if humanoid then
		local hp = math.max(0, math.floor(humanoid.Health))
		local maxHp = math.floor(humanoid.MaxHealth)

		TweenService:Create(healthFill, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
			Size = UDim2.new(hp / maxHp, 0, 1, 0)
		}):Play()

		healthText.Text = "HP: " .. hp .. " / " .. maxHp
	end
end

-- B. 更新经验值
local function updateExp()
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then return end

	local levelVal = leaderstats:FindFirstChild("Level")
	local expVal = leaderstats:FindFirstChild("Experience") -- 确认这里是 Experience

	if levelVal and expVal then
		local currentLevel = levelVal.Value
		local currentExp = expVal.Value

		-- 获取升级所需经验
		local requiredExp = GameConfig.Leveling.GetXpRequired(currentLevel)
		if requiredExp <= 0 then requiredExp = 1 end

		local progress = math.clamp(currentExp / requiredExp, 0, 1)

		TweenService:Create(expFill, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
			Size = UDim2.new(progress, 0, 1, 0)
		}):Play()

		expText.Text = "LV. " .. currentLevel .. " | " .. currentExp .. " / " .. requiredExp
	end
end

-- ==========================================
-- 6. 事件监听
-- ==========================================

player.CharacterAdded:Connect(function(char)
	local humanoid = char:WaitForChild("Humanoid", 10)
	if humanoid then
		humanoid.HealthChanged:Connect(updateHealth)
		humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(updateHealth)
		updateHealth()
	end
end)

-- 初始角色检查
if player.Character then
	local hum = player.Character:FindFirstChild("Humanoid")
	if hum then
		hum.HealthChanged:Connect(updateHealth)
		updateHealth()
	end
end

-- 启动数据监听 (使用循环重试，确保能连上)
task.spawn(function()
	print("🔵 [HealthHUD] 等待 leaderstats 数据...")

	-- 无限等待直到加载出来，防止超时失效
	local leaderstats = player:WaitForChild("leaderstats", 9999) 
	print("🔵 [HealthHUD] 找到 leaderstats!")

	local levelStat = leaderstats:WaitForChild("Level", 9999)
	local expStat = leaderstats:WaitForChild("Experience", 10) 

	if not expStat then
		warn("❌ [HealthHUD] 没有找到 'Experience' 属性！请检查 PlayerManager 脚本！")
		-- 尝试用 Instance.new 创建一个临时的防止报错 (仅客户端)
		return
	end

	print("🔵 [HealthHUD] 数据连接成功，更新 UI")
	levelStat.Changed:Connect(updateExp)
	expStat.Changed:Connect(updateExp)
	updateExp()
end)