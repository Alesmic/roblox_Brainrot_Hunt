local tool = script.Parent
local handle = tool.Handle
local knife = handle.Bat
local anims = tool.anims:GetChildren()
local db = false
local db2 = false
local attacking = false
local idle = nil

knife.Touched:Connect(function(e)
	if attacking and not db2 and e.Parent:FindFirstChildWhichIsA("Humanoid") then
		db2 = true
		e.Parent.Humanoid:TakeDamage(10)
		handle.hit:Play()
		e.Velocity = tool.Parent.HumanoidRootPart.CFrame.LookVector * 50
		wait(0.7)
		db2 = false
	end
end)

tool.Equipped:Connect(function()
	handle.equip:Play()
	knife.CanCollide = false
	idle = tool.Parent:FindFirstChildWhichIsA("Humanoid"):LoadAnimation(tool.idle)
	idle.Priority = Enum.AnimationPriority.Action
	idle:Play()
end)

tool.Unequipped:Connect(function()
	knife.CanCollide = true
	idle:Stop()
end)

tool.Activated:Connect(function()
	if not db then
		db = true
		attacking = true
		local anim = tool.Parent.Humanoid:LoadAnimation(anims[math.random(1, #anims)])
		anim.Priority = Enum.AnimationPriority.Action2
		anim:Play()
		handle.slash:Play()
		anim.Ended:Wait()
		attacking = false
		db = false
	end
end)