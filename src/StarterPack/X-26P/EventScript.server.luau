--HeroThePinaist
local Tool = script.Parent
script.TaserEvent.OnServerEvent:connect(function(plr,event,arg1,arg2,arg3,arg4)
	if event == "MakeBarbs" then
		local v = (arg1 - Tool.Cart.Position).unit
		local v2 = ((arg1 + Vector3.new(0,-1.5,0)) - Tool.Cart.Position).unit
		
		local spawnPos = script.Parent.Cart.Position
		spawnPos  = spawnPos + (v * 2)
		
		Tool.BlastDoor1.Transparency = 1
		Tool.BlastDoor2.Transparency = 1
			
		local barb_1 = Instance.new("Part")
		
		barb_1.Position = spawnPos
		barb_1.FormFactor = 3
		barb_1.Size = Vector3.new(1,1,1)
		barb_1.Velocity = v * 500--1000
		barb_1.BrickColor = BrickColor.new(194)
		barb_1.BottomSurface = 0
		barb_1.TopSurface = 0
		barb_1.Name = "TaserBarb"
		barb_1.Elasticity = 0
		barb_1.Reflectance = 0.1
		barb_1.Friction = 1
		
		Tool.BarbMesh:clone().Parent = barb_1
		
		local sc = Tool.BarbScript:clone()
		sc.Parent = barb_1
		sc.Disabled = false
		
		local force = Instance.new("BodyForce")
		force.force = Vector3.new(0,150,0)
		force.Parent = barb_1
			
		barb_1.Parent = game.Workspace
		
		local barb_2 = barb_1:clone()
		barb_2.Position = spawnPos + (v2 * 2) + Vector3.new(0,-0.5,0)
		barb_2.Velocity = v2 * 500
		barb_2.BodyForce.force = Vector3.new(0,150,0)
		barb_2.Parent = game.Workspace
		
		local taseScript1 = Tool.TaseScript:Clone()
		taseScript1.Parent = barb_1
		taseScript1.Disabled = false	
		local taseScript2 = Tool.TaseScript:Clone()
		taseScript2.Parent = barb_2
		taseScript2.Disabled = false
		
		Tool.Handle.Shot:Play()
	elseif event == "PlaySounds" then
		script.Parent.Handle.sound:Play()
		script.Parent.Handle.sound2:Play()
		script.Parent.Handle.sound3:Play()
	elseif event == "TurnOnLight" then
		Tool.Lamp.Light.Enabled = false
		Tool.Lamp.Material = "SmoothPlastic"
	elseif event == "TurnOnLight2" then
		Tool.Lamp.Light.Enabled = true
		Tool.Lamp.Material = "Neon"
	elseif event == "ReloadCart" then
		Tool.Cartr.Value = false
		Tool.Cart.Transparency = 1
		Tool.Cart.CanCollide = false
		Tool.CartPart1.Transparency = 1
		Tool.CartPart1.CanCollide = false
		Tool.CartPart2.Transparency = 1
		Tool.CartPart2.CanCollide = false
		Tool.BlastDoor1.Transparency = 1
		Tool.BlastDoor1.CanCollide = false
		Tool.BlastDoor2.Transparency = 1
		Tool.BlastDoor2.CanCollide = false
	elseif event == "ReloadCart2" then
		Tool.Cartr.Value = true
		Tool.Deployed.Value = false
		Tool.Cart.Transparency = 0
		Tool.Cart.CanCollide = true
		Tool.CartPart1.Transparency = 0
		Tool.CartPart1.CanCollide = true
		Tool.CartPart2.Transparency = 0
		Tool.CartPart2.CanCollide = true
		Tool.BlastDoor1.Transparency = 0
		Tool.BlastDoor1.CanCollide = true
		Tool.BlastDoor2.Transparency = 0
		Tool.BlastDoor2.CanCollide = true
	end
end)