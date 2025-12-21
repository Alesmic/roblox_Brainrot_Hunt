--local Players = game:GetService("Players")
--local ReplicatedStorage = game:GetService("ReplicatedStorage")
--local UserInputService = game:GetService("UserInputService")
--local GuiService = game:GetService("GuiService")

--local player = Players.LocalPlayer
--local playerGui = player:WaitForChild("PlayerGui")
--local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

---- 动态 UI 引用
--local scrollingFrame = nil

--print("🔍 [InventoryController] 脚本启动，开始寻找 UI...")

---- ==========================================
---- 1. 寻找容器 (增强版：带等待和报错)
---- ==========================================
--local function findContainer()
--	-- 1. 找 ScreenGui
--	local inventoryGui = playerGui:WaitForChild("InventoryGui", 5)
--	if not inventoryGui then
--		warn("❌ [InventoryController] 找不到 InventoryGui！UI 生成器可能未运行。")
--		return nil
--	end

--	-- 2. 找 MainFrame
--	local mainFrame = inventoryGui:WaitForChild("MainFrame", 5)
--	if not mainFrame then
--		warn("❌ [InventoryController] 找不到 MainFrame！结构可能不对。")
--		return nil
--	end

--	-- 3. 找 Container
--	local container = mainFrame:WaitForChild("Container", 5)
--	if not container then
--		warn("❌ [InventoryController] 找不到 Container！滚动框去哪了？")
--		return nil
--	end

--	return container
--end

---- ==========================================
---- 2. 更新引用
---- ==========================================
--local function updateUIReference()
--	local container = findContainer()
--	if container then
--		if scrollingFrame ~= container then
--			print("✅ [InventoryController] 成功连接到背包容器: ", container:GetFullName())
--			scrollingFrame = container
--		end
--		return true
--	else
--		scrollingFrame = nil
--		return false
--	end
--end

---- ==========================================
---- 3. 装备逻辑
---- ==========================================
--local function toggleEquipItem(itemName)
--	local backpack = player:WaitForChild("Backpack")
--	local character = player.Character
--	local humanoid = character and character:FindFirstChild("Humanoid")
--	if not humanoid then return false end

--	local heldTool = character:FindFirstChild(itemName)
--	if heldTool then
--		heldTool.Parent = backpack
--		return false
--	end

--	local tool = backpack:FindFirstChild(itemName)
--	if tool then
--		humanoid:EquipTool(tool)
--		return true
--	end
--	return false
--end

---- ==========================================
---- 4. 刷新界面 (核心逻辑)
---- ==========================================
--local function updateInventoryUI()
--	-- 1. 检查引用
--	if not updateUIReference() then 
--		warn("⚠️ [InventoryController] 无法刷新：没有 UI 引用")
--		return 
--	end

--	-- 2. 清理旧图标 (保留 Layout)
--	for _, child in pairs(scrollingFrame:GetChildren()) do
--		if child:IsA("ImageButton") then child:Destroy() end
--	end

--	-- 3. 读取数据
--	local invFolder = player:FindFirstChild("Inventory")
--	if not invFolder then 
--		warn("⚠️ [InventoryController] 玩家还没有 Inventory 文件夹！")
--		return 
--	end

--	local items = invFolder:GetChildren()
--	if #items == 0 then
--		print("ℹ️ [InventoryController] 背包是空的 (Inventory 文件夹里没东西)")
--		-- 可以在这里显示一个 "Empty" 的提示文本
--	end

--	-- 4. 创建图标
--	for _, itemVal in ipairs(items) do
--		local itemName = itemVal.Name

--		-- 安全获取配置，防止报错中断
--		local conf = nil
--		if GameConfig.Weapons then conf = GameConfig.Weapons[itemName] end
--		if not conf and GameConfig.Items then conf = GameConfig.Items[itemName] end

--		-- 即使没配置也创建按钮，方便调试
--		local card = Instance.new("ImageButton")
--		card.Name = itemName
--		card.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
--		card.Parent = scrollingFrame
--		Instance.new("UICorner", card).CornerRadius = UDim.new(0.1, 0)

--		local icon = Instance.new("ImageLabel")
--		icon.Size = UDim2.new(0.8, 0, 0.8, 0)
--		icon.Position = UDim2.new(0.1, 0, 0.1, 0)
--		icon.BackgroundTransparency = 1
--		icon.Image = conf and conf.ImageId or "rbxasset://textures/ui/GuiImagePlaceholder.png"
--		icon.Parent = card

--		-- 数量
--		if itemVal.Value > 1 then
--			local qty = Instance.new("TextLabel")
--			qty.Size = UDim2.new(0.4, 0, 0.3, 0)
--			qty.Position = UDim2.new(0.6, 0, 0.7, 0)
--			qty.BackgroundTransparency = 1
--			qty.TextColor3 = Color3.new(1,1,1)
--			qty.Font = Enum.Font.FredokaOne
--			qty.TextSize = 14
--			qty.Text = "x"..itemVal.Value
--			qty.Parent = card
--		end

--		-- 装备状态 E
--		local equipStatus = Instance.new("TextLabel")
--		equipStatus.Size = UDim2.new(0.3, 0, 0.3, 0)
--		equipStatus.Position = UDim2.new(0, 5, 0, 5)
--		equipStatus.BackgroundTransparency = 1
--		equipStatus.TextColor3 = Color3.fromRGB(0, 255, 100)
--		equipStatus.Font = Enum.Font.FredokaOne
--		equipStatus.TextSize = 18
--		equipStatus.Text = "E"
--		equipStatus.Visible = false
--		equipStatus.Parent = card

--		if player.Character and player.Character:FindFirstChild(itemName) then
--			card.BackgroundColor3 = Color3.fromRGB(60, 80, 60)
--			card.BorderSizePixel = 2
--			card.BorderColor3 = Color3.fromRGB(0, 255, 0)
--			equipStatus.Visible = true
--		end

--		card.MouseButton1Click:Connect(function()
--			local isEquipped = toggleEquipItem(itemName)
--			if isEquipped then
--				card.BackgroundColor3 = Color3.fromRGB(60, 80, 60)
--				card.BorderSizePixel = 2
--				card.BorderColor3 = Color3.fromRGB(0, 255, 0)
--				equipStatus.Visible = true
--			else
--				card.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
--				card.BorderSizePixel = 0
--				equipStatus.Visible = false
--			end
--			-- 延时一点刷新以保证状态同步
--			task.delay(0.1, updateInventoryUI)
--		end)
--	end

--	print("✅ [InventoryController] 刷新完毕，显示了 " .. #items .. " 个物品")
--end

---- ==========================================
---- 5. 监听
---- ==========================================
---- 监听 UI 重建 (针对 UI 生成器可能会销毁重建的情况)
--playerGui.ChildAdded:Connect(function(child)
--	if child.Name == "InventoryGui" then
--		print("🔄 [InventoryController] 检测到 UI 重建，尝试重新连接...")
--		task.wait(0.5) -- 等待子组件加载
--		updateInventoryUI()
--	end
--end)

---- 监听数据
--if player:FindFirstChild("Inventory") then
--	player.Inventory.ChildAdded:Connect(updateInventoryUI)
--	player.Inventory.ChildRemoved:Connect(updateInventoryUI)
--	for _, c in pairs(player.Inventory:GetChildren()) do
--		c.Changed:Connect(updateInventoryUI)
--	end
--else
--	warn("⚠️ [InventoryController] 初始未找到 Inventory 文件夹，等待 PlayerAdded 处理...")
--	player.ChildAdded:Connect(function(c)
--		if c.Name == "Inventory" then
--			print("✅ [InventoryController] Inventory 文件夹已加载")
--			c.ChildAdded:Connect(updateInventoryUI)
--			c.ChildRemoved:Connect(updateInventoryUI)
--			updateInventoryUI()
--		end
--	end)
--end

--local function bindChar(char)
--	char.ChildAdded:Connect(function(c) if c:IsA("Tool") then updateInventoryUI() end end)
--	char.ChildRemoved:Connect(function(c) if c:IsA("Tool") then updateInventoryUI() end end)
--end
--if player.Character then bindChar(player.Character) end
--player.CharacterAdded:Connect(bindChar)

---- 启动
--task.wait(1)
--updateInventoryUI()