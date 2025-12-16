-- 位置: Workspace -> Boss Area -> BossTrigger -> Script
local triggerPart = script.Parent
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- 引入配置
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local RemoteEventFolder = ReplicatedStorage:WaitForChild("RemoteEvent")
local bossEvent = RemoteEventFolder:WaitForChild("BossBattleEvent")

-- =================配置区域=================
local BOSS_NAME = "Samurai Boss" 
local BARRIER_NAME = "BossBarrier"
local EXIT_POINT_NAME = "BossRoomExitPoint"
local ARENA_SPAWN_NAME = "BossArenaSpawn" -- [新增] 战斗开始传送点
-- =========================================

-- 获取同级文件夹内的物体
local folder = script.Parent.Parent
local barrier = folder:WaitForChild(BARRIER_NAME)
local exitPoint = folder:WaitForChild(EXIT_POINT_NAME)
local arenaSpawn = folder:WaitForChild(ARENA_SPAWN_NAME)
local bossModel = folder:WaitForChild(BOSS_NAME) -- 确保 Boss 在文件夹里，或改成 workspace:WaitForChild(BOSS_NAME)

local bossHumanoid = bossModel:WaitForChild("Humanoid")
local bossRoot = bossModel:WaitForChild("HumanoidRootPart")
local bossOriginCFrame = bossRoot.CFrame

local isFighting = false
local currentChallenger = nil

barrier.CanCollide = false 
barrier.Transparency = 1 

-- 辅助函数：冻结/解冻玩家
local function freezePlayer(player, freeze)
	local char = player.Character
	if char and char:FindFirstChild("Humanoid") then
		if freeze then
			char.Humanoid.WalkSpeed = 0
			char.Humanoid.JumpPower = 0
		else
			-- 恢复默认速度 (从配置读取或给定值)
			char.Humanoid.WalkSpeed = 16 
			char.Humanoid.JumpPower = 50
		end
	end
end

-- 1. 玩家触碰触发器
triggerPart.Touched:Connect(function(hit)
	if isFighting then return end

	local player = Players:GetPlayerFromCharacter(hit.Parent)
	if player and not player:GetAttribute("IsAskingBoss") then

		local leaderstats = player:FindFirstChild("leaderstats")
		local level = leaderstats and leaderstats:FindFirstChild("Level").Value or 0
		local bossConfig = GameConfig.Mobs[BOSS_NAME]

		if not bossConfig then warn("配置缺失") return end
		local requiredLevel = bossConfig.UnlockLevel or 20

		if level >= requiredLevel then
			-- A. 满足等级 -> 冻结玩家并弹窗
			player:SetAttribute("IsAskingBoss", true)
			freezePlayer(player, true) -- ❄️ 冻结！

			bossEvent:FireClient(player, "ASK_FIGHT", BOSS_NAME)

			local connection
			connection = bossEvent.OnServerEvent:Connect(function(client, response)
				if client == player then
					if response == "YES" then
						startBattle(player)
					elseif response == "NO" then
						-- 选择 No -> 解冻并传送到门外
						freezePlayer(player, false)
						player.Character:PivotTo(exitPoint.CFrame)
						player:SetAttribute("IsAskingBoss", nil)
					end
					if connection then connection:Disconnect() end
				end
			end)

			-- 超时处理 (防止挂机卡住)
			task.delay(10, function() 
				if player:GetAttribute("IsAskingBoss") then
					freezePlayer(player, false)
					player:SetAttribute("IsAskingBoss", nil)
					if connection then connection:Disconnect() end
				end
			end)
		else
			-- B. 等级不足 -> 发送提示
			bossEvent:FireClient(player, "SHOW_ERROR", "Level " .. requiredLevel .. " Unlock")
		end
	end
end)

-- 2. 开始战斗逻辑
function startBattle(player)
	if isFighting then return end
	isFighting = true
	currentChallenger = player

	print("⚔️ 战斗开始")

	-- 1. 解冻并传送到场内
	freezePlayer(player, false)
	player.Character:PivotTo(arenaSpawn.CFrame) -- 传送！

	-- 2. 封锁区域
	barrier.CanCollide = true
	barrier.Transparency = 0.5 
	barrier.Color = Color3.fromRGB(255, 0, 0)

	-- 3. Boss 归位
	bossModel:PivotTo(bossOriginCFrame)
	bossHumanoid.Health = bossHumanoid.MaxHealth

	-- [关键] 激活 Boss AI (如果有名为 'AI' 的脚本)
	local aiScript = bossModel:FindFirstChild("AI") or bossModel:FindFirstChild("BossAI")
	if aiScript then aiScript.Enabled = true end

	bossEvent:FireClient(player, "START_UI", {Name = BOSS_NAME, Humanoid = bossHumanoid})

	-- 4. 胜负监听
	local char = player.Character
	local hum = char and char:FindFirstChild("Humanoid")

	local playerDiedConn
	local bossDiedConn
	local removingConn

	if hum then
		playerDiedConn = hum.Died:Connect(function() endBattle(false) end)
	end

	bossDiedConn = bossHumanoid.Died:Connect(function() endBattle(true) end)

	removingConn = Players.PlayerRemoving:Connect(function(p)
		if p == player then endBattle(false) end
	end)

	function cleanUpConns()
		if playerDiedConn then playerDiedConn:Disconnect() end
		if bossDiedConn then bossDiedConn:Disconnect() end
		if removingConn then removingConn:Disconnect() end
	end

	function endBattle(playerWon)
		cleanUpConns()
		isFighting = false
		currentChallenger = nil

		if player then
			bossEvent:FireClient(player, "STOP_UI")
			player:SetAttribute("IsAskingBoss", nil)
		end

		barrier.CanCollide = false
		barrier.Transparency = 1

		-- 停用 AI
		if aiScript then aiScript.Enabled = false end

		if playerWon then
			task.wait(5)
			bossHumanoid.Health = bossHumanoid.MaxHealth
			bossModel:PivotTo(bossOriginCFrame)
		else
			bossHumanoid.Health = bossHumanoid.MaxHealth
			bossModel:PivotTo(bossOriginCFrame)

			-- 战败复活传送到门外
			local respawnConn
			respawnConn = player.CharacterAdded:Connect(function(newChar)
				task.wait(0.5)
				newChar:PivotTo(exitPoint.CFrame)
				if respawnConn then respawnConn:Disconnect() end
			end)
		end
	end
end