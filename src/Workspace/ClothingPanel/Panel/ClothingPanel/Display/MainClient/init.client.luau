-- this is a terrible mess

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local TextService = game:GetService("TextService")

local Slider = require(script.Slider)
local constants = require(script.Constants)

local replicated = ReplicatedStorage:WaitForChild("ClothingPanel")
local localPlayer = Players.LocalPlayer

local main = script.Parent.Main
local mainButtons = main.Buttons
local overlays = script.Parent.Overlays.Content
local popup = script.Parent.Popup

local outfits = overlays.Outfits
local remover = overlays.Remover
local scaleSliders = overlays.ScaleSliders
local skinColourChanger = overlays.SkinColourChanger

local lastOverlayOpenTime = os.clock()
local currentOutfitsPage = 1
local lastMaxPages = 1
local currentOutfitView = "list"
local currentOutfit
local currentlyInputtedType = ""
local visibleOverlay = nil
local outfitPrivacy = "private"
local privacyCooldown = false
local selectedEmoteSlot = 1
local lastID

local selectedColour = constants.colours.BLUE1
local deselectedColour = constants.colours.DARK5

local sliders = {
	{
		name = "Height",
		id = "height",
		humanoidProperty = "BodyHeightScale",
		frame = scaleSliders.Sliders.Height,
	},
	{
		name = "Width",
		id = "width",
		humanoidProperty = "BodyWidthScale",
		frame = scaleSliders.Sliders.Width,
	},
	{
		name = "Depth",
		id = "depth",
		humanoidProperty = "BodyDepthScale",
		frame = scaleSliders.Sliders.Depth,
	},
	{
		name = "Head",
		id = "head",
		humanoidProperty = "HeadScale",
		frame = scaleSliders.Sliders.Head,
	}
}

local function sendEvent(eventName: string, ...)
	local event = replicated:FindFirstChild(eventName)
	if event:IsA("RemoteEvent") then
		event:FireServer(script.Parent.Parent.Adornee, ...)
	else
		return event:InvokeServer(script.Parent.Parent.Adornee, ...)
	end
end

local function showOverlay(overlayName: string, openTime: number?)
	if visibleOverlay then
		if overlayName == visibleOverlay.Name then return end
		local currentOverlay = visibleOverlay
		local newOverlay = overlays:FindFirstChild(overlayName)
		visibleOverlay = newOverlay

		TweenService:Create(overlays, TweenInfo.new(0.2), { Position = UDim2.new(0.5, 0, 1, 0) }):Play()
		task.delay(0.25, function()
			currentOverlay.Visible = false
			newOverlay.Visible = true
			TweenService:Create(overlays, TweenInfo.new(0.2), { Position = UDim2.new(0.5, 0, 0, 64) }):Play()
		end)
	else
		lastOverlayOpenTime = openTime or os.clock()
		visibleOverlay = overlays:FindFirstChild(overlayName)
		visibleOverlay.Visible = true
		overlays.Visible = true
		visibleOverlay.Position = UDim2.fromScale(0, 0)
		TweenService:Create(overlays.Parent, TweenInfo.new(0.2), { BackgroundTransparency = 0.4 }):Play()
		overlays.Position = UDim2.new(0.5, 0, 1, 0)
		TweenService:Create(overlays, TweenInfo.new(0.2), { Position = UDim2.new(0.5, 0, 0, 64) }):Play()
	end
end

local function hideOverlay()
	if not visibleOverlay then return end
	TweenService:Create(overlays.Parent, TweenInfo.new(0.2), { BackgroundTransparency = 1 }):Play()
	TweenService:Create(overlays, TweenInfo.new(0.2), { Position = UDim2.new(0.5, 0, 1, 0) }):Play()
	task.wait(0.3)
	visibleOverlay.Visible = false
	visibleOverlay = nil
end

local function updateEmoteWheel()
	local description: HumanoidDescription = Players.LocalPlayer.Character.Humanoid:GetAppliedDescription()
	local equippedEmotes = description:GetEquippedEmotes()
	local emotes = description:GetEmotes()
	local slotsUsed = table.create(8, false)
	for _, data in equippedEmotes do
		slotsUsed[data.Slot] = true
		local button = overlays.EmoteChanger.Slots[data.Slot]
		local emoteId = emotes[data.Name][1]
		button.Icon.Image = `rbxthumb://type=Asset&id={emoteId}&w=150&h=150`
	end
	for slotId, slotUsed in slotsUsed do
		if slotUsed == false then
			local button = overlays.EmoteChanger.Slots[slotId]
			button.Icon.Image = ""
		end
	end
end

local function connectButton(func)
	return function()
		if visibleOverlay then return end
		func()
	end
end

local function getProductInfo(id)
	for i = 1, 3 do
		local success, info = pcall(function()
			return MarketplaceService:GetProductInfo(id)
		end)
		if success then
			return info
		end
	end
	return nil
end

local function getNames()
	local names = {}
	local description: HumanoidDescription = Players.LocalPlayer.Character.Humanoid:GetAppliedDescription()
	for categoryName, propertyNames in pairs(constants.properties) do
		for _, propertyName in propertyNames do
			local value = description[propertyName]
			if value ~= 0 then
				table.insert(names, { Category = categoryName, Id = value, Property = propertyName })
			end
		end
	end
	local accessories = description:GetAccessories(true)
	for _, accessoryData in accessories do
		table.insert(names, { Category = "accessories", Id = accessoryData.AssetId, Property = "Accessory" })
	end
	return names
end

local function changeOutfitBackButton(state: "create" | "back")
	local button = overlays.Outfits.ViewSwitch
	button.Title.Text = if state == "create" then "Create" else "Back"
	button.BackIcon.Visible = state == "back"
	button.CreateIcon.Visible = state == "create"
	button.BackgroundColor3 = if state == "create" then constants.colours.BUTTON_ACTIVE_BLUE else constants.colours.DARK5
end

local function updatePrivacyIcons()
	local icon = if currentOutfit.Private then constants.icons.private else constants.icons.public
	local text = if currentOutfit.Private then "Private" else "Public"
	overlays.Outfits.OutfitDetails.Details.Buttons.ChangePrivacy.Icon.Image = icon
	overlays.Outfits.OutfitDetails.Details.Buttons.ChangePrivacy.Title.Text = text
	overlays.Outfits.OutfitDetails.Details.Icon.PrivacyStatus.Icon.Image = if currentOutfit.Private then constants.icons.private else constants.icons.public
end

local function hideOutfitDeletePrompt()
	local popup = overlays.Outfits.DeleteConfirmationPopup
	TweenService:Create(popup.Content, TweenInfo.new(0.2), { Position = UDim2.fromScale(0.5, 1.5) }):Play()
	TweenService:Create(popup, TweenInfo.new(0.2), { BackgroundTransparency = 1 }):Play()
	task.wait(0.2)
	popup.Visible = false
end

local function showOutfitDeletePrompt()
	local popup = overlays.Outfits.DeleteConfirmationPopup
	popup.BackgroundTransparency = 1
	TweenService:Create(popup, TweenInfo.new(0.2), { BackgroundTransparency = 0.1 }):Play()
	popup.Content.Position = UDim2.fromScale(0.5, 1.5)
	TweenService:Create(popup.Content, TweenInfo.new(0.2), { Position = UDim2.fromScale(0.5, 0.5) }):Play()
	popup.Visible = true
end

local function showOutfitDetails(outfit)
	currentOutfitView = "details"
	overlays.Outfits.OutfitList.Visible = false
	overlays.Outfits.OutfitDetails.Visible = true
	changeOutfitBackButton("back")
	
	overlays.Outfits.OutfitDetails.Details.Info.Namer.Text = outfit.Name
	overlays.Outfits.OutfitDetails.Details.Info.Creator.Text = `{outfit.Owner}`
	
	currentOutfit = outfit
	
	updatePrivacyIcons()
	
	local shouldDangerousButtonsBeVisible = currentOutfit.OwnerID == Players.LocalPlayer.UserId
	
	overlays.Outfits.OutfitDetails.Details.Buttons.ChangePrivacy.Visible = shouldDangerousButtonsBeVisible
	overlays.Outfits.OutfitDetails.Details.Buttons.Delete.Visible = shouldDangerousButtonsBeVisible
	
	for _, child in overlays.Outfits.OutfitDetails.AssetList:GetChildren() do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	
	local assetList = sendEvent("GetOutfitAssets", outfit.ID)
	
	if currentOutfit ~= outfit then
		return
	end
	
	for _, assetId in assetList do
		task.spawn(function()
			local itemFrame = script.Item:Clone()
			itemFrame.RemoveButton:Destroy()
			itemFrame.Namer.Text = "Loading name.."
			itemFrame.Icon.Image = `rbxthumb://type=Asset&id={assetId}&w=150&h=150`
			itemFrame.Parent = overlays.Outfits.OutfitDetails.AssetList
			local assetFetchSuccess, assetData = pcall(MarketplaceService.GetProductInfo, MarketplaceService, assetId)
			if assetFetchSuccess then
				itemFrame.Namer.Text = assetData.Name
			end
		end)
	end
end

local function showOutfitsPage(pageNumber: number)
	for _, thing in overlays.Outfits.OutfitList.List:GetChildren() do
		if thing:IsA("Frame") then
			thing:Destroy()
		elseif thing:IsA("TextLabel") then
			thing.Visible = true
		end
	end
	local outfits, totalPages = replicated.GetOutfitPage:InvokeServer(pageNumber, overlays.Outfits.OutfitList.SearchBar.TextBox.Text)
	
	if not outfits then
		overlays.Outfits.OutfitList.List.Loading.Text = `Couldn't load outfits. {if RunService:IsStudio() then "Make sure that Studio Access to API Services is enabled in game settings" else ""}`
		return
	end
	
	totalPages = math.max(totalPages, 1)
	lastMaxPages = totalPages
	overlays.Outfits.OutfitList.Controls.CurrentPage.Text = `{pageNumber} / {totalPages}`
	for _, thing in overlays.Outfits.OutfitList.List:GetChildren() do
		if thing:IsA("Frame") then
			thing:Destroy()
		elseif thing:IsA("TextLabel") then
			thing.Visible = false
		end
	end
	for _, outfit in outfits do
		local frame = script.Outfit:Clone()
		frame.Details.Namer.Text = outfit.Name
		frame.Details.Creator.Text = `{outfit.Owner}`
		frame.Icon.PrivacyStatus.Icon.Image = if outfit.Private then constants.icons.private else constants.icons.public
		frame.WearButton.MouseButton1Click:Connect(function()
			showOutfitDetails(outfit)
		end)
		frame.Parent = overlays.Outfits.OutfitList.List
	end
end

local function onCharacterAdded(character)
	local humanoid = character:WaitForChild("Humanoid")
	
	for _, sliderData in sliders do
		local scaleValue: NumberValue = humanoid:WaitForChild(sliderData.humanoidProperty)
		sliderData.slider:SetValue(scaleValue.Value * 100)
		scaleValue.Changed:Connect(function(newVal: number)
			sliderData.slider:SetValue(newVal * 100)
		end)
	end
end

local function showPopup(message: string, success: boolean?)
	local colour = if success then constants.colours.BLUE1 else constants.colours.RED1
	popup.BackgroundColor3 = colour
	popup.Text = message
	TweenService:Create(popup, TweenInfo.new(0.1), { BackgroundTransparency = 0, TextTransparency = 0 }):Play()
	task.wait(4)
	TweenService:Create(popup, TweenInfo.new(0.2), { BackgroundTransparency = 1, TextTransparency = 1 }):Play()
end

local function waitForPartToLoad()
	if not script.Parent.Parent.Adornee then
		script.Parent.Parent:GetPropertyChangedSignal("Adornee"):Wait()
	end
end

local function showUpdateInformation()
	local value = replicated.UpdateInformation.Value
	if value == "nil" then
		return
	end
	
	local data = HttpService:JSONDecode(value)
	local moreUpdates = overlays.Update.MessageArea.VersionList.MoreUpdatesAvailable
	local versionTemplate = overlays.Update.MessageArea.VersionList.VersionTemplate
	
	if data.update then
		if data.update.additionalUpdates > 0 then
			moreUpdates.Visible = true
			moreUpdates.Text = `{data.update.additionalUpdates} more updates available`
		else
			moreUpdates.Visible = false
		end
		
		local totalUpdateCount = #data.update.updates + data.update.additionalUpdates
		overlays.Update.WindowTitle.Text = `Update{if totalUpdateCount > 1 then "s" else ""} available`
		
		for _, update in data.update.updates do
			local frame = versionTemplate:Clone()
			local itemTemplate = frame.Changelog.Item
			frame.Info.Version.Text = `Version {update.version}`
			frame.Info.ReleaseDate.Text = `Released on {update.releaseDate}`
			for _, change in update.changelog do
				local item = itemTemplate:Clone()
				item.Text = `• {change}`
				item.Parent = frame.Changelog
			end
			frame.Parent = overlays.Update.MessageArea.VersionList
			itemTemplate:Destroy()
		end
		versionTemplate:Destroy()
		
		main.Parent.Topbar.UpdateIndicator.Visible = true
	end
	
	if data.announcement then
		task.spawn(function()
			waitForPartToLoad()
			task.wait(0.1)
			local list = overlays.Announcement.MessageArea.List
			local params = Instance.new("GetTextBoundsParams")
			params.Font = Font.fromId(12187365364, Enum.FontWeight.Regular)
			params.Size = 18
			params.Width = list.AbsoluteCanvasSize.X - 32 -- 32 = padding
			params.Text = data.announcement.content
			local textBounds = TextService:GetTextBoundsAsync(params)
			list.Content.Size = UDim2.new(1, -32, 0, textBounds.Y)
			list.Content.Text = data.announcement.content
			list.Title.Text = data.announcement.title
			main.Parent.Topbar.Announcement.Visible = true
		end)
	end
	
	if data.announcement and data.announcement.isImportant then
		showOverlay("Announcement")
	elseif data.update and data.update.isImportant then
		showOverlay("Update")
	end
end

local function showItemDeleter()
	local thisOpenTime = os.clock()
	showOverlay("Remover", thisOpenTime) -- TODO: thisOpenTime is no longer needed
	overlays.Remover.SearchBar.TextBox.Text = ""
	for _, thing in overlays.Remover.ScrollingFrame:GetChildren() do
		if thing:IsA("Frame") then
			thing:Destroy()
		end
	end
	local names = getNames()
	for _, data in names do
		local itemFrame = script.Item:Clone()
		itemFrame.Namer.Text = "Loading name.."
		itemFrame.Icon.Image = `rbxthumb://type=Asset&id={data.Id}&w=150&h=150`
		itemFrame.Parent = overlays.Remover.ScrollingFrame
		itemFrame.RemoveButton.MouseButton1Click:Connect(function()
			sendEvent("Delete", data.Property, data.Id)
			itemFrame:Destroy()
		end)
		task.spawn(function()
			local assetInfo = getProductInfo(data.Id)
			if assetInfo then
				itemFrame.Namer.Text = assetInfo.Name
				itemFrame.Name = string.lower(assetInfo.Name)
			end
		end)
	end
end

local function connectButtonPresses()
	main.Parent.Topbar.UpdateIndicator.Activated:Connect(function()
		showOverlay("Update")
	end)
	main.Parent.Topbar.Version.Activated:Connect(function()
		showOverlay("About")
	end)
	main.Parent.Topbar.Announcement.Activated:Connect(function()
		showOverlay("Announcement")
	end)
	
	mainButtons.Outfits.MouseButton1Click:Connect(connectButton(function()
		showOverlay("Outfits")
		showOutfitsPage(1)
	end))
	mainButtons.Scaling.MouseButton1Click:Connect(connectButton(function()
		showOverlay("ScaleSliders")
	end))
	mainButtons.SkinColour.MouseButton1Click:Connect(connectButton(function()
		showOverlay("SkinColourChanger")
	end))
	mainButtons.Refresh.MouseButton1Click:Connect(connectButton(function()
		local cframe = workspace.CurrentCamera.CFrame
		sendEvent("Refresh")
		task.wait(1 / 30)
		workspace.CurrentCamera.CFrame = cframe
	end))
	mainButtons:FindFirstChild("Remove").MouseButton1Click:Connect(connectButton(showItemDeleter))
	
	main.IDBox.EquipAsset.Activated:Connect(connectButton(function()
		local id = tonumber(main.IDBox.AssetIDBox.Text)
		if not id then
			return
		end
		main.IDBox.Loading.Visible = true
		lastID = id
		local equipped, names = sendEvent("EquipID", tostring(id))
		main.IDBox.Loading.Visible = false
		if not equipped then
			showOverlay("ChooseID")
			overlays.ChooseID.List.Asset.Namer.Text = names[1]
			overlays.ChooseID.List.Bundle.Namer.Text = names[2]
			overlays.ChooseID.List.Asset.Icon.Image = `rbxthumb://type=Asset&id={id}&w=150&h=150`
			overlays.ChooseID.List.Bundle.Icon.Image = `rbxthumb://type=BundleThumbnail&id={id}&w=150&h=150`
		end
	end))
	
	overlays.ChooseID.List.Asset.WearButton.Activated:Connect(function()
		sendEvent("EquipAsset", tostring(lastID))
		hideOverlay()
	end)
	overlays.ChooseID.List.Bundle.WearButton.Activated:Connect(function()
		sendEvent("EquipBundle", tostring(lastID))
		hideOverlay()
	end)

	mainButtons.Emotes.Activated:Connect(connectButton(function()
		showOverlay("EmoteChanger")
		updateEmoteWheel()
	end))
	
	for _, button in overlays.EmoteChanger.Slots:GetChildren() do
		if button:IsA("GuiButton") then
			button.Activated:Connect(function()
				selectedEmoteSlot = tonumber(button.Name)
				for _, button2 in overlays.EmoteChanger.Slots:GetChildren() do
					if button2:IsA("GuiButton") then
						button2.BackgroundColor3 = if tonumber(button2.Name) == selectedEmoteSlot then constants.colours.BLUE1 else constants.colours.DARK4
					end
				end
			end)
		end
	end
	
	overlays.EmoteChanger.Submit.Activated:Connect(function()
		local success = sendEvent("ChangeEmote", overlays.EmoteChanger.IdBox.Text, selectedEmoteSlot)
		if success then
			updateEmoteWheel()
			showPopup("Emote equipped", true)
		else
			showPopup("Couldn't equip this emote, is the ID correct?", false)
		end
	end)
	
	overlays.ScaleSliders.ResetAll.Activated:Connect(function()
		for _, slider in sliders do
			slider.slider:SetValue(100, true)
		end
	end)
	
	overlays.About.Content.Extra.Donate.Activated:Connect(function()
		MarketplaceService:PromptGamePassPurchase(Players.LocalPlayer, 1231991042)
	end)
	
	-- generic overlay stuff
	overlays.BackButton.MouseButton1Click:Connect(hideOverlay)
	
	-- outfits
	overlays.Outfits.OutfitList.Controls.Next.MouseButton1Click:Connect(function()
		currentOutfitsPage += 1
		if currentOutfitsPage > lastMaxPages then
			currentOutfitsPage = lastMaxPages
		end
		showOutfitsPage(currentOutfitsPage)
	end)
	overlays.Outfits.OutfitList.Controls.Previous.MouseButton1Click:Connect(function()
		currentOutfitsPage -= 1
		if currentOutfitsPage < 1 then
			currentOutfitsPage = 1
		end
		showOutfitsPage(currentOutfitsPage)
	end)
	overlays.Outfits.OutfitList.SearchBar.TextBox:GetPropertyChangedSignal("Text"):Connect(function()
		overlays.Outfits.OutfitList.SearchBar.ClearButton.Visible = overlays.Outfits.OutfitList.SearchBar.TextBox.Text ~= ""
	end)
	overlays.Outfits.OutfitList.SearchBar.TextBox.FocusLost:Connect(function()
		currentOutfitsPage = 1
		showOutfitsPage(currentOutfitsPage)
	end)
	overlays.Outfits.OutfitList.SearchBar.ClearButton.Activated:Connect(function()
		overlays.Outfits.OutfitList.SearchBar.TextBox.Text = ""
		currentOutfitsPage = 1
		showOutfitsPage(currentOutfitsPage)
	end)
	
	overlays.Outfits.NewOutfit.Options.OutfitPrivacy.Buttons.Public.MouseButton1Click:Connect(function()
		outfitPrivacy = "public"
		overlays.Outfits.NewOutfit.Options.OutfitPrivacy.Buttons.Private.BackgroundColor3 = deselectedColour
		overlays.Outfits.NewOutfit.Options.OutfitPrivacy.Buttons.Public.BackgroundColor3 = selectedColour
	end)
	overlays.Outfits.NewOutfit.Options.OutfitPrivacy.Buttons.Private.MouseButton1Click:Connect(function()
		outfitPrivacy = "private"
		overlays.Outfits.NewOutfit.Options.OutfitPrivacy.Buttons.Private.BackgroundColor3 = selectedColour
		overlays.Outfits.NewOutfit.Options.OutfitPrivacy.Buttons.Public.BackgroundColor3 = deselectedColour
	end)

	overlays.Outfits.NewOutfit.CreateOutfit.MouseButton1Click:Connect(function()
		local name = overlays.Outfits.NewOutfit.Options.OutfitName.NameBox.Text
		local nameWithoutSpaces = string.gsub(name, " ", "")
		if string.len(nameWithoutSpaces) == 0 then return showPopup("You need to provide a name for the outfit") end
		if string.find(name, "#") then return showPopup("Outfit name can't contain #s") end

		local success, errorMessage = sendEvent("CreateOutfit", name, outfitPrivacy)
		if not success then
			return showPopup(errorMessage or "Something went wrong")
		end

		return showPopup("Outfit created successfully", true)
	end)

	overlays.Outfits.OutfitDetails.WearButton.MouseButton1Click:Connect(function()
		sendEvent("WearOutfit", currentOutfit.ID)
	end)

	overlays.Outfits.OutfitDetails.Details.Buttons.ChangePrivacy.MouseButton1Click:Connect(function()
		if privacyCooldown then return end
		privacyCooldown = true
		sendEvent("ChangePrivacy", currentOutfit.ID)
		currentOutfit.Private = not currentOutfit.Private
		updatePrivacyIcons()
		task.wait(5)
		privacyCooldown = false
	end)

	overlays.Outfits.OutfitDetails.Details.Buttons.Delete.MouseButton1Click:Connect(function()
		showOutfitDeletePrompt()
	end)
	
	overlays.Outfits.DeleteConfirmationPopup.Content.Buttons.Delete.Activated:Connect(function()
		hideOutfitDeletePrompt()
		showPopup("Deleting outfit..", true)
		sendEvent("DeleteOutfit", currentOutfit.ID)
		currentOutfitView = "list"
		changeOutfitBackButton("create")
		overlays.Outfits.OutfitList.Visible = true
		overlays.Outfits.NewOutfit.Visible = false
		overlays.Outfits.OutfitDetails.Visible = false
		showOutfitsPage(currentOutfitsPage)
	end)
	
	overlays.Outfits.DeleteConfirmationPopup.Content.Buttons.Cancel.Activated:Connect(function()
		hideOutfitDeletePrompt()
	end)
	
	overlays.Outfits.ViewSwitch.MouseButton1Click:Connect(function()
		if currentOutfitView == "list" then
			currentOutfitView = "new"
			changeOutfitBackButton("back")
			overlays.Outfits.OutfitList.Visible = false
			overlays.Outfits.NewOutfit.Visible = true
			overlays.Outfits.OutfitDetails.Visible = false
		else
			currentOutfitView = "list"
			changeOutfitBackButton("create")
			overlays.Outfits.OutfitList.Visible = true
			overlays.Outfits.NewOutfit.Visible = false
			overlays.Outfits.OutfitDetails.Visible = false
			showOutfitsPage(currentOutfitsPage)
		end
	end)
	
	-- skin colour
	for _, button in overlays.SkinColourChanger.Colours:GetChildren() do
		if button:IsA("TextButton") then
			button.MouseButton1Click:Connect(function()
				sendEvent("ChangeSkinColour", button.BackgroundColor3)
			end)
		end
	end
	
	-- remover
	overlays.Remover.RemoveAll.Activated:Connect(function()
		sendEvent("DeleteAll")
		for _, child in overlays.Remover.ScrollingFrame:GetChildren() do
			if child:IsA("Frame") then
				child:Destroy()
			end
		end
	end)
	
	overlays.Remover.SearchBar.TextBox.FocusLost:Connect(function()
		local searchPhrase = overlays.Remover.SearchBar.TextBox.Text
		for _, child in overlays.Remover.ScrollingFrame:GetChildren() do
			if child:IsA("Frame") then
				child.Visible = string.find(child.Name, searchPhrase)
			end
		end
	end)
	overlays.Remover.SearchBar.TextBox:GetPropertyChangedSignal("Text"):Connect(function()
		overlays.Remover.SearchBar.ClearButton.Visible = overlays.Remover.SearchBar.TextBox.Text ~= ""
	end)
	overlays.Remover.SearchBar.ClearButton.Activated:Connect(function()
		overlays.Remover.SearchBar.TextBox.Text = ""
		for _, child in overlays.Remover.ScrollingFrame:GetChildren() do
			if child:IsA("Frame") then
				child.Visible = true
			end
		end
	end)
end

local function setupSliders()
	for _, sliderData in sliders do
		local slider = Slider.new(sliderData.name, sliderData.frame, script.Parent.Parent.Adornee, 25, 200, "%")
		slider.Changed.Event:Connect(function(value)
			sendEvent("Slider", sliderData.id, value)
		end)
		sliderData.slider = slider
	end
end

local function connectUpdateListener()
	if replicated.UpdateInformation.Value == "" then
		replicated.UpdateInformation.Changed:Once(showUpdateInformation)
	else
		showUpdateInformation()
	end
end

local function setup()
	connectButtonPresses()
	setupSliders()
	connectUpdateListener()
	
	if localPlayer.Character then
		onCharacterAdded(localPlayer.Character)
	end
	localPlayer.CharacterAdded:Connect(onCharacterAdded)
end

setup()