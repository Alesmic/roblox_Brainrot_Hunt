-- 位置: Workspace -> ShopNPC -> NPC_ServerScript
local npc = script.Parent
local prompt = npc:WaitForChild("ProximityPrompt")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local remoteEvent = ReplicatedStorage:WaitForChild("RemoteEvent"):WaitForChild("ToggleWindow")

-- ❗ 新方案：直接使用 NPC 的名字作为类型
local npcType = npc.Name 
print("NPC名称作为类型: " .. npcType)

-- 当玩家按下 E 键
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