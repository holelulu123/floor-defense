-- Studio-only: mirrors the server Output to the developer's local log server so test runs can be read
-- without looking at the Studio window. Does nothing in a published game or when HttpService is off.
local HttpService = game:GetService("HttpService")
local LogService = game:GetService("LogService")
local RunService = game:GetService("RunService")

if not RunService:IsStudio() then
	return
end

local BASE = "http://127.0.0.1:8799/__log/"
local queue: { string } = {}

local function flush()
	if #queue == 0 then
		return
	end
	local batch = table.concat(queue, "\n")
	table.clear(queue)
	pcall(function()
		HttpService:GetAsync(BASE .. HttpService:UrlEncode("studio " .. batch), true)
	end)
end

LogService.MessageOut:Connect(function(message, messageType)
	table.insert(queue, ("[%s] %s"):format(messageType.Name, message))
	if #queue >= 20 then
		flush()
	end
end)

task.spawn(function()
	while true do
		task.wait(1)
		flush()
	end
end)
print("DevLog: mirroring Output to the local log server")
