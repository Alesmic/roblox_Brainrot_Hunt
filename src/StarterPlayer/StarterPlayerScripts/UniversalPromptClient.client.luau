local ProximityPromptService = game:GetService("ProximityPromptService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ==========================================
-- 1. 创建移动端交互按钮 (MobilePromptUI)
-- ==========================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MobilePromptUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local mobileBtn = Instance.new("ImageButton")
mobileBtn.Name = "InteractButton"
mobileBtn.Size = UDim2.new(0, 80, 0, 80)
-- 放在右侧，跳跃键左上方
mobileBtn.Position = UDim2.new(0.75, 0, 0.6, 0) 
mobileBtn.AnchorPoint = Vector2.new(0.5, 0.5)
mobileBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
mobileBtn.BackgroundTransparency = 0.5
mobileBtn.Image = "rbxasset://textures/ui/Input/Touch/Interact.png"
mobileBtn.Visible = false -- 默认隐藏
mobileBtn.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(1, 0)
corner.Parent = mobileBtn

local label = Instance.new("TextLabel")
label.Size = UDim2.new(1, 0, 0.4, 0)
label.Position = UDim2.new(0, 0, 1, 5)
label.BackgroundTransparency = 1
label.TextColor3 = Color3.new(1, 1, 1)
label.Font = Enum.Font.FredokaOne
label.TextSize = 18
label.Text = "Interact"
label.Parent = mobileBtn

-- ==========================================
-- 2. 交互逻辑
-- ==========================================
local currentPrompt = nil

local function onPromptShown(prompt, inputType)
	-- 只在触摸设备或强制移动模式下启用
	if inputType == Enum.ProximityPromptInputType.Touch or UserInputService.TouchEnabled then
		prompt.Style = Enum.ProximityPromptStyle.Custom -- 隐藏默认UI

		currentPrompt = prompt
		mobileBtn.Visible = true
		label.Text = prompt.ActionText or "Interact"

		-- 弹入动画
		mobileBtn.Size = UDim2.new(0, 0, 0, 0)
		TweenService:Create(mobileBtn, TweenInfo.new(0.2, Enum.EasingStyle.Back), {
			Size = UDim2.new(0, 80, 0, 80)
		}):Play()
	end
end

local function onPromptHidden(prompt)
	if currentPrompt == prompt then
		mobileBtn.Visible = false
		currentPrompt = nil
		prompt.Style = Enum.ProximityPromptStyle.Default -- 恢复默认
	end
end

-- 绑定点击
mobileBtn.MouseButton1Down:Connect(function()
	if currentPrompt then
		currentPrompt:InputHoldBegin()
		mobileBtn.ImageColor3 = Color3.fromRGB(150, 150, 150)
	end
end)

mobileBtn.MouseButton1Up:Connect(function()
	if currentPrompt then
		currentPrompt:InputHoldEnd()
		mobileBtn.ImageColor3 = Color3.fromRGB(255, 255, 255)
	end
end)

ProximityPromptService.PromptShown:Connect(onPromptShown)
ProximityPromptService.PromptHidden:Connect(onPromptHidden)
print("✅ UniversalPromptClient 已加载 (移动端交互优化)")