local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

-- 引入配置和处理模块
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
-- 尝试引用 MobHandler，如果没找到则不报错（兼容性）
local MobHandler
pcall(function() 
	MobHandler = require(ServerScriptService:WaitForChild("MobHandler")) 
end)

local MobAI = {}
local ACTIVE_MOBS = {} -- 存储正在运行的怪物

-- ==========================================
-- [新增] 辅助函数：检查是否在安全区
-- ==========================================
local function isInSafeZone(character)
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
-- AI 核心逻辑: 寻找最近的玩家
-- ==========================================
local function findNearestPlayer(rootPart, range)
	local nearestPlr = nil
	local minDst = range or 20 -- 默认侦测范围 20

	for _, player in pairs(Players:GetPlayers()) do
		local char = player.Character
		if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Humanoid") then
			local hum = char.Humanoid
			-- 判定条件：
			-- 1. 玩家活着 (Health > 0)
			-- 2. 玩家不在安全区内 (not isInSafeZone) [关键修改]
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
-- 激活单个怪物
-- ==========================================
function MobAI.initializeMob(mob)
	if ACTIVE_MOBS[mob] then return end -- 防止重复初始化

	-- 1. 验证配置
	local config = GameConfig.Mobs[mob.Name]
	if not config then 
		-- print("   [AI] 跳过无关 NPC: " .. mob.Name) 
		return 
	end

	print("🤖 [AI] 接管怪物: " .. mob.Name)
	ACTIVE_MOBS[mob] = true

	-- 2. 获取关键部件 (兼容 R6 和 R15)
	local humanoid = mob:WaitForChild("Humanoid", 5)
	local rootPart = mob:WaitForChild("HumanoidRootPart", 5) or mob:WaitForChild("Torso", 5)

	if not humanoid or not rootPart then
		warn("❌ [AI] " .. mob.Name .. " 缺少 Humanoid 或 RootPart，无法移动！")
		return
	end

	-- 3. 强制初始化属性 (防卡死)
	humanoid.WalkSpeed = config.WalkSpeed or 12
	humanoid.MaxHealth = config.MaxHealth
	humanoid.Health = config.MaxHealth

	-- 确保怪物不被冻结
	for _, part in pairs(mob:GetDescendants()) do
		if part:IsA("BasePart") then part.Anchored = false end
	end

	-- 如果有 MobHandler，进行掉落/血量设置
	if MobHandler and MobHandler.setupMob then
		MobHandler.setupMob(mob)
	end

	-- 4. 启动 AI 循环 (使用 task.spawn 独立运行)
	task.spawn(function()
		while mob and mob.Parent do
			if humanoid.Health <= 0 then break end

			-- 寻找目标 (侦测范围 50)
			local target = findNearestPlayer(rootPart, 50) 

			if target then
				-- A. 追击模式
				humanoid:MoveTo(target.Position)

				-- 攻击判断
				local dist = (target.Position - rootPart.Position).Magnitude
				if dist <= (config.AttackRange or 5) then
					-- 这里可以播放攻击动画
					-- 造成伤害 (简单版)
					if os.time() % (config.AttackSpeed or 1.5) < 0.1 then
						local targetHum = target.Parent:FindFirstChild("Humanoid")
						if targetHum then
							targetHum:TakeDamage(config.Damage)
						end
					end
				end
			else
				-- B. 巡逻模式 (随机走动) - 可选
				-- humanoid:MoveTo(rootPart.Position + Vector3.new(math.random(-10,10), 0, math.random(-10,10)))
			end

			task.wait(0.2) -- AI 刷新频率
		end
		ACTIVE_MOBS[mob] = nil
	end)
end

-- ==========================================
-- 自动扫描系统
-- ==========================================
local npcFolder = Workspace:WaitForChild("NPCs")

-- 1. 扫描现有怪物
for _, child in pairs(npcFolder:GetChildren()) do
	MobAI.initializeMob(child)
end

-- 2. 监听新生成的怪物
npcFolder.ChildAdded:Connect(function(child)
	MobAI.initializeMob(child)
end)

return MobAI