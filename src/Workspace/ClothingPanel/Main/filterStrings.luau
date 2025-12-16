--!strict

local Players = game:GetService("Players")
local TextService = game:GetService("TextService")

local L = require("./Logger")

return function(stringsToFilter: { string }, sourcePlayer: Player?): { string }
	if not sourcePlayer then
		if #Players:GetPlayers() == 0 then
			Players.PlayerAdded:Wait()
		end
		sourcePlayer = Players:GetPlayers()[math.random(1, #Players:GetPlayers())]
	end
	if not sourcePlayer then
		L.error("There are no players in the server")
		return { "[ FILTER ERROR ]" }
	end
	local outputStrings = {}
	for _, stringToFilter in stringsToFilter do
		local success, filter =
			pcall(TextService.FilterStringAsync, TextService, stringToFilter, sourcePlayer.UserId, nil)
		if not success then
			L.warn("An error occured during text filtering:", filter)
			table.insert(outputStrings, "[ FILTER ERROR ]")
			continue
		end
		local output = filter:GetNonChatStringForBroadcastAsync()
		table.insert(outputStrings, output)
	end
	return outputStrings
end
