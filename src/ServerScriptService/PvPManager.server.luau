local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

-- Import configuration
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local MIN_LEVEL = GameConfig.PvP and GameConfig.PvP.MinLevel or 20

-- Initialize RemoteEvent
local pvpEvent = ReplicatedStorage:FindFirstChild("PvPEvent")
if not pvpEvent then
	pvpEvent = Instance.new("RemoteEvent")
	pvpEvent.Name = "PvPEvent"
	pvpEvent.Parent = ReplicatedStorage
end

local PvPManager = {}

-- ==========================================
-- 1. Multi-SafeZone Detection System
-- ==========================================
local SafeZoneParts = {} -- Cache list

-- Refresh SafeZone list (Run on startup)
local function refreshSafeZones()
	table.clear(SafeZoneParts)
	for _, part in pairs(Workspace:GetDescendants()) do
		if part.Name == "SafeZone" and part:IsA("BasePart") then
			table.insert(SafeZoneParts, part)
		end
	end
	print("🛡️ [PvPManager] Loaded " .. #SafeZoneParts .. " SafeZones")
end

refreshSafeZones() -- Execute once on initialization

-- Check if player is in ANY SafeZone
local function isInSafeZone(character)
	if not character then return false end
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return false end

	for _, zonePart in pairs(SafeZoneParts) do
		if zonePart and zonePart.Parent then -- Ensure part still exists
			-- Use spatial query API
			local parts = Workspace:GetPartsInPart(zonePart)
			for _, part in pairs(parts) do
				if part == rootPart then
					return true -- Considered safe if in any zone
				end
			end
		end
	end
	return false
end

-- ==========================================
-- 2. PvP Status Management (Core)
-- ==========================================
local function updatePvPStatus(player, isEnabled, reason)
	local char = player.Character
	if not char then return end

	-- A. Checks when attempting to enable
	if isEnabled then
		-- 1. SafeZone check
		if isInSafeZone(char) then
			pvpEvent:FireClient(player, "Error", "PvP cannot be enabled in SafeZone!")
			return -- 🚫 Block
		end

		-- 2. Level check
		local level = 0
		if player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Level") then
			level = player.leaderstats.Level.Value
		end
		if level < MIN_LEVEL then
			pvpEvent:FireClient(player, "Error", "You need to reach level " .. MIN_LEVEL .. " to enable PvP!")
			return -- 🚫 Block
		end
	end

	-- B. Execute status change
	player:SetAttribute("PvPEnabled", isEnabled)

	-- C. Visual effects (Red outline)
	local oldHighlight = char:FindFirstChild("PvP_Highlight")
	if oldHighlight then oldHighlight:Destroy() end

	if isEnabled then
		local highlight = Instance.new("Highlight")
		highlight.Name = "PvP_Highlight"
		highlight.Adornee = char
		highlight.FillTransparency = 1 -- Transparent fill
		highlight.OutlineColor = Color3.fromRGB(255, 0, 0) -- Red outline
		highlight.OutlineTransparency = 0
		highlight.Parent = char

		local humanoid = char:FindFirstChild("Humanoid")
		if humanoid then humanoid.DisplayName = "⚔️ " .. player.Name end
	else
		local humanoid = char:FindFirstChild("Humanoid")
		if humanoid then humanoid.DisplayName = player.Name end
	end

	-- D. Notify client to update UI
	pvpEvent:FireClient(player, "UpdateState", isEnabled)

	-- E. Send prompt (if any)
	if reason then
		pvpEvent:FireClient(player, "Error", reason)
	end

	-- print(player.Name .. (isEnabled and " enabled PvP" or " disabled PvP"))
end

-- ==========================================
-- 3. Auto-detection loop (Auto-disable when entering SafeZone)
-- ==========================================
task.spawn(function()
	while true do
		task.wait(0.5) -- Check every 0.5 seconds

		for _, player in pairs(Players:GetPlayers()) do
			-- Only check players with PvP currently enabled
			if player:GetAttribute("PvPEnabled") then
				local char = player.Character
				if char and isInSafeZone(char) then
					-- ⚠️ Player with active PvP ran into SafeZone -> Force disable
					print("🛡️ [SafeZone] Forced PvP disable for " .. player.Name)
					updatePvPStatus(player, false, "Entered SafeZone, PvP has been automatically disabled")
				end
			end
		end
	end
end)

-- ==========================================
-- 4. Event Listeners
-- ==========================================
pvpEvent.OnServerEvent:Connect(function(player, action)
	if action == "TogglePvP" then
		local currentState = player:GetAttribute("PvPEnabled") or false
		-- Attempt to toggle state (SafeZone/level checks will be re-performed inside updatePvPStatus)
		updatePvPStatus(player, not currentState)
	end
end)

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function()
		-- Reset to disabled state on respawn
		updatePvPStatus(player, false)
	end)
end)

return PvPManager