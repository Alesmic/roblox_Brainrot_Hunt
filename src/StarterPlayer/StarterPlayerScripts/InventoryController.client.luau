local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
-- 等待 UI 加载
local gui = playerGui:WaitForChild("RPG_Inventory", 10) 
if not gui then return end 

local mainFrame = gui:WaitForChild("MainFrame")
local container = mainFrame:WaitForChild("ScrollingFrame")
local actionFrame = mainFrame:WaitForChild("Frame") 
local infoLabel = actionFrame:WaitForChild("InfoLabel")
local sellBtn = actionFrame:WaitForChild("SellButton")

-- 适配 RemoteFunction 文件夹
local RemoteFunctionFolder = ReplicatedStorage:WaitForChild("RemoteFunction")
local getInvFunc = RemoteFunctionFolder:WaitForChild("GetInventoryData")

-- 适配 RemoteEvent 文件夹
local RemoteEventFolder = ReplicatedStorage:WaitForChild("RemoteEvent")
local sellEvent = RemoteEventFolder:WaitForChild("SellItem")

local currentTab = "Backpack" 
local selectedItemRealName = nil 
local selectedItemPrice = 0 -- [新增] 存储选中物品的原价

-- ==========================================
-- 1. 分类映射表
-- ==========================================
local CategoryMap = {
	Backpack = {
		["Backpack"] = true,
		["Weapons"] = true,
		["Consumables"] = true,
		["Misc"] = true,
		["Item"] = true
	},
	Wardrobe = {
		["Wardrobe"] = true,
		["Skins"] = true,
		["Aura Skin"] = true,
		["Character Skin"] = true
	}
}

local function clearList()
	for _, child in pairs(container:GetChildren()) do
		if child:IsA("Frame") or child:IsA("TextButton") then
			child:Destroy()
		end
	end
end

local function refreshInventory()
	clearList()
	selectedItemRealName = nil
	selectedItemPrice = 0
	sellBtn.Visible = false
	infoLabel.Text = "Select an item..."

	-- 获取数据
	local success, items = pcall(function() return getInvFunc:InvokeServer() end)
	if not success or not items then return end

	print("[Client Log] 刷新背包，当前标签: " .. currentTab)

	for _, item in pairs(items) do
		-- 检查分类
		local allowedCategories = CategoryMap[currentTab]

		if allowedCategories and allowedCategories[item.Category] then

			local card = Instance.new("TextButton")
			card.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
			card.Text = ""
			card.Parent = container

			-- 圆角
			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(0, 6)
			corner.Parent = card

			-- 图片显示
			local icon = Instance.new("ImageLabel")
			icon.Size = UDim2.new(0, 50, 0, 50) 
			icon.Position = UDim2.new(0, 5, 0.5, 0)
			icon.AnchorPoint = Vector2.new(0, 0.5)
			icon.BackgroundTransparency = 1
			icon.Image = item.ImageId or "" 
			icon.Parent = card

			-- 物品名称
			local nameLbl = Instance.new("TextLabel", card)
			nameLbl.Size = UDim2.new(0.6, 0, 0.3, 0) 
			nameLbl.Position = UDim2.new(0.3, 0, 0, 0)
			nameLbl.BackgroundTransparency = 1
			nameLbl.Text = item.DisplayName 
			nameLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
			nameLbl.TextScaled = true
			nameLbl.Font = Enum.Font.SourceSansBold

			-- 类型显示
			local typeLbl = Instance.new("TextLabel", card)
			typeLbl.Position = UDim2.new(0.3, 0, 0.3, 0)
			typeLbl.Size = UDim2.new(0.6, 0, 0.3, 0)
			typeLbl.BackgroundTransparency = 1
			typeLbl.Text = item.Category or "Item" 
			typeLbl.TextColor3 = Color3.fromRGB(200,200,200)
			typeLbl.TextScaled = true

			-- 数量显示
			local qtyLbl = Instance.new("TextLabel", card)
			qtyLbl.Position = UDim2.new(0.3, 0, 0.6, 0)
			qtyLbl.Size = UDim2.new(0.6, 0, 0.3, 0)
			qtyLbl.BackgroundTransparency = 1
			qtyLbl.Text = "x" .. item.Qty
			qtyLbl.TextColor3 = Color3.fromRGB(255, 215, 0) 
			qtyLbl.TextScaled = true

			-- 点击卡片
			card.MouseButton1Click:Connect(function()
				selectedItemRealName = item.RealName 
				selectedItemPrice = item.Price -- [关键] 记录价格

				infoLabel.Text = item.DisplayName .. "\nType: " .. item.Category

				if item.CanSell then
					local sellPrice = math.floor(item.Price * 0.5)
					sellBtn.Visible = true
					sellBtn.Text = "Sell ($" .. sellPrice .. ")"
				else
					sellBtn.Visible = false
				end
				print("[Client Log] 选中物品: " .. item.DisplayName)
			end)
		end
	end
end

-- === 按钮连接 ===
gui.OpenInventoryBtn.MouseButton1Click:Connect(function()
	mainFrame.Visible = not mainFrame.Visible
	if mainFrame.Visible then
		refreshInventory()
	end
end)

if mainFrame:FindFirstChild("CloseButton") then
	mainFrame.CloseButton.MouseButton1Click:Connect(function()
		mainFrame.Visible = false
	end)
end

local tabs = mainFrame:WaitForChild("Tabs")
tabs.BackpackTab.MouseButton1Click:Connect(function()
	currentTab = "Backpack"
	tabs.BackpackTab.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
	tabs.WardrobeTab.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	refreshInventory()
end)

tabs.WardrobeTab.MouseButton1Click:Connect(function()
	currentTab = "Wardrobe"
	tabs.WardrobeTab.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
	tabs.BackpackTab.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	refreshInventory()
end)

-- 出售按钮逻辑
sellBtn.MouseButton1Click:Connect(function()
	if selectedItemRealName then
		print("[Client Log] 请求出售: " .. selectedItemRealName)

		-- [核心修复] 发送完整的 3 个参数: 名字, 价格, 数量
		-- 虽然服务器会重新计算价格，但为了格式匹配，我们还是发过去
		local sellPrice = math.floor(selectedItemPrice * 0.5)
		sellEvent:FireServer(selectedItemRealName, sellPrice, 1) 

		task.wait(0.2)
		refreshInventory() 
	end
end)