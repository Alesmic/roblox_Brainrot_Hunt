local h = script.Parent:FindFirstChild("Humanoid")
local n = script.Parent
local name = script.Parent.Config.MonsterName.Value

wait(math.random(0.01,0.10))
n.Name = ""..name.." Health: "..h.Health.."/"..h.MaxHealth.."."

script.Parent.Humanoid.HealthChanged:connect(function()
n.Name = ""..name.." Health: "..h.Health.."/"..h.MaxHealth.."."
wait()
end)
