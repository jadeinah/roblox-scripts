local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local webhookForwardURL = "http://192.168.100.2:5000/send"

-- Wait for Adopt Me client data to load
local function wait_for_data()
	local clientData = require(ReplicatedStorage:WaitForChild("ClientModules").Core.ClientData)
	print("⏳ Waiting for client data...")

	repeat task.wait(1)
	until clientData.get_data() and clientData.get_data()[Players.LocalPlayer.Name] 
	       and clientData.get("money") ~= nil

	print("✅ Client data is ready!")
	return clientData
end

-- Collect potions, bucks, and pets (max 20 kinds)
local function collect_stats(clientData)
	local playerData = clientData.get_data()[Players.LocalPlayer.Name]
	local bucks = tonumber(clientData.get("money")) or 0
	local potions = 0
	local pets = {}

	for _, item in pairs(playerData.inventory.food or {}) do
		if item.kind == "pet_age_potion" then
			potions += 1
		end
	end

	local kinds_added = 0
	for _, pet in pairs(playerData.inventory.pets or {}) do
		local kind = pet.kind
		if not pets[kind] then
			if kinds_added >= 20 then
				pets["..."] = "... and more"
				break
			end
			kinds_added += 1
		end
		pets[kind] = (pets[kind] or 0) + 1
	end

	return potions, bucks, pets
end

-- Main execution
print("📡 Adopt Me Stats Uploader Started")

local clientData = wait_for_data()

while true do
	local player = Players.LocalPlayer.Name
	local potions, bucks, petsTable = collect_stats(clientData)

	local petJSON = HttpService:JSONEncode(petsTable)
	local encodedPets = HttpService:UrlEncode(petJSON)

	local url = string.format(
		"%s?player=%s&potions=%d&bucks=%d&pets=%s",
		webhookForwardURL,
		HttpService:UrlEncode(player),
		potions,
		bucks,
		encodedPets
	)

	print("🌐 Sending stats:", url)

	local success, response = pcall(function()
		return game:HttpGet(url)
	end)

	if success then
		print("✅ Stats sent successfully!")
	else
		warn("❌ Failed to send stats:", response)
	end

	task.wait(3600) -- send every hour
end
