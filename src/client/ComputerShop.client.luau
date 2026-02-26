print("[ComputerShop] Starting...")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local CardData = require(ReplicatedStorage:WaitForChild("CardData"))

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local BuyCardEvent = Remotes:WaitForChild("BuyCard")
local BuyCardResultEvent = Remotes:WaitForChild("BuyCardResult")
local UpdateMoneyEvent = Remotes:WaitForChild("UpdateMoney")
local GetMoneyRemote = Remotes:WaitForChild("GetMoney")
local EndDayRemote = Remotes:WaitForChild("EndDay")

print("[ComputerShop] Remotes loaded!")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local shopOpen = false
local currentMoney = GetMoneyRemote:InvokeServer()
local selectedCategory = "all"
local searchQuery = ""
local showToast -- forward declaration

local function playClick()
	local sound = SoundService:FindFirstChild("MouseClick")
	if sound then sound:Play() end
end

-- =====================
-- PROXIMITY PROMPT ON COMPUTER
-- =====================
local function setupComputerPrompt()
	print("[ComputerShop] Setting up prompt...")
	local store = workspace:WaitForChild("PokemonStore", 10)
	if not store then
		print("[ComputerShop] ERROR: PokemonStore not found!")
		return
	end

	local laptop = store:WaitForChild("StoreLaptop", 10)
	if not laptop then
		print("[ComputerShop] ERROR: StoreLaptop not found!")
		return
	end

	local promptParent = laptop:WaitForChild("LaptopPromptPart", 10)
	if not promptParent then
		print("[ComputerShop] ERROR: LaptopPromptPart not found!")
		return
	end

	print("[ComputerShop] Attaching prompt to LaptopPromptPart")
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Open Shop"
	prompt.ObjectText = "CardMarket.gg"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = promptParent

	prompt.Triggered:Connect(function()
		toggleShop()
	end)
	print("[ComputerShop] Prompt created!")
end

-- =====================
-- SHOP GUI - "WEBSITE" STYLE
-- =====================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ComputerShopGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- Dark overlay
local overlay = Instance.new("Frame")
overlay.Size = UDim2.new(1, 0, 1, 0)
overlay.BackgroundColor3 = Color3.new(0, 0, 0)
overlay.BackgroundTransparency = 0.4
overlay.BorderSizePixel = 0
overlay.Visible = false
overlay.Parent = screenGui

-- Browser window
local browser = Instance.new("Frame")
browser.Name = "Browser"
browser.Size = UDim2.new(0, 650, 0, 480)
browser.Position = UDim2.new(0.5, -325, 0.5, -240)
browser.BackgroundColor3 = Color3.new(0.96, 0.96, 0.97)
browser.BorderSizePixel = 0
browser.Parent = overlay

local browserCorner = Instance.new("UICorner")
browserCorner.CornerRadius = UDim.new(0, 10)
browserCorner.Parent = browser

-- Browser tab bar (chrome-like)
local tabBar = Instance.new("Frame")
tabBar.Size = UDim2.new(1, 0, 0, 35)
tabBar.BackgroundColor3 = Color3.new(0.88, 0.88, 0.9)
tabBar.BorderSizePixel = 0
tabBar.Parent = browser

local tabBarCorner = Instance.new("UICorner")
tabBarCorner.CornerRadius = UDim.new(0, 10)
tabBarCorner.Parent = tabBar

local tabBarFix = Instance.new("Frame")
tabBarFix.Size = UDim2.new(1, 0, 0, 10)
tabBarFix.Position = UDim2.new(0, 0, 1, -10)
tabBarFix.BackgroundColor3 = Color3.new(0.88, 0.88, 0.9)
tabBarFix.BorderSizePixel = 0
tabBarFix.Parent = tabBar

-- Tab
local tab = Instance.new("Frame")
tab.Size = UDim2.new(0, 180, 0, 28)
tab.Position = UDim2.new(0, 8, 0, 4)
tab.BackgroundColor3 = Color3.new(0.96, 0.96, 0.97)
tab.BorderSizePixel = 0
tab.Parent = tabBar

local tabCorner = Instance.new("UICorner")
tabCorner.CornerRadius = UDim.new(0, 6)
tabCorner.Parent = tab

local tabLabel = Instance.new("TextLabel")
tabLabel.Size = UDim2.new(1, -8, 1, 0)
tabLabel.Position = UDim2.new(0, 4, 0, 0)
tabLabel.BackgroundTransparency = 1
tabLabel.Text = "CardMarket.gg"
tabLabel.TextColor3 = Color3.new(0.3, 0.3, 0.3)
tabLabel.TextSize = 11
tabLabel.Font = Enum.Font.LuckiestGuy
tabLabel.TextXAlignment = Enum.TextXAlignment.Left
tabLabel.Parent = tab

-- Close browser button
local closeBrowser = Instance.new("TextButton")
closeBrowser.Size = UDim2.new(0, 24, 0, 24)
closeBrowser.Position = UDim2.new(1, -32, 0, 6)
closeBrowser.BackgroundColor3 = Color3.new(0.85, 0.3, 0.3)
closeBrowser.Text = "X"
closeBrowser.TextColor3 = Color3.new(1, 1, 1)
closeBrowser.TextSize = 12
closeBrowser.Font = Enum.Font.LuckiestGuy
closeBrowser.BorderSizePixel = 0
closeBrowser.Parent = tabBar

local closeBrowserCorner = Instance.new("UICorner")
closeBrowserCorner.CornerRadius = UDim.new(1, 0)
closeBrowserCorner.Parent = closeBrowser

-- URL bar
local urlBar = Instance.new("Frame")
urlBar.Size = UDim2.new(1, -20, 0, 30)
urlBar.Position = UDim2.new(0, 10, 0, 38)
urlBar.BackgroundColor3 = Color3.new(1, 1, 1)
urlBar.BorderSizePixel = 0
urlBar.Parent = browser

local urlBarCorner = Instance.new("UICorner")
urlBarCorner.CornerRadius = UDim.new(0, 15)
urlBarCorner.Parent = urlBar

local urlIcon = Instance.new("TextLabel")
urlIcon.Size = UDim2.new(0, 20, 1, 0)
urlIcon.Position = UDim2.new(0, 10, 0, 0)
urlIcon.BackgroundTransparency = 1
urlIcon.Text = "🔒"
urlIcon.TextSize = 12
urlIcon.Parent = urlBar

local urlText = Instance.new("TextLabel")
urlText.Size = UDim2.new(1, -40, 1, 0)
urlText.Position = UDim2.new(0, 30, 0, 0)
urlText.BackgroundTransparency = 1
urlText.Text = "https://cardmarket.gg/pokemon-tcg/catalog"
urlText.TextColor3 = Color3.new(0.3, 0.3, 0.3)
urlText.TextSize = 12
urlText.Font = Enum.Font.LuckiestGuy
urlText.TextXAlignment = Enum.TextXAlignment.Left
urlText.Parent = urlBar

-- =====================
-- WEBSITE CONTENT
-- =====================
local content = Instance.new("Frame")
content.Name = "Content"
content.Size = UDim2.new(1, 0, 1, -75)
content.Position = UDim2.new(0, 0, 0, 75)
content.BackgroundColor3 = Color3.new(0.98, 0.98, 0.99)
content.BorderSizePixel = 0
content.ClipsDescendants = true
content.Parent = browser

-- Header banner
local banner = Instance.new("Frame")
banner.Size = UDim2.new(1, 0, 0, 80)
banner.BackgroundColor3 = Color3.new(0.15, 0.2, 0.35)
banner.BorderSizePixel = 0
banner.Parent = content

local bannerTitle = Instance.new("TextLabel")
bannerTitle.Size = UDim2.new(0.6, 0, 1, 0)
bannerTitle.Position = UDim2.new(0, 15, 0, 0)
bannerTitle.BackgroundTransparency = 1
bannerTitle.Text = "CardMarket.gg"
bannerTitle.TextColor3 = Color3.new(1, 1, 1)
bannerTitle.TextSize = 24
bannerTitle.Font = Enum.Font.LuckiestGuy
bannerTitle.TextXAlignment = Enum.TextXAlignment.Left
bannerTitle.Parent = banner

local bannerSub = Instance.new("TextLabel")
bannerSub.Size = UDim2.new(0.6, 0, 0, 16)
bannerSub.Position = UDim2.new(0, 15, 1, -20)
bannerSub.BackgroundTransparency = 1
bannerSub.Text = "The best Pokemon TCG marketplace"
bannerSub.TextColor3 = Color3.new(0.7, 0.75, 0.85)
bannerSub.TextSize = 11
bannerSub.Font = Enum.Font.LuckiestGuy
bannerSub.TextXAlignment = Enum.TextXAlignment.Left
bannerSub.Parent = banner

-- Money display on banner
local shopMoney = Instance.new("TextLabel")
shopMoney.Name = "ShopMoney"
shopMoney.Size = UDim2.new(0, 140, 0, 30)
shopMoney.Position = UDim2.new(1, -155, 0, 15)
shopMoney.BackgroundColor3 = Color3.new(0.1, 0.25, 0.1)
shopMoney.Text = "Balance: $0"
shopMoney.TextColor3 = Color3.new(0.3, 1, 0.3)
shopMoney.TextSize = 16
shopMoney.Font = Enum.Font.LuckiestGuy
shopMoney.BorderSizePixel = 0
shopMoney.Parent = banner

local shopMoneyCorner = Instance.new("UICorner")
shopMoneyCorner.CornerRadius = UDim.new(0, 6)
shopMoneyCorner.Parent = shopMoney

-- End Day button on banner
local endDayBtn = Instance.new("TextButton")
endDayBtn.Name = "EndDayBtn"
endDayBtn.Size = UDim2.new(0, 100, 0, 26)
endDayBtn.Position = UDim2.new(1, -155, 0, 48)
endDayBtn.BackgroundColor3 = Color3.new(0.6, 0.15, 0.15)
endDayBtn.Text = "End Day"
endDayBtn.TextColor3 = Color3.new(1, 1, 1)
endDayBtn.TextSize = 12
endDayBtn.Font = Enum.Font.LuckiestGuy
endDayBtn.BorderSizePixel = 0
endDayBtn.Visible = false
endDayBtn.Parent = banner

local endDayBtnCorner = Instance.new("UICorner")
endDayBtnCorner.CornerRadius = UDim.new(0, 6)
endDayBtnCorner.Parent = endDayBtn

-- =====================
-- DAY SUMMARY OVERLAY (inside content area)
-- =====================
local summaryFrame = Instance.new("Frame")
summaryFrame.Name = "DaySummary"
summaryFrame.Size = UDim2.new(1, 0, 1, 0)
summaryFrame.BackgroundColor3 = Color3.new(0.12, 0.14, 0.2)
summaryFrame.BorderSizePixel = 0
summaryFrame.Visible = false
summaryFrame.ZIndex = 5
summaryFrame.Parent = content

local summaryTitle = Instance.new("TextLabel")
summaryTitle.Size = UDim2.new(1, 0, 0, 45)
summaryTitle.BackgroundColor3 = Color3.new(0.08, 0.1, 0.16)
summaryTitle.Text = "DAY SUMMARY"
summaryTitle.TextColor3 = Color3.new(1, 0.85, 0.3)
summaryTitle.TextSize = 22
summaryTitle.Font = Enum.Font.LuckiestGuy
summaryTitle.BorderSizePixel = 0
summaryTitle.ZIndex = 6
summaryTitle.Parent = summaryFrame

local summaryBody = Instance.new("Frame")
summaryBody.Size = UDim2.new(1, -40, 1, -110)
summaryBody.Position = UDim2.new(0, 20, 0, 55)
summaryBody.BackgroundTransparency = 1
summaryBody.ZIndex = 6
summaryBody.Parent = summaryFrame

local function makeSummaryLine(yPos, label, value, valueColor)
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(0.6, 0, 0, 24)
	lbl.Position = UDim2.new(0, 0, 0, yPos)
	lbl.BackgroundTransparency = 1
	lbl.Text = label
	lbl.TextColor3 = Color3.new(0.75, 0.75, 0.8)
	lbl.TextSize = 14
	lbl.Font = Enum.Font.LuckiestGuy
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.ZIndex = 7
	lbl.Parent = summaryBody

	local val = Instance.new("TextLabel")
	val.Name = label
	val.Size = UDim2.new(0.4, 0, 0, 24)
	val.Position = UDim2.new(0.6, 0, 0, yPos)
	val.BackgroundTransparency = 1
	val.Text = value
	val.TextColor3 = valueColor or Color3.new(1, 1, 1)
	val.TextSize = 16
	val.Font = Enum.Font.LuckiestGuy
	val.TextXAlignment = Enum.TextXAlignment.Right
	val.ZIndex = 7
	val.Parent = summaryBody

	return val
end

local sumClosedAt = makeSummaryLine(0, "Closed at", "--:--")
local sumVisitors = makeSummaryLine(30, "Visitors", "0")
local sumBuyers = makeSummaryLine(60, "Buyers", "0", Color3.new(0.3, 1, 0.3))
local sumCardsSold = makeSummaryLine(90, "Cards sold", "0")
local sumRevenue = makeSummaryLine(120, "Revenue", "$0", Color3.new(1, 0.85, 0.3))

-- Separator
local sumSep = Instance.new("Frame")
sumSep.Size = UDim2.new(1, 0, 0, 1)
sumSep.Position = UDim2.new(0, 0, 0, 155)
sumSep.BackgroundColor3 = Color3.new(0.3, 0.3, 0.4)
sumSep.BorderSizePixel = 0
sumSep.ZIndex = 7
sumSep.Parent = summaryBody

-- Customer feedback section
local feedbackTitle = Instance.new("TextLabel")
feedbackTitle.Size = UDim2.new(1, 0, 0, 24)
feedbackTitle.Position = UDim2.new(0, 0, 0, 165)
feedbackTitle.BackgroundTransparency = 1
feedbackTitle.Text = "CUSTOMER FEEDBACK"
feedbackTitle.TextColor3 = Color3.new(1, 0.7, 0.3)
feedbackTitle.TextSize = 13
feedbackTitle.Font = Enum.Font.LuckiestGuy
feedbackTitle.TextXAlignment = Enum.TextXAlignment.Left
feedbackTitle.ZIndex = 7
feedbackTitle.Parent = summaryBody

local sumTooExpensive = makeSummaryLine(195, "Found prices too high", "0", Color3.new(1, 0.4, 0.4))
local sumCheapDeals = makeSummaryLine(225, "Found great deals", "0", Color3.new(0.4, 0.8, 1))
local sumEmptyShelf = makeSummaryLine(255, "Found empty shelves", "0", Color3.new(0.6, 0.6, 0.6))

-- OK button
local sumOkBtn = Instance.new("TextButton")
sumOkBtn.Size = UDim2.new(0, 200, 0, 36)
sumOkBtn.Position = UDim2.new(0.5, -100, 1, -50)
sumOkBtn.BackgroundColor3 = Color3.new(0.15, 0.45, 0.15)
sumOkBtn.Text = "START NEW DAY"
sumOkBtn.TextColor3 = Color3.new(1, 1, 1)
sumOkBtn.TextSize = 15
sumOkBtn.Font = Enum.Font.LuckiestGuy
sumOkBtn.BorderSizePixel = 0
sumOkBtn.ZIndex = 7
sumOkBtn.Parent = summaryFrame

local sumOkCorner = Instance.new("UICorner")
sumOkCorner.CornerRadius = UDim.new(0, 8)
sumOkCorner.Parent = sumOkBtn

local showingSummary = false

local function showSummary(stats)
	sumClosedAt.Text = stats.closedAt
	sumVisitors.Text = tostring(stats.visitors)
	sumBuyers.Text = tostring(stats.buyers)
	sumCardsSold.Text = tostring(stats.cardsSold)
	sumRevenue.Text = "$" .. tostring(stats.revenue)
	sumTooExpensive.Text = tostring(stats.tooExpensive)
	sumCheapDeals.Text = tostring(stats.cheapDeals)
	sumEmptyShelf.Text = tostring(stats.emptyShelf)

	summaryFrame.Visible = true
	showingSummary = true
	endDayBtn.Visible = false
end

local function hideSummary()
	summaryFrame.Visible = false
	showingSummary = false
	shopOpen = false
	overlay.Visible = false
end

sumOkBtn.MouseButton1Click:Connect(function()
	playClick()
	hideSummary()
end)

endDayBtn.MouseButton1Click:Connect(function()
	playClick()
	endDayBtn.Text = "Closing..."
	local stats = EndDayRemote:InvokeServer()
	endDayBtn.Text = "End Day"
	if stats then
		showSummary(stats)
	else
		showToast("Shop is not open!", true)
	end
end)

-- Category filters
local filterBar = Instance.new("Frame")
filterBar.Size = UDim2.new(1, 0, 0, 35)
filterBar.Position = UDim2.new(0, 0, 0, 80)
filterBar.BackgroundColor3 = Color3.new(0.93, 0.93, 0.95)
filterBar.BorderSizePixel = 0
filterBar.Parent = content

local filterLayout = Instance.new("UIListLayout")
filterLayout.FillDirection = Enum.FillDirection.Horizontal
filterLayout.VerticalAlignment = Enum.VerticalAlignment.Center
filterLayout.Padding = UDim.new(0, 5)
filterLayout.Parent = filterBar

local filterPadding = Instance.new("UIPadding")
filterPadding.PaddingLeft = UDim.new(0, 10)
filterPadding.Parent = filterBar

local categories = { "all", "Common", "Rare", "Ultra Rare", "Legendary" }
local categoryNames = { all = "All", Common = "Common", Rare = "Rare", ["Ultra Rare"] = "Ultra Rare", Legendary = "Legendary" }
local filterButtons = {}

-- Search bar
local searchBar = Instance.new("Frame")
searchBar.Size = UDim2.new(1, -20, 0, 28)
searchBar.Position = UDim2.new(0, 10, 0, 118)
searchBar.BackgroundColor3 = Color3.new(1, 1, 1)
searchBar.BorderSizePixel = 0
searchBar.Parent = content

local searchBarCorner = Instance.new("UICorner")
searchBarCorner.CornerRadius = UDim.new(0, 14)
searchBarCorner.Parent = searchBar

local searchBarStroke = Instance.new("UIStroke")
searchBarStroke.Thickness = 1
searchBarStroke.Color = Color3.new(0.8, 0.8, 0.82)
searchBarStroke.Parent = searchBar

local searchIcon = Instance.new("TextLabel")
searchIcon.Size = UDim2.new(0, 28, 1, 0)
searchIcon.Position = UDim2.new(0, 6, 0, 0)
searchIcon.BackgroundTransparency = 1
searchIcon.Text = "?"
searchIcon.TextColor3 = Color3.new(0.55, 0.55, 0.6)
searchIcon.TextSize = 14
searchIcon.Font = Enum.Font.LuckiestGuy
searchIcon.Parent = searchBar

local searchBox = Instance.new("TextBox")
searchBox.Name = "SearchBox"
searchBox.Size = UDim2.new(1, -40, 1, 0)
searchBox.Position = UDim2.new(0, 34, 0, 0)
searchBox.BackgroundTransparency = 1
searchBox.PlaceholderText = "Search cards..."
searchBox.PlaceholderColor3 = Color3.new(0.65, 0.65, 0.7)
searchBox.Text = ""
searchBox.TextColor3 = Color3.new(0.2, 0.2, 0.2)
searchBox.TextSize = 12
searchBox.Font = Enum.Font.LuckiestGuy
searchBox.TextXAlignment = Enum.TextXAlignment.Left
searchBox.ClearTextOnFocus = false
searchBox.Parent = searchBar

-- Card grid (scrolling)
local cardGrid = Instance.new("ScrollingFrame")
cardGrid.Name = "CardGrid"
cardGrid.Size = UDim2.new(1, -20, 1, -155)
cardGrid.Position = UDim2.new(0, 10, 0, 150)
cardGrid.BackgroundTransparency = 1
cardGrid.BorderSizePixel = 0
cardGrid.ScrollBarThickness = 4
cardGrid.ScrollBarImageColor3 = Color3.new(0.5, 0.5, 0.6)
cardGrid.CanvasSize = UDim2.new(0, 0, 0, 0)
cardGrid.AutomaticCanvasSize = Enum.AutomaticSize.Y
cardGrid.Parent = content

local gridLayout = Instance.new("UIGridLayout")
gridLayout.CellSize = UDim2.new(0, 145, 0, 190)
gridLayout.CellPadding = UDim2.new(0, 10, 0, 10)
gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
gridLayout.Parent = cardGrid

-- Status toast
local toast = Instance.new("TextLabel")
toast.Name = "Toast"
toast.Size = UDim2.new(0, 300, 0, 35)
toast.Position = UDim2.new(0.5, -150, 1, -45)
toast.BackgroundColor3 = Color3.new(0.15, 0.4, 0.15)
toast.BackgroundTransparency = 0.1
toast.Text = ""
toast.TextColor3 = Color3.new(1, 1, 1)
toast.TextSize = 14
toast.Font = Enum.Font.LuckiestGuy
toast.BorderSizePixel = 0
toast.Visible = false
toast.Parent = content

local toastCorner = Instance.new("UICorner")
toastCorner.CornerRadius = UDim.new(0, 8)
toastCorner.Parent = toast

-- =====================
-- POPULATE CARDS
-- =====================
showToast = function(message, isError)
	toast.Text = message
	toast.BackgroundColor3 = isError and Color3.new(0.5, 0.15, 0.15) or Color3.new(0.15, 0.4, 0.15)
	toast.Visible = true
	task.delay(2.5, function()
		toast.Visible = false
	end)
end

local function populateCards()
	-- Clear existing
	for _, child in cardGrid:GetChildren() do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	local allCards = CardData.GetShopCards()
	local order = 0

	for _, cardInfo in allCards do
		-- Filter by category
		if selectedCategory ~= "all" and cardInfo.rarity ~= selectedCategory then
			continue
		end

		-- Filter by search
		if searchQuery ~= "" and not cardInfo.name:lower():find(searchQuery, 1, true) then
			continue
		end

		order += 1

		local card = Instance.new("Frame")
		card.Name = cardInfo.id
		card.LayoutOrder = order
		card.BackgroundColor3 = Color3.new(1, 1, 1)
		card.BorderSizePixel = 0
		card.Parent = cardGrid

		local cardCorner = Instance.new("UICorner")
		cardCorner.CornerRadius = UDim.new(0, 8)
		cardCorner.Parent = card

		local cardStroke = Instance.new("UIStroke")
		cardStroke.Thickness = 1
		cardStroke.Color = Color3.new(0.85, 0.85, 0.87)
		cardStroke.Parent = card

		-- Card color preview (top area)
		local preview = Instance.new("Frame")
		preview.Size = UDim2.new(1, -10, 0, 80)
		preview.Position = UDim2.new(0, 5, 0, 5)
		preview.BackgroundColor3 = cardInfo.color
		preview.BorderSizePixel = 0
		preview.Parent = card

		local previewCorner = Instance.new("UICorner")
		previewCorner.CornerRadius = UDim.new(0, 6)
		previewCorner.Parent = preview

		-- Rarity badge
		local rarityColor = CardData.RarityColors[cardInfo.rarity] or Color3.new(0.5, 0.5, 0.5)
		local badge = Instance.new("TextLabel")
		badge.Size = UDim2.new(0, 70, 0, 16)
		badge.Position = UDim2.new(0, 3, 0, 3)
		badge.BackgroundColor3 = Color3.new(0, 0, 0)
		badge.BackgroundTransparency = 0.4
		badge.Text = cardInfo.rarity
		badge.TextColor3 = rarityColor
		badge.TextSize = 9
		badge.Font = Enum.Font.LuckiestGuy
		badge.BorderSizePixel = 0
		badge.Parent = preview

		local badgeCorner = Instance.new("UICorner")
		badgeCorner.CornerRadius = UDim.new(0, 4)
		badgeCorner.Parent = badge

		-- Card name
		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.new(1, -10, 0, 20)
		nameLabel.Position = UDim2.new(0, 5, 0, 90)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = cardInfo.name
		nameLabel.TextColor3 = Color3.new(0.1, 0.1, 0.1)
		nameLabel.TextSize = 13
		nameLabel.Font = Enum.Font.LuckiestGuy
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
		nameLabel.Parent = card

		-- Sell price info
		local sellLabel = Instance.new("TextLabel")
		sellLabel.Size = UDim2.new(1, -10, 0, 14)
		sellLabel.Position = UDim2.new(0, 5, 0, 110)
		sellLabel.BackgroundTransparency = 1
		sellLabel.Text = "Market: $" .. cardInfo.price
		sellLabel.TextColor3 = Color3.new(0.4, 0.4, 0.4)
		sellLabel.TextSize = 10
		sellLabel.Font = Enum.Font.LuckiestGuy
		sellLabel.TextXAlignment = Enum.TextXAlignment.Left
		sellLabel.Parent = card

		-- Cost + Buy button row
		local costLabel = Instance.new("TextLabel")
		costLabel.Size = UDim2.new(0.5, -5, 0, 35)
		costLabel.Position = UDim2.new(0, 5, 1, -42)
		costLabel.BackgroundTransparency = 1
		costLabel.Text = "$" .. cardInfo.cost
		costLabel.TextColor3 = Color3.new(0.1, 0.1, 0.1)
		costLabel.TextSize = 20
		costLabel.Font = Enum.Font.LuckiestGuy
		costLabel.TextXAlignment = Enum.TextXAlignment.Left
		costLabel.Parent = card

		local buyBtn = Instance.new("TextButton")
		buyBtn.Size = UDim2.new(0.5, -10, 0, 30)
		buyBtn.Position = UDim2.new(0.5, 0, 1, -38)
		buyBtn.BackgroundColor3 = Color3.new(0.2, 0.55, 0.2)
		buyBtn.Text = "Buy"
		buyBtn.TextColor3 = Color3.new(1, 1, 1)
		buyBtn.TextSize = 13
		buyBtn.Font = Enum.Font.LuckiestGuy
		buyBtn.BorderSizePixel = 0
		buyBtn.Parent = card

		local buyBtnCorner = Instance.new("UICorner")
		buyBtnCorner.CornerRadius = UDim.new(0, 6)
		buyBtnCorner.Parent = buyBtn

		buyBtn.MouseButton1Click:Connect(function()
			playClick()
			if currentMoney < cardInfo.cost then
				showToast("Not enough money! Need $" .. cardInfo.cost, true)
				return
			end
			BuyCardEvent:FireServer(cardInfo.id)
		end)
	end
end

searchBox:GetPropertyChangedSignal("Text"):Connect(function()
	searchQuery = searchBox.Text:lower()
	populateCards()
end)

-- =====================
-- CATEGORY FILTER BUTTONS
-- =====================
for i, cat in categories do
	local btn = Instance.new("TextButton")
	btn.Name = cat
	btn.Size = UDim2.new(0, 85, 0, 25)
	btn.BackgroundColor3 = cat == "all" and Color3.new(0.2, 0.35, 0.6) or Color3.new(0.82, 0.82, 0.85)
	btn.Text = categoryNames[cat]
	btn.TextColor3 = cat == "all" and Color3.new(1, 1, 1) or Color3.new(0.3, 0.3, 0.3)
	btn.TextSize = 11
	btn.Font = Enum.Font.LuckiestGuy
	btn.BorderSizePixel = 0
	btn.LayoutOrder = i
	btn.Parent = filterBar

	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 12)
	btnCorner.Parent = btn

	filterButtons[cat] = btn

	btn.MouseButton1Click:Connect(function()
		playClick()
		selectedCategory = cat
		-- Update button visuals
		for c, b in filterButtons do
			if c == cat then
				b.BackgroundColor3 = Color3.new(0.2, 0.35, 0.6)
				b.TextColor3 = Color3.new(1, 1, 1)
			else
				b.BackgroundColor3 = Color3.new(0.82, 0.82, 0.85)
				b.TextColor3 = Color3.new(0.3, 0.3, 0.3)
			end
		end
		populateCards()
	end)
end

-- =====================
-- OPEN / CLOSE
-- =====================
function toggleShop()
	shopOpen = not shopOpen
	overlay.Visible = shopOpen
	if shopOpen then
		searchQuery = ""
		searchBox.Text = ""
		shopMoney.Text = "Balance: $" .. currentMoney
		endDayBtn.Visible = true
		summaryFrame.Visible = false
		showingSummary = false
		populateCards()
	end
end

closeBrowser.MouseButton1Click:Connect(function()
	shopOpen = false
	overlay.Visible = false
end)

-- Update money display when it changes
UpdateMoneyEvent.OnClientEvent:Connect(function(amount)
	currentMoney = amount
	if shopOpen then
		shopMoney.Text = "Balance: $" .. currentMoney
	end
end)

-- Buy result
BuyCardResultEvent.OnClientEvent:Connect(function(success, message)
	if success then
		showToast(message, false)
		shopMoney.Text = "Balance: $" .. currentMoney
	else
		showToast(message, true)
	end
end)

-- Setup
setupComputerPrompt()
