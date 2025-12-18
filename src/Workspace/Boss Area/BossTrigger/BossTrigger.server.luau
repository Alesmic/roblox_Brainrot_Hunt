local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

-- 引入 MobHandler 用于获取复活时间
local MobHandler = require(ServerScriptService:WaitForChild("MobHandler"))

-- ==========================================
-- [关键] 这里必须修改为当前房间对应的 Boss 名字
-- ==========================================
local BOSS_NAME = "AntBoss" -- <--- 如果是新Boss，请在这里改成新名字！
local MIN_LEVEL = 50
-- ==========================================

local triggerPart = script.Parent
local BossEvent = ReplicatedStorage:WaitForChild("RemoteEvent"):WaitForChild("BossEvent")
local debounce = {}

triggerPart.Touched:Connect(function(hit)
	local player = Players:GetPlayerFromCharacter(hit.Parent)
	if not player then return end

	if debounce[player.UserId] and (os.time() - debounce[player.UserId] < 2) then return end
	debounce[player.UserId] = os.time()

	-- 1. 等级检查
	local level = 0
	if player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Level") then
		level = player.leaderstats.Level.Value
	end

	if level < MIN_LEVEL then
		BossEvent:FireClient(player, "Error", "Level " .. MIN_LEVEL .. " Required!")
		return
	end

	-- 2. Boss 存活/冷却检查
	local boss = Workspace:WaitForChild("NPCs"):FindFirstChild(BOSS_NAME)
	if not boss then
		local respawnTimestamp = MobHandler.getRespawnTime(BOSS_NAME)
		if respawnTimestamp then
			local timeLeft = math.max(0, respawnTimestamp - os.time())
			-- 发送倒计时 (带名字)
			BossEvent:FireClient(player, "ShowRespawnCountDown", {Name = BOSS_NAME, Time = timeLeft})
		else
			BossEvent:FireClient(player, "Error", "Boss Missing (Error)")
		end
		return
	end

	-- 3. [核心修改] 发送弹窗请求，并把 BOSS_NAME 传给客户端
	BossEvent:FireClient(player, "ShowConfirm", BOSS_NAME) 
end)