npc = script.Parent:Clone()

script.Parent:FindFirstChild("Humanoid").Died:connect(function()
	wait(5)
	npc.Parent = script.Parent.Parent
	npc:MakeJoints()
	npc.Humanoid.Health = npc.Humanoid.MaxHealth
	for i,v in pairs(npc:GetChildren()) do
		if v:IsA("BasePart") then
			v.Locked = true
		end	end
	script.Parent:Remove()
end)
