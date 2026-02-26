local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local CardData = require(ReplicatedStorage:WaitForChild("CardData"))

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local InitInventoryEvent = Remotes:WaitForChild("InitInventory")
local PlaceCardEvent = Remotes:WaitForChild("PlaceCard")
local RemoveCardEvent = Remotes:WaitForChild("RemoveCard")
local UpdateMoneyEvent = Remotes:WaitForChild("UpdateMoney")

-- playerId -> { cardId = count }
local inventories = {}
-- playerId -> { slotName = cardId }
local placedCards = {}

-- Shared money reference (CheckoutManager also writes to this)
-- Use a module-level table that CheckoutManager can access via BindableFunction
local playerMoney = {}

-- Create BindableFunction so CheckoutManager can read/write money
local getMoneyFunc = Instance.new("BindableFunction")
getMoneyFunc.Name = "GetPlayerMoney"
getMoneyFunc.OnInvoke = function(userId)
	return playerMoney[userId] or 0
end
getMoneyFunc.Parent = ReplicatedStorage

local setMoneyEvent = Instance.new("BindableEvent")
setMoneyEvent.Name = "SetPlayerMoney"
setMoneyEvent.Parent = ReplicatedStorage
setMoneyEvent.Event:Connect(function(userId, amount)
	playerMoney[userId] = amount
end)

local BuyCardEvent = Remotes:WaitForChild("BuyCard")
local BuyCardResultEvent = Remotes:WaitForChild("BuyCardResult")
local GetMoneyRemote = Remotes:WaitForChild("GetMoney")

-- Client requests current balance (solves race condition on startup)
GetMoneyRemote.OnServerInvoke = function(player)
	return playerMoney[player.UserId] or 0
end

local function sendInventory(player)
	local inv = inventories[player.UserId]
	if not inv then return end

	local cardIds = {}
	for id, count in inv do
		for i = 1, count do
			table.insert(cardIds, id)
		end
	end
	InitInventoryEvent:FireClient(player, cardIds)
end

local STARTING_MONEY = 50

local function giveInitialCards(player)
	inventories[player.UserId] = {}
	placedCards[player.UserId] = {}
	playerMoney[player.UserId] = STARTING_MONEY

	sendInventory(player)
	UpdateMoneyEvent:FireClient(player, STARTING_MONEY)
	print("[InventoryManager] Gave $" .. STARTING_MONEY .. " to " .. player.Name)
end

PlaceCardEvent.OnServerEvent:Connect(function(player, slotName, cardId, _shelfPrice)
	local inv = inventories[player.UserId]
	if not inv or not inv[cardId] or inv[cardId] <= 0 then
		warn("[InventoryManager] Player doesn't have card: " .. tostring(cardId))
		return
	end

	inv[cardId] = inv[cardId] - 1
	if inv[cardId] <= 0 then
		inv[cardId] = nil
	end

	placedCards[player.UserId][slotName] = cardId
	sendInventory(player)
end)

RemoveCardEvent.OnServerEvent:Connect(function(player, slotName)
	local placed = placedCards[player.UserId]
	if not placed or not placed[slotName] then return end

	local cardId = placed[slotName]
	local inv = inventories[player.UserId]
	if inv then
		inv[cardId] = (inv[cardId] or 0) + 1
	end

	placed[slotName] = nil
	sendInventory(player)
end)

-- Add cards to inventory (called by DeliveryManager when delivery is collected)
local addCardEvent = Instance.new("BindableEvent")
addCardEvent.Name = "AddCardToInventory"
addCardEvent.Parent = ReplicatedStorage
addCardEvent.Event:Connect(function(userId, cardIds)
	local inv = inventories[userId]
	if not inv then return end
	for _, cardId in cardIds do
		inv[cardId] = (inv[cardId] or 0) + 1
	end
	local player = Players:GetPlayerByUserId(userId)
	if player then
		sendInventory(player)
	end
	print("[InventoryManager] Added " .. #cardIds .. " cards to userId " .. userId)
end)

-- Queue delivery event (InventoryManager creates it, DeliveryManager listens)
local queueDeliveryEvent = Instance.new("BindableEvent")
queueDeliveryEvent.Name = "QueueDeliveryItem"
queueDeliveryEvent.Parent = ReplicatedStorage

-- Buy card from computer shop (queues delivery instead of direct add)
BuyCardEvent.OnServerEvent:Connect(function(player, cardId)
	local cardInfo = CardData.GetCardById(cardId)
	if not cardInfo then
		BuyCardResultEvent:FireClient(player, false, "Invalid card!")
		return
	end

	local money = playerMoney[player.UserId] or 0
	local cost = cardInfo.cost

	if money < cost then
		BuyCardResultEvent:FireClient(player, false, "Not enough money! Need $" .. cost)
		return
	end

	-- Deduct money
	playerMoney[player.UserId] = money - cost
	UpdateMoneyEvent:FireClient(player, playerMoney[player.UserId])

	-- Queue delivery instead of direct inventory add
	queueDeliveryEvent:Fire(player.UserId, cardId)

	BuyCardResultEvent:FireClient(player, true, cardInfo.name .. " ordered!")
	print("[InventoryManager] " .. player.Name .. " ordered " .. cardInfo.name .. " for $" .. cost)
end)

Players.PlayerRemoving:Connect(function(player)
	inventories[player.UserId] = nil
	placedCards[player.UserId] = nil
	playerMoney[player.UserId] = nil
end)

Players.PlayerAdded:Connect(giveInitialCards)

for _, player in Players:GetPlayers() do
	task.spawn(giveInitialCards, player)
end
