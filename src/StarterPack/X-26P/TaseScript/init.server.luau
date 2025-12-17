--HeroThePianist
local barb = script.Parent
barb.Touched:connect(function(hit)
	if hit == nil then return end
	if hit.Parent == nil then return end
	if hit.Parent:findFirstChild("Humanoid") or hit.Parent:findFirstChild("Zombie") ~= nil then
--	if hit.Parent.Name == game.Players.LocalPlayer.Name then return end
	
	if hit.Parent:findFirstChild("OverrideScript") == nil then
		local s = script.OverrideScript:clone()
		s.Parent = hit.Parent
		s.Disabled = false
	end
	
	barb:Remove()
	
	elseif hit.CanCollide == true then
		barb:Remove()
	end
end)