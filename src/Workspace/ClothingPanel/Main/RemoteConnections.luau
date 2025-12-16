local MarketplaceService = game:GetService("MarketplaceService")
local AssetService = game:GetService("AssetService")
local AvatarEditorService = game:GetService("AvatarEditorService")

local utils = require(script.Parent.Utils)
local constants = require(script.Parent.Constants)
local dataStore = require(script.Parent.DataStore)
local Settings = require(script.Parent.Parent.Settings)

local function performDescriptionChanges(plr: Player, func: (HumanoidDescription) -> any)
	local humanoid = utils.getHumanoidFromPlayer(plr)
	local description = humanoid:GetAppliedDescription()
	func(description)
	humanoid:ApplyDescription(description)
end

local function applyAnimation(assetId: number, description: HumanoidDescription)
	local success, productInfo = pcall(MarketplaceService.GetProductInfo, MarketplaceService, assetId)
	if not success then return end

	local assetTypeId = productInfo.AssetTypeId
	local assetTypeEnum = utils.enumIdToEnum(Enum.AssetType, assetTypeId)
	if not utils.isAnimation(assetTypeEnum) then return end

	local assetId = productInfo.AssetId
	local propertyName = assetTypeEnum.Name
	description[propertyName] = assetId
end

local function changeSkinColour(plr: Player, colour: any)
	if typeof(colour) ~= "Color3" then return end

	performDescriptionChanges(plr, function(description)
		for _, propertyName in constants.colourProperties do
			description[propertyName] = colour
		end
	end)
end

local function handleAsset(id: number, description: HumanoidDescription)
	local assetInfo = MarketplaceService:GetProductInfo(id, Enum.InfoType.Asset)
	local assetType = utils.enumIdToEnum(Enum.AssetType, assetInfo.AssetTypeId)

	if assetType == Enum.AssetType.Shirt then
		description.Shirt = id
	elseif assetType == Enum.AssetType.Pants then
		description.Pants = id
	elseif assetType == Enum.AssetType.TShirt then
		description.GraphicTShirt = id
	elseif assetType == Enum.AssetType.Face then
		description.Face = id
		if description.Head ~= 0 then
			local headInfo = MarketplaceService:GetProductInfo(description.Head, Enum.InfoType.Asset)
			if headInfo.AssetTypeId == Enum.AssetType.DynamicHead.Value then
				description.Head = 0
			end
		end
	elseif utils.isAnimation(assetType) then
		local propertyName = assetType.Name
		description[propertyName] = id
	elseif utils.isBodyPart(assetType) then
		if assetType == Enum.AssetType.DynamicHead then
			description.Head = id
		else
			description[assetType.Name] = id
		end
	elseif utils.isRigidAccessory(assetType) then
		local currentAccessories = description:GetAccessories(true)
		table.insert(currentAccessories, {
			AccessoryType = constants.assetTypeToAccessoryType[assetType],
			AssetId = id,
			IsLayered = false
		})
		description:SetAccessories(currentAccessories, true)
	elseif utils.isLayeredAccessory(assetType) then
		local accessoryType = constants.assetTypeToAccessoryType[assetType]
		local currentAccessories = description:GetAccessories(false)
		local alreadyExistingAccessory = utils.findAccessoryOfType(currentAccessories, accessoryType)
		if alreadyExistingAccessory and not table.find(constants.layeredAccessoryTypesThatShouldntBeReplaced, accessoryType) then
			alreadyExistingAccessory.AssetId = id
			alreadyExistingAccessory.Puffiness = nil
		else
			table.insert(currentAccessories, {
				AccessoryType = accessoryType,
				AssetId = id,
				IsLayered = true,
				Order = constants.defaultLayeredClothingOrder[accessoryType]
			})
		end
		description:SetAccessories(currentAccessories, false)
	end
end

local function equipAsset(plr: Player, assetId: any)
	if typeof(assetId) ~= "string" then return end

	local id = tonumber(assetId)
	if not id then return end

	performDescriptionChanges(plr, function(description)
		handleAsset(id, description)
	end)
end

local function equipBundle(plr: Player, bundleId: any)
	if typeof(bundleId) ~= "string" then return end	

	local id = tonumber(bundleId)
	if not id then return end

	local bundleDetails = AssetService:GetBundleDetailsAsync(id)
	performDescriptionChanges(plr, function(description)
		for _, item in bundleDetails.Items do
			if item.Type == "Asset" then
				handleAsset(item.Id, description)
			end
		end
	end)
end

local function equipID(plr: Player, assetId: any): boolean
	if typeof(assetId) ~= "string" then return end

	local id = tonumber(assetId)
	if not id then return true end

	local assetInfoSuccess, assetInfo = pcall(MarketplaceService.GetProductInfo, MarketplaceService, id, Enum.InfoType.Asset)
	local bundleInfoSuccess, bundleInfo = pcall(AssetService.GetBundleDetailsAsync, AssetService, id)
	
	if assetInfoSuccess then
		local isValidAsset = true
		for _, assetTypeEnum in constants.assetTypesThatAreNotCatalogRelated do
			if assetInfo.AssetTypeId == assetTypeEnum.Value then
				isValidAsset = false
				break
			end
		end
		if not isValidAsset then
			assetInfoSuccess = false
		end
	end
	
	if assetInfoSuccess == false and bundleInfoSuccess == false then
		return true
	end
	
	if assetInfoSuccess and bundleInfoSuccess then
		return false, {
			if typeof(assetInfo) == "table" then assetInfo.Name or "< Error fetching name >" else "< Error >",
			if typeof(bundleInfo) == "table" then bundleInfo.Name or "< Error fetching name >" else "< Error >"
		}
	end
	
	pcall(function()
		if assetInfoSuccess then
			equipAsset(plr, assetId)
		else
			equipBundle(plr, assetId)
		end
	end)
	
	return true
end

local function refresh(plr: Player)
	local humanoid = utils.getHumanoidFromPlayer(plr)
	local character = humanoid.Parent
	local position = character:WaitForChild("HumanoidRootPart").CFrame
	local tools = {}

	humanoid:UnequipTools()
	for _, tool in plr.Backpack:GetChildren() do
		if tool:IsA("Tool") or tool:IsA("HopperBin") then
			table.insert(tools, tool)
			tool.Parent = nil
		end
	end

	plr:LoadCharacter()
	task.wait()

	plr.Character.HumanoidRootPart.CFrame = position
	if plr.Character:FindFirstChild("ForceField") then
		plr.Character:FindFirstChild("ForceField"):Destroy()
	end

	plr.Backpack:ClearAllChildren()
	for _, tool in tools do
		tool.Parent = plr.Backpack
	end
end

local function sliderSlide(plr: Player, sliderName: string, value: number)
	local actualValue = math.clamp(value, 25, 200) / 100

	performDescriptionChanges(plr, function(description)
		if sliderName == "height" then
			description.HeightScale = actualValue
		elseif sliderName == "width" then
			description.WidthScale = actualValue
		elseif sliderName == "depth" then
			description.DepthScale = actualValue
		elseif sliderName == "head" then
			description.HeadScale = actualValue
		end
	end)
end

local function delete(plr: Player, property: string, id: number)
	performDescriptionChanges(plr, function(description)
		if property == "Accessory" then
			local accessories = description:GetAccessories(true)
			for i, data in accessories do
				if data.AssetId == id then
					table.remove(accessories, i)
					break
				end
			end
			description:SetAccessories(accessories, true)
		else
			description[property] = 0
		end
	end)

	-- Face = 0 gives a default face
	if property == "Face" then
		local character = plr.Character
		local head = character:FindFirstChild("Head")
		local face = head:FindFirstChild("face")
		if face then
			face:Destroy()
		end
	end
end

local function deleteAll(plr: Player)
	performDescriptionChanges(plr, function(description)
		description:SetAccessories({}, true)
		for _, property in constants.assetProperties do
			description[property] = 0
		end
	end)

	local character = plr.Character
	local head = character:FindFirstChild("Head")
	local face = head:FindFirstChild("face")
	if face then
		face:Destroy()
	end
end

local function changeEmote(plr: Player, emoteId: any, emoteSlot: any)
	if typeof(emoteId) ~= "string" or typeof(emoteSlot) ~= "number" then return end
	local emote = tonumber(emoteId)
	if not emote then return false end
	
	local emoteDataSuccess, emoteData = pcall(AvatarEditorService.GetItemDetails, AvatarEditorService, emote, Enum.AvatarItemType.Asset)
	if not emoteDataSuccess then
		return false
	end
	
	if emoteData.AssetType ~= Enum.AssetType.EmoteAnimation.Name then return end
	local emoteName = emoteData.Name
	
	performDescriptionChanges(plr, function(description)
		local currentEmotes = description:GetEmotes()
		if not currentEmotes[emoteName] then
			description:AddEmote(emoteName, emote)
		end
		local equippedEmotes = description:GetEquippedEmotes()
		local currentEmoteInThatSlot = nil
		for _, emote in equippedEmotes do
			if emote.Slot == emoteSlot then
				currentEmoteInThatSlot = emote
				break
			end
		end
		if currentEmoteInThatSlot then
			currentEmoteInThatSlot.Name = emoteName
		else
			table.insert(equippedEmotes, { Name = emoteName, Slot = emoteSlot })
		end
		description:SetEquippedEmotes(equippedEmotes)
	end)
	
	return true
end

local function createOutfit(plr: Player, name: string, privacy: string)
	if not name or not privacy then return false, "Provide everything" end
	local success, errorm = dataStore.createOutfit(plr, name, privacy)
	return success, errorm
end

local function getOutfitPage(plr: Player, page: any, searchPhrase: string)
	if typeof(page) ~= "number" then return end
	if typeof(searchPhrase) ~= "nil" and typeof(searchPhrase) ~= "string" then return end

	return dataStore.getOutfitsPage(plr, page, searchPhrase)
end

local function wearOutfit(plr: Player, id: any)
	if typeof(id) ~= "string" then return end
	local outfit = dataStore.getOutfit(plr, id)
	if not outfit then return end

	performDescriptionChanges(plr, function(description)
		for propertyName, value in outfit.Properties do
			if string.find(propertyName, "Color") then
				description[propertyName] = Color3.fromHex(value)
			else
				description[propertyName] = value
			end
		end

		local accessories = outfit.Accessories
		for _, accessoryData in accessories do
			accessoryData.AccessoryType = utils.enumIdToEnum(Enum.AccessoryType, accessoryData.AccessoryType)
			accessoryData.Position = if accessoryData.Position then Vector3.new(accessoryData.Position[1], accessoryData.Position[2], accessoryData.Position[3]) else Vector3.zero
			accessoryData.Rotation = if accessoryData.Rotation then Vector3.new(accessoryData.Rotation[1], accessoryData.Rotation[2], accessoryData.Rotation[3]) else Vector3.zero
			accessoryData.Scale = if accessoryData.Scale then Vector3.new(accessoryData.Scale[1], accessoryData.Scale[2], accessoryData.Scale[3]) else Vector3.one
		end
		description:SetAccessories(accessories, true)
		
		local emotesData = outfit.Emotes
		if emotesData then
			local equippedEmotes = {}
			local emotes = {}
			for _, emote in emotesData do
				emotes[emote.Name] = emote.IDs
				table.insert(equippedEmotes, { Slot = emote.Slot, Name = emote.Name })
			end
			description:SetEmotes(emotes)
			description:SetEquippedEmotes(equippedEmotes)
		end
	end)

	if outfit.DeleteFace then
		local face = plr.Character:FindFirstChild("Head"):FindFirstChild("face")
		if face then
			face:Destroy()
		end
	end
end

local function changePrivacy(plr: Player, id: any)
	if typeof(id) ~= "string" then return end

	local outfit = dataStore.getOutfit(plr, id)
	if not outfit then return end
	if outfit.Owner ~= plr.UserId then return end

	local newPrivacy = not outfit.Private
	dataStore.updateOutfitPrivacy(id, newPrivacy)
end

local function deleteOutfit(plr: Player, id: string)
	if typeof(id) ~= "string" then return end

	local outfit = dataStore.getOutfit(plr, id)
	if not outfit then return end
	if outfit.Owner ~= plr.UserId then return end

	dataStore.deleteOutfit(id)
end

local function getOutfitAssets(plr: Player, id: string)
	local outfit = dataStore.getOutfit(plr, id)
	if not outfit then return end
	
	local ids = {}
	
	local properties = outfit.Properties
	local accessories = outfit.Accessories
	local emotes = outfit.Emotes
	
	for _, propertyName in constants.assetProperties do
		local value = properties[propertyName]
		if value and value ~= 0 then
			table.insert(ids, value)
		end
	end
	
	for _, accessory in accessories do
		table.insert(ids, accessory.AssetId)
	end
	
	if emotes then
		for _, emote in emotes do
			table.insert(ids, emote.IDs[1])
		end
	end
	
	return ids
end

return {
	changeSkinColour = changeSkinColour,
	refresh = refresh,
	sliderSlide = sliderSlide,
	delete = delete,
	deleteAll = deleteAll,
	createOutfit = createOutfit,
	getOutfitPage = getOutfitPage,
	wearOutfit = wearOutfit,
	changePrivacy = changePrivacy,
	deleteOutfit = deleteOutfit,
	equipAsset = equipAsset,
	equipBundle = equipBundle,
	equipID = equipID,
	changeEmote = changeEmote,
	getOutfitAssets = getOutfitAssets,
}