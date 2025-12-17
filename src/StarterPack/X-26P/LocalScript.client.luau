local Tool = script.Parent;

autolength = 5
enabled = true
enabled2 = true
benabled = true
pgui = nil
mtarg = nil
mousedown = false

cart = true
electrictextures = {"http://www.roblox.com/asset/?id=109201383", "http://www.roblox.com/asset/?id=109201366", "http://www.roblox.com/asset/?id=109201474", "http://www.roblox.com/asset/?id=109201980", "http://www.roblox.com/asset/?id=109202011"}

local event = Tool:WaitForChild("EventScript"):WaitForChild("TaserEvent")

--function BarbTouched(hit, barb)
--if hit == nil then return end
--if hit.Parent == nil then return end
--if hit.Parent:findFirstChild("Humanoid") or hit.Parent:findFirstChild("Zombie") ~= nil then
--if hit.Parent.Name == game.Players.LocalPlayer.Name then return end
--if target ~= nil then return end
--
--if hit.Parent:findFirstChild("OverrideScript") == nil then
--	local s = script.Parent.OverrideScript:clone()
--	s.Parent = hit.Parent
--	target = hit.Parent
--	s.Disabled = false
--end
--
--barb:Remove()
--
--elseif hit.CanCollide == true then
--	barb:Remove()
--end
--end

function DriveStun(hit)
if hit.Parent:findFirstChild("Humanoid") or hit.Parent:findFirstChild("Zombie") ~= nil then
local s = script.Parent.DriveStunScript:clone()
s.Parent = hit.Parent
s.Disabled = false
end
end

function GetElectricTexture()
	local r = math.random(1,#electrictextures)
	return electrictextures[r]
end

function onButton1Down(mouse)
	mousedown = true
	if not enabled then
		return
	end
	if not enabled2 then return end
	enabled = false
	enabled2 = false
	
	if mouse.Hit ~= nil then
	mtarg = mouse.Hit.p
	end
	
	if cart and benabled then
	benabled = false
	Tool.Deployed.Value = true
	event:FireServer("MakeBarbs",mtarg)
--	local v = (mtarg - Tool.Cart.Position).unit
--	local v2 = ((mtarg + Vector3.new(0,-1.5,0)) - Tool.Cart.Position).unit
--	
--	local spawnPos = script.Parent.Cart.Position
--	spawnPos  = spawnPos + (v * 2)
--	
--	Tool.BlastDoor1.Transparency = 1
--	Tool.BlastDoor2.Transparency = 1
--		
--	local barb_1 = Instance.new("Part")
--	
--	barb_1.Position = spawnPos
--	barb_1.FormFactor = 3
--	barb_1.Size = Vector3.new(1,1,1)
--	barb_1.Velocity = v * 500--1000
--	barb_1.BrickColor = BrickColor.new(194)
--	barb_1.BottomSurface = 0
--	barb_1.TopSurface = 0
--	barb_1.Name = "TaserBarb"
--	barb_1.Elasticity = 0
--	barb_1.Reflectance = 0.1
--	barb_1.Friction = 1
--	
--	Tool.BarbMesh:clone().Parent = barb_1
--	
--	local sc = Tool.BarbScript:clone()
--	sc.Parent = barb_1
--	sc.Disabled = false
--	
--	local force = Instance.new("BodyForce")
--	force.force = Vector3.new(0,150,0)
--	force.Parent = barb_1
--		
--	barb_1.Parent = game.Workspace
--	
--	local barb_2 = barb_1:clone()
--	barb_2.Position = spawnPos + (v2 * 2) + Vector3.new(0,-0.5,0)
--	barb_2.Velocity = v2 * 500
--	barb_2.BodyForce.force = Vector3.new(0,150,0)
--	barb_2.Parent = game.Workspace

--	barb_1.Touched:connect(function(hit) BarbTouched(hit, barb_1) end)
--	barb_2.Touched:connect(function(hit) BarbTouched(hit, barb_2) end)
--	Tool.Handle.Shot:Play()

	local al = 70 * (autolength / 5) + 2
	local t = 0
	local timerval = 0

	coroutine.resume(coroutine.create(function()
		while not enabled do
			t = t + 0.1
			if t < autolength then
			Tool.TimerVal.Value = math.ceil(autolength - t)
			else
			Tool.TimerVal.Value = math.ceil(t)			
			end
			wait(0.1)
		end
		Tool.TimerVal.Value = 0
		end))

	while (mousedown or t < autolength  - 0.2) and not safety and t < 90 do
--		script.Parent.Handle.sound:Play()
--		script.Parent.Handle.sound2:Play()
--		script.Parent.Handle.sound3:Play()
		event:FireServer("PlaySounds")
		wait(0.06)
	end
	
	Tool.TimerVal.Value = 0
	safety = false
	enabled = true
	wait(0.2)
	enabled2 = true
	
	elseif cart then
		
	enabled = false	
	
	local al = 70 * (autolength / 5) + 2
	local t = 0
	local timerval = 0

	coroutine.resume(coroutine.create(function()
		while not enabled do
			t = t + 0.1
			if t < autolength then
			Tool.TimerVal.Value = math.ceil(autolength - t)
			else
			Tool.TimerVal.Value = math.ceil(t)				
			end
			wait(0.1)
		end
		Tool.TimerVal.Value = 0
		end))

	while (mousedown or t < autolength  - 0.2) and not safety and t < 90 do
--		script.Parent.Handle.sound:Play()
--		script.Parent.Handle.sound2:Play()
--		script.Parent.Handle.sound3:Play()
		event:FireServer("PlaySounds")
		wait(0.06)
	end
	
	
	Tool.TimerVal.Value = 0
	safety = false
	enabled = true
	wait(0.2)
	enabled2 = true
	
	elseif not cart then
		
	enabled = false	
	local con2 = script.Parent.Cart.Touched:connect(DriveStun)	
	
	local al = 70 * (autolength / 5) + 2
	local t = 0

	coroutine.resume(coroutine.create(function()
		while not enabled do
			t = t + 0.1
			if t < autolength then
			Tool.TimerVal.Value = math.ceil(autolength - t)
			else
			Tool.TimerVal.Value = math.ceil(t)				
			end
			wait(0.1)
		end
		Tool.TimerVal.Value = 0
		end))

	while (mousedown or t < autolength  - 0.2) and not safety and t < 90 do
		Tool.Electric.Decal.Texture = GetElectricTexture()	
--		script.Parent.Handle.sound:Play()
--		script.Parent.Handle.sound2:Play()
--		script.Parent.Handle.sound3:Play()
event:FireServer("PlaySounds")
		wait(0.06)
	end
	
	Tool.Electric.Decal.Texture = ""	
	con2:disconnect()

	Tool.TimerVal.Value = 0
	safety = false
	enabled = true
	wait(0.2)
	enabled2 = true
	else
	enabled = true
	enabled2 = true
	end
end

function onButton1Up(mouse)
	mousedown = false
end

function UpdateDisplay()
	if pgui == nil then return end
	if Tool.TimerVal.Value == 0 then
		pgui.Main.Countdown.Text = ""
	else
		pgui.Main.Countdown.Text = Tool.TimerVal.Value		
	end
	if Tool.Cartr.Value == false then
		pgui.Main.CartStatus.BackgroundColor3 = Color3.new(1,1,1)
		pgui.Main.CartStatus.BorderColor3 = Color3.new(195/255,195/255,195/255)
		pgui.Main.CartStatus.Text = "-"
	elseif Tool.Deployed.Value == true then
		pgui.Main.CartStatus.BackgroundColor3 = Color3.new(1,79/255,79/255)
		pgui.Main.CartStatus.BorderColor3 = Color3.new(1,0,0)
		pgui.Main.CartStatus.Text = "X"
	else
		pgui.Main.CartStatus.BackgroundColor3 = Color3.new(1,1,127/255)
		pgui.Main.CartStatus.BorderColor3 = Color3.new(1,1,1)
		pgui.Main.CartStatus.Text = "1"		
	end
end

function onKeyDown(key)
	if key == "y" and Tool.Lamp.Light.Enabled == true then
--		Tool.Lamp.Light.Enabled = false
--		Tool.Lamp.Material = "SmoothPlastic"
		event:FireServer("TurnOnLight")
	elseif key == "y" then
--		Tool.Lamp.Light.Enabled = true
--		Tool.Lamp.Material = "Neon"
		event:FireServer("TurnOnLight2")
	end
	if key == "r" and not enabled then
		safety = true
	elseif key == "r" and cart then
		cart = false
--		Tool.Cartr.Value = false
--		Tool.Cart.Transparency = 1
--		Tool.Cart.CanCollide = false
--		Tool.CartPart1.Transparency = 1
--		Tool.CartPart1.CanCollide = false
--		Tool.CartPart2.Transparency = 1
--		Tool.CartPart2.CanCollide = false
--		Tool.BlastDoor1.Transparency = 1
--		Tool.BlastDoor1.CanCollide = false
--		Tool.BlastDoor2.Transparency = 1
--		Tool.BlastDoor2.CanCollide = false
event:FireServer("ReloadCart")
	elseif key == "r" then
--		Tool.Cartr.Value = true
--		Tool.Deployed.Value = false
		cart = true
		benabled = true
--		Tool.Cart.Transparency = 0
--		Tool.Cart.CanCollide = true
--		Tool.CartPart1.Transparency = 0
--		Tool.CartPart1.CanCollide = true
--		Tool.CartPart2.Transparency = 0
--		Tool.CartPart2.CanCollide = true
--		Tool.BlastDoor1.Transparency = 0
--		Tool.BlastDoor1.CanCollide = true
--		Tool.BlastDoor2.Transparency = 0
--		Tool.BlastDoor2.CanCollide = true
event:FireServer("ReloadCart2")
	end
end

function onEquippedLocal(mouse)

	if mouse == nil then
		print("Mouse not found")
		return 
	end

	local h = Tool.Parent:findFirstChild("Humanoid")

	if h~=nil and game.Players:findFirstChild(h.Parent.Name)~=nil then
	local gui = Tool.Gui:clone()
	gui.Parent = game.Players:findFirstChild(h.Parent.Name).PlayerGui
	pgui = gui
		
	UpdateDisplay()
	
	Tool.TimerVal.Changed:connect(UpdateDisplay)
	Tool.Cartr.Changed:connect(UpdateDisplay)
	Tool.Deployed.Changed:connect(UpdateDisplay)
	end

	mouse.Icon = "http://www.roblox.com/asset/?id=2966012"
	mouse.Button1Down:connect(function() onButton1Down(mouse) end)	
	mouse.Button1Up:connect(function() onButton1Up(mouse)end)
	mouse.KeyDown:connect(onKeyDown)
end


Tool.Equipped:connect(onEquippedLocal)

function onUnequippedLocal()
	if pgui ~= nil then
		pgui:Remove()
		pgui = nil
	end
end

Tool.Unequipped:connect(onUnequippedLocal)
