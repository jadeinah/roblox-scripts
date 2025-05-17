local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local webhookForwardURL = "http://192.168.100.2:5000/send"

-- Wait until Adopt Me client data is loaded
local function wait_for_data()
	local clientData = require(ReplicatedStorage:WaitForChild("ClientModules").Core.ClientData)
	print("⏳ Waiting for client data...")

	repeat
		task.wait(1)
	until clientData.get_data() and clientData.get_data()[Players.LocalPlayer.Name] 
	       and clientData.get("money") ~= nil

	print("✅ Client data is ready!")
	return clientData
end

-- Get potions, bucks, and pet kinds
local function check_stats(clientData)
	local data = clientData.get_data()
	local playerData = data[Players.LocalPlayer.Name]

	local bucks = tonumber(clientData.get("money")) or 0
	local potions = 0

	-- Count age-up potions
	for _, v in pairs(playerData.inventory.food or {}) do
		if v.kind == "pet_age_potion" then
			potions += 1
		end
	end

	-- Count pet kinds
	local petCounts = {}
	for _, pet in pairs(playerData.inventory.pets or {}) do
		local kind = pet.kind
		petCounts[kind] = (petCounts[kind] or 0) + 1
	end

	print("🍼 Potions:", potions)
	print("💵 Bucks:", bucks)
	print("🐾 Pets:", petCounts)

	-- Return as JSON string
	local petJSON = HttpService:JSONEncode(petCounts)
	return potions, bucks, petJSON
end

-- Main loop
print("📡 Adopt Me Stats Uploader Starting...")

local clientData = wait_for_data()

while true do
	local potions, bucks, petJSON = check_stats(clientData)
	local player = Players.LocalPlayer.Name

	-- URL encode the JSON pet data
	local encodedPets = HttpService:UrlEncode(petJSON)

	local url = string.format(
		"%s?player=%s&potions=%d&bucks=%d&pets=%s",
		webhookForwardURL,
		player,
		potions,
		bucks,
		encodedPets
	)

	print("🌐 Sending:", url)

	local success, result = pcall(function()
		return game:HttpGet(url)
	end)

	if success then
		print("✅ Stats sent successfully!")
	else
		warn("❌ Failed to send stats:", result)
	end

	task.wait(3600) -- send every hour
end
