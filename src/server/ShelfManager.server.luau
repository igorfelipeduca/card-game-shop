local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CardData = require(ReplicatedStorage:WaitForChild("CardData"))

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local PlaceCardEvent = Remotes:WaitForChild("PlaceCard")
local RemoveCardEvent = Remotes:WaitForChild("RemoveCard")
local UpdateSlotEvent = Remotes:WaitForChild("UpdateSlot")

-- State: slotName -> { cardId: string, playerId: number, shelfPrice: number } or nil
local slotState = {}

-- Expose slot data for NPC system
local getFilledSlots = Instance.new("BindableFunction")
getFilledSlots.Name = "GetFilledSlots"
getFilledSlots.OnInvoke = function()
	local filled = {}
	for slotName, state in slotState do
		if state then
			table.insert(filled, { slotName = slotName, cardId = state.cardId, shelfPrice = state.shelfPrice })
		end
	end
	return filled
end
getFilledSlots.Parent = ReplicatedStorage

local function findShelf()
	local store = workspace:FindFirstChild("PokemonStore")
	if not store then return nil end
	return store:FindFirstChild("PokemonShelf")
end

local function setupSlots()
	local pokemonShelf = findShelf()
	if not pokemonShelf then
		warn("[ShelfManager] PokemonStore/PokemonShelf not found")
		return
	end

	local slotIndex = 0
	for _, child in pokemonShelf:GetChildren() do
		if child:IsA("Part") and child:GetAttribute("IsSlot") then
			slotIndex += 1
			slotState[child.Name] = nil
		end
	end

	print("[ShelfManager] Setup " .. slotIndex .. " slots")
end

PlaceCardEvent.OnServerEvent:Connect(function(player, slotName, cardId, shelfPrice)
	local cardInfo = CardData.GetCardById(cardId)
	if not cardInfo then
		warn("[ShelfManager] Invalid card: " .. tostring(cardId))
		return
	end

	if slotState[slotName] ~= nil then
		warn("[ShelfManager] Slot occupied: " .. slotName)
		return
	end

	-- Validate shelf price
	shelfPrice = tonumber(shelfPrice) or cardInfo.price
	if shelfPrice < 1 then shelfPrice = 1 end

	local pokemonShelf = findShelf()
	if not pokemonShelf then return end
	local slotPart = pokemonShelf:FindFirstChild(slotName)
	if not slotPart then
		warn("[ShelfManager] Slot not found: " .. slotName)
		return
	end

	-- Update state
	slotState[slotName] = { cardId = cardId, playerId = player.UserId, shelfPrice = shelfPrice }

	-- Update visual
	slotPart.Transparency = 0
	slotPart.Color = cardInfo.color
	slotPart.Material = Enum.Material.SmoothPlastic

	-- Add SurfaceGui with card name + price
	local existing = slotPart:FindFirstChild("CardLabel")
	if existing then existing:Destroy() end

	local surfaceGui = Instance.new("SurfaceGui")
	surfaceGui.Name = "CardLabel"
	surfaceGui.Face = Enum.NormalId.Right
	surfaceGui.Parent = slotPart

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 0.6, 0)
	label.BackgroundTransparency = 1
	label.Text = cardInfo.name
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextScaled = true
	label.Font = Enum.Font.LuckiestGuy
	label.TextStrokeTransparency = 0.5
	label.Parent = surfaceGui

	local priceLabel = Instance.new("TextLabel")
	priceLabel.Size = UDim2.new(1, 0, 0.4, 0)
	priceLabel.Position = UDim2.new(0, 0, 0.6, 0)
	priceLabel.BackgroundTransparency = 1
	priceLabel.Text = "$" .. shelfPrice
	priceLabel.TextColor3 = Color3.new(1, 1, 0.4)
	priceLabel.TextScaled = true
	priceLabel.Font = Enum.Font.LuckiestGuy
	priceLabel.TextStrokeTransparency = 0.3
	priceLabel.Parent = surfaceGui

	-- Notify all clients
	UpdateSlotEvent:FireAllClients(slotName, cardId, player.UserId, shelfPrice)

	print("[ShelfManager] " .. player.Name .. " placed " .. cardInfo.name .. " in " .. slotName .. " for $" .. shelfPrice)
end)

RemoveCardEvent.OnServerEvent:Connect(function(player, slotName)
	local state = slotState[slotName]
	if not state then
		warn("[ShelfManager] Slot already empty: " .. slotName)
		return
	end

	if state.playerId ~= player.UserId then
		warn("[ShelfManager] Not your card")
		return
	end

	local pokemonShelf = findShelf()
	if not pokemonShelf then return end
	local slotPart = pokemonShelf:FindFirstChild(slotName)
	if not slotPart then return end

	-- Reset visual
	slotPart.Transparency = 0.7
	slotPart.Color = Color3.new(0.5, 0.5, 0.5)

	local cardLabel = slotPart:FindFirstChild("CardLabel")
	if cardLabel then cardLabel:Destroy() end

	-- Clear state
	slotState[slotName] = nil

	-- Notify all clients
	UpdateSlotEvent:FireAllClients(slotName, nil, nil)

	print("[ShelfManager] " .. player.Name .. " removed card from " .. slotName)
end)

-- NPC picked up a card from a slot
task.spawn(function()
	local npcPickedUp = ReplicatedStorage:WaitForChild("NPCPickedUpCard", 10)
	if not npcPickedUp then return end

	npcPickedUp.Event:Connect(function(slotName)
		local state = slotState[slotName]
		if not state then return end

		local pokemonShelf = findShelf()
		local slotPart = pokemonShelf and pokemonShelf:FindFirstChild(slotName)
		if slotPart then
			slotPart.Transparency = 0.7
			slotPart.Color = Color3.new(0.5, 0.5, 0.5)

			local cardLabel = slotPart:FindFirstChild("CardLabel")
			if cardLabel then cardLabel:Destroy() end
		end

		slotState[slotName] = nil
		UpdateSlotEvent:FireAllClients(slotName, nil, nil)

		print("[ShelfManager] NPC picked up card from " .. slotName)
	end)
end)

setupSlots()
