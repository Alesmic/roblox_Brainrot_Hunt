local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

-- 引入配置和处理模块
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local MobHandler
pcall(function() 
	MobHandler = require(ServerScriptService:WaitForChild("MobHandler")) 
end)

local MobAI = {}
local ACTIVE_MOBS = {} 

-- ==========================================
-- 🚫 忽略列表 (在此添加不希望 AI 控制的 NPC)
-- ==========================================
local IGNORE_LIST = {
	["Buyer/Seller"] = true,
	["SkinSeller"] = true,
	["Doctor"] = true,
	["Tung Tung Sahur"] = true,
	["Ring"] = true, -- 场景物体
	["SpawnPoint"] = true,
}

-- ==========================================
-- 配置参数
-- ==========================================
local ACTIVATION_DISTANCE = 50   -- 追击范围
local ACTIVE_UPDATE_RATE = 0.2   -- 追击刷新率
local IDLE_UPDATE_RATE = 4.0     -- 巡逻刷新率
local WANDER_RADIUS = 15         -- 巡逻范围

-- ==========================================
-- 核心修复：获取真实的怪物名字
-- ==========================================
local function getRealMobName(model)
	-- 1. 如果名字直接在配置里，直接返回
	if GameConfig.Mobs[model.Name] then 
		return model.Name 
	end

	-- 2. 尝试处理被改名的 Boss
	-- 例如: "[Boss] Saharan Master (Lv. 300)..." -> 提取 "Saharan Master"
	-- 匹配规则：查找 [Boss] 和 (Lv 之间的文字
	local cleanName = string.match(model.Name, "^%[Boss%]%s+(.-)%s+%(")
	if cleanName and GameConfig.Mobs[cleanName] then
		return cleanName
	end

	-- 3. 还是找不到，返回 nil
	return nil
end

-- ==========================================
-- 辅助函数：安全区检测
-- ==========================================
local function isInSafeZone(character)
	local safeZonePart = Workspace:FindFirstChild("SafeZone")
	if not safeZonePart then return false end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return false end

	local partsInZone = Workspace:GetPartsInPart(safeZonePart)
	for _, part in pairs(partsInZone) do
		if part == rootPart then return true end
	end
	return false
end

-- ==========================================
-- 寻找最近玩家
-- ==========================================
local function findNearestPlayer(rootPart, range)
	local nearestPlr = nil
	local minDst = range 

	for _, player in pairs(Players:GetPlayers()) do
		local char = player.Character
		if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Humanoid") then
			local hum = char.Humanoid
			if hum.Health > 0 and not isInSafeZone(char) then
				local dst = (char.HumanoidRootPart.Position - rootPart.Position).Magnitude
				if dst < minDst then
					minDst = dst
					nearestPlr = char.HumanoidRootPart
				end
			end
		end
	end
	return nearestPlr
end

-- ==========================================
-- 激活怪物
-- ==========================================
function MobAI.initializeMob(mob)
	if ACTIVE_MOBS[mob] then return end 

	-- 1. [过滤] 检查是否在忽略列表
	if IGNORE_LIST[mob.Name] then return end

	-- 2. [过滤] 检查是否是有效的生物 (必须有 Humanoid)
	-- 这能过滤掉像 'Ring' 这样的纯零件
	local humanoid = mob:FindFirstChild("Humanoid")
	if not humanoid then return end 

	-- 3. [修复] 获取真实名字并读取配置
	local realName = getRealMobName(mob)
	local config = realName and GameConfig.Mobs[realName]

	if not config then 
		-- 只有当它看起来像个怪(有Humanoid)但没配置时才警告
		warn("⚠️ [AI] 跳过: '" .. mob.Name .. "' (未在 GameConfig 找到配置，或名字被修改)")
		return 
	end

	ACTIVE_MOBS[mob] = true
	-- print("🤖 [AI] 启动: " .. realName)

	-- 4. 获取 RootPart
	local rootPart = mob:FindFirstChild("HumanoidRootPart") or mob:FindFirstChild("Torso")
	if not rootPart then return end

	-- 5. 初始化属性
	humanoid.WalkSpeed = config.WalkSpeed or 12
	humanoid.MaxHealth = config.MaxHealth

	-- 强制解冻
	for _, part in pairs(mob:GetDescendants()) do
		if part:IsA("BasePart") then part.Anchored = false end
	end

	pcall(function() rootPart:SetNetworkOwner(nil) end)

	if MobHandler and MobHandler.setupMob then
		-- 注意：如果 MobHandler 也依赖名字，这里可能会有问题，
		-- 但 setupMob 通常只依赖 Humanoid 设置血量
		MobHandler.setupMob(mob)
	end

	-- 6. 启动循环
	task.spawn(function()
		task.wait(math.random() * 2) 

		while mob and mob.Parent do
			if humanoid.Health <= 0 then break end

			local target = findNearestPlayer(rootPart, ACTIVATION_DISTANCE) 

			if target then
				-- [追击]
				humanoid:MoveTo(target.Position)
				local dist = (target.Position - rootPart.Position).Magnitude

				if dist <= (config.AttackRange or 5) then
					if os.time() % (config.AttackSpeed or 1.5) < 0.2 then
						local targetHum = target.Parent:FindFirstChild("Humanoid")
						if targetHum then
							targetHum:TakeDamage(config.Damage)
						end
					end
				end
				task.wait(ACTIVE_UPDATE_RATE)
			else
				-- [巡逻]
				local randomOffset = Vector3.new(
					math.random(-WANDER_RADIUS, WANDER_RADIUS), 
					0, 
					math.random(-WANDER_RADIUS, WANDER_RADIUS)
				)
				humanoid:MoveTo(rootPart.Position + randomOffset)
				task.wait(IDLE_UPDATE_RATE)
			end
		end
		ACTIVE_MOBS[mob] = nil
	end)
end

-- ==========================================
-- 自动扫描
-- ==========================================
local npcFolder = Workspace:WaitForChild("NPCs")

for _, child in pairs(npcFolder:GetChildren()) do
	MobAI.initializeMob(child)
end

npcFolder.ChildAdded:Connect(function(child)
	MobAI.initializeMob(child)
end)

return MobAI