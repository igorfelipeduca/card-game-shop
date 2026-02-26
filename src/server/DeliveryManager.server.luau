print("[DeliveryManager] Starting...")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local SoundService = game:GetService("SoundService")
local Players = game:GetService("Players")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local DeliveryUpdateEvent = Remotes:WaitForChild("DeliveryUpdate")
local DeliveryArrivedEvent = Remotes:WaitForChild("DeliveryArrived")

local DELIVERY_TIME = 15
local BOX_POSITION = Vector3.new(8, 1, 19)

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
		task.wait(DELIVERY_TIME)

		local delivery = deliveries[userId]
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
		deliveries[userId] = {
			items = { cardId },
			startTime = tick(),
			delivered = false,
			box = nil,
		}
		startDeliveryTimer(userId)

		local player = Players:GetPlayerByUserId(userId)
		if player then
			DeliveryUpdateEvent:FireClient(player, {
				totalItems = 1,
				totalTime = DELIVERY_TIME,
				remainingTime = DELIVERY_TIME,
			})
		end
	else
		-- Add to existing pending delivery
		table.insert(delivery.items, cardId)

		local elapsed = tick() - delivery.startTime
		local remaining = math.max(0, DELIVERY_TIME - elapsed)

		local player = Players:GetPlayerByUserId(userId)
		if player then
			DeliveryUpdateEvent:FireClient(player, {
				totalItems = #delivery.items,
				totalTime = DELIVERY_TIME,
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
