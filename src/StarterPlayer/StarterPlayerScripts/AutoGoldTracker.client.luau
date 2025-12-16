-- AutoGoldTracker.lua
-- 此脚本将自动创建 UI 并实时显示玩家的金币数量。
-- 建议放置在 StarterPlayer/StarterPlayerScripts

local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- 常量定义
local UI_NAME = "CurrencyUI"
local FRAME_NAME = "GoldDisplay"
local LABEL_NAME = "GoldAmount"
local UI_SIZE = UDim2.new(0, 150, 0, 35) -- 宽度 200，高度 40
-- 左下角位置：(0, 10) 是 X 轴偏移 10 像素，(1, -10) 是 Y 轴偏移 (100% - 10 像素)
local UI_POSITION = UDim2.new(0, 20, 1, -50) 
local UI_ANCHOR = Vector2.new(0, 1) -- 锚点设为左下角

-- ----------------------------------------------------
-- 1. UI 结构创建函数
-- ----------------------------------------------------

local function createUI()
	-- 1. 创建 ScreenGui (容器)
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = UI_NAME
	screenGui.ResetOnSpawn = false -- 确保玩家重生时 UI 不会被重置
	screenGui.Parent = player:WaitForChild("PlayerGui")

	-- 2. 创建 Frame (背景/容器)
	local goldDisplayFrame = Instance.new("Frame")
	goldDisplayFrame.Name = FRAME_NAME
	goldDisplayFrame.Size = UI_SIZE
	goldDisplayFrame.Position = UI_POSITION
	goldDisplayFrame.AnchorPoint = UI_ANCHOR
	goldDisplayFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0) -- 黑色背景
	goldDisplayFrame.BackgroundTransparency = 0.5 -- 半透明
	goldDisplayFrame.BorderSizePixel = 0

	-- 可选：添加圆角
	local uiCorner = Instance.new("UICorner")
	uiCorner.CornerRadius = UDim.new(0, 8)
	uiCorner.Parent = goldDisplayFrame

	goldDisplayFrame.Parent = screenGui

	-- 3. 创建 TextLabel (显示数值)
	local goldAmountLabel = Instance.new("TextLabel")
	goldAmountLabel.Name = LABEL_NAME
	goldAmountLabel.Size = UDim2.new(1, -10, 1, -10) -- 相比父级 Frame 稍微缩小
	goldAmountLabel.Position = UDim2.new(0, 5, 0, 5) -- 居中对齐
	goldAmountLabel.Text = "Gold: Loading..."
	goldAmountLabel.Font = Enum.Font.SourceSansBold
	goldAmountLabel.TextSize = 24
	goldAmountLabel.TextColor3 = Color3.fromRGB(255, 215, 0) -- 金色字体
	goldAmountLabel.TextXAlignment = Enum.TextXAlignment.Left -- 左对齐显示
	goldAmountLabel.BackgroundTransparency = 1 -- 透明背景
	goldAmountLabel.Parent = goldDisplayFrame

	return goldAmountLabel -- 返回 TextLabel 供后续更新
end

-- ----------------------------------------------------
-- 2. 格式化和更新函数
-- ----------------------------------------------------

-- 格式化函数 (例如，将 100000 格式化为 100K)
local function formatNumber(n)
	if n >= 1000000 then
		return string.format("%.1fM", n / 1000000)
	elseif n >= 1000 then
		return string.format("%.1fK", n / 1000)
	else
		return tostring(math.floor(n)) -- 取整数部分
	end
end

-- 实时更新 UI 的函数
local function updateGoldUI(label, newGoldValue)
	label.Text = "Gold: " .. formatNumber(newGoldValue)
end

-- ----------------------------------------------------
-- 3. 核心逻辑：设置跟踪
-- ----------------------------------------------------

local goldAmountLabel = createUI()

local function setupGoldTracking()
	-- 等待服务器创建 leaderstats 文件夹
	local leaderstats = player:WaitForChild("leaderstats")

	if not leaderstats then
		warn("Leaderstats not found. Gold display will not work.")
		return
	end

	-- 等待 Gold IntValue 创建
	local goldStat = leaderstats:WaitForChild("Gold")

	if goldStat and goldStat:IsA("IntValue") then
		-- 1. 首次设置初始值
		updateGoldUI(goldAmountLabel, goldStat.Value)

		-- 2. 监听金币值变化，实时更新 UI
		-- IntValue 的 Changed 事件会在值改变时触发
		goldStat.Changed:Connect(function(newVal)
			updateGoldUI(goldAmountLabel, newVal)
		end)

		print("✅ Gold tracking setup successful.")
	else
		warn("Gold IntValue not found in leaderstats. Check PlayerManager script.")
	end
end

-- 开始执行跟踪设置
setupGoldTracking()