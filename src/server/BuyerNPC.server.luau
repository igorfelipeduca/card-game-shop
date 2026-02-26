print("[BuyerNPC] Starting...")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local SoundService = game:GetService("SoundService")
local CardData = require(ReplicatedStorage:WaitForChild("CardData"))

-- =====================
-- NPC PICKED UP EVENT
-- =====================
local npcPickedUp = Instance.new("BindableEvent")
npcPickedUp.Name = "NPCPickedUpCard"
npcPickedUp.Parent = ReplicatedStorage

-- =====================
-- NPC TEMPLATE
-- =====================
local npcModel = workspace:WaitForChild("BuyerNPC", 10)
if not npcModel then
	warn("[BuyerNPC] BuyerNPC model not found!")
	return
end

local NPC_Y = npcModel:GetBoundingBox().Position.Y
local npcTemplate = npcModel:Clone()
npcTemplate.Name = "BuyerNPCTemplate"
npcTemplate.Parent = ServerStorage
npcModel:Destroy()
print("[BuyerNPC] Template stored, original removed")

-- =====================
-- KEY POSITIONS (inside PokemonStore)
-- =====================
local SPAWN_POS = Vector3.new(8, NPC_Y, 15)
local ENTER_POS = Vector3.new(2, NPC_Y, 30)
local SHELF_BROWSE_POS = Vector3.new(-18, NPC_Y, 45)
local EXIT_POS = Vector3.new(8, NPC_Y, 15)
local REGISTER_LOOK_TARGET = Vector3.new(26, 0, 57.5)

local function getRegisterFrontPos()
	return Vector3.new(24, NPC_Y, 53)
end

local function getQueuePos(index)
	local front = getRegisterFrontPos()
	return front + Vector3.new(0, 0, -(index - 1) * 3.5)
end

-- =====================
-- NPC HELPERS
-- =====================
local function faceToward(npc, targetPos)
	local root = npc:FindFirstChild("HumanoidRootPart")
	if not root then return end
	local from = root.Position
	local lookAt = Vector3.new(targetPos.X, from.Y, targetPos.Z)
	root.CFrame = CFrame.lookAt(from, lookAt)
end

local function walkTo(humanoid, position)
	humanoid:MoveTo(position)
	humanoid.MoveToFinished:Wait()
end

local function showCardsBillboard(npc, cards)
	local head = npc:FindFirstChild("Head")
	if not head then return end

	-- Remove existing
	local existing = head:FindFirstChild("CardNameDisplay")
	if existing then existing:Destroy() end

	local totalPrice = 0
	local names = {}
	for _, c in cards do
		table.insert(names, c.cardInfo.name)
		totalPrice += c.shelfPrice
	end

	local displayHeight = #cards > 1 and 70 or 55

	local billboardGui = Instance.new("BillboardGui")
	billboardGui.Name = "CardNameDisplay"
	billboardGui.Size = UDim2.new(0, 160, 0, displayHeight)
	billboardGui.StudsOffset = Vector3.new(0, 3, 0)
	billboardGui.AlwaysOnTop = true
	billboardGui.Parent = head

	local bg = Instance.new("Frame")
	bg.Size = UDim2.new(1, 0, 1, 0)
	bg.BackgroundColor3 = cards[1].cardInfo.color
	bg.BackgroundTransparency = 0.2
	bg.BorderSizePixel = 0
	bg.Parent = billboardGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = bg

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, -8, 0, 20)
	nameLabel.Position = UDim2.new(0, 4, 0, 4)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = #cards > 1 and (#cards .. " cards") or names[1]
	nameLabel.TextColor3 = Color3.new(1, 1, 1)
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.LuckiestGuy
	nameLabel.TextStrokeTransparency = 0.3
	nameLabel.Parent = bg

	local priceLabel = Instance.new("TextLabel")
	priceLabel.Size = UDim2.new(1, -8, 0, 20)
	priceLabel.Position = UDim2.new(0, 4, 0, 24)
	priceLabel.BackgroundTransparency = 1
	priceLabel.Text = "$" .. totalPrice
	priceLabel.TextColor3 = Color3.new(1, 1, 0.4)
	priceLabel.TextScaled = true
	priceLabel.Font = Enum.Font.LuckiestGuy
	priceLabel.TextStrokeTransparency = 0.3
	priceLabel.Parent = bg

	if #cards > 1 then
		local detailLabel = Instance.new("TextLabel")
		detailLabel.Size = UDim2.new(1, -8, 0, 16)
		detailLabel.Position = UDim2.new(0, 4, 0, 46)
		detailLabel.BackgroundTransparency = 1
		detailLabel.Text = table.concat(names, ", ")
		detailLabel.TextColor3 = Color3.new(0.9, 0.9, 0.9)
		detailLabel.TextScaled = true
		detailLabel.Font = Enum.Font.LuckiestGuy
		detailLabel.TextStrokeTransparency = 0.5
		detailLabel.Parent = bg
	end
end

-- =====================
-- DAILY STATS
-- =====================
local dayStats = {
	visitors = 0,
	buyers = 0,
	tooExpensive = 0,
	cheapDeals = 0,
	emptyShelf = 0,
}

local getBuyerStatsFunc = Instance.new("BindableFunction")
getBuyerStatsFunc.Name = "GetBuyerStats"
getBuyerStatsFunc.OnInvoke = function()
	return dayStats
end
getBuyerStatsFunc.Parent = ReplicatedStorage

-- ShopOpened event (DayCycleManager listens)
local shopOpenedEvent = Instance.new("BindableEvent")
shopOpenedEvent.Name = "ShopOpened"
shopOpenedEvent.Parent = ReplicatedStorage

-- Listen for day reset
task.spawn(function()
	local resetStats = ReplicatedStorage:WaitForChild("ResetDayStats", 30)
	if not resetStats then return end
	resetStats.Event:Connect(function()
		dayStats.visitors = 0
		dayStats.buyers = 0
		dayStats.tooExpensive = 0
		dayStats.cheapDeals = 0
		dayStats.emptyShelf = 0
		print("[BuyerNPC] Day stats reset")
	end)
end)

local shopOpen = false

-- Listen for CloseShop from DayCycleManager
task.spawn(function()
	local closeShop = ReplicatedStorage:WaitForChild("CloseShop", 30)
	if not closeShop then return end
	closeShop.Event:Connect(function()
		shopOpen = false
		local s = workspace:FindFirstChild("ShopSign")
		if s then
			for _, gui in s:GetChildren() do
				if gui:IsA("SurfaceGui") then
					local bg = gui:FindFirstChild("Bg")
					if bg then
						bg.BackgroundColor3 = Color3.new(0.7, 0.1, 0.1)
						local label = bg:FindFirstChild("StatusLabel")
						if label then label.Text = "CLOSED" end
					end
				end
			end
			local sp = s:FindFirstChildOfClass("ProximityPrompt")
			if sp then sp.ActionText = "Open Shop" end
		end
		print("[BuyerNPC] Shop closed by DayCycleManager")
	end)
end)

-- =====================
-- SHOP SIGN
-- =====================
local sign = workspace:WaitForChild("ShopSign", 10)

if sign then
	local signPrompt = Instance.new("ProximityPrompt")
	signPrompt.ActionText = "Open Shop"
	signPrompt.ObjectText = "Shop Sign"
	signPrompt.HoldDuration = 0
	signPrompt.MaxActivationDistance = 10
	signPrompt.RequiresLineOfSight = false
	signPrompt.Parent = sign

	local function updateSign()
		for _, gui in sign:GetChildren() do
			if gui:IsA("SurfaceGui") then
				local bg = gui:FindFirstChild("Bg")
				if bg then
					local label = bg:FindFirstChild("StatusLabel")
					if shopOpen then
						bg.BackgroundColor3 = Color3.new(0.1, 0.65, 0.1)
						if label then label.Text = "OPEN" end
					else
						bg.BackgroundColor3 = Color3.new(0.7, 0.1, 0.1)
						if label then label.Text = "CLOSED" end
					end
				end
			end
		end
		signPrompt.ActionText = shopOpen and "Close Shop" or "Open Shop"
	end

	signPrompt.Triggered:Connect(function(player)
		shopOpen = not shopOpen
		updateSign()
		local openShopSound = SoundService:FindFirstChild("OpenShop")
		if openShopSound then openShopSound:Play() end
		print("[BuyerNPC] Shop " .. (shopOpen and "OPENED" or "CLOSED") .. " by " .. player.Name)

		if shopOpen then
			shopOpenedEvent:Fire()
			task.spawn(spawnCustomersLoop)
		end
	end)

	print("[BuyerNPC] Shop sign ready")
end

-- =====================
-- REGISTER QUEUE
-- =====================
local registerQueue = {}
local servingCustomer = false

local function serveNextInQueue()
	if #registerQueue == 0 then
		servingCustomer = false
		local queueEmpty = ReplicatedStorage:FindFirstChild("QueueEmpty")
		if queueEmpty then
			queueEmpty:Fire()
		end
		return
	end

	servingCustomer = true
	local front = registerQueue[1]

	local npcAtRegister = ReplicatedStorage:FindFirstChild("NPCAtRegister")
	if npcAtRegister then
		npcAtRegister:Fire(front.cards)
	end

	print("[BuyerNPC] Serving customer with " .. #front.cards .. " card(s)")
end

-- After checkout, NPC leaves and next steps up
task.spawn(function()
	local checkoutDone = ReplicatedStorage:WaitForChild("CheckoutDone", 30)
	if not checkoutDone then return end

	checkoutDone.Event:Connect(function()
		if #registerQueue == 0 then return end

		local served = table.remove(registerQueue, 1)
		print("[BuyerNPC] Customer served, leaving...")

		-- Remove card billboard
		local head = served.npc:FindFirstChild("Head")
		if head then
			local gui = head:FindFirstChild("CardNameDisplay")
			if gui then gui:Destroy() end
		end

		local humanoid = served.npc:FindFirstChildOfClass("Humanoid")
		if humanoid then
			task.spawn(function()
				-- Walk to entrance first, then outside
				walkTo(humanoid, ENTER_POS)
				walkTo(humanoid, EXIT_POS)
				served.npc:Destroy()
			end)
		else
			served.npc:Destroy()
		end

		-- Move remaining customers forward in queue
		for i, entry in registerQueue do
			local h = entry.npc:FindFirstChildOfClass("Humanoid")
			if h then
				task.spawn(function()
					h:MoveTo(getQueuePos(i))
					h.MoveToFinished:Wait()
					faceToward(entry.npc, REGISTER_LOOK_TARGET)
				end)
			end
		end

		task.wait(1.5)
		serveNextInQueue()
	end)
end)

-- =====================
-- NPC AI (runs per NPC)
-- =====================
local MAX_PRICE_RATIO = 1.5  -- NPC refuses if shelfPrice > marketPrice * 1.5
local CHEAP_RATIO = 0.7      -- NPC buys multiple if shelfPrice <= marketPrice * 0.7
local MAX_MULTI_CARDS = 3    -- Max cards a single NPC can buy

local function runNPCAI(npc, customerIndex)
	local humanoid = npc:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		npc:Destroy()
		return
	end

	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	dayStats.visitors += 1
	print("[BuyerNPC] Customer #" .. customerIndex .. " entering shop")

	-- 1. Walk into shop entrance
	walkTo(humanoid, ENTER_POS)

	local doorbell = SoundService:FindFirstChild("Store Door Bell")
	if doorbell then
		doorbell:Play()
	end

	-- 2. Walk toward shelf area
	walkTo(humanoid, SHELF_BROWSE_POS + Vector3.new(math.random(-3, 3), 0, math.random(-3, 3)))
	task.wait(1.5)

	-- 3. Check shelf for stocked cards
	local getFilledSlots = ReplicatedStorage:FindFirstChild("GetFilledSlots")
	if not getFilledSlots then
		print("[BuyerNPC] Customer #" .. customerIndex .. " can't find shelf data, leaving")
		walkTo(humanoid, ENTER_POS)
		walkTo(humanoid, EXIT_POS)
		npc:Destroy()
		return
	end

	local filledSlots = getFilledSlots:Invoke()

	if #filledSlots == 0 then
		dayStats.emptyShelf += 1
		print("[BuyerNPC] Customer #" .. customerIndex .. " found empty shelf, leaving")
		task.wait(1)
		walkTo(humanoid, ENTER_POS)
		walkTo(humanoid, EXIT_POS)
		npc:Destroy()
		return
	end

	-- 4. Evaluate prices - filter out cards that are too expensive
	local affordableSlots = {}
	local cheapSlots = {}
	for _, slot in filledSlots do
		local cardInfo = CardData.GetCardById(slot.cardId)
		if cardInfo then
			local shelfPrice = slot.shelfPrice or cardInfo.price
			local marketPrice = cardInfo.price
			local ratio = shelfPrice / marketPrice

			if ratio <= MAX_PRICE_RATIO then
				table.insert(affordableSlots, { slot = slot, cardInfo = cardInfo, shelfPrice = shelfPrice })
				if ratio <= CHEAP_RATIO then
					table.insert(cheapSlots, { slot = slot, cardInfo = cardInfo, shelfPrice = shelfPrice })
				end
			end
		end
	end

	if #affordableSlots == 0 then
		dayStats.tooExpensive += 1
		print("[BuyerNPC] Customer #" .. customerIndex .. " thinks everything is too expensive, leaving")
		task.wait(1)
		walkTo(humanoid, ENTER_POS)
		walkTo(humanoid, EXIT_POS)
		npc:Destroy()
		return
	end

	-- 5. Decide how many cards to buy
	local cardsToBuy = {}
	if #cheapSlots >= 2 and math.random() < 0.6 then
		-- Buy multiple cheap cards
		local shuffled = {}
		for _, v in cheapSlots do table.insert(shuffled, v) end
		for i = #shuffled, 2, -1 do
			local j = math.random(1, i)
			shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
		end
		local count = math.min(math.random(2, MAX_MULTI_CARDS), #shuffled)
		for i = 1, count do
			table.insert(cardsToBuy, shuffled[i])
		end
		dayStats.cheapDeals += 1
		print("[BuyerNPC] Customer #" .. customerIndex .. " found cheap deals! Buying " .. count .. " cards")
	else
		-- Buy one random affordable card
		local pick = affordableSlots[math.random(1, #affordableSlots)]
		table.insert(cardsToBuy, pick)
	end

	-- 6. Walk to first card's slot and pick up all cards
	local store = workspace:FindFirstChild("PokemonStore")
	local pokemonShelf = store and store:FindFirstChild("PokemonShelf")

	for i, entry in cardsToBuy do
		local slotPart = pokemonShelf and pokemonShelf:FindFirstChild(entry.slot.slotName)
		if slotPart then
			local slotPos = slotPart.Position
			walkTo(humanoid, Vector3.new(slotPos.X + 5, NPC_Y, slotPos.Z))
			task.wait(0.8)
		end
		npcPickedUp:Fire(entry.slot.slotName)
		print("[BuyerNPC] Customer #" .. customerIndex .. " picked up " .. entry.cardInfo.name .. " ($" .. entry.shelfPrice .. ") from " .. entry.slot.slotName)
	end

	dayStats.buyers += 1
	showCardsBillboard(npc, cardsToBuy)
	task.wait(0.5)

	-- 7. Join the register queue
	local queueIndex = #registerQueue + 1
	table.insert(registerQueue, { npc = npc, cards = cardsToBuy })

	print("[BuyerNPC] Customer #" .. customerIndex .. " joining queue at position " .. queueIndex)
	walkTo(humanoid, getQueuePos(queueIndex))
	faceToward(npc, REGISTER_LOOK_TARGET)

	-- 8. If first in queue and no one being served, start service
	if queueIndex == 1 and not servingCustomer then
		serveNextInQueue()
	end
end

-- =====================
-- CONTINUOUS CUSTOMER SPAWNING
-- =====================
local customerCount = 0

function spawnCustomersLoop()
	print("[BuyerNPC] Customer spawning started")

	while shopOpen do
		local waitTime = math.random(8, 20)
		task.wait(waitTime)

		if not shopOpen then break end

		customerCount += 1
		local npc = npcTemplate:Clone()
		npc.Name = "Customer_" .. customerCount .. "_" .. tick()
		npc:PivotTo(CFrame.new(SPAWN_POS + Vector3.new(math.random(-2, 2), 0, math.random(-2, 2))))
		npc.Parent = workspace

		print("[BuyerNPC] Customer #" .. customerCount .. " arriving")
		task.spawn(runNPCAI, npc, customerCount)
	end

	print("[BuyerNPC] Customer spawning stopped")
end

print("[BuyerNPC] System ready! Toggle the shop sign to start.")
