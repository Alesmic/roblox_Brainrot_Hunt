local tool = script.Parent

tool.Activated:Connect(function()
	local humanoid = tool.Parent:FindFirstChild("Humanoid")
	humanoid.Health = humanoid.Health + 45
	tool:Destroy()
end)