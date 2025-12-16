--!strict

--[[
	Example usage:

	local UpdateChecker = require(...)
	local ProductInfo = require(...)

	local updateInformation = UpdateChecker.getUpdateInformation(ProductInfo.id, ProductInfo.version)
	if updateInformation then
		if updateInformation.update then
			for _, update in updateInformation.update.updates do
				local version = update.version
				local releaseDate = update.releaseDate
				local changelog = table.concat(update.changelog, "\n")
			end
			local additionalUpdates = updateInformation.update.additionalUpdates
			local shouldShowFullScreen = updateInformation.update.isImportant
		end
		if updateInformation.announcement then
			local title = updateInformation.announcement.title
			local description = updateInformation.announcement.description
			local shouldShowFullScreen = updateInformation.announcement.isImportant
		end
	end

	If an update can't be checked (HttpService not enabled or api server down) then the code will not error
	and will pretend as if there's no update
]]

local HttpService = game:GetService("HttpService")
local API_SERVER = "https://api.gybasoft.dev"
local API_VERSION = 1
local DEBUG = false

local UpdateChecker = {}
local filterStrings = require("./filterStrings")

export type Version = {
	major: number,
	minor: number,
	patch: number,
	branch: string,
	year: number,
	month: number,
	day: number,
	revision: number?,
	isImportant: boolean?,
}

export type Changelog = { string }

export type VersionWithChangelog = Version & {
	changelog: Changelog,
}

export type ChangelogInformation = {
	isImportant: boolean,
	updates: {
		{
			version: string,
			releaseDate: string,
			changelog: { string },
		}
	},
	additionalUpdates: number,
}

export type AnnouncementInformation = {
	title: string,
	content: string,
	isImportant: boolean,
}

export type UpdateInformation = {
	update: ChangelogInformation?,
	announcement: AnnouncementInformation?,
}

type CacheEntry = {
	generating: boolean,
	done: BindableEvent?,
	data: any?,
}

local cache: { [string]: CacheEntry } = {}

local function cacheEvent(cacheId: string, func: () -> any)
	local cached = cache[cacheId]
	if cached and cached.generating == true then
		if cached.done then
			cached.done.Event:Wait()
		end
		return cached.data
	elseif cached then
		return cached.data
	else
		local thisCache: CacheEntry = {
			generating = true,
			done = Instance.new("BindableEvent"),
		}
		cache[cacheId] = thisCache
		local result = func()
		thisCache.data = result
		thisCache.generating = false
		if thisCache.done then
			thisCache.done:Fire()
			thisCache.done:Destroy()
		end
		thisCache.done = nil
		return result
	end
end

local function fetchUpdates(product: string, version: Version): UpdateInformation?
	if not UpdateChecker.shouldCheckForUpdate() then
		return nil
	end
	return cacheEvent(`v-{product}`, function(): UpdateInformation?
		local url = if DEBUG
			then `{API_SERVER}/v{API_VERSION}/product/random-changelog?v={version.major}.{version.minor}.{version.patch}`
			else `{API_SERVER}/v{API_VERSION}/product/changelog/{product}/{version.branch}?v={version.major}.{version.minor}.{version.patch}`
		local requestOptions: { [string]: any } = {
			Method = "GET",
			Url = url,
		}
		local requestSuccess, response = pcall(HttpService.RequestAsync, HttpService, requestOptions)

		if not requestSuccess then
			return nil
		end
		if response.StatusCode ~= 200 then
			return nil
		end
		if typeof(response.Body) ~= "string" then
			return nil
		end
		local decodeSuccess, updateInformation = pcall(HttpService.JSONDecode, HttpService, response.Body)
		if not decodeSuccess then
			return nil
		end

		local updates = {}
		for _, update in updateInformation.updates do
			local major, minor, patch =
				tonumber(update.major) or 0, tonumber(update.minor) or 0, tonumber(update.patch) or 0
			local year, month, day = tonumber(update.year) or 0, tonumber(update.month) or 0, tonumber(update.day) or 0

			local thisVersion: Version = {
				major = major,
				minor = minor,
				patch = patch,
				year = year,
				month = month,
				day = day,
				branch = update.branch,
				revision = if update.revision then tonumber(update.revision) or 0 else nil,
			}

			table.insert(updates, {
				version = UpdateChecker.formatVersion(thisVersion),
				releaseDate = UpdateChecker.formatDate(thisVersion),
				changelog = filterStrings(update.changelog),
			})
		end

		local updateInfo: ChangelogInformation? = nil

		if #updates > 0 or updateInformation.additionalUpdates > 0 then
			updateInfo = {
				isImportant = not not updateInformation.isImportant,
				updates = updates,
				additionalUpdates = tonumber(updateInformation.additionalUpdates) or 0,
			}
		end

		local announcementInfo: AnnouncementInformation? = nil

		if updateInformation.announcementContent then
			local strings =
				filterStrings({ updateInformation.announcementTitle, updateInformation.announcementContent })
			announcementInfo = {
				title = strings[1],
				content = strings[2],
				isImportant = not not updateInformation.isAnnouncementImportant,
			}
		end

		return {
			update = updateInfo,
			announcement = announcementInfo,
		}
	end)
end

function UpdateChecker.getUpdateInformation(product: string, version: Version): UpdateInformation?
	local updates = fetchUpdates(product, version)
	if not updates then
		return nil
	end
	return updates
end

function UpdateChecker.formatVersion(Version: Version): string
	local branchLabel
	if Version.branch == "release" then
		branchLabel = ""
	elseif string.len(Version.branch) <= 3 then
		branchLabel = ` {string.upper(Version.branch)} {Version.revision}`
	else
		branchLabel =
			` {string.upper(string.sub(Version.branch, 1, 1))}{string.lower(string.sub(Version.branch, 2))} {Version.revision}`
	end
	if branchLabel ~= "" then
		branchLabel = filterStrings({ branchLabel })[1]
	end
	return `{Version.major}.{Version.minor}.{Version.patch}{branchLabel}`
end

local months = {
	"January",
	"February",
	"March",
	"April",
	"May",
	"June",
	"July",
	"August",
	"September",
	"October",
	"November",
	"December",
}

function UpdateChecker.formatDate(Version: Version): string
	return `{months[Version.month]} {Version.day}, {Version.year}`
end

function UpdateChecker.shouldCheckForUpdate(): boolean
	return HttpService.HttpEnabled
end

return UpdateChecker
