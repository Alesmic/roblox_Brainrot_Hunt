local t = script.Parent.Torso

local w = script.Parent:GetChildren()

local h = nil

for i = 1, #w do
if w[i].ClassName == "Humanoid" then h = w[i] end
end

t.CFrame = CFrame.new(t.Position.x,t.Position.y,t.Position.z,0,-1,0,0,0,-1,1,0,0)
h:UnequipTools()

function OnAttempt()
	t.CFrame = CFrame.new(t.Position.x,t.Position.y,t.Position.z,0,-1,0,0,0,-1,1,0,0)
	wait(8)
	script:Destroy()
end

local c = h.Jumping:connect(OnAttempt)
local c2 = h.GettingUp:connect(OnAttempt)
local c3 = h.Running:connect(OnAttempt)

h.Jump = true

while true do
	h:UnequipTools()
	wait()
end
