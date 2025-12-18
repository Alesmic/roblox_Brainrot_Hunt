function findCharacter(pos)
	local P = script.Parent
	local list = workspace['PlayerHolder']:GetChildren()
	local dist = 40
	local torso = nil
	local temp = nil
	local human = nil
	local t2 = nil
	for x = 1, #list do
		t2 = list[x]
		if t2:IsA("Model") and t2 ~= P and game.Players:GetPlayerFromCharacter(t2) then
			temp = t2:FindFirstChild("Right Arm")
			human = t2:FindFirstChild("Humanoid")
			if (temp ~= nil) and (human ~= nil) and (human.Health > 0) then
				if (temp.Position - pos).magnitude < dist then
					torso = temp
					dist = (temp.Position - pos).magnitude
				end
			end
		end
	end
	return torso
end

while wait(0.50) do
	if (not script.Parent) then return end
	if (not script.Parent:FindFirstChild("Torso")) then return end
	if (not script.Parent:FindFirstChild("Humanoid")) then return end
	local target = findCharacter(script.Parent:FindFirstChild("Torso").Position)
	if target then
		script.Parent:FindFirstChild("Humanoid"):MoveTo(target.Position, target)
	end
end
