-- 位置: Workspace -> ExchangeSystem -> (出口墙部件) -> Script
local triggerPart = script.Parent
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- 引用资源
local RemoteEventFolder = ReplicatedStorage:WaitForChild("RemoteEvent")
local bossEvent = RemoteEventFolder:WaitForChild("BossBattleEvent") 

-- =================配置区域=================
local folder = script.Parent.Parent 

-- 确保文件夹里有这两个 Part
local IN_PART_NAME = "InPart" 
local OUT_PART_NAME = "outsidePart"

-- [修改] 弹窗文字：询问是否离开
local PROMPT_TEXT = "Do you want to leave the exchange?"
-- =========================================

local inPart = folder:WaitForChild(IN_PART_NAME)
local outPart = folder:WaitForChild(OUT_PART_NAME)

-- ❄️ 冻结/解冻函数 (保持不变)
local function freezePlayer(player, freeze)
	local char = player.Character
	if char then
		local humanoid = char:FindFirstChild("Humanoid")
		local rootPart = char:FindFirstChild("HumanoidRootPart")

		if humanoid and rootPart then
			if freeze then
				rootPart.Anchored = true 
				humanoid.WalkSpeed = 0
				humanoid.JumpPower = 0
			else
				rootPart.Anchored = false
				humanoid.WalkSpeed = 16 
				humanoid.JumpPower = 50
			end
		end
	end
end

-- 1. 玩家触碰识别墙
triggerPart.Touched:Connect(function(hit)
	local player = Players:GetPlayerFromCharacter(hit.Parent)

	-- 防止重复触发
	if player and not player:GetAttribute("IsAskingExchange") then

		-- A. 立即冻结
		player:SetAttribute("IsAskingExchange", true)
		freezePlayer(player, true) 

		-- B. 发送弹窗 (显示新的英文提示)
		bossEvent:FireClient(player, "ASK_FIGHT", PROMPT_TEXT)

		-- C. 监听回复
		local connection
		connection = bossEvent.OnServerEvent:Connect(function(client, response)
			if client == player then
				if response == "YES" then
					print("🏃 " .. player.Name .. " 离开交易所")

					-- 解冻
					freezePlayer(player, false)

					-- [修改] YES -> 传送到外面 (Outside)
					if player.Character then
						player.Character:PivotTo(outPart.CFrame)
					end

				elseif response == "NO" then
					print("🏠 " .. player.Name .. " 决定留下")

					-- 解冻
					freezePlayer(player, false)

					-- [修改] NO -> 传送到里面 (Inside)
					-- 防止玩家卡在墙里，把他传回交易所内部安全点
					if player.Character then
						player.Character:PivotTo(inPart.CFrame)
					end
				end

				-- 清理状态
				player:SetAttribute("IsAskingExchange", nil)
				if connection then connection:Disconnect() end
			end
		end)

		-- D. 超时处理 (10秒不选自动留在里面)
		task.delay(10, function() 
			if player:GetAttribute("IsAskingExchange") then
				freezePlayer(player, false)
				player:SetAttribute("IsAskingExchange", nil)
				if connection then connection:Disconnect() end

				-- [修改] 超时默认留在里面 (InPart)
				if player.Character then
					player.Character:PivotTo(inPart.CFrame)
				end
			end
		end)
	end
end)