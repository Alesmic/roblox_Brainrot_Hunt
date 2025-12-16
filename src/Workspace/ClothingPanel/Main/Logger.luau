local Logger = {}

local DEBUG = false

local DEFAULT_PRODUCT_INFO = {
	name = "No product info supplied",
	id = "product",
}

local ProductInfo

if script.Parent.Parent:FindFirstChild("ProductInfo") then
	local success, result = pcall(require, script.Parent:FindFirstChild("ProductInfo"))
	if success then
		ProductInfo = result
	else
		ProductInfo = DEFAULT_PRODUCT_INFO
	end
end

local warnEvent = Instance.new("BindableEvent")
local errorEvent = Instance.new("BindableEvent")

warnEvent.Parent = script
errorEvent.Parent = script

Logger.warned = warnEvent.Event
Logger.errored = errorEvent.Event
Logger.lastWarning = nil
Logger.lastError = nil

function Logger.info(...: any)
	print(`[[ {ProductInfo.name} ]]:`, ...)
end

function Logger.warn(...: any)
	warn(`[[ {ProductInfo.name} ]]:`, ...)
	local packed = table.concat(table.pack(...), " ")
	warnEvent:Fire(packed)
	Logger.lastWarning = packed
end

function Logger.error(...: any)
	local packed = table.concat(table.pack(...), " ")
	errorEvent:Fire(packed)
	Logger.lastError = packed
	error(`[[ {ProductInfo.name} ]]: {packed}`, 0)
end

function Logger.assert(condition: any, ...: any)
	if not condition then
		Logger.error(...)
	end
	return condition
end

function Logger.debugInfo(...: any)
	if DEBUG then
		Logger.info(...)
	end
end

function Logger.debugWarn(...: any)
	if DEBUG then
		Logger.warn(...)
	end
end

return Logger