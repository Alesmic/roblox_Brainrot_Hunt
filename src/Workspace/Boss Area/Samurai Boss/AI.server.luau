-- 位置: Samurai Boss -> Script (重命名为 AI)
-- ⚠️ 重要：在属性面板里把这个脚本的 Enabled 取消勾选！
local boss = script.Parent
local humanoid = boss:WaitForChild("Humanoid")
local root = boss:WaitForChild("HumanoidRootPart")

-- 攻击参数
local ATTACK_RANGE = 80 -- 索敌范围 (改大点，防止玩家跑太远它发呆)
local STOP_RANGE = 4    -- 停止距离 (防止贴脸穿模)
local DAMAGE = 20
local ATTACK_COOLDOWN = 1.5

local lastAttack = 0

print("🤖 Boss AI 已启动！")

while task.wait(0.1) do
	local target = nil
	local shortestDist = ATTACK_RANGE

	-- 寻找最近的玩家
	for _, player in pairs(game.Players:GetPlayers()) do
		if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			local char = player.Character
			local dist = (root.Position - char.HumanoidRootPart.Position).Magnitude

			-- 必须在范围内，且玩家活着
			if dist < shortestDist and char.Humanoid.Health > 0 then
				shortestDist = dist
				target = char
			end
		end
	end

	if target then
		-- 1. 移动向玩家
		if shortestDist > STOP_RANGE then
			humanoid:MoveTo(target.HumanoidRootPart.Position)
		else
			-- 距离够近了，停下攻击
			humanoid:MoveTo(root.Position)
		end

		-- 2. 攻击判断 (简单触碰或距离判断)
		if shortestDist <= 6 and os.clock() - lastAttack > ATTACK_COOLDOWN then
			lastAttack = os.clock()

			-- 造成伤害
			target.Humanoid:TakeDamage(DAMAGE)
			print("⚔️ Boss 攻击了 " .. target.Name)

			-- 可选：这里可以播放攻击动画
		end
	else
		-- 没目标，停在原地
		humanoid:MoveTo(root.Position)
	end
end