if _G.ClothingPanelLoaded then
	warn("[ Clothing Panel ]: Multiple Main scripts exist in the game, this could cause unintended behaviour (error code: GB-CL-2)")
end
_G.ClothingPanelLoaded = true

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local HttpService = game:GetService("HttpService")

local remoteConnections = require(script.RemoteConnections)
local Settings = require(script.Parent.Settings)
local UpdateChecker = require("@self/UpdateChecker")
local ProductInfo = require("@self/ProductInfo")

local replicated = script:FindFirstChild("Replicated")
assert(replicated, "[ Clothing Panel ]: Couldn't find Replicated folder inside of Main script (error code: GB-CL-1)")
replicated.Name = "ClothingPanel"
replicated.Parent = ReplicatedStorage

local function isAllowedToDo(plr: Player, panel: any)
	local shouldCheckTeam = #Settings.AllowedTeams > 0
	if shouldCheckTeam then
		local plrTeam = plr.Team
		if not plrTeam then
			return false
		end
		if table.find(Settings.AllowedTeams, plrTeam.Name) == nil then
			return false
		end
	end

	local isValidPanel = panel and typeof(panel) == "Instance" and panel:IsA("Part") and panel:IsDescendantOf(script.Parent)
	if not isValidPanel then
		return false
	end

	local character = plr.Character
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	local distance = (rootPart.Position - panel.Position).Magnitude

	if distance > Settings.MaxDistanceFromPanel then
		return false
	end
	
	return true
end

local function verifyAbility(funcToRun)
	return function(plr: Player, panel: any, ...)
		if isAllowedToDo(plr, panel) then
			return funcToRun(plr, ...)
		end
	end
end

local function movePanels()
	for _, possiblePanel in script.Parent:GetChildren() do
		if possiblePanel:IsA("Part") and possiblePanel:FindFirstChild("ClothingPanel") then
			local gui = possiblePanel:FindFirstChild("ClothingPanel")
			gui.Adornee = possiblePanel
			for _, plr in Players:GetPlayers() do
				gui:Clone().Parent = plr:WaitForChild("PlayerGui")
			end
			gui.Parent = StarterGui
		end
	end
end

local function connectRemotes()
	replicated.ChangeSkinColour.OnServerEvent:Connect(verifyAbility(remoteConnections.changeSkinColour))
	replicated.Refresh.OnServerInvoke = verifyAbility(remoteConnections.refresh)
	replicated.Slider.OnServerEvent:Connect(verifyAbility(remoteConnections.sliderSlide))
	replicated.Delete.OnServerEvent:Connect(verifyAbility(remoteConnections.delete))
	replicated.DeleteAll.OnServerEvent:Connect(verifyAbility(remoteConnections.deleteAll))
	replicated.CreateOutfit.OnServerInvoke = verifyAbility(remoteConnections.createOutfit)
	replicated.GetOutfitPage.OnServerInvoke = remoteConnections.getOutfitPage
	replicated.WearOutfit.OnServerEvent:Connect(verifyAbility(remoteConnections.wearOutfit))
	replicated.ChangePrivacy.OnServerInvoke = verifyAbility(remoteConnections.changePrivacy)
	replicated.DeleteOutfit.OnServerInvoke = verifyAbility(remoteConnections.deleteOutfit)
	replicated.EquipAsset.OnServerEvent:Connect(verifyAbility(remoteConnections.equipAsset))
	replicated.EquipBundle.OnServerEvent:Connect(verifyAbility(remoteConnections.equipBundle))
	replicated.EquipID.OnServerInvoke = verifyAbility(remoteConnections.equipID)
	replicated.ChangeEmote.OnServerInvoke = verifyAbility(remoteConnections.changeEmote)
	replicated.GetOutfitAssets.OnServerInvoke = verifyAbility(remoteConnections.getOutfitAssets)
end

local function removeThumbnailStuff()
	local thumbnailCamera = script.Parent:FindFirstChild("ThumbnailCamera")
	if thumbnailCamera then
		thumbnailCamera:Destroy()
	end
	for _, possiblePanel in script.Parent:GetChildren() do
		if possiblePanel:IsA("Part") and possiblePanel:FindFirstChild("ThumbnailDecal") then
			possiblePanel:FindFirstChild("ThumbnailDecal"):Destroy()
		end
	end
end

local function checkForUpdates()
	if Settings.CheckForUpdates then
		local updateInformation = UpdateChecker.getUpdateInformation(ProductInfo.id, ProductInfo.version)
		if updateInformation then
			replicated.UpdateInformation.Value = HttpService:JSONEncode(updateInformation)
		else
			replicated.UpdateInformation.Value = "nil"
		end
	end
end

local function setup()
	removeThumbnailStuff()
	movePanels()
	connectRemotes()
	checkForUpdates()
end

setup()