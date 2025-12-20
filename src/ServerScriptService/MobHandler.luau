local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

local MobHandler = {}

-- ==========================================
-- Configuration Area
-- ==========================================
local RESPAWN_TIME = 300       -- Respawn cooldown: 5 minutes
local CORPSE_LIFETIME = 3      -- Corpse retention time (seconds)

-- Store mob templates
local MobRegistry = {} 
local mobTemplateFolder = ServerStorage:FindFirstChild("MobTemplates")
if not mobTemplateFolder then
	mobTemplateFolder = Instance.new("Folder")
	mobTemplateFolder.Name = "MobTemplates"
	mobTemplateFolder.Parent = ServerStorage
end

-- Record respawn times
MobHandler.DeadBosses = {} 

function MobHandler.getRespawnTime(mobName)
	return MobHandler.DeadBosses[mobName]
end

-- ==========================================
-- Helper Function: Give Item (Keep your loot logic)
-- ==========================================
local function giveItemToPlayer(player, itemName)
	local tool = ServerStorage:FindFirstChild("Tools") and ServerStorage.Tools:FindFirstChild(itemName)
	if not tool then
		tool = ServerStorage:FindFirstChild("Items") and ServerStorage.Items:FindFirstChild(itemName)
	end

	if tool then
		local clone = tool:Clone()
		clone.Parent = player.Backpack

		-- Write to inventory data
		local inventory = player:FindFirstChild("Inventory")
		if inventory then
			local itemVal = inventory:FindFirstChild(itemName)
			if not itemVal then
				itemVal = Instance.new("IntValue")
				itemVal.Name = itemName
				itemVal.Value = 0
				itemVal.Parent = inventory
			end
			itemVal.Value = itemVal.Value + 1
		end
		return true
	else
		warn("❌ [MobHandler] Loot item '"..itemName.."' not found in ServerStorage!")
		return false
	end
end

-- ==========================================
-- Core Logic: Handle Mob Death Cycle
-- ==========================================
local function handleMobLifecycle(mob, originCFrame)
	local humanoid = mob:WaitForChild("Humanoid", 10)
	if not humanoid then return end

	-- Listen for death
	humanoid.Died:Connect(function()
		print("💀 [MobHandler] " .. mob.Name .. " has died")

		-- [Added] 1. Record respawn time (Prevent being detected as existing before respawn)
		MobHandler.DeadBosses[mob.Name] = os.time() + RESPAWN_TIME

		-- Get killer
		local creatorTag = humanoid:FindFirstChild("creator")
		local killerPlayer = creatorTag and creatorTag.Value

		if killerPlayer then
			print("    🗡️ Killer: " .. killerPlayer.Name)
			local mobConfig = GameConfig.Mobs[mob.Name]

			if mobConfig then
				-- A. Give experience
				local leaderstats = killerPlayer:FindFirstChild("leaderstats")
				if leaderstats and leaderstats:FindFirstChild("Experience") then
					leaderstats.Experience.Value = leaderstats.Experience.Value + mobConfig.Exp
				end

				-- B. Give gold (if configured)
				if leaderstats and leaderstats:FindFirstChild("Gold") and mobConfig.GoldReward then
					leaderstats.Gold.Value = leaderstats.Gold.Value + mobConfig.GoldReward
				end

				-- C. Update quest progress (Quest)
				local hiddenStats = killerPlayer:FindFirstChild("HiddenStats")
				if hiddenStats and GameConfig.Quests then
					for questID, questData in pairs(GameConfig.Quests) do
						if questData.TargetMob == mob.Name then
							local questStat = hiddenStats:FindFirstChild("Quest_" .. questID)
							if questStat and questStat.Value < questData.TargetCount then
								questStat.Value = questStat.Value + 1
								-- Simple immediate quest completion reward
								if questStat.Value == questData.TargetCount and questData.GoldReward then
									if leaderstats and leaderstats.Gold then
										leaderstats.Gold.Value = leaderstats.Gold.Value + questData.GoldReward
									end
								end
							end
						end
					end
				end

				-- D. Item drops (Drops)
				if mobConfig.Drops then
					for _, dropData in pairs(mobConfig.Drops) do
						if math.random() <= dropData.Chance then
							local success = giveItemToPlayer(killerPlayer, dropData.ItemName)
							if success then
								print("    🎁 Dropped item: " .. dropData.ItemName)
							end
						end
					end
				end
			end
		end

		-- [Critical] 2. Notify BossRoomManager (Victory settlement)
		local notifyEvent = ServerStorage:FindFirstChild("BossDeathNotify")
		if notifyEvent then
			print("📡 [MobHandler] Sending Boss death notification: " .. mob.Name)
			notifyEvent:Fire(mob.Name)
		else
			-- Fallback: Try to find in _G if event not found on first run
			if _G.BossRoomManager then
				_G.BossRoomManager.onBossDeath(mob.Name)
			else
				warn("⚠️ [MobHandler] BossDeathNotify event not found, and _G.BossRoomManager is missing!")
			end
		end

		-- 3. Corpse cleanup
		task.delay(CORPSE_LIFETIME, function()
			if mob and mob.Parent then mob:Destroy() end
		end)

		-- 4. Respawn countdown
		task.delay(RESPAWN_TIME, function()
			MobHandler.respawnMob(mob.Name, originCFrame)
		end)
	end)
end

-- ==========================================
-- Respawn and Initialization Functions
-- ==========================================
function MobHandler.respawnMob(mobName, spawnCFrame)
	local template = MobRegistry[mobName]
	if template then
		MobHandler.DeadBosses[mobName] = nil -- Clear death record

		local newMob = template:Clone()
		newMob.Name = mobName
		local root = newMob:FindFirstChild("HumanoidRootPart") or newMob:FindFirstChild("Torso")
		if root then root.CFrame = spawnCFrame else newMob:PivotTo(spawnCFrame) end

		newMob.Parent = Workspace:WaitForChild("NPCs")

		-- Rebind lifecycle
		handleMobLifecycle(newMob, spawnCFrame)
		MobHandler.setupMob(newMob)

		print("✨ " .. mobName .. " has respawned!")
	end
end

function MobHandler.setupMob(mob)
	local config = GameConfig.Mobs[mob.Name]
	if not config then return end

	local humanoid = mob:WaitForChild("Humanoid", 10)
	if humanoid then
		humanoid.MaxHealth = config.MaxHealth
		humanoid.Health = config.MaxHealth
		humanoid.WalkSpeed = config.WalkSpeed or 12
	end
end

-- ==========================================
-- Initialization: Scan existing mobs and create templates
-- ==========================================
local npcFolder = Workspace:WaitForChild("NPCs")

for _, mob in pairs(npcFolder:GetChildren()) do
	if GameConfig.Mobs[mob.Name] then
		local root = mob:FindFirstChild("HumanoidRootPart") or mob:FindFirstChild("Torso")
		local originCF = root and root.CFrame or mob:GetPivot()

		-- Create backup template (for respawning)
		if not MobRegistry[mob.Name] then
			local template = mob:Clone()
			for _, script in pairs(template:GetDescendants()) do
				if script:IsA("Script") then script:Destroy() end
			end
			template.Parent = mobTemplateFolder
			MobRegistry[mob.Name] = template
		end

		handleMobLifecycle(mob, originCF)
		MobHandler.setupMob(mob)
	end
end

return MobHandler