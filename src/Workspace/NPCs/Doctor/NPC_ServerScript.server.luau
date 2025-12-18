-- 位置: Workspace -> DoctorNPC -> NPC_ServerScript (服务器脚本)
local npc = script.Parent
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- 1. 获取 RemoteEvent 文件夹
local RemoteEventFolder = ReplicatedStorage:WaitForChild("RemoteEvent")

-- ⚠️ [关键] 必须指向 "ToggleHealerWindow" (对应客户端 DoctorShop_Local)
local openDoctorEvent = RemoteEventFolder:WaitForChild("ToggleHealerWindow")

-- 2. 获取交互提示
local prompt = npc:FindFirstChild("ProximityPrompt") 
	or (npc:FindFirstChild("HumanoidRootPart") and npc.HumanoidRootPart:FindFirstChild("ProximityPrompt"))

if prompt then
	prompt.Triggered:Connect(function(player)
		-- ==========================================
		-- 1. PvP 检查 (优先拦截)
		-- ==========================================
		local isPvP = player:GetAttribute("PvPEnabled")

		if isPvP then
			print("🚫 [NPC] 拒绝服务: 玩家处于 PvP 模式")
			local pvpEvent = ReplicatedStorage:FindFirstChild("PvPEvent")
			if pvpEvent then
				pvpEvent:FireClient(player, "Error", "战斗状态下无法治疗！请先关闭 PvP。")
			end
			return -- 🛑 必须在这里结束
		end

		-- ==========================================
		-- 2. 打开医生商店 (核心修复)
		-- ==========================================
		print("🚑 [服务器] 玩家 " .. player.Name .. " 请求治疗/购买物品")

		-- ❌ 错误代码 (原先的):
		-- local shopEvent = ReplicatedStorage:FindFirstChild("ShopEvent")
		-- shopEvent:FireClient(player, "OpenShop", "Weapons") 

		-- ✅ 正确代码: 使用上面定义的 openDoctorEvent
		openDoctorEvent:FireClient(player) 
	end)
else
	warn("❌ DoctorNPC 找不到 ProximityPrompt")
end