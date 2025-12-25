local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

-- Boss 配置表 [Boss名称] = "对应的Quest Stat名称"
-- 请确保 BossName 与 Workspace 中的模型名字完全一致
local BOSS_CONFIG = {
	["Saharan Master"] = "Quest_KillDesertBoss",
	["WolfBoss"] = "Quest_KillWolfBoss",       -- 假设 Workspace 里叫 WolfBoss
	["DesertKing"] = "Quest_KillDesertKing"    -- 假设 Workspace 里叫 DesertKing
}

local function onHumanoidDied(bossName, player)
	local questStatName = BOSS_CONFIG[bossName]
	if not questStatName then return end

	local hiddenStats = player:FindFirstChild("HiddenStats")
	if not hiddenStats then return end

	-- 查找或创建对应的 Quest Stat
	local questStat = hiddenStats:FindFirstChild(questStatName)
	if not questStat then
		questStat = Instance.new("IntValue")
		questStat.Name = questStatName
		questStat.Parent = hiddenStats
	end

	-- 只有当任务没完成时才更新
	if questStat.Value < 1 then
		questStat.Value = 1
		print(player.Name .. " has defeated " .. bossName .. "!")
	end
end

-- 监听 Boss
local function setupBossListener(model)
	if BOSS_CONFIG[model.Name] then
		local humanoid = model:WaitForChild("Humanoid", 10)
		if humanoid then
			humanoid.Died:Connect(function()
				local creatorTag = humanoid:FindFirstChild("creator")
				if creatorTag and creatorTag.Value then
					local player = creatorTag.Value
					if player and player:IsA("Player") then
						onHumanoidDied(model.Name, player)
					end
				else
					-- 无主击杀，奖励给附近玩家
					local bossPos = model.PrimaryPart and model.PrimaryPart.Position or humanoid.RootPart.Position
					for _, player in ipairs(Players:GetPlayers()) do
						if player.Character and player.Character.PrimaryPart then
							local dist = (player.Character.PrimaryPart.Position - bossPos).Magnitude
							if dist < 100 then 
								onHumanoidDied(model.Name, player)
							end
						end
					end
				end
			end)
		end
	end
end

-- 初始化监听
for _, child in ipairs(Workspace:GetDescendants()) do
	if child:IsA("Model") then setupBossListener(child) end
end

Workspace.DescendantAdded:Connect(function(descendant)
	if descendant:IsA("Model") then setupBossListener(descendant) end
end)