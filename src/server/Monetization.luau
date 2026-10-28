-- Game pass checks and developer product receipt handling.

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local PlayerData = require(script.Parent.PlayerData)

local Monetization = {}

-- What each developer product grants. Keyed by product ID.
local productHandlers: { [number]: (Player) -> () } = {
	[Config.Products.Gems500] = function(player)
		PlayerData.addGems(player, 500)
	end,
}

function Monetization.hasPass(player: Player, passId: number): boolean
	local ok, owns = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, player.UserId, passId)
	return ok and owns
end

-- Roblox retries this until it returns PurchaseGranted, so it must be idempotent.
local function processReceipt(info)
	local player = Players:GetPlayerByUserId(info.PlayerId)
	local data = player and PlayerData.get(player)
	if not data then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	if data.ProcessedReceipts[info.PurchaseId] then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	local handler = productHandlers[info.ProductId]
	if not handler then
		warn(`No handler for developer product {info.ProductId}`)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	handler(player)
	data.ProcessedReceipts[info.PurchaseId] = true

	if not PlayerData.save(player) then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

function Monetization.init()
	MarketplaceService.ProcessReceipt = processReceipt

	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
		if purchased then
			print(`{player.Name} bought game pass {passId}`)
		end
	end)
end

return Monetization
