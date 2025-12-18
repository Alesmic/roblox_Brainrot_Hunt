-- Sword/Bat Script: 终极修复版
-- (多安全区支持 + PvP检查 + 防误触 + 任务计数)

local Tool = script.Parent
local Handle = Tool:WaitForChild("Handle")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

-- 1. 获取配置
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local toolName = Tool.Name
local weaponStats = GameConfig.Weapons[toolName] or GameConfig.Weapons["Bat"] or {Damage = 10}

local BaseDamage = weaponStats.Damage or 10
local SlashDamage = BaseDamage
local LungeDamage = math.floor(BaseDamage * 1.5)
local CurrentDamage = BaseDamage

-- 音效
local BaseUrl = "rbxassetid://"
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
	Slash = loadSound("Slash", "12222216"),
	Lunge = loadSound("Lunge", "12222208"),
	Unsheath = loadSound("Unsheath", "12222225")
}

-- 变量
local ToolEquipped = false
local Character = nil
local Player = nil
local Humanoid = nil
local IsAttacking = false -- 攻击状态标记

Tool.Enabled = true

-- ==========================================
-- [核心升级] 多安全区检测系统
-- ==========================================
local SafeZoneParts = {} -- 缓存所有的安全区零件

-- 刷新安全区列表 (在脚本启动时运行一次)
local function refreshSafeZones()
	table.clear(SafeZoneParts)
	-- 遍历 Workspace 下的所有东西，找到名字叫 "SafeZone" 的零件
	for _, part in pairs(Workspace:GetDescendants()) do
		if part.Name == "SafeZone" and part:IsA("BasePart") then
			table.insert(SafeZoneParts, part)
		end
	end
	-- print("🛡️ 已加载 " .. #SafeZoneParts .. " 个安全区")
end

-- 初始化加载
refreshSafeZones()

-- 检查角色是否在【任意一个】安全区内
local function isInSafeZone(char)
	local rootPart = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")
	if not rootPart then return false end

	-- 只需要遍历缓存的列表，性能极高
	for _, zonePart in pairs(SafeZoneParts) do
		-- 确保零件还在(没被删掉)
		if zonePart and zonePart.Parent then
			local partsInZone = Workspace:GetPartsInPart(zonePart)
			for _, part in pairs(partsInZone) do
				if part == rootPart then
					return true -- 只要在一个圈里，就算安全
				end
			end
		end
	end
	return false
end
-- ==========================================

function TagHumanoid(humanoid, player)
	local creator_tag = Instance.new("ObjectValue")
	creator_tag.Name = "creator"
	creator_tag.Value = player
	Debris:AddItem(creator_tag, 5) 
	creator_tag.Parent = humanoid
end

function UntagHumanoid(humanoid)
	for i, v in pairs(humanoid:GetChildren()) do
		if v:IsA("ObjectValue") and v.Name == "creator" then
			v:Destroy()
		end
	end
end

function Blow(Hit)
	if not Hit or not Hit.Parent or not ToolEquipped or not Player then return end

	-- 1. [防误触] 如果没有在挥动，直接忽略
	if not IsAttacking then return end

	local targetChar = Hit.Parent
	if targetChar == Character then return end

	local targetHum = targetChar:FindFirstChild("Humanoid")
	if not targetHum or targetHum.Health <= 0 then return end

	-- 2. [安全区拦截] 任意一方在安全区，都无效
	if isInSafeZone(Character) or isInSafeZone(targetChar) then
		return
	end

	-- 3. [PvP拦截]
	local targetPlayer = Players:GetPlayerFromCharacter(targetChar)
	if targetPlayer then
		if targetPlayer == Player then return end
		if targetPlayer.Team and targetPlayer.Team == Player.Team then return end

		-- 双方必须都开启 PvP
		local myPvP = Player:GetAttribute("PvPEnabled")
		local targetPvP = targetPlayer:GetAttribute("PvPEnabled")

		if not (myPvP and targetPvP) then
			return 
		end
	end

	-- 造成伤害
	UntagHumanoid(targetHum)
	TagHumanoid(targetHum, Player)
	targetHum:TakeDamage(CurrentDamage)
end

function Attack()
	IsAttacking = true
	CurrentDamage = SlashDamage
	Sounds.Slash:Play()

	if Humanoid then
		local anim = Instance.new("Animation")
		anim.AnimationId = "rbxassetid://522635514"
		local track = Humanoid:LoadAnimation(anim)
		track:Play()
	end

	task.wait(0.5) -- 挥砍判定时间
	IsAttacking = false
end

function Lunge()
	IsAttacking = true
	CurrentDamage = LungeDamage
	Sounds.Lunge:Play()

	if Humanoid then
		local anim = Instance.new("Animation")
		anim.AnimationId = "rbxassetid://522638767"
		local track = Humanoid:LoadAnimation(anim)
		track:Play()
	end

	if Character and Character:FindFirstChild("HumanoidRootPart") then
		local bv = Instance.new("BodyVelocity")
		bv.Velocity = Character.HumanoidRootPart.CFrame.LookVector * 50
		bv.MaxForce = Vector3.new(10000, 0, 10000)
		bv.Parent = Character.HumanoidRootPart
		Debris:AddItem(bv, 0.2)
	end

	task.wait(0.5)
	CurrentDamage = SlashDamage
	IsAttacking = false
end

local LastClick = 0

function Activated()
	if not Tool.Enabled or not ToolEquipped then return end
	Tool.Enabled = false

	local now = tick()
	if (now - LastClick < 0.3) then
		Lunge()
		LastClick = 0
	else
		Attack()
		LastClick = now
	end

	Tool.Enabled = true
end

function Equipped()
	Character = Tool.Parent
	Player = Players:GetPlayerFromCharacter(Character)
	Humanoid = Character:FindFirstChild("Humanoid")
	ToolEquipped = true
	IsAttacking = false
	Sounds.Unsheath:Play()
end

function Unequipped()
	ToolEquipped = false
	IsAttacking = false
end

Tool.Activated:Connect(Activated)
Tool.Equipped:Connect(Equipped)
Tool.Unequipped:Connect(Unequipped)
Handle.Touched:Connect(Blow)