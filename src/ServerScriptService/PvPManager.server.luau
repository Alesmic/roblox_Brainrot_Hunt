local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

-- 1. 初始化远程事件
local pvpEvent = ReplicatedStorage:FindFirstChild("PvPEvent")
if not pvpEvent then
	pvpEvent = Instance.new("RemoteEvent")
	pvpEvent.Name = "PvPEvent"
	pvpEvent.Parent = ReplicatedStorage
end

local PvPManager = {}

-- ==========================================
-- 辅助：检查是否在安全区
-- ==========================================
local function isInSafeZone(character)
	-- 寻找场景中的 SafeZone 零件
	local safeZonePart = Workspace:FindFirstChild("SafeZone")
	if not safeZonePart then return false end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return false end

	-- 空间查询
	local partsInZone = Workspace:GetPartsInPart(safeZonePart)
	for _, part in pairs(partsInZone) do
		if part == rootPart then
			return true
		end
	end
	return false
end

-- ==========================================
-- 核心功能：切换 PVP 状态
-- ==========================================
local function updatePvPStatus(player, isEnabled, reason)
	local char = player.Character
	if not char then return end

	-- 1. 开启时的安全区检查 (防止在安全区内开启)
	if isEnabled then
		if isInSafeZone(char) then
			pvpEvent:FireClient(player, "Error", "此为安全区，禁止开启PvP")
			return 
		end
	end

	-- 2. 设置属性
	player:SetAttribute("PvPEnabled", isEnabled)

	-- 3. 视觉反馈
	local oldHighlight = char:FindFirstChild("PvP_Highlight")
	if oldHighlight then oldHighlight:Destroy() end

	if isEnabled then
		local highlight = Instance.new("Highlight")
		highlight.Name = "PvP_Highlight"
		highlight.Adornee = char
		highlight.FillTransparency = 1 
		highlight.OutlineColor = Color3.fromRGB(255, 0, 0) -- 红色轮廓
		highlight.OutlineTransparency = 0
		highlight.Parent = char

		-- 头顶名字提示
		local humanoid = char:FindFirstChild("Humanoid")
		if humanoid then humanoid.DisplayName = "⚔️ " .. player.Name end
	else
		-- 恢复名字
		local humanoid = char:FindFirstChild("Humanoid")
		if humanoid then humanoid.DisplayName = player.Name end
	end

	-- 4. 通知客户端更新 UI
	pvpEvent:FireClient(player, "UpdateState", isEnabled)

	-- 如果有额外原因（比如被强制关闭），可以发个提示
	if reason then
		pvpEvent:FireClient(player, "Error", reason)
	end

	print(player.Name .. (isEnabled and " 开启了 PVP" or " 关闭了 PVP"))
end

-- ==========================================
-- [新增] 自动检测循环：进入安全区强制关闭
-- ==========================================
task.spawn(function()
	while true do
		task.wait(0.5) -- 每 0.5 秒检查一次，性能消耗很低

		for _, player in pairs(Players:GetPlayers()) do
			-- 只检查当前开启了 PvP 的玩家
			if player:GetAttribute("PvPEnabled") then
				local char = player.Character
				if char and isInSafeZone(char) then
					-- 强制关闭
					print("🛡️ [安全区] 强制关闭 " .. player.Name .. " 的 PvP 模式")
					updatePvPStatus(player, false, "进入安全区，PvP已自动关闭")
				end
			end
		end
	end
end)

-- ==========================================
-- 事件监听
-- ==========================================
pvpEvent.OnServerEvent:Connect(function(player, action)
	if action == "TogglePvP" then
		local currentState = player:GetAttribute("PvPEnabled") or false
		updatePvPStatus(player, not currentState)
	end
end)

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function()
		updatePvPStatus(player, false)
	end)
end)

return PvPManager