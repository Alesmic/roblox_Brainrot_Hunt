local outfitsPerPage = 10

-- HumanoidDescription skin colour properties
local colourProperties = {
	"HeadColor",
	"LeftArmColor",
	"LeftLegColor",
	"RightArmColor",
	"RightLegColor",
	"TorsoColor"
}

local assetTypeToAccessoryType = {
	[Enum.AssetType.Hat] = Enum.AccessoryType.Hat,
	[Enum.AssetType.HairAccessory] = Enum.AccessoryType.Hair,
	[Enum.AssetType.FaceAccessory] = Enum.AccessoryType.Face,
	[Enum.AssetType.NeckAccessory] = Enum.AccessoryType.Neck,
	[Enum.AssetType.ShoulderAccessory] = Enum.AccessoryType.Shoulder,
	[Enum.AssetType.FrontAccessory] = Enum.AccessoryType.Front,
	[Enum.AssetType.BackAccessory] = Enum.AccessoryType.Back,
	[Enum.AssetType.WaistAccessory] = Enum.AccessoryType.Waist,
	[Enum.AssetType.TShirtAccessory] = Enum.AccessoryType.TShirt,
	[Enum.AssetType.ShirtAccessory] = Enum.AccessoryType.Shirt,
	[Enum.AssetType.PantsAccessory] = Enum.AccessoryType.Pants,
	[Enum.AssetType.JacketAccessory] = Enum.AccessoryType.Jacket,
	[Enum.AssetType.SweaterAccessory] = Enum.AccessoryType.Sweater,
	[Enum.AssetType.ShortsAccessory] = Enum.AccessoryType.Shorts,
	[Enum.AssetType.LeftShoeAccessory] = Enum.AccessoryType.LeftShoe,
	[Enum.AssetType.RightShoeAccessory] = Enum.AccessoryType.RightShoe,
	[Enum.AssetType.DressSkirtAccessory] = Enum.AccessoryType.DressSkirt,
	[Enum.AssetType.EyebrowAccessory] = Enum.AccessoryType.Eyebrow,
	[Enum.AssetType.EyelashAccessory] = Enum.AccessoryType.Eyelash
}

-- accessories (hats, shoulder, back, etc.)
local rigidAccessoryTypes = {
	Enum.AssetType.HairAccessory,
	Enum.AssetType.FaceAccessory,
	Enum.AssetType.NeckAccessory,
	Enum.AssetType.ShoulderAccessory,
	Enum.AssetType.FrontAccessory,
	Enum.AssetType.BackAccessory,
	Enum.AssetType.WaistAccessory,
	Enum.AssetType.Hat
}

-- 3d clothing (jackets, shoes, sweaters, etc.)
local layeredAccessoryTypes = {
	Enum.AssetType.TShirtAccessory,
	Enum.AssetType.ShirtAccessory,
	Enum.AssetType.PantsAccessory,
	Enum.AssetType.JacketAccessory,
	Enum.AssetType.SweaterAccessory,
	Enum.AssetType.ShortsAccessory,
	Enum.AssetType.LeftShoeAccessory,
	Enum.AssetType.RightShoeAccessory,
	Enum.AssetType.DressSkirtAccessory,
	Enum.AssetType.EyebrowAccessory,
	Enum.AssetType.EyelashAccessory,
	Enum.AssetType.EarAccessory,
	Enum.AssetType.EyeAccessory
}

-- ugc creators are using these types to bypass ugc limits
-- (shoes / tops)
local layeredAccessoryTypesThatShouldntBeReplaced = {
	Enum.AccessoryType.Pants,
	Enum.AccessoryType.DressSkirt
}

local bodyPartTypes = {
	Enum.AssetType.Torso,
	Enum.AssetType.RightArm,
	Enum.AssetType.LeftArm,
	Enum.AssetType.LeftLeg,
	Enum.AssetType.RightLeg,
	Enum.AssetType.Head,
	Enum.AssetType.DynamicHead
}

local animationTypes = {
	Enum.AssetType.ClimbAnimation,
	Enum.AssetType.DeathAnimation,
	Enum.AssetType.FallAnimation,
	Enum.AssetType.IdleAnimation,
	Enum.AssetType.JumpAnimation,
	Enum.AssetType.RunAnimation,
	Enum.AssetType.SwimAnimation,
	Enum.AssetType.WalkAnimation,
	Enum.AssetType.PoseAnimation,
	Enum.AssetType.MoodAnimation
}

-- copied from the 3d clothing devforum announcement
local defaultLayeredClothingOrder = {
	[Enum.AccessoryType.LeftShoe] = 3,
	[Enum.AccessoryType.RightShoe] = 3,
	[Enum.AccessoryType.Pants] = 4,
	[Enum.AccessoryType.Shorts] = 5,
	[Enum.AccessoryType.DressSkirt] = 6,
	[Enum.AccessoryType.TShirt] = 7,
	[Enum.AccessoryType.Shirt] = 8,
	[Enum.AccessoryType.Sweater] = 9,
	[Enum.AccessoryType.Jacket] = 10,
	[Enum.AccessoryType.Hair] = 11,
}

-- all properties of HumanoidDescription that need to be saved for outfits
local humanoidDescriptionProperties = {
	"ClimbAnimation",
	"FallAnimation",
	"IdleAnimation",
	"JumpAnimation",
	"MoodAnimation",
	"RunAnimation",
	"SwimAnimation",
	"WalkAnimation",
	"HeadColor",
	"LeftArmColor",
	"LeftLegColor",
	"RightArmColor",
	"RightLegColor",
	"TorsoColor",
	"Face",
	"Head",
	"LeftArm",
	"RightLeg",
	"RightArm",
	"LeftLeg",
	"Torso",
	"GraphicTShirt",
	"Pants",
	"Shirt",
	"BodyTypeScale",
	"DepthScale",
	"HeadScale",
	"HeightScale",
	"ProportionScale",
	"WidthScale"
}

local assetProperties = {
	"ClimbAnimation",
	"FallAnimation",
	"IdleAnimation",
	"JumpAnimation",
	"MoodAnimation",
	"RunAnimation",
	"SwimAnimation",
	"WalkAnimation",
	"GraphicTShirt",
	"Shirt",
	"Pants",
	"Face",
	"Head",
	"LeftArm",
	"LeftLeg",
	"RightArm",
	"RightLeg",
	"Torso",
}

local assetTypesThatAreNotCatalogRelated = {
	Enum.AssetType.Image,
	Enum.AssetType.Audio,
	Enum.AssetType.Mesh,
	Enum.AssetType.Lua,
	Enum.AssetType.Place,
	Enum.AssetType.Model,
	Enum.AssetType.Decal,
	Enum.AssetType.Gear,
	Enum.AssetType.Badge,
	Enum.AssetType.Package,
	Enum.AssetType.GamePass,
	Enum.AssetType.Plugin,
	Enum.AssetType.MeshPart,
	Enum.AssetType.Video,
	Enum.AssetType.FontFamily,
}

return {
	colourProperties = colourProperties,
	assetTypeToAccessoryType = assetTypeToAccessoryType,
	rigidAccessoryTypes = rigidAccessoryTypes,
	layeredAccessoryTypes = layeredAccessoryTypes,
	bodyPartTypes = bodyPartTypes,
	defaultLayeredClothingOrder = defaultLayeredClothingOrder,
	humanoidDescriptionProperties = humanoidDescriptionProperties,
	animationTypes = animationTypes,
	layeredAccessoryTypesThatShouldntBeReplaced = layeredAccessoryTypesThatShouldntBeReplaced,
	assetProperties = assetProperties,
	assetTypesThatAreNotCatalogRelated = assetTypesThatAreNotCatalogRelated,
	outfitsPerPage = outfitsPerPage,
}