print("[CheckoutManager] Starting...")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local Players = game:GetService("Players")
local CardData = require(ReplicatedStorage:WaitForChild("CardData"))

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local OpenCheckoutEvent = Remotes:WaitForChild("OpenCheckout")
local SubmitChangeEvent = Remotes:WaitForChild("SubmitChange")
local CheckoutResultEvent = Remotes:WaitForChild("CheckoutResult")
local UpdateMoneyEvent = Remotes:WaitForChild("UpdateMoney")
local CloseCheckoutEvent = Remotes:WaitForChild("CloseCheckout")
local CancelCheckoutEvent = Remotes:WaitForChild("CancelCheckout")

-- =====================
-- PLAYER MONEY (shared with InventoryManager via BindableEvents)
-- =====================
local function getMoney(player)
	local func = ReplicatedStorage:FindFirstChild("GetPlayerMoney")
	if func then
		return func:Invoke(player.UserId)
	end
	return 0
end

local function addMoney(player, amount)
	local currentMoney = getMoney(player)
	local newMoney = currentMoney + amount
	local setEvent = ReplicatedStorage:FindFirstChild("SetPlayerMoney")
	if setEvent then
		setEvent:Fire(player.UserId, newMoney)
	end
	UpdateMoneyEvent:FireClient(player, newMoney)
end

-- =====================
-- BILL DENOMINATIONS
-- =====================
local BILLS = {5, 10, 20, 50, 100, 200, 500, 1000}

local function pickPayment(price)
	-- 25% chance of exact payment
	if math.random() < 0.25 then
		return price
	end

	-- Find bills >= price, sorted smallest first (already sorted)
	local validBills = {}
	for _, bill in BILLS do
		if bill >= price then
			table.insert(validBills, bill)
		end
	end

	if #validBills == 0 then
		local largest = BILLS[#BILLS]
		local count = math.ceil(price / largest)
		return count * largest
	end

	-- Prefer smaller bills: 60% smallest, 25% second, 15% rest
	local roll = math.random()
	if roll < 0.60 then
		return validBills[1]
	elseif roll < 0.85 and #validBills >= 2 then
		return validBills[2]
	elseif #validBills >= 3 then
		return validBills[math.random(3, math.min(#validBills, 4))]
	end

	return validBills[1]
end

-- =====================
-- PROXIMITY PROMPT ON CASH REGISTER
-- =====================
local pokemonStore = workspace:WaitForChild("PokemonStore", 10)
local register = pokemonStore and pokemonStore:WaitForChild("CashRegister", 10)
local prompt = nil

if register then
	local promptParent = nil
	for _, desc in register:GetDescendants() do
		if desc:IsA("BasePart") then
			promptParent = desc
			break
		end
	end

	if promptParent then
		prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = "Serve Customer"
		prompt.ObjectText = "Cash Register"
		prompt.HoldDuration = 0
		prompt.MaxActivationDistance = 10
		prompt.RequiresLineOfSight = false
		prompt.Enabled = false
		prompt.Parent = promptParent
		print("[CheckoutManager] ProximityPrompt created")
	end
end

-- =====================
-- DAILY SALE STATS
-- =====================
local saleStats = { revenue = 0, cardsSold = 0 }

local getSaleStatsFunc = Instance.new("BindableFunction")
getSaleStatsFunc.Name = "GetSaleStats"
getSaleStatsFunc.OnInvoke = function()
	return saleStats
end
getSaleStatsFunc.Parent = ReplicatedStorage

task.spawn(function()
	local resetStats = ReplicatedStorage:WaitForChild("ResetDayStats", 30)
	if not resetStats then return end
	resetStats.Event:Connect(function()
		saleStats.revenue = 0
		saleStats.cardsSold = 0
		print("[CheckoutManager] Sale stats reset")
	end)
end)

-- =====================
-- CHECKOUT STATE
-- =====================
local currentCheckout = nil
local currentCashier = nil

local npcAtRegisterEvent = Instance.new("BindableEvent")
npcAtRegisterEvent.Name = "NPCAtRegister"
npcAtRegisterEvent.Parent = ReplicatedStorage

local checkoutDoneEvent = Instance.new("BindableEvent")
checkoutDoneEvent.Name = "CheckoutDone"
checkoutDoneEvent.Parent = ReplicatedStorage

local queueEmptyEvent = Instance.new("BindableEvent")
queueEmptyEvent.Name = "QueueEmpty"
queueEmptyEvent.Parent = ReplicatedStorage

-- =====================
-- HELPERS
-- =====================
local function getCheckoutData()
	if not currentCheckout then return nil end

	local items = {}
	for _, card in currentCheckout.cards do
		table.insert(items, {
			cardName = card.cardInfo.name,
			cardColor = {
				R = card.cardInfo.color.R,
				G = card.cardInfo.color.G,
				B = card.cardInfo.color.B,
			},
			shelfPrice = card.shelfPrice,
		})
	end

	return {
		items = items,
		totalPrice = currentCheckout.totalPrice,
		payment = currentCheckout.payment,
	}
end

-- =====================
-- NPC ARRIVES AT REGISTER
-- =====================
npcAtRegisterEvent.Event:Connect(function(cards)
	print("[CheckoutManager] NPC arrived with " .. #cards .. " card(s)")

	local totalPrice = 0
	for _, card in cards do
		totalPrice += card.shelfPrice
	end

	local payment = pickPayment(totalPrice)
	local correctChange = payment - totalPrice

	currentCheckout = {
		cards = cards,
		totalPrice = totalPrice,
		payment = payment,
		correctChange = correctChange,
	}

	print("[CheckoutManager] Total=$" .. totalPrice .. " Payment=$" .. payment .. " Change=$" .. correctChange)

	if currentCashier then
		print("[CheckoutManager] Auto-opening for " .. currentCashier.Name)
		OpenCheckoutEvent:FireClient(currentCashier, getCheckoutData())
	elseif prompt then
		prompt.Enabled = true
	end
end)

-- =====================
-- PROMPT TRIGGERED (first interaction)
-- =====================
if prompt then
	prompt.Triggered:Connect(function(player)
		if not currentCheckout then return end

		print("[CheckoutManager] " .. player.Name .. " opened checkout")
		prompt.Enabled = false
		currentCashier = player

		OpenCheckoutEvent:FireClient(player, getCheckoutData())
	end)
end

-- =====================
-- SUBMIT CHANGE
-- =====================
SubmitChangeEvent.OnServerEvent:Connect(function(player, changeAmount)
	if not currentCheckout then
		CheckoutResultEvent:FireClient(player, false, "No customer waiting!")
		return
	end

	local correct = currentCheckout.correctChange

	if changeAmount == correct then
		print("[CheckoutManager] Correct! Sale complete.")

		local bell = SoundService:FindFirstChild("Bell2")
		if bell then
			bell:Play()
		end

		saleStats.revenue += currentCheckout.totalPrice
		saleStats.cardsSold += #currentCheckout.cards

		addMoney(player, currentCheckout.totalPrice)
		CheckoutResultEvent:FireClient(player, true, "Sale complete! +$" .. currentCheckout.totalPrice)
		checkoutDoneEvent:Fire()
		currentCheckout = nil
	else
		print("[CheckoutManager] Wrong change. Got $" .. changeAmount .. ", expected $" .. correct)

		local hint = ""
		if changeAmount > correct then
			hint = "Change too high!"
		elseif changeAmount < correct then
			hint = "Change too low!"
		end

		CheckoutResultEvent:FireClient(player, false, hint)
	end
end)

-- =====================
-- PLAYER CANCELS (closes UI manually)
-- =====================
CancelCheckoutEvent.OnServerEvent:Connect(function(player)
	if currentCashier == player then
		print("[CheckoutManager] " .. player.Name .. " left the register")
		currentCashier = nil
		if currentCheckout and prompt then
			prompt.Enabled = true
		end
	end
end)

-- =====================
-- QUEUE EMPTY (no more customers)
-- =====================
queueEmptyEvent.Event:Connect(function()
	print("[CheckoutManager] Queue empty")
	if currentCashier then
		CloseCheckoutEvent:FireClient(currentCashier)
		currentCashier = nil
	end
end)

-- =====================
-- PLAYER LEAVING
-- =====================
Players.PlayerRemoving:Connect(function(player)
	if currentCashier == player then
		currentCashier = nil
		if currentCheckout and prompt then
			prompt.Enabled = true
		end
	end
end)

print("[CheckoutManager] Ready!")
