local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

-- Import configuration and handling modules
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
-- Try to require MobHandler, do not error if not found (Compatibility)
local MobHandler
pcall(function() 
	MobHandler = require(ServerScriptService:WaitForChild("MobHandler")) 
end)

local MobAI = {}
local ACTIVE_MOBS = {} -- Stores currently active mobs

-- ==========================================
-- AI Core Logic: Find nearest player
-- ==========================================
local function findNearestPlayer(rootPart, range)
	local nearestPlr = nil
	local minDst = range or 20 -- Default detection range 20

	for _, player in pairs(Players:GetPlayers()) do
		local char = player.Character
		if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Humanoid") then
			local hum = char.Humanoid
			if hum.Health > 0 then
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
-- Activate a single mob
-- ==========================================
function MobAI.initializeMob(mob)
	if ACTIVE_MOBS[mob] then return end -- Prevent duplicate initialization

	-- 1. Verify Configuration
	local config = GameConfig.Mobs[mob.Name]
	if not config then 
		-- print("   [AI] Skipping irrelevant NPC: " .. mob.Name) 
		return 
	end

	print("🤖 [AI] Taking control of mob: " .. mob.Name)
	ACTIVE_MOBS[mob] = true

	-- 2. Get key parts (Compatible with R6 and R15)
	local humanoid = mob:WaitForChild("Humanoid", 5)
	local rootPart = mob:WaitForChild("HumanoidRootPart", 5) or mob:WaitForChild("Torso", 5)

	if not humanoid or not rootPart then
		warn("❌ [AI] " .. mob.Name .. " missing Humanoid or RootPart, cannot move!")
		return
	end

	-- 3. Force initialize attributes (Prevent getting stuck)
	humanoid.WalkSpeed = config.WalkSpeed or 12
	humanoid.MaxHealth = config.MaxHealth
	humanoid.Health = config.MaxHealth

	-- Ensure mob is not anchored
	for _, part in pairs(mob:GetDescendants()) do
		if part:IsA("BasePart") then part.Anchored = false end
	end

	-- If MobHandler exists, setup drops/health
	if MobHandler and MobHandler.setupMob then
		MobHandler.setupMob(mob)
	end

	-- 4. Start AI Loop (Run independently using task.spawn)
	task.spawn(function()
		while mob and mob.Parent do
			if humanoid.Health <= 0 then break end

			-- Find target
			local target = findNearestPlayer(rootPart, 50) -- 50 is the max detection distance

			if target then
				-- A. Chase Mode
				humanoid:MoveTo(target.Position)

				-- Attack Check
				local dist = (target.Position - rootPart.Position).Magnitude
				if dist <= (config.AttackRange or 5) then
					-- Can play attack animation here
					-- Deal Damage (Simple version)
					if os.time() % (config.AttackSpeed or 1.5) < 0.1 then
						local targetHum = target.Parent:FindFirstChild("Humanoid")
						if targetHum then
							targetHum:TakeDamage(config.Damage)
						end
					end
				end
			else
				-- B. Patrol Mode (Random wandering) - Optional
				-- humanoid:MoveTo(rootPart.Position + Vector3.new(math.random(-10,10), 0, math.random(-10,10)))
			end

			task.wait(0.2) -- AI refresh rate
		end
		ACTIVE_MOBS[mob] = nil
	end)
end

-- ==========================================
-- Auto Scan System
-- ==========================================
local npcFolder = Workspace:WaitForChild("NPCs")

-- 1. Scan existing mobs
for _, child in pairs(npcFolder:GetChildren()) do
	MobAI.initializeMob(child)
end

-- 2. Listen for newly spawned mobs
npcFolder.ChildAdded:Connect(function(child)
	MobAI.initializeMob(child)
end)

return MobAI