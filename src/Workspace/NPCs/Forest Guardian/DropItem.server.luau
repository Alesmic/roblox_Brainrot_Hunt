local Mob = script.Parent
local Humanoid = Mob:FindFirstChild("Humanoid")
local WP = script.Weapon.Value

Humanoid.Died:connect(function()
	local tag = Humanoid:FindFirstChild("creator") 
	if tag ~= nil and script.Parent.Humanoid.Health < 1 then 
		if (tag.Value == nil) then return end
		local BP = tag.Value:FindFirstChild("Backpack") 
		local SG = tag.Value:FindFirstChild("StarterGear")
		if BP and SG and (not SG:FindFirstChild(WP)) then 
			local wep = game:GetService("ServerStorage").Tools:FindFirstChild(WP):Clone()
			wep.Parent = BP
			local wep2 = wep:Clone()
			wep2.Parent = SG
			script:Destroy()
		end 
	end 
end)
