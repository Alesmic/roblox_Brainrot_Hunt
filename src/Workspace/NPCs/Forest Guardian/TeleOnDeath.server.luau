local Mob = script.Parent
local Humanoid = Mob:FindFirstChild("Humanoid")
local Spawn = workspace.ToSpawn

Humanoid.Died:connect(function()
	local tag = Humanoid:findFirstChild("creator") 
	if tag ~= nil then
		if (tag.Value == nil) then return end
		if (not tag.Value.Character) then return end
		tag.Value.Character.Humanoid.Torso.CFrame = CFrame.new(Spawn.Position)
	end 
end)
