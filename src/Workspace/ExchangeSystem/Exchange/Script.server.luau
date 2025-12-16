-- 位置: Workspace -> ExchangeSystem -> ExchangeWall -> Script
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

-- 弹窗文字
local PROMPT_TEXT = "Whether to enter the exchange"
-- =========================================

local inPart = folder:WaitForChild(IN_PART_NAME)
local outPart = folder:WaitForChild(OUT_PART_NAME)

-- ❄️ [升级版] 强力冻结/解冻函数
local function freezePlayer(player, freeze)
	local char = player.Character
	if char then
		local humanoid = char:FindFirstChild("Humanoid")
		local rootPart = char:FindFirstChild("HumanoidRootPart") -- 获取核心部位

		if humanoid and rootPart then
			if freeze then
				-- 1. 锚定核心 (最关键一步，防止惯性滑动)
				rootPart.Anchored = true 
				-- 2. 速度归零
				humanoid.WalkSpeed = 0
				humanoid.JumpPower = 0
			else
				-- 1. 解除锚定
				rootPart.Anchored = false
				-- 2. 恢复速度 (这里假设默认是 16，如果你的游戏有加速鞋，需读取 GameConfig)
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

		-- A. 立即冻结！
		player:SetAttribute("IsAskingExchange", true)
		freezePlayer(player, true) 

		-- B. 发送弹窗
		bossEvent:FireClient(player, "ASK_FIGHT", PROMPT_TEXT)

		-- C. 监听回复
		local connection
		connection = bossEvent.OnServerEvent:Connect(function(client, response)
			if client == player then
				if response == "YES" then
					print("✅ " .. player.Name .. " 进入交易所")

					-- 先解冻 (否则传送过去也是定住的)
					freezePlayer(player, false)

					-- 再传送
					if player.Character then
						player.Character:PivotTo(inPart.CFrame)
					end

				elseif response == "NO" then
					print("❌ " .. player.Name .. " 拒绝进入")

					-- 先解冻
					freezePlayer(player, false)

					-- 传送到外面 (防止卡在墙里触发二次弹窗)
					if player.Character then
						player.Character:PivotTo(outPart.CFrame)
					end
				end

				-- 清理状态
				player:SetAttribute("IsAskingExchange", nil)
				if connection then connection:Disconnect() end
			end
		end)

		-- D. 超时处理 (10秒不选自动解冻)
		task.delay(10, function() 
			if player:GetAttribute("IsAskingExchange") then
				-- 必须解冻，否则玩家就永远动不了了
				freezePlayer(player, false)
				player:SetAttribute("IsAskingExchange", nil)
				if connection then connection:Disconnect() end

				-- 超时弹出到外面
				if player.Character then
					player.Character:PivotTo(outPart.CFrame)
				end
			end
		end)
	end
end)