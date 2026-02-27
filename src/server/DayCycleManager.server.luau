print("[DayCycleManager] Starting...")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local TimeUpdateEvent = Remotes:WaitForChild("TimeUpdate")
local EndDayRemote = Remotes:WaitForChild("EndDay")

-- =====================
-- BINDABLE EVENTS (DayCycleManager creates these)
-- =====================
local closeShopEvent = Instance.new("BindableEvent")
closeShopEvent.Name = "CloseShop"
closeShopEvent.Parent = ReplicatedStorage

local resetDayStatsEvent = Instance.new("BindableEvent")
resetDayStatsEvent.Name = "ResetDayStats"
resetDayStatsEvent.Parent = ReplicatedStorage

-- =====================
-- CLOCK CONFIG
-- =====================
local DAY_START_HOUR = 8
local WARNING_HOUR = 18
local MINUTES_PER_SECOND = 4 -- 4 game minutes per real second; full day ~4 real minutes (8:00-23:59)

-- =====================
-- CLOCK STATE
-- =====================
local clockRunning = false
local dayStartTime = 0 -- tick() when day started

local function getGameMinutes()
	if not clockRunning then return DAY_START_HOUR * 60 end
	local elapsed = tick() - dayStartTime
	local minutes = DAY_START_HOUR * 60 + elapsed * MINUTES_PER_SECOND
	return math.min(minutes, 24 * 60 - 1)
end

local function getTime()
	local totalMinutes = getGameMinutes()
	local h = math.floor(totalMinutes / 60) % 24
	local m = math.floor(totalMinutes) % 60
	return h, m
end

local lastLoggedHour = -1

local function broadcastTime()
	local h, m = getTime()
	local elapsed = tick() - dayStartTime
	local isLate = h >= WARNING_HOUR

	-- Log every broadcast with exact timestamps
	print(string.format("[DayCycleManager] tick=%.3f | elapsed=%.2fs | game=%02d:%02d | isLate=%s",
		tick(), elapsed, h, m, tostring(isLate)))

	-- Extra log on hour change
	if h ~= lastLoggedHour then
		lastLoggedHour = h
		print(string.format("[DayCycleManager] >> HOUR CHANGE -> %02d:00 | real elapsed: %.1fs", h, elapsed))
	end

	for _, player in Players:GetPlayers() do
		TimeUpdateEvent:FireClient(player, { hour = h, minute = m, isLate = isLate })
	end
end

-- =====================
-- BROADCAST LOOP (every 5 seconds)
-- =====================
task.spawn(function()
	while true do
		task.wait(2)
		if clockRunning then
			broadcastTime()
		end
	end
end)

-- =====================
-- PLAYER JOINS MID-DAY
-- =====================
Players.PlayerAdded:Connect(function(player)
	if clockRunning then
		local h, m = getTime()
		local isLate = h >= WARNING_HOUR
		TimeUpdateEvent:FireClient(player, { hour = h, minute = m, isLate = isLate })
	end
end)

-- =====================
-- SHOP OPENED (BuyerNPC signals this)
-- =====================
task.spawn(function()
	local shopOpened = ReplicatedStorage:WaitForChild("ShopOpened", 30)
	if not shopOpened then return end

	shopOpened.Event:Connect(function()
		if not clockRunning then
			clockRunning = true
			dayStartTime = tick()
			lastLoggedHour = -1
			broadcastTime()
			print(string.format("[DayCycleManager] Day started at 8:00 AM | MINUTES_PER_SECOND=%.4f | Expected duration: %.0fs (%.1f min)", MINUTES_PER_SECOND, 960 / MINUTES_PER_SECOND, 960 / MINUTES_PER_SECOND / 60))
		end
	end)
end)

-- =====================
-- END DAY (client requests via RemoteFunction)
-- =====================
EndDayRemote.OnServerInvoke = function(player)
	if not clockRunning then
		return nil
	end

	print("[DayCycleManager] " .. player.Name .. " ending the day")

	-- Gather stats from BuyerNPC
	local getBuyerStats = ReplicatedStorage:FindFirstChild("GetBuyerStats")
	local buyerStats = getBuyerStats and getBuyerStats:Invoke() or {}

	-- Gather stats from CheckoutManager
	local getSaleStats = ReplicatedStorage:FindFirstChild("GetSaleStats")
	local saleStats = getSaleStats and getSaleStats:Invoke() or {}

	local h, m = getTime()

	local summary = {
		closedAt = string.format("%02d:%02d", h, m),
		visitors = buyerStats.visitors or 0,
		buyers = buyerStats.buyers or 0,
		tooExpensive = buyerStats.tooExpensive or 0,
		cheapDeals = buyerStats.cheapDeals or 0,
		emptyShelf = buyerStats.emptyShelf or 0,
		revenue = saleStats.revenue or 0,
		cardsSold = saleStats.cardsSold or 0,
	}

	-- Stop clock
	clockRunning = false

	-- Close shop
	closeShopEvent:Fire()

	-- Reset stats
	resetDayStatsEvent:Fire()

	-- Broadcast clock off
	for _, p in Players:GetPlayers() do
		TimeUpdateEvent:FireClient(p, { dayEnded = true })
	end

	print("[DayCycleManager] Day ended. Visitors=" .. summary.visitors .. " Buyers=" .. summary.buyers .. " Revenue=$" .. summary.revenue)
	return summary
end

print("[DayCycleManager] Ready!")
