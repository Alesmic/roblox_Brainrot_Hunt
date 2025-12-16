local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- 1. 创建主 ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "RPG_Inventory"
screenGui.ResetOnSpawn = false --以此确保重生后界面不会消失/重置
screenGui.Parent = playerGui

-- 2. 创建打开按钮 (ITEMS)
local openBtn = Instance.new("TextButton")
openBtn.Name = "OpenInventoryBtn"
openBtn.Size = UDim2.new(0, 100, 0, 50)
openBtn.Position = UDim2.new(0, 20, 0.4, 0)
openBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
openBtn.Text = "ITEMS"
openBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
openBtn.TextScaled = true
openBtn.Parent = screenGui

local corner = Instance.new("UICorner")
corner.Parent = openBtn

-- 3. 创建背包主框架
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 500, 0, 400)
mainFrame.Position = UDim2.new(0.5, -250, 0.5, -200)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
mainFrame.Visible = false
mainFrame.Parent = screenGui

-- 标题
local title = Instance.new("TextLabel")
title.Name = "TitleLabel"
title.Text = "INVENTORY"
title.Size = UDim2.new(1, 0, 0, 40)
title.BackgroundTransparency = 1
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.FredokaOne
title.TextSize = 24
title.Parent = mainFrame

-- [关键修复] 关闭按钮
local closeBtn = Instance.new("TextButton")
closeBtn.Name = "CloseButton" -- 这里确保有名字
closeBtn.Text = "X"
closeBtn.Size = UDim2.new(0, 40, 0, 40)
closeBtn.Position = UDim2.new(1, -40, 0, 0)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeBtn.Parent = mainFrame

-- 4. 分页按钮文件夹
local tabFolder = Instance.new("Folder")
tabFolder.Name = "Tabs"
tabFolder.Parent = mainFrame

local function createTab(name, text, xPos)
	local btn = Instance.new("TextButton")
	btn.Name = name
	btn.Text = text
	btn.Size = UDim2.new(0.5, 0, 0, 40)
	btn.Position = UDim2.new(xPos, 0, 0.1, 0)
	btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.Parent = tabFolder
	return btn
end

local backpackTab = createTab("BackpackTab", "Backpack", 0)
local wardrobeTab = createTab("WardrobeTab", "Wardrobe", 0.5)

-- 5. 物品滚动列表 (之前报错 Infinite yield 的原因是因为这里没生成成功)
local scrollingFrame = Instance.new("ScrollingFrame")
scrollingFrame.Name = "ScrollingFrame" -- 确保有名字
scrollingFrame.Size = UDim2.new(0.9, 0, 0.6, 0)
scrollingFrame.Position = UDim2.new(0.05, 0, 0.25, 0)
scrollingFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
scrollingFrame.Parent = mainFrame

local gridLayout = Instance.new("UIGridLayout")
gridLayout.CellSize = UDim2.new(0, 100, 0, 120)
gridLayout.Parent = scrollingFrame

-- 6. 操作区域
local actionFrame = Instance.new("Frame")
actionFrame.Name = "Frame" -- 这里的名字要和 Controller 里对应
actionFrame.Size = UDim2.new(1, 0, 0.15, 0)
actionFrame.Position = UDim2.new(0, 0, 0.85, 0)
actionFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
actionFrame.Parent = mainFrame

local infoLabel = Instance.new("TextLabel")
infoLabel.Name = "InfoLabel"
infoLabel.Text = "Select an item..."
infoLabel.Size = UDim2.new(0.6, 0, 1, 0)
infoLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
infoLabel.BackgroundTransparency = 1
infoLabel.Parent = actionFrame

local sellBtn = Instance.new("TextButton")
sellBtn.Name = "SellButton"
sellBtn.Text = "SELL"
sellBtn.Size = UDim2.new(0.3, 0, 0.8, 0)
sellBtn.Position = UDim2.new(0.65, 0, 0.1, 0)
sellBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
sellBtn.Visible = false
sellBtn.Parent = actionFrame

print("✅ UI 生成器运行完毕，所有组件已创建。")