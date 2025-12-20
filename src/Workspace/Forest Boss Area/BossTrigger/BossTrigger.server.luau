local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

-- [Core] Import MobHandler to get respawn time
local MobHandler = require(ServerScriptService:WaitForChild("MobHandler"))

-- ==========================================
-- [Configuration] Original Boss name
-- ==========================================
local BOSS_NAME = "WolfBoss" -- <--- Ensure this is your original Boss name
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

	-- 1. Level check
	local level = 0
	if player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Level") then
		level = player.leaderstats.Level.Value
	end

	if level < MIN_LEVEL then
		BossEvent:FireClient(player, "Error", "Level " .. MIN_LEVEL .. " Required!")
		return
	end

	-- 2. Boss alive/cool-down check
	local boss = Workspace:WaitForChild("NPCs"):FindFirstChild(BOSS_NAME)

	-- [Core Fix] Show countdown if Boss is not present!
	if not boss then
		-- Get remaining time from MobHandler
		local respawnTimestamp = MobHandler.getRespawnTime(BOSS_NAME)

		if respawnTimestamp then
			local timeLeft = math.max(0, respawnTimestamp - os.time())
			-- Send countdown (with name)
			BossEvent:FireClient(player, "ShowRespawnCountDown", {Name = BOSS_NAME, Time = timeLeft})
		else
			-- If Boss is missing and MobHandler has no time record (server may have just started, or name is wrong)
			BossEvent:FireClient(player, "Error", "Boss is currently missing (No Timer Found).")
		end
		return
	end

	-- 3. Boss is alive, show challenge confirmation
	-- [Important] Send BOSS_NAME to client so clicking YES enters the correct room
	BossEvent:FireClient(player, "ShowConfirm", BOSS_NAME) 
end)