-- HumanoidDescription properties and the icon they should display in the "Remove" menu
local properties = {
	animation = {
		"ClimbAnimation",
		"FallAnimation",
		"IdleAnimation",
		"JumpAnimation",
		"MoodAnimation",
		"RunAnimation",
		"SwimAnimation",
		"WalkAnimation"
	},
	shirt = {
		"GraphicTShirt",
		"Shirt"
	},
	pants = {
		"Pants"
	},
	face = {
		"Face"
	},
	parts = {
		"Head",
		"LeftArm",
		"LeftLeg",
		"RightArm",
		"RightLeg",
		"Torso"
	}
}

local icons = {
	outfit = "rbxassetid://105553235759095",
	public = "rbxassetid://134759592848636",
	private = "rbxassetid://131106213123071",
}

return {
	properties = properties,
	icons = icons,
	colours = require(script.Colours),
}