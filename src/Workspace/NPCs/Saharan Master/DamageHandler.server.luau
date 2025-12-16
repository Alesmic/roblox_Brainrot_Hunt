local dmg = script.Parent.Config.Damage.Value
check = false

script.Parent:FindFirstChild("Right Leg").Touched:connect(function(hit)
	if (check) then return end
	if (not hit.Parent) then return end
	if hit.Parent:FindFirstChild("HumanoidRootPart") then
		local plr = game.Players:GetPlayerFromCharacter(hit.Parent)
		local chr = plr.Character
		local hum = chr:FindFirstChild("Humanoid")
		if script.Parent:FindFirstChild("Humanoid").Health > 1 then
			check = true
			hum:TakeDamage(dmg)
			wait(.2)
			check = false
		end
	end
end)

script.Parent:FindFirstChild("Left Leg").Touched:connect(function(hit)
	if (check) then return end
	if (not hit.Parent) then return end
	if hit.Parent:FindFirstChild("HumanoidRootPart") then
		local plr = game.Players:GetPlayerFromCharacter(hit.Parent)
		local chr = plr.Character
		local hum = chr:FindFirstChild("Humanoid")
		if script.Parent:FindFirstChild("Humanoid").Health > 1 then
			check = true
			hum:TakeDamage(dmg)
			wait(.2)
			check = false
		end
	end
end)
