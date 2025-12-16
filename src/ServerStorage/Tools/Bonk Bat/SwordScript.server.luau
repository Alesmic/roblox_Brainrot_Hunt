-- Sword Script: 强化任务计数版 (Bat PvP修复版)
local Tool = script.Parent
local Handle = Tool:WaitForChild("Handle")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- 1. 获取配置
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local toolName = Tool.Name
-- 尝试获取 Bat 的配置，如果没有则使用默认值
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

Tool.Enabled = true

-- ==========================================
-- 核心功能：标记击杀者 (任务系统的关键)
-- ==========================================
function TagHumanoid(humanoid, player)
	local creator_tag = Instance.new("ObjectValue")
	creator_tag.Name = "creator"
	creator_tag.Value = player
	-- [优化] 延长 Tag 时间到 5 秒，确保MobHandler能读到
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

	local targetChar = Hit.Parent
	if targetChar == Character then return end -- 不打自己

	local targetHum = targetChar:FindFirstChild("Humanoid")
	if not targetHum or targetHum.Health <= 0 then return end

	-- 玩家判定与 PvP 检查
	local targetPlayer = Players:GetPlayerFromCharacter(targetChar)
	if targetPlayer then
		-- 1. 队友判定
		if targetPlayer == Player then return end
		if targetPlayer.Team and targetPlayer.Team == Player.Team then return end

		-- ==========================================
		-- [新增] PvP 模式检查逻辑 (核心修复)
		-- ==========================================
		local myPvP = Player:GetAttribute("PvPEnabled")      -- 攻击者(我)的状态
		local targetPvP = targetPlayer:GetAttribute("PvPEnabled")  -- 受击者(他)的状态

		-- 只有双方都开启了 PVP，才允许造成伤害
		if not (myPvP and targetPvP) then
			return -- 🚫 停止执行，不造成伤害
		end
		-- ==========================================
	end

	-- 造成伤害前，先标记
	UntagHumanoid(targetHum)
	TagHumanoid(targetHum, Player)

	targetHum:TakeDamage(CurrentDamage)
end

-- ==========================================
-- 攻击逻辑
-- ==========================================
function Attack()
	CurrentDamage = SlashDamage
	Sounds.Slash:Play()

	if Humanoid then
		local anim = Instance.new("Animation")
		anim.AnimationId = "rbxassetid://522635514"
		local track = Humanoid:LoadAnimation(anim)
		track:Play()
	end
end

function Lunge()
	CurrentDamage = LungeDamage
	Sounds.Lunge:Play()

	if Humanoid then
		local anim = Instance.new("Animation")
		anim.AnimationId = "rbxassetid://522638767"
		local track = Humanoid:LoadAnimation(anim)
		track:Play()
	end

	-- 突刺位移
	if Character and Character:FindFirstChild("HumanoidRootPart") then
		local bv = Instance.new("BodyVelocity")
		bv.Velocity = Character.HumanoidRootPart.CFrame.LookVector * 50
		bv.MaxForce = Vector3.new(10000, 0, 10000) -- 只推水平方向
		bv.Parent = Character.HumanoidRootPart
		Debris:AddItem(bv, 0.2)
	end

	task.wait(0.5)
	CurrentDamage = SlashDamage
end

-- 双击判定
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

	task.wait(0.4) -- 攻速
	Tool.Enabled = true
end

function Equipped()
	Character = Tool.Parent
	Player = Players:GetPlayerFromCharacter(Character)
	Humanoid = Character:FindFirstChild("Humanoid")
	ToolEquipped = true
	Sounds.Unsheath:Play()
end

function Unequipped()
	ToolEquipped = false
end

Tool.Activated:Connect(Activated)
Tool.Equipped:Connect(Equipped)
Tool.Unequipped:Connect(Unequipped)
Handle.Touched:Connect(Blow)