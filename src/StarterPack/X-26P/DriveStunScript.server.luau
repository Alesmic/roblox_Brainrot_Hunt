local t = script.Parent.Torso
local w = script.Parent:GetChildren()

local h = nil

for i = 1, #w do
if w[i].ClassName == "Humanoid" then h = w[i] end
end

h.Jump = true

t.CFrame = CFrame.new(t.Position.x,t.Position.y,t.Position.z,0,-1,0,0,0,-1,1,0,0)
h:UnequipTools()

wait(1)
script:Remove()
