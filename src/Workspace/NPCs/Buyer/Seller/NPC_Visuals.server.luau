-- 位置: NPC模型内部 -> NPC_Visuals
local npc = script.Parent
local rootPart = npc:WaitForChild("HumanoidRootPart")
local head = npc:WaitForChild("Head")

-- ============================
-- 2. 创建头顶符号 ($)
-- ============================
local function createOverheadSymbol()
	if head:FindFirstChild("ShopSymbol") then return end

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "ShopSymbol"
	billboard.Adornee = head
	billboard.Size = UDim2.new(0, 80, 0, 80)
	billboard.StudsOffset = Vector3.new(0, 2.5, 0) 
	billboard.AlwaysOnTop = true 

	-- [核心修改] 设置最大显示距离为 100 米 (Studs)
	billboard.MaxDistance = 100 

	billboard.Parent = head

	local textLabel = Instance.new("TextLabel")
	textLabel.Text = "$"
	textLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
	textLabel.BackgroundTransparency = 1
	textLabel.TextStrokeTransparency = 0 
	textLabel.Size = UDim2.new(1, 0, 1, 0)
	textLabel.Font = Enum.Font.FredokaOne 
	textLabel.TextScaled = true 
	textLabel.Parent = billboard
end

createOverheadSymbol()