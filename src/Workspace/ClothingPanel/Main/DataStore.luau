local DataStoreService = game:GetService("DataStoreService")
local DataStore
local RunService = game:GetService("RunService")
local TextService = game:GetService("TextService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local Settings = require(script.Parent.Parent.Settings)
local utils = require(script.Parent.Utils)
local constants = require(script.Parent.Constants)

local dataStoreEnabled
local dataStoreDownErrorMessage = if RunService:IsStudio() then "Studio Access to API Services is disabled" else "Roblox Datastores are down"

local function isDataStoreEnabled()
	if dataStoreEnabled ~= nil then
		return dataStoreEnabled
	end

	for i = 1, 3 do
		local success = pcall(function()
			DataStore = DataStoreService:GetDataStore(Settings.DatastoreName)
			DataStore:GetAsync("_test")
		end)
		if success then
			dataStoreEnabled = true
			return true
		else
			task.wait(1)
		end
	end
	dataStoreEnabled = false
	return false
end

local function createOutfit(plr: Player, name: string, privacy: string)
	if RunService:IsStudio() then return false, "Creating outfits is disabled in Studio for security reasons" end
	if not isDataStoreEnabled() then return false, dataStoreDownErrorMessage end
	local isPrivate = privacy == "private"

	local filterResult = TextService:FilterStringAsync(name, plr.UserId)
	local resultText = filterResult:GetNonChatStringForBroadcastAsync()
	if string.find(resultText, "#") then
		return false, "The name got filtered"
	end

	local existingData = DataStore:GetAsync("index") or {}
	local hasSameName = false
	local outfitsByThisUser = 0

	for _, dataPiece in existingData do
		if dataPiece.Owner ~= plr.UserId then
			continue
		end
		outfitsByThisUser += 1
		if dataPiece.Name == name then
			hasSameName = true
			break
		end
	end

	if outfitsByThisUser >= Settings.MaxOutfitsPerUser then
		return false, "You already saved the max number of outfits"
	end

	if hasSameName then
		return false, "You already saved an outfit with this name, pick a different one"
	end

	local humanoid = utils.getHumanoidFromPlayer(plr)
	local description = humanoid:GetAppliedDescription()

	local dataToSave = {
		Properties = {},
		Accessories = {},
		Name = resultText,
		Owner = plr.UserId,
		DeleteFace = plr.Character:FindFirstChild("Head"):FindFirstChild("face") == nil,
		Emotes = {},
	}

	-- Properties
	for _, propertyName in constants.humanoidDescriptionProperties do
		local value = description[propertyName]
		if typeof(value) == "Color3" then
			value = value:ToHex()
		end
		dataToSave.Properties[propertyName] = value
	end
	
	-- Accessories
	local accessories = description:GetAccessories(true)
	for _, accessoryData in accessories do
		accessoryData.AccessoryType = accessoryData.AccessoryType.Value
		accessoryData.Position = { accessoryData.Position.X, accessoryData.Position.Y, accessoryData.Position.Z }
		accessoryData.Rotation = { accessoryData.Rotation.X, accessoryData.Rotation.Y, accessoryData.Rotation.Z }
		accessoryData.Scale = { accessoryData.Scale.X, accessoryData.Scale.Y, accessoryData.Scale.Z }
	end
	dataToSave.Accessories = accessories

	-- Emotes
	local emotes = description:GetEmotes()
	local equippedEmotes = description:GetEquippedEmotes()
	for _, equippedEmote in equippedEmotes do
		local slot = equippedEmote.Slot
		local name = equippedEmote.Name
		local ids = emotes[name]
		table.insert(dataToSave.Emotes, {
			Slot = slot,
			Name = name,
			IDs = ids,
		})
	end

	local id = HttpService:GenerateGUID(false)

	DataStore:SetAsync(id, dataToSave)

	DataStore:UpdateAsync("index", function(data)
		local dataToInsert = {
			Name = resultText,
			Owner = plr.UserId,
			ID = id,
			Private = isPrivate
		}
		if not data then
			return { dataToInsert }
		end
		table.insert(data, dataToInsert)
		return data
	end)

	return true
end

local function getOutfitsPage(plr: Player, page: number, searchPhrase: string?)
	if not isDataStoreEnabled() then return end
	local outfits = DataStore:GetAsync("index") or {}
	local thisUsersOutfits = {}
	for _, outfit in outfits do	
		if (outfit.Private == false or outfit.Owner == plr.UserId) and (searchPhrase == nil or searchPhrase == "" or string.find(string.lower(outfit.Name), string.lower(searchPhrase :: string))) then
			table.insert(thisUsersOutfits, outfit)
		end
	end
	local actualOutfits = {}
	local offset = (page - 1) * constants.outfitsPerPage
	for i = 1, constants.outfitsPerPage do
		local outfit = thisUsersOutfits[offset + i]
		if not outfit then break end
		table.insert(actualOutfits, outfit)
	end

	for _, outfit in actualOutfits do
		local author = Players:GetNameFromUserIdAsync(outfit.Owner)
		outfit.OwnerID = outfit.Owner
		outfit.Owner = author
	end
	return actualOutfits, math.ceil(#thisUsersOutfits / constants.outfitsPerPage)
end

local function getOutfit(plr: Player, id: string)
	if not isDataStoreEnabled() then return end
	local outfit = DataStore:GetAsync(id)
	if not outfit then return end
	if outfit.Private and outfit.Owner ~= plr.UserId then return end
	return outfit
end

local function updateOutfitPrivacy(id: string, isPrivate: boolean)
	if not isDataStoreEnabled() then return end
	DataStore:UpdateAsync(id, function(data)
		data.Private = isPrivate
		return data
	end)
	DataStore:UpdateAsync("index", function(currentOutfits)
		local outfits = currentOutfits or {}
		for i, outfit in outfits do
			if outfit.ID == id then
				outfit.Private = isPrivate
				break
			end
		end
		return outfits
	end)
end

local function deleteOutfit(id: string)
	if not isDataStoreEnabled() then return end
	DataStore:UpdateAsync("index", function(currentOutfits)
		local outfits = currentOutfits or {}

		for i, outfit in outfits do
			if outfit.ID == id then
				table.remove(outfits, i)
				break
			end
		end

		return outfits
	end)

	DataStore:RemoveAsync(id)
end

return {
	isDataStoreEnabled = isDataStoreEnabled,
	createOutfit = createOutfit,
	getOutfitsPage = getOutfitsPage,
	getOutfit = getOutfit,
	updateOutfitPrivacy = updateOutfitPrivacy,
	deleteOutfit = deleteOutfit
}