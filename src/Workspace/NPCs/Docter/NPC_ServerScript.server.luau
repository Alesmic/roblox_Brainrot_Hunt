-- 位置: Workspace -> DoctorNPC -> NPC_ServerScript (服务器脚本)
local npc = script.Parent
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- 1. 获取 RemoteEvent 文件夹
local RemoteEventFolder = ReplicatedStorage:WaitForChild("RemoteEvent")

-- ⚠️ [关键修改] 这里必须指向 "ToggleHealerWindow"
-- 如果写成 "ToggleWindow"，它就会打开那个卖剑的普通商店！
local openDoctorEvent = RemoteEventFolder:WaitForChild("ToggleHealerWindow")

-- 2. 获取交互提示
local prompt = npc:FindFirstChild("ProximityPrompt") 
	or (npc:FindFirstChild("HumanoidRootPart") and npc.HumanoidRootPart:FindFirstChild("ProximityPrompt"))

if prompt then
	prompt.Triggered:Connect(function(player)
		-- [新增] 检查玩家是否开启了 PvP
		local isPvP = player:GetAttribute("PvPEnabled")

		if isPvP then
			print("🚫 [NPC] 拒绝服务: 玩家处于 PvP 模式")

			-- 发送提示给玩家 (使用 RemoteEvent 通知客户端弹窗或显示文字)
			local pvpEvent = ReplicatedStorage:FindFirstChild("PvPEvent")
			if pvpEvent then
				pvpEvent:FireClient(player, "Error", "战斗状态下无法交易！请先关闭 PvP。")
			end

			return -- ⚠️ 直接结束，不执行下面的商店逻辑
		end

		-- [原有逻辑] 下面是你原来的商店代码，保持不变
		print("🖱️ [服务器] 玩家 " .. player.Name .. " 打开了商店")
		local shopEvent = ReplicatedStorage:FindFirstChild("ShopEvent") -- 假设你的商店事件
		if shopEvent then
			shopEvent:FireClient(player, "OpenShop", "Weapons") 
		end
	end)
else
	warn("❌ DoctorNPC 找不到 ProximityPrompt")
end