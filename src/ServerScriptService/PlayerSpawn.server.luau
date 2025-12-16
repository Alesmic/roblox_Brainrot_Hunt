local Players = game:GetService("Players")

-- Define your target coordinates
local SPAWN_POSITION = Vector3.new(-783.183, 36.304, 220.17)

-- When a player joins the game
Players.PlayerAdded:Connect(function(player)

	-- When the player's character finishes loading
	player.CharacterAdded:Connect(function(character)

		-- Wait a moment to ensure the character's physics model is fully loaded
		task.wait()

		-- Use PivotTo to move the character to the specified coordinates
		-- PivotTo is the safest and most modern method to move models (like player characters)
		character:PivotTo(CFrame.new(SPAWN_POSITION))
	end)
end)