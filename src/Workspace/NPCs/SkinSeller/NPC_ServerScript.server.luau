-- 位置: Workspace -> ShopNPC -> NPC_ServerScript
local npc = script.Parent
local prompt = npc:WaitForChild("ProximityPrompt")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- 1. 获取正确的远程事件 (对应客户端的 CyberShopController)
local remoteFolder = ReplicatedStorage:WaitForChild("RemoteEvent", 10)
if not remoteFolder then
	-- 如果文件夹不存在，尝试直接找 (兼容旧结构)
	warn("⚠️ RemoteEvent 文件夹未找到，尝试直接查找 ToggleWindow")
end

-- 优先从文件夹找，找不到则在根目录找
local remoteEvent = (remoteFolder and remoteFolder:FindFirstChild("ToggleWindow")) 
	or ReplicatedStorage:FindFirstChild("ToggleWindow")

-- 2. NPC 类型定义
local npcType = npc.Name 
print("✅ NPC脚本已加载: " .. npcType)

-- 当玩家按下 E 键
prompt.Triggered:Connect(function(player)
	-- ==========================================
	-- [PVP 检查] 战斗中禁止交易
	-- ==========================================
	local isPvP = player:GetAttribute("PvPEnabled")

	if isPvP then
		print("🚫 [NPC] 拒绝服务: 玩家处于 PvP 模式")
		local pvpEvent = ReplicatedStorage:FindFirstChild("PvPEvent")
		if pvpEvent then
			pvpEvent:FireClient(player, "Error", "战斗状态下无法交易！请先关闭 PvP。")
		end
		return 
	end

	-- ==========================================
	-- [打开商店] 核心修复部分
	-- ==========================================
	print("🛒 [服务器] 玩家 " .. player.Name .. " 请求交易")

	if remoteEvent then
		-- 参数1: VendorType (用于客户端判断卖什么, 如 "SkinSeller" 或其他)
		-- 参数2: NPC Name (用于显示在UI标题上)
		remoteEvent:FireClient(player, npcType, npc.Name)
	else
		warn("❌ 致命错误: 找不到 'ToggleWindow' RemoteEvent！无法打开商店。")
		-- 尝试紧急修复：如果你的项目结构不同，可能是 ShopEvent
		local fallbackEvent = ReplicatedStorage:FindFirstChild("ShopEvent")
		if fallbackEvent then
			fallbackEvent:FireClient(player, "Open", "Weapons")
		end
	end
end)