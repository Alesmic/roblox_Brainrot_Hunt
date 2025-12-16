-- PvPResult_Client.lua (Located at StarterGui/PvP_UI)
-- Handles the freeze frame and the win/loss popup at the end of a PvP match.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService") 
local player = Players.LocalPlayer
local gui = script.Parent -- ScreenGui

-- Color Definitions
local GRAYISH_WHITE = Color3.fromRGB(200, 200, 200)
local DARK_BACKGROUND = Color3.fromRGB(30, 30, 30) -- Darker base background for consistency

-- Check for core services
if not TweenService or not Enum.EasingStyle.Quad then
	warn("PvPResult_Client: Missing core services (TweenService) or EasingStyle is unavailable. Script terminating early.")
	return
end

local RemoteEventFolder = ReplicatedStorage:WaitForChild("RemoteEvent")
local FreezeAndShowResultEvent = RemoteEventFolder:WaitForChild("FreezeAndShowResult") 

-- =========================================================
-- A. UI Initialization: Create ResultPanel and its children
-- =========================================================

local ResultPanel = Instance.new("Frame")
ResultPanel.Name = "ResultPanel"
ResultPanel.Size = UDim2.new(0.4, 0, 0.3, 0)
ResultPanel.Position = UDim2.new(0.5, 0, 0.5, 0)
ResultPanel.AnchorPoint = Vector2.new(0.5, 0.5)
ResultPanel.BorderSizePixel = 0
ResultPanel.BorderColor3 = Color3.fromRGB(27, 42, 53)
ResultPanel.ZIndex = 20 -- Ensure it's on top
ResultPanel.Visible = false
ResultPanel.BackgroundTransparency = 0 -- Ensure initial visibility
ResultPanel.BackgroundColor3 = DARK_BACKGROUND -- Dark background color
ResultPanel.Parent = gui

-- Use UICorner for rounded corners
local ResultCorner = Instance.new("UICorner")
ResultCorner.CornerRadius = UDim.new(0, 10) 
ResultCorner.Parent = ResultPanel 

local ResultText = Instance.new("TextLabel")
ResultText.Name = "ResultTextLabel"
ResultText.Size = UDim2.new(0.9, 0, 0.5, 0)
ResultText.Position = UDim2.new(0.5, 0, 0.5, 0)
ResultText.AnchorPoint = Vector2.new(0.5, 0.5)
ResultText.BackgroundColor3 = Color3.fromRGB(255, 255, 255) 
ResultText.BackgroundTransparency = 1 -- Transparent text background
ResultText.TextTransparency = 0 -- Ensure text is visible initially
ResultText.Text = "..."
ResultText.Font = Enum.Font.SourceSansBold
ResultText.TextSize = 36
ResultText.TextColor3 = GRAYISH_WHITE -- Grayish-white text color
ResultText.TextScaled = true
ResultText.TextWrapped = true
ResultText.ZIndex = 21
ResultText.Parent = ResultPanel

-- [KEY: Record original size and position]
local originalPanelSize = ResultPanel.Size
local originalPanelPosition = ResultPanel.Position


-- =========================================================
-- B. Core Logic: Freeze and Popup
-- =========================================================

-- Handle freeze and result display
local function handleFreezeAndResult(isWinner, duration)

	if not ResultPanel or not ResultText then
		warn("PvPResult_Client: UI elements missing, cannot display result.")
		return
	end

	-- 1. Block player input (freeze effect)
	UserInputService.ModalEnabled = true 
	print("PvPResult_Client: Player input disabled (ModalEnabled = true)")

	-- 2. Disable camera control (enhance freeze perception)
	local camera = workspace.CurrentCamera
	if camera then
		if camera.CameraType ~= Enum.CameraType.Scriptable then
			camera.CameraType = Enum.CameraType.Scriptable
		end
	end

	-- 3. Set popup content and color
	ResultPanel.Visible = true
	ResultPanel.BackgroundTransparency = 0 -- Ensure background is visible
	ResultText.TextTransparency = 0 -- Ensure text is visible

	if isWinner then
		ResultPanel.BackgroundColor3 = Color3.fromRGB(0, 80, 0) -- Victory: Dark green
		ResultText.Text = "🏆 VICTORY!" 
	else
		ResultPanel.BackgroundColor3 = Color3.fromRGB(120, 0, 0) -- Defeat: Dark red
		ResultText.Text = "❌ DEFEAT!" 
	end

	-- Play in-animation
	ResultPanel.Size = UDim2.new(0, 0, 0, 0) -- Start small

	TweenService:Create(
		ResultPanel, 
		TweenInfo.new(0.3, Enum.EasingStyle.Quad), -- Use Quad easing style
		{Size = originalPanelSize} -- Animate to original size
	):Play()
	print("PvPResult_Client: Popup entry animation started.")


	-- 4. Wait for freeze duration 
	local success, message = pcall(task.wait, duration)
	if not success then
		warn("PvPResult_Client: task.wait was interrupted/failed. Reason: ", message)
	end

	-- 5. Unfreeze and play fade-out animation
	local exitInfo = TweenInfo.new(0.2, Enum.EasingStyle.Linear)

	-- Animation 1: Frame background fade out
	local exitPanelTween = TweenService:Create(
		ResultPanel, 
		exitInfo, 
		{BackgroundTransparency = 1} 
	)

	-- Animation 2: TextLabel text fade out
	local exitTextTween = TweenService:Create(
		ResultText, 
		exitInfo, 
		{TextTransparency = 1} 
	)

	exitPanelTween:Play()
	exitTextTween:Play()
	print("PvPResult_Client: Popup fade out animation started.")


	exitPanelTween.Completed:Wait() -- Wait for animation to finish
	print("PvPResult_Client: Popup fade out animation complete, starting cleanup.")


	-- 6. Final cleanup and state restoration
	ResultPanel.Visible = false
	-- Reset to original size and position for next animation
	ResultPanel.Size = originalPanelSize
	ResultPanel.Position = originalPanelPosition 
	ResultPanel.BackgroundTransparency = 0  
	ResultText.TextTransparency = 0         

	-- Ensure camera reverts to Custom mode
	if camera then
		if camera.CameraType == Enum.CameraType.Scriptable then
			camera.CameraType = Enum.CameraType.Custom
		end
	end

	-- Ensure input is restored
	UserInputService.ModalEnabled = false
	print("PvPResult_Client: Player input restored (ModalEnabled = false).")
end

-- Listen for the freeze event from the server
if FreezeAndShowResultEvent and FreezeAndShowResultEvent:IsA("RemoteEvent") then
	FreezeAndShowResultEvent.OnClientEvent:Connect(function(isWinner, duration)
		print("PvPResult_Client: Freeze event listener activated.")
		handleFreezeAndResult(isWinner, duration)
	end)
else
	warn("PvPResult_Client: Missing FreezeAndShowResult RemoteEvent, freeze functionality will be disabled.")
end