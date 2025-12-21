--local Players = game:GetService("Players")
--local ReplicatedStorage = game:GetService("ReplicatedStorage")
--local TweenService = game:GetService("TweenService")
--local UserInputService = game:GetService("UserInputService")

--local player = Players.LocalPlayer
--local playerGui = player:WaitForChild("PlayerGui")

---- 1. 清理旧界面 (防止重叠)
--if playerGui:FindFirstChild("InventoryGui") then
--	playerGui.InventoryGui:Destroy()
--end

--local screenGui = Instance.new("ScreenGui")
--screenGui.Name = "InventoryGui" -- 必须叫这个名字
--screenGui.ResetOnSpawn = false
--screenGui.DisplayOrder = 1
--screenGui.Parent = playerGui
--screenGui.DisplayOrder = -10

---- ==========================================
---- A. 背包主窗口 (默认隐藏)
---- ==========================================
--local mainFrame = Instance.new("Frame")
--mainFrame.Name = "MainFrame" -- 必须叫 MainFrame
--mainFrame.Size = UDim2.new(0.7, 0, 0.8, 0)
--mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
--mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
--mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
--mainFrame.BorderSizePixel = 0
--mainFrame.Visible = false
--mainFrame.Parent = screenGui

--Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 10)

---- 标题
--local titleLabel = Instance.new("TextLabel")
--titleLabel.Name = "Title"
--titleLabel.Size = UDim2.new(1, -20, 0, 40)
--titleLabel.Position = UDim2.new(0, 10, 0, 5)
--titleLabel.BackgroundTransparency = 1
--titleLabel.Text = "INVENTORY"
--titleLabel.Font = Enum.Font.FredokaOne
--titleLabel.TextSize = 24
--titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
--titleLabel.TextXAlignment = Enum.TextXAlignment.Left
--titleLabel.Parent = mainFrame

---- 关闭按钮
--local closeBtn = Instance.new("TextButton")
--closeBtn.Name = "CloseButton"
--closeBtn.Size = UDim2.new(0, 30, 0, 30)
--closeBtn.Position = UDim2.new(1, -35, 0, 5)
--closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
--closeBtn.Text = "X"
--closeBtn.TextColor3 = Color3.new(1,1,1)
--closeBtn.Font = Enum.Font.FredokaOne
--closeBtn.TextSize = 18
--closeBtn.Parent = mainFrame
--Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 4)

---- 物品容器
--local scrollingFrame = Instance.new("ScrollingFrame")
--scrollingFrame.Name = "Container" -- 必须叫 Container
--scrollingFrame.Size = UDim2.new(1, -20, 1, -60)
--scrollingFrame.Position = UDim2.new(0, 10, 0, 50)
--scrollingFrame.BackgroundTransparency = 1
--scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
--scrollingFrame.ScrollBarThickness = 6
--scrollingFrame.Parent = mainFrame

--local gridLayout = Instance.new("UIGridLayout")
--gridLayout.CellSize = UDim2.new(0, 90, 0, 90)
--gridLayout.CellPadding = UDim2.new(0, 10, 0, 10)
--gridLayout.Parent = scrollingFrame

---- ==========================================
---- B. 圆形背包按钮 (左侧居中)
---- ==========================================
--local toggleBtn = Instance.new("ImageButton")
--toggleBtn.Name = "ToggleInventoryBtn"
--toggleBtn.Size = UDim2.new(0, 60, 0, 60)
--toggleBtn.Position = UDim2.new(0, 10, 0.4, 0) -- 屏幕左侧
--toggleBtn.AnchorPoint = Vector2.new(0, 0.5) 
--toggleBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
--toggleBtn.BackgroundTransparency = 0.4
----toggleBtn.Image = "http://www.roblox.com/asset/?id=120000874590886" 
--toggleBtn.Parent = screenGui

--Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(1, 0) -- 圆形
--local stroke = Instance.new("UIStroke")
--stroke.Color = Color3.fromRGB(255, 215, 0)
--stroke.Thickness = 2
--stroke.Parent = toggleBtn

---- ==========================================
---- C. 交互逻辑
---- ==========================================
--local isOpen = false

--local function toggleInventory()
--	isOpen = not isOpen
--	mainFrame.Visible = isOpen

--	if isOpen then
--		mainFrame.Size = UDim2.new(0.4, 0, 0.3, 0)
--		TweenService:Create(mainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Back), {
--			Size = UDim2.new(0.5, 0, 0.4, 0)
--		}):Play()
--	end
--end

--closeBtn.MouseButton1Click:Connect(toggleInventory)
--toggleBtn.MouseButton1Click:Connect(toggleInventory)

--UserInputService.InputBegan:Connect(function(input, processed)
--	if processed then return end
--	if input.KeyCode == Enum.KeyCode.M or input.KeyCode == Enum.KeyCode.Tab then
--		toggleInventory()
--	end
--end)

--print("✅ InventoryUI_Generator (生成器) 已运行：按钮和窗口已创建")