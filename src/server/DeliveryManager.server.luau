print("[DeliveryManager] Starting...")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local SoundService = game:GetService("SoundService")
local Players = game:GetService("Players")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local DeliveryUpdateEvent = Remotes:WaitForChild("DeliveryUpdate")
local DeliveryArrivedEvent = Remotes:WaitForChild("DeliveryArrived")

-- Dynamic delivery time: 5s base + 2s per card, max 20s
local BASE_DELIVERY_TIME = 5
local PER_CARD_TIME = 2
local MAX_DELIVERY_TIME = 20
local BOX_POSITION = Vector3.new(8, 1, 19)

local function getDeliveryTime(itemCount)
	return math.min(BASE_DELIVERY_TIME + PER_CARD_TIME * itemCount, MAX_DELIVERY_TIME)
end

-- =====================
-- DELIVERY BOX TEMPLATE
-- =====================
local boxModel = workspace:WaitForChild("DeliveryBox", 10)
if not boxModel then
	warn("[DeliveryManager] DeliveryBox not found!")
	return
end

local boxTemplate = boxModel:Clone()
boxTemplate.Name = "DeliveryBoxTemplate"
boxTemplate.Parent = ServerStorage
boxModel:Destroy()
print("[DeliveryManager] Template stored")

-- =====================
-- QUEUE EVENT (InventoryManager creates this, we listen)
-- =====================
local queueEvent = ReplicatedStorage:WaitForChild("QueueDeliveryItem", 15)
if not queueEvent then
	warn("[DeliveryManager] QueueDeliveryItem not found!")
	return
end

-- =====================
-- DELIVERY STATE
-- =====================
-- userId -> { items: {cardId...}, startTime: number, delivered: bool, box: Part? }
local deliveries = {}

local function startDeliveryTimer(userId)
	task.spawn(function()
		local delivery = deliveries[userId]
		if not delivery then return end

		local deliveryTime = getDeliveryTime(#delivery.items)
		delivery.totalTime = deliveryTime

		task.wait(deliveryTime)

		delivery = deliveries[userId]
		if not delivery or delivery.delivered then return end

		delivery.delivered = true

		-- Spawn box
		local box = boxTemplate:Clone()
		box.Position = BOX_POSITION
		box.Anchored = true
		box.Name = "Delivery_" .. userId
		box.Parent = workspace
		delivery.box = box

		-- Add ProximityPrompt
		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = "Collect Delivery"
		prompt.ObjectText = "Delivery Box"
		prompt.HoldDuration = 0.5
		prompt.MaxActivationDistance = 8
		prompt.RequiresLineOfSight = false
		prompt.Parent = box

		prompt.PromptButtonHoldBegan:Connect(function(player)
			if player.UserId ~= userId then return end
			local openingBox = SoundService:FindFirstChild("OpeningBox")
			if openingBox then openingBox:Play() end
		end)

		prompt.PromptButtonHoldEnded:Connect(function(player)
			if player.UserId ~= userId then return end
			local openingBox = SoundService:FindFirstChild("OpeningBox")
			if openingBox then openingBox:Stop() end
		end)

		prompt.Triggered:Connect(function(player)
			if player.UserId ~= userId then return end

			local openingBox = SoundService:FindFirstChild("OpeningBox")
			if openingBox then openingBox:Stop() end

			local addCard = ReplicatedStorage:FindFirstChild("AddCardToInventory")
			if addCard and delivery.items then
				addCard:Fire(userId, delivery.items)
			end

			box:Destroy()
			deliveries[userId] = nil
			print("[DeliveryManager] " .. player.Name .. " collected delivery (" .. #delivery.items .. " items)")
		end)

		-- Notify client (client plays Honk sound)
		local player = Players:GetPlayerByUserId(userId)
		if player then
			DeliveryArrivedEvent:FireClient(player)
		end

		print("[DeliveryManager] Delivery arrived for userId " .. userId .. " (" .. #delivery.items .. " items)")
	end)
end

-- =====================
-- QUEUE ITEM
-- =====================
queueEvent.Event:Connect(function(userId, cardId)
	local delivery = deliveries[userId]

	if not delivery or delivery.delivered then
		-- Start new delivery
		local deliveryTime = getDeliveryTime(1)
		deliveries[userId] = {
			items = { cardId },
			startTime = tick(),
			delivered = false,
			box = nil,
			totalTime = deliveryTime,
		}
		startDeliveryTimer(userId)

		local player = Players:GetPlayerByUserId(userId)
		if player then
			DeliveryUpdateEvent:FireClient(player, {
				totalItems = 1,
				totalTime = deliveryTime,
				remainingTime = deliveryTime,
			})
		end
	else
		-- Add to existing pending delivery
		table.insert(delivery.items, cardId)

		-- Recalculate delivery time based on new item count
		local newDeliveryTime = getDeliveryTime(#delivery.items)
		delivery.totalTime = newDeliveryTime

		local elapsed = tick() - delivery.startTime
		local remaining = math.max(0, newDeliveryTime - elapsed)

		local player = Players:GetPlayerByUserId(userId)
		if player then
			DeliveryUpdateEvent:FireClient(player, {
				totalItems = #delivery.items,
				totalTime = newDeliveryTime,
				remainingTime = remaining,
			})
		end
	end

	print("[DeliveryManager] Queued card " .. tostring(cardId) .. " for userId " .. userId)
end)

-- =====================
-- CLEANUP
-- =====================
Players.PlayerRemoving:Connect(function(player)
	local delivery = deliveries[player.UserId]
	if delivery and delivery.box then
		delivery.box:Destroy()
	end
	deliveries[player.UserId] = nil
end)

print("[DeliveryManager] Ready!")
