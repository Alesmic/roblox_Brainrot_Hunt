MonsterSettings = script.Parent.Parent:FindFirstChild("Settings");

function onTouched(hit)
	local human = hit.Parent:findFirstChild("Humanoid")
	if (human ~= nil) then
		human.Health = human.Health - MonsterSettings:findFirstChild("Damage").Value;
	end
end

--if (script.Parent ~= nil) and (script.Parent.className == "Part") then --Work if in a block
--	connection = script.Parent.Touched:connect(onTouched)
--end
script.Parent.Touched:connect(onTouched)
