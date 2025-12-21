local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService") -- [Added] Used to detect top notch screen area

local player = Players.LocalPlayer
local pvpEvent = ReplicatedStorage:WaitForChild("PvPEvent")

-- ==========================================
-- 1. Auto-generate UI (Top Right + Mobile Adaptation)
-- ==========================================
local screenGui = script.Parent
screenGui.ResetOnSpawn = false 
-- [Important] Set to false to let Roblox automatically handle top notch/status bar to avoid button occlusion
screenGui.IgnoreGuiInset = false 
screenGui.DisplayOrder = -10

-- Create main container Frame
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"

-- [Core Adaptation 1: Anchor Point] Set to (1, 0) which means anchored to top-right corner
mainFrame.AnchorPoint = Vector2.new(1, 0)

-- [Core Adaptation 2: Position] 
-- UDim2.new(X scale, X offset, Y scale, Y offset)
-- Position at 0% from right edge and 2% from top edge
mainFrame.Position = UDim2.new(1, 0, 0, 0) 

-- [Core Adaptation 3: Base Size] 
-- Use Scale (percentage) instead of fixed Offset (pixels)
-- Base width set to 18% of screen width, height set to 8% of screen height (adjust based on actual effect)
mainFrame.Size = UDim2.new(0.12, 0, 0.08, 0)

mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
mainFrame.BackgroundTransparency = 0.3
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

-- [Core Adaptation 4: Size Constraint] Critical! Ensure consistent experience across different screens
local sizeConstraint = Instance.new("UISizeConstraint")
-- Minimum size: Ensure buttons are large enough for easy tapping on small mobile devices (e.g., 130x60 pixels)
sizeConstraint.MinSize = Vector2.new(130, 60)
-- Maximum size: Prevent buttons from being too large on computer screens (e.g., 200x90 pixels)
sizeConstraint.MaxSize = Vector2.new(200, 90)
sizeConstraint.Parent = mainFrame

-- Round corner beautification
local uiCorner = Instance.new("UICorner")
uiCorner.CornerRadius = UDim.new(0.2, 0) -- Use relative scale for corner radius
uiCorner.Parent = mainFrame

-- Layout list (automatically arrange inner elements vertically)
local layout = Instance.new("UIListLayout")
layout.FillDirection = Enum.FillDirection.Vertical
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.VerticalAlignment = Enum.VerticalAlignment.Center
layout.Padding = UDim.new(0.05, 0) -- Element spacing
layout.Parent = mainFrame

-- Status text Label
local statusLabel = Instance.new("TextLabel")
statusLabel.Name = "StatusLabel"
-- Use Scale to fill container width, height takes 35%
statusLabel.Size = UDim2.new(0.9, 0, 0.35, 0) 
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "PvP: Safe Zone"
statusLabel.TextColor3 = Color3.fromRGB(0, 255, 100)
statusLabel.Font = Enum.Font.GothamBold
-- [Core Adaptation 5: Auto text scaling]
statusLabel.TextScaled = true 
statusLabel.Parent = mainFrame

-- Toggle Button
local toggleBtn = Instance.new("TextButton")
toggleBtn.Name = "ToggleButton"
-- Use Scale to fill container width, height takes 45%
toggleBtn.Size = UDim2.new(0.9, 0, 0.45, 0)
toggleBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
toggleBtn.Text = "Enable PvP"
toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleBtn.Font = Enum.Font.GothamBold
-- [Core Adaptation 5: Auto text scaling]
toggleBtn.TextScaled = true 
toggleBtn.Parent = mainFrame

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0.2, 0)
btnCorner.Parent = toggleBtn

-- ==========================================
-- 2. Button Logic (Unchanged)
-- ==========================================
local debounce = false

toggleBtn.MouseButton1Click:Connect(function()
	if debounce then return end
	debounce = true

	pvpEvent:FireServer("TogglePvP")

	task.wait(1)
	debounce = false
end)

-- ==========================================
-- 3. Feedback Handling (Unchanged, only adjusted colors and text)
-- ==========================================
pvpEvent.OnClientEvent:Connect(function(action, value)
	if action == "UpdateState" then
		local isPvP = value

		if isPvP then
			statusLabel.Text = "PvP: Enabled"
			statusLabel.TextColor3 = Color3.fromRGB(231, 76, 60)
			toggleBtn.Text = "Disable PvP"
			toggleBtn.BackgroundColor3 = Color3.fromRGB(192, 57, 43)
		else
			statusLabel.Text = "PvP: Safe Mode"
			statusLabel.TextColor3 = Color3.fromRGB(46, 204, 113)
			toggleBtn.Text = "Enable PvP"
			toggleBtn.BackgroundColor3 = Color3.fromRGB(39, 174, 96)
		end

	elseif action == "Error" then
		local oldText = toggleBtn.Text
		local oldColor = toggleBtn.BackgroundColor3
		-- Temporarily display error message
		toggleBtn.Text = value 
		toggleBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
		toggleBtn.TextSize = 12 -- Error messages may be longer, slightly reduce size (even with TextScaled enabled)

		task.wait(2.5)

		toggleBtn.Text = oldText
		toggleBtn.BackgroundColor3 = oldColor
	end
end)