local UserInputService = game:GetService("UserInputService")
local camera = workspace.CurrentCamera

local Slider = {}
Slider.IsAnySliderBeingMoved = false
Slider.__index = Slider

local function Map(n: number, oldMin: number, oldMax: number, min: number, max: number): number
	return (min + ((max - min) * ((n - oldMin) / (oldMax - oldMin))))
end

function Slider.new(title: string, frame: Frame, adornee: Part, min: number, max: number, suffix: string?)
	local self = setmetatable({
		Value = 0,
		Title = title,
		Min = min,
		Max = max,
		Suffix = suffix
	}, Slider)
	
	local valueChangedEvent = Instance.new("BindableEvent")
	self.Changed = valueChangedEvent
	
	-- TODO: check if exists
	local container = frame:FindFirstChild("SliderContainer")
	local slider = container:FindFirstChild("Slider")
	local ball = slider:FindFirstChild("Ball")
	local namer = frame:FindFirstChild("Namer")
	local input = frame:FindFirstChild("Input")
	local reset = frame:FindFirstChild("Reset")
	
	self.Ball = ball
	self.Namer = namer
	self.Input = input
	
	local mouseDown = false
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Include
	raycastParams.FilterDescendantsInstances = { adornee }	
	
	self.RaycastParams = raycastParams
	self.Container = container
	self.Adornee = adornee
	self.GUI = frame:FindFirstAncestorOfClass("SurfaceGui")
	self.GUI:GetPropertyChangedSignal("Adornee"):Connect(function()
		self.Adornee = self.GUI.Adornee
		self.RaycastParams.FilterDescendantsInstances = { self.Adornee }
	end)
	
	container.InputBegan:Connect(function(input: InputObject)
		if Slider.IsAnySliderBeingMoved then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			mouseDown = true
			Slider.IsAnySliderBeingMoved = true
			while mouseDown do
				self:CastRay()
				task.wait()
			end
		end
	end)
	
	UserInputService.InputEnded:Connect(function(input: InputObject)
		if mouseDown and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
			mouseDown = false
			Slider.IsAnySliderBeingMoved = false
			self.Changed:Fire(self.Value)
		end
	end)
	
	reset.Activated:Connect(function()
		self:SetValue(100)
		self.Changed:Fire(self.Value)
	end)
	
	input.FocusLost:Connect(function()
		local text = string.gsub(input.Text, "%%", "")
		local number = tonumber(text)
		if number then
			self:SetValue(math.clamp(math.round(number), min, max))
			self.Changed:Fire(self.Value)
		end
		self.Input.Text = ""
	end)
	
	return self
end

function Slider:CastRay()
	local screenPosition = UserInputService:GetMouseLocation()
	local ray = camera:ViewportPointToRay(screenPosition.X, screenPosition.Y)
	local hit = workspace:Raycast(ray.Origin, ray.Direction * 500, self.RaycastParams)
	if hit and hit.Instance then
		if hit.Normal == self.Adornee.CFrame.LookVector then
			local topLeftCFrame = self.Adornee.CFrame * CFrame.new(self.Adornee.Size.X / 2, self.Adornee.Size.Y / 2, self.Adornee.Size.Z / 2)
			local positionRelativeToAdornee = topLeftCFrame:PointToObjectSpace(hit.Position)
			local projectedPosition = -positionRelativeToAdornee.X * self.GUI.PixelsPerStud
			local mappedValue = math.clamp(math.map(projectedPosition, self.Container.AbsolutePosition.X, self.Container.AbsolutePosition.X + self.Container.AbsoluteSize.X, 0, 1), 0, 1)
			self:SetPosition(mappedValue)
		end
	end
end

function Slider:SetPosition(x: number)
	local mapped = Map(x, 0, 1, self.Min, self.Max)
	self.Ball.Position = UDim2.fromScale(x, 0.5)
	self.Input.PlaceholderText = `{math.round(mapped)}{self.Suffix}`
	self.Value = mapped
end

function Slider:SetValue(x: number, fireEvent: boolean?)
	self.Value = x
	local mapped = Map(x, self.Min, self.Max, 0, 1)
	self.Ball.Position = UDim2.fromScale(mapped, 0.5)
	self.Input.PlaceholderText = `{math.round(x)}{self.Suffix}`
	if fireEvent then
		self.Changed:Fire(self.Value)
	end
end

return Slider