return {
	
	-- How many outfits a single player can save
	MaxOutfitsPerUser = 5,
	
	-- If not empty, only players in those teams can use the panels
	-- Example: { "Participants", "Staff" },
	AllowedTeams = {
		
	},
	
	-- If a player is further away from a panel than the number below
	-- (in studs), they won't be able to use that panel
	MaxDistanceFromPanel = 40,
	
	-- Which datastore outfits get saved to
	-- Changing this setting will remove all outfits
	-- You can change the setting back to bring the outfits back
	DatastoreName = "ClothingPanel",
	
	-- When set to 'true', the system will check for possible updates
	-- and important announcements. Set to 'false' to disable.
	-- It is recommended to keep this setting set to 'true'
	CheckForUpdates = true,
	
}