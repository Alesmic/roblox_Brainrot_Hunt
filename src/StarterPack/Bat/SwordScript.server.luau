-- Sword Script: 恢复双击突刺版 + GameConfig 伤害
local Tool = script.Parent
local Handle = Tool:WaitForChild("Handle")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- 1. 尝试引入 GameConfig
local GameConfig
local success, result = pcall(function()
	return require(ReplicatedStorage:WaitForChild("GameConfig", 2))
end)

if success and result then
	GameConfig = result
else
	GameConfig = { Weapons = {} }
end

-- 2. 获取武器配置
local toolName = Tool.Name
-- 兼容 Bat 和 Wooden Club
local weaponStats = GameConfig.Weapons[toolName] or GameConfig.Weapons["Wooden Club"] 
local DefaultStats = {Damage = 10, Cooldown = 0.5} -- 默认冷却改短一点

if not weaponStats then
	weaponStats = DefaultStats
end

local ConfigDamage = weaponStats.Damage or 10

-- 定义伤害倍率
local DamageValues = {
	BaseDamage = 5, 
	SlashDamage = ConfigDamage,             -- 普攻伤害 (读配置)
	LungeDamage = math.floor(ConfigDamage * 1.5) -- 突刺伤害 (1.5倍)
}

local Damage = DamageValues.BaseDamage
local BaseUrl = "rbxassetid://"

-- 3. 自动补全音效 (防止卡死)
local function loadSound(name, id)
	local sound = Handle:FindFirstChild(name)
	if not sound then
		sound = Instance.new("Sound")
		sound.Name = name
		sound.SoundId = BaseUrl .. id
		sound.Volume = 0.5
		sound.Parent = Handle
	end
	return sound
end

local Sounds = {
	Slash = loadSound("SwordSlash", "12222216"),
	Lunge = loadSound("SwordLunge", "12222208"),
	Unsheath = loadSound("Unsheath", "12222225")
}

local Animations = {
	R15Slash = 522635514,
	R15Lunge = 522638767
}

local Grips = {
	Up = CFrame.new(0, -1.5, 0, 5, -90, 1, 1, 0, 0, 0, 1, 0),
	Out = CFrame.new(0, -1.5, 0, 5, -90, 0, 1, -0, 0, 0, 0, -1)
}

local ToolEquipped = false

Tool.Grip = Grips.Up
Tool.Enabled = true

-- 辅助函数
function IsTeamMate(Player1, Player2)
	return (Player1 and Player2 and not Player1.Neutral and not Player2.Neutral and Player1.TeamColor == Player2.TeamColor)
end

function TagHumanoid(humanoid, player)
	local Creator_Tag = Instance.new("ObjectValue")
	Creator_Tag.Name = "creator"
	Creator_Tag.Value = player
	Debris:AddItem(Creator_Tag, 2)
	Creator_Tag.Parent = humanoid
end

function UntagHumanoid(humanoid)
	for i, v in pairs(humanoid:GetChildren()) do
		if v:IsA("ObjectValue") and v.Name == "creator" then
			v:Destroy()
		end
	end
end

function Blow(Hit)
	if not Hit or not Hit.Parent or not ToolEquipped then return end
	local character = Hit.Parent
	if character == Character then return end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health == 0 then return end
	local player = Players:GetPlayerFromCharacter(character)
	if player and (player == Player or IsTeamMate(Player, player)) then return end

	UntagHumanoid(humanoid)
	TagHumanoid(humanoid, Player)
	humanoid:TakeDamage(Damage)	
end

function Attack()
	Damage = DamageValues.SlashDamage
	Sounds.Slash:Play()

	if Humanoid then
		local Anim = Tool:FindFirstChild("R15Slash")
		if not Anim then
			Anim = Instance.new("Animation")
			Anim.Name = "R15Slash"
			Anim.AnimationId = BaseUrl .. Animations.R15Slash
			Anim.Parent = Tool
		end
		local Track = Humanoid:LoadAnimation(Anim)
		Track:Play()
	end	
end

function Lunge()
	Damage = DamageValues.LungeDamage
	Sounds.Lunge:Play()

	if Humanoid then
		local Anim = Tool:FindFirstChild("R15Lunge")
		if not Anim then
			Anim = Instance.new("Animation")
			Anim.Name = "R15Lunge"
			Anim.AnimationId = BaseUrl .. Animations.R15Lunge
			Anim.Parent = Tool
		end
		local Track = Humanoid:LoadAnimation(Anim)
		Track:Play()
	end	

	-- 突刺位移
	local force = Instance.new("BodyVelocity")
	force.velocity = Vector3.new(0, 10, 0) 
	force.maxForce = Vector3.new(0, 4000, 0)
	Debris:AddItem(force, 0.4)
	if Torso then force.Parent = Torso end

	task.wait(0.2)
	Tool.Grip = Grips.Out
	task.wait(0.6)
	Tool.Grip = Grips.Up

	Damage = DamageValues.SlashDamage
end

local LastAttack = 0

-- ✨ 核心修复：Activated 逻辑 ✨
function Activated()
	if not Tool.Enabled or not ToolEquipped then return end

	Tool.Enabled = false

	local Tick = RunService.Stepped:wait() -- 获取当前帧时间

	-- 判断距离上次攻击是否小于 0.2 秒
	if (Tick - LastAttack < 0.2) then
		-- >> 触发突刺 (双击) <<
		Lunge()
		LastAttack = 0 -- 重置时间，防止三连击
	else
		-- >> 触发普攻 (单击) <<
		Attack()
		LastAttack = Tick
	end

	-- ⚠️ 这里不再使用 ConfigCooldown，因为它会阻塞双击
	-- 我们只给一个极短的等待，防止宏一秒点100下，同时保证能点出第二下
	task.wait(0.25) 

	Damage = DamageValues.BaseDamage
	Tool.Enabled = true
end

function CheckIfAlive()
	return (((Player and Player.Parent and Character and Character.Parent and Humanoid and Humanoid.Parent and Humanoid.Health > 0) and true) or false)
end

function Equipped()
	Character = Tool.Parent
	Player = Players:GetPlayerFromCharacter(Character)
	Humanoid = Character:FindFirstChildOfClass("Humanoid")
	Torso = Character:FindFirstChild("Torso") or Character:FindFirstChild("HumanoidRootPart")

	if not CheckIfAlive() then return end

	ToolEquipped = true
	if Sounds.Unsheath then Sounds.Unsheath:Play() end
end

function Unequipped()
	Tool.Grip = Grips.Up
	ToolEquipped = false
end

Tool.Activated:Connect(Activated)
Tool.Equipped:Connect(Equipped)
Tool.Unequipped:Connect(Unequipped)
Handle.Touched:Connect(Blow)