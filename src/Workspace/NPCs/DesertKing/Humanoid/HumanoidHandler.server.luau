local hp = script.Parent.Parent.Config.Health.Value
local sp = script.Parent.Parent.Config.Walkspeed.Value
local human = script.Parent

human.MaxHealth = hp
human.Health = hp
human.WalkSpeed = sp

wait(1)

script:Destroy()
