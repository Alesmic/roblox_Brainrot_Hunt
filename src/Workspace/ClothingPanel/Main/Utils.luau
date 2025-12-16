local constants = require(script.Parent.Constants)

local function isRigidAccessory(t: Enum.AssetType)
	return table.find(constants.rigidAccessoryTypes, t) ~= nil
end

local function isLayeredAccessory(t: Enum.AssetType)
	return table.find(constants.layeredAccessoryTypes, t) ~= nil
end

local function isBodyPart(t: Enum.AssetType)
	return table.find(constants.bodyPartTypes, t) ~= nil
end

local function isAnimation(t: Enum.AssetType)
	return table.find(constants.animationTypes, t) ~= nil
end

local function enumIdToEnum(enum: Enum, id: number)
	local values = enum:GetEnumItems()
	for _, value in values do
		if value.Value == id then
			return value
		end
	end
end

local function findAccessoryOfType(accessoryTable, accessoryType)
	for _, entry in accessoryTable do
		if entry.AccessoryType == accessoryType then
			return entry
		end
	end
end

local function getHumanoidFromPlayer(plr: Player)
	local character = plr.Character or plr.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid")
	return humanoid :: Humanoid
end

return {
	isRigidAccessory = isRigidAccessory,
	isLayeredAccessory = isLayeredAccessory,
	isBodyPart = isBodyPart,
	isAnimation = isAnimation,
	findAccessoryOfType = findAccessoryOfType,
	getHumanoidFromPlayer = getHumanoidFromPlayer,
	enumIdToEnum = enumIdToEnum
}