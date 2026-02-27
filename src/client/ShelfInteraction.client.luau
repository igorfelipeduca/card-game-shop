local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CardData = require(ReplicatedStorage:WaitForChild("CardData"))

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local PlaceCardEvent = Remotes:WaitForChild("PlaceCard")
local RemoveCardEvent = Remotes:WaitForChild("RemoveCard")
local UpdateSlotEvent = Remotes:WaitForChild("UpdateSlot")
local UpdateShelfPriceEvent = Remotes:WaitForChild("UpdateShelfPrice")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local mouse = player:GetMouse()

local getSelectedCard = player:WaitForChild("GetSelectedCard")
local clearSelection = player:WaitForChild("ClearCardSelection")

-- Track slot states locally: slotName -> { cardId, shelfPrice } or nil
local localSlotState = {}

-- Selection box for hover
local selectionBox = Instance.new("SelectionBox")
selectionBox.Color3 = Color3.new(0.2, 0.5, 1)
selectionBox.LineThickness = 0.05
selectionBox.SurfaceTransparency = 0.7
selectionBox.SurfaceColor3 = Color3.new(0.3, 0.6, 1)
selectionBox.Parent = playerGui

local currentHover = nil

-- =====================
-- QUICK ACTION MENU (for occupied slots)
-- =====================
local quickMenuOpen = false
local quickMenuSlot = nil

local quickMenuGui = Instance.new("ScreenGui")
quickMenuGui.Name = "QuickMenuGui"
quickMenuGui.ResetOnSpawn = false
quickMenuGui.Parent = playerGui

local quickMenuOverlay = Instance.new("Frame")
quickMenuOverlay.Size = UDim2.new(1, 0, 1, 0)
quickMenuOverlay.BackgroundColor3 = Color3.new(0, 0, 0)
quickMenuOverlay.BackgroundTransparency = 0.5
quickMenuOverlay.BorderSizePixel = 0
quickMenuOverlay.Visible = false
quickMenuOverlay.Parent = quickMenuGui

local quickPanel = Instance.new("Frame")
quickPanel.Size = UDim2.new(0, 220, 0, 190)
quickPanel.Position = UDim2.new(0.5, -110, 0.5, -95)
quickPanel.BackgroundColor3 = Color3.new(0.1, 0.1, 0.12)
quickPanel.BorderSizePixel = 0
quickPanel.Parent = quickMenuOverlay

local qpCorner = Instance.new("UICorner")
qpCorner.CornerRadius = UDim.new(0, 10)
qpCorner.Parent = quickPanel

local qpStroke = Instance.new("UIStroke")
qpStroke.Thickness = 2
qpStroke.Color = Color3.new(0.3, 0.3, 0.4)
qpStroke.Parent = quickPanel

-- Card color bar in quick menu
local qmColorBar = Instance.new("Frame")
qmColorBar.Size = UDim2.new(1, -20, 0, 30)
qmColorBar.Position = UDim2.new(0, 10, 0, 10)
qmColorBar.BackgroundColor3 = Color3.new(0.5, 0.5, 0.5)
qmColorBar.BorderSizePixel = 0
qmColorBar.Parent = quickPanel

local qmColorCorner = Instance.new("UICorner")
qmColorCorner.CornerRadius = UDim.new(0, 6)
qmColorCorner.Parent = qmColorBar

local qmCardName = Instance.new("TextLabel")
qmCardName.Size = UDim2.new(1, -10, 1, 0)
qmCardName.Position = UDim2.new(0, 5, 0, 0)
qmCardName.BackgroundTransparency = 1
qmCardName.Text = ""
qmCardName.TextColor3 = Color3.new(1, 1, 1)
qmCardName.TextSize = 13
qmCardName.Font = Enum.Font.LuckiestGuy
qmCardName.TextStrokeTransparency = 0.3
qmCardName.Parent = qmColorBar

local qmPriceLabel = Instance.new("TextLabel")
qmPriceLabel.Size = UDim2.new(1, -20, 0, 22)
qmPriceLabel.Position = UDim2.new(0, 10, 0, 46)
qmPriceLabel.BackgroundTransparency = 1
qmPriceLabel.Text = "Price: $0"
qmPriceLabel.TextColor3 = Color3.new(1, 1, 0.4)
qmPriceLabel.TextSize = 14
qmPriceLabel.Font = Enum.Font.LuckiestGuy
qmPriceLabel.TextXAlignment = Enum.TextXAlignment.Center
qmPriceLabel.Parent = quickPanel

local function makeQuickBtn(text, yPos, bgColor)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, -30, 0, 30)
	btn.Position = UDim2.new(0, 15, 0, yPos)
	btn.BackgroundColor3 = bgColor
	btn.Text = text
	btn.TextColor3 = Color3.new(1, 1, 1)
	btn.TextSize = 13
	btn.Font = Enum.Font.LuckiestGuy
	btn.BorderSizePixel = 0
	btn.Parent = quickPanel

	local bc = Instance.new("UICorner")
	bc.CornerRadius = UDim.new(0, 6)
	bc.Parent = btn

	return btn
end

local qmChangePriceBtn = makeQuickBtn("CHANGE PRICE", 76, Color3.new(0.15, 0.35, 0.6))
local qmRemoveBtn = makeQuickBtn("REMOVE CARD", 112, Color3.new(0.6, 0.15, 0.15))
local qmCancelBtn = makeQuickBtn("CANCEL", 148, Color3.new(0.25, 0.25, 0.3))

local function closeQuickMenu()
	quickMenuOpen = false
	quickMenuOverlay.Visible = false
	quickMenuSlot = nil
end

local function openQuickMenu(slotName)
	local slotData = localSlotState[slotName]
	if not slotData then return end

	local cardInfo = CardData.GetCardById(slotData.cardId)
	if not cardInfo then return end

	quickMenuSlot = slotName
	quickMenuOpen = true

	qmColorBar.BackgroundColor3 = cardInfo.color
	qmCardName.Text = cardInfo.name
	qmPriceLabel.Text = "Price: $" .. (slotData.shelfPrice or cardInfo.price)

	quickMenuOverlay.Visible = true
end

-- =====================
-- PRICING UI
-- =====================
local pricingOpen = false
local pricingEditMode = false -- true when editing an existing slot's price
local pendingSlot = nil
local pendingCardId = nil
local priceInput = ""

local pricingGui = Instance.new("ScreenGui")
pricingGui.Name = "PricingGui"
pricingGui.ResetOnSpawn = false
pricingGui.Parent = playerGui

local pricingOverlay = Instance.new("Frame")
pricingOverlay.Size = UDim2.new(1, 0, 1, 0)
pricingOverlay.BackgroundColor3 = Color3.new(0, 0, 0)
pricingOverlay.BackgroundTransparency = 0.5
pricingOverlay.BorderSizePixel = 0
pricingOverlay.Visible = false
pricingOverlay.Parent = pricingGui

local pricingPanel = Instance.new("Frame")
pricingPanel.Size = UDim2.new(0, 320, 0, 420)
pricingPanel.Position = UDim2.new(0.5, -160, 0.5, -210)
pricingPanel.BackgroundColor3 = Color3.new(0.1, 0.1, 0.12)
pricingPanel.BorderSizePixel = 0
pricingPanel.Parent = pricingOverlay

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 10)
panelCorner.Parent = pricingPanel

local panelStroke = Instance.new("UIStroke")
panelStroke.Thickness = 2
panelStroke.Color = Color3.new(0.3, 0.3, 0.4)
panelStroke.Parent = pricingPanel

-- Title
local pricingTitle = Instance.new("TextLabel")
pricingTitle.Size = UDim2.new(1, 0, 0, 35)
pricingTitle.BackgroundColor3 = Color3.new(0.15, 0.15, 0.2)
pricingTitle.Text = "SET SHELF PRICE"
pricingTitle.TextColor3 = Color3.new(1, 1, 1)
pricingTitle.TextSize = 16
pricingTitle.Font = Enum.Font.LuckiestGuy
pricingTitle.BorderSizePixel = 0
pricingTitle.Parent = pricingPanel

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 10)
titleCorner.Parent = pricingTitle

-- Card color bar
local cardColorBar = Instance.new("Frame")
cardColorBar.Name = "CardColorBar"
cardColorBar.Size = UDim2.new(1, -20, 0, 30)
cardColorBar.Position = UDim2.new(0, 10, 0, 42)
cardColorBar.BackgroundColor3 = Color3.new(0.5, 0.5, 0.5)
cardColorBar.BorderSizePixel = 0
cardColorBar.Parent = pricingPanel

local colorBarCorner = Instance.new("UICorner")
colorBarCorner.CornerRadius = UDim.new(0, 6)
colorBarCorner.Parent = cardColorBar

local cardNameLabel = Instance.new("TextLabel")
cardNameLabel.Size = UDim2.new(1, -10, 1, 0)
cardNameLabel.Position = UDim2.new(0, 5, 0, 0)
cardNameLabel.BackgroundTransparency = 1
cardNameLabel.Text = ""
cardNameLabel.TextColor3 = Color3.new(1, 1, 1)
cardNameLabel.TextSize = 14
cardNameLabel.Font = Enum.Font.LuckiestGuy
cardNameLabel.TextStrokeTransparency = 0.3
cardNameLabel.Parent = cardColorBar

-- Info lines
local function makeInfoLine(yPos, labelText, valueText, valueColor)
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(0.55, 0, 0, 22)
	lbl.Position = UDim2.new(0, 15, 0, yPos)
	lbl.BackgroundTransparency = 1
	lbl.Text = labelText
	lbl.TextColor3 = Color3.new(0.7, 0.7, 0.7)
	lbl.TextSize = 12
	lbl.Font = Enum.Font.LuckiestGuy
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Parent = pricingPanel

	local val = Instance.new("TextLabel")
	val.Name = labelText
	val.Size = UDim2.new(0.4, 0, 0, 22)
	val.Position = UDim2.new(0.55, 0, 0, yPos)
	val.BackgroundTransparency = 1
	val.Text = valueText
	val.TextColor3 = valueColor or Color3.new(1, 1, 1)
	val.TextSize = 14
	val.Font = Enum.Font.LuckiestGuy
	val.TextXAlignment = Enum.TextXAlignment.Right
	val.Parent = pricingPanel

	return val
end

local buyCostValue = makeInfoLine(80, "You paid", "$0", Color3.new(1, 0.4, 0.4))
local marketValue = makeInfoLine(104, "Market value", "$0", Color3.new(0.5, 0.7, 1))

-- Separator
local sep = Instance.new("Frame")
sep.Size = UDim2.new(1, -30, 0, 1)
sep.Position = UDim2.new(0, 15, 0, 132)
sep.BackgroundColor3 = Color3.new(0.3, 0.3, 0.35)
sep.BorderSizePixel = 0
sep.Parent = pricingPanel

-- Price input display
local inputFrame = Instance.new("Frame")
inputFrame.Size = UDim2.new(1, -30, 0, 40)
inputFrame.Position = UDim2.new(0, 15, 0, 140)
inputFrame.BackgroundColor3 = Color3.new(0.02, 0.05, 0.02)
inputFrame.BorderSizePixel = 0
inputFrame.Parent = pricingPanel

local inputCorner = Instance.new("UICorner")
inputCorner.CornerRadius = UDim.new(0, 6)
inputCorner.Parent = inputFrame

local inputStroke = Instance.new("UIStroke")
inputStroke.Thickness = 2
inputStroke.Color = Color3.new(0.1, 0.3, 0.1)
inputStroke.Parent = inputFrame

local inputLabel = Instance.new("TextLabel")
inputLabel.Size = UDim2.new(1, -10, 1, 0)
inputLabel.Position = UDim2.new(0, 5, 0, 0)
inputLabel.BackgroundTransparency = 1
inputLabel.Text = "$ 0"
inputLabel.TextColor3 = Color3.new(0.2, 1, 0.2)
inputLabel.TextSize = 24
inputLabel.Font = Enum.Font.LuckiestGuy
inputLabel.TextXAlignment = Enum.TextXAlignment.Right
inputLabel.Parent = inputFrame

-- Profit display
local profitLabel = makeInfoLine(188, "Profit", "$0", Color3.new(0.3, 1, 0.3))

-- Numpad
local numpadFrame = Instance.new("Frame")
numpadFrame.Size = UDim2.new(0, 240, 0, 100)
numpadFrame.Position = UDim2.new(0.5, -120, 0, 218)
numpadFrame.BackgroundTransparency = 1
numpadFrame.Parent = pricingPanel

local numpadGrid = Instance.new("UIGridLayout")
numpadGrid.CellSize = UDim2.new(0, 72, 0, 28)
numpadGrid.CellPadding = UDim2.new(0, 6, 0, 4)
numpadGrid.HorizontalAlignment = Enum.HorizontalAlignment.Center
numpadGrid.SortOrder = Enum.SortOrder.LayoutOrder
numpadGrid.Parent = numpadFrame

local function makeBtn(text, order, bgColor)
	local btn = Instance.new("TextButton")
	btn.LayoutOrder = order
	btn.BackgroundColor3 = bgColor or Color3.new(0.2, 0.2, 0.25)
	btn.Text = text
	btn.TextColor3 = Color3.new(1, 1, 1)
	btn.TextSize = 16
	btn.Font = Enum.Font.LuckiestGuy
	btn.BorderSizePixel = 0
	btn.Parent = numpadFrame

	local bc = Instance.new("UICorner")
	bc.CornerRadius = UDim.new(0, 6)
	bc.Parent = btn

	return btn
end

makeBtn("1", 1); makeBtn("2", 2); makeBtn("3", 3)
makeBtn("4", 4); makeBtn("5", 5); makeBtn("6", 6)
makeBtn("7", 7); makeBtn("8", 8); makeBtn("9", 9)
makeBtn("C", 10, Color3.new(0.6, 0.15, 0.15))
makeBtn("0", 11)
makeBtn("00", 12, Color3.new(0.25, 0.25, 0.3))

-- Confirm / Cancel buttons
local confirmBtn = Instance.new("TextButton")
confirmBtn.Size = UDim2.new(0.5, -18, 0, 32)
confirmBtn.Position = UDim2.new(0, 15, 1, -42)
confirmBtn.BackgroundColor3 = Color3.new(0.1, 0.5, 0.1)
confirmBtn.Text = "PLACE"
confirmBtn.TextColor3 = Color3.new(1, 1, 1)
confirmBtn.TextSize = 14
confirmBtn.Font = Enum.Font.LuckiestGuy
confirmBtn.BorderSizePixel = 0
confirmBtn.Parent = pricingPanel

local confirmCorner = Instance.new("UICorner")
confirmCorner.CornerRadius = UDim.new(0, 6)
confirmCorner.Parent = confirmBtn

local cancelBtn = Instance.new("TextButton")
cancelBtn.Size = UDim2.new(0.5, -18, 0, 32)
cancelBtn.Position = UDim2.new(0.5, 3, 1, -42)
cancelBtn.BackgroundColor3 = Color3.new(0.5, 0.15, 0.15)
cancelBtn.Text = "CANCEL"
cancelBtn.TextColor3 = Color3.new(1, 1, 1)
cancelBtn.TextSize = 14
cancelBtn.Font = Enum.Font.LuckiestGuy
cancelBtn.BorderSizePixel = 0
cancelBtn.Parent = pricingPanel

local cancelCorner = Instance.new("UICorner")
cancelCorner.CornerRadius = UDim.new(0, 6)
cancelCorner.Parent = cancelBtn

-- =====================
-- PRICING LOGIC
-- =====================
local currentCardCost = 0

local function updatePriceDisplay()
	local price = tonumber(priceInput) or 0
	inputLabel.Text = "$ " .. (priceInput == "" and "0" or priceInput)

	local profit = price - currentCardCost
	if profit >= 0 then
		profitLabel.Text = "+$" .. profit
		profitLabel.TextColor3 = Color3.new(0.3, 1, 0.3)
	else
		profitLabel.Text = "-$" .. math.abs(profit)
		profitLabel.TextColor3 = Color3.new(1, 0.3, 0.3)
	end
end

local function openPricing(slotName, cardId, editMode, currentShelfPrice)
	local cardInfo = CardData.GetCardById(cardId)
	if not cardInfo then return end

	pendingSlot = slotName
	pendingCardId = cardId
	pricingEditMode = editMode or false
	currentCardCost = cardInfo.cost

	if editMode and currentShelfPrice then
		priceInput = tostring(currentShelfPrice)
		pricingTitle.Text = "EDIT SHELF PRICE"
		confirmBtn.Text = "UPDATE"
	else
		priceInput = tostring(cardInfo.price)
		pricingTitle.Text = "SET SHELF PRICE"
		confirmBtn.Text = "PLACE"
	end

	pricingOpen = true

	cardColorBar.BackgroundColor3 = cardInfo.color
	cardNameLabel.Text = cardInfo.name
	buyCostValue.Text = "$" .. cardInfo.cost
	marketValue.Text = "$" .. cardInfo.price

	updatePriceDisplay()
	pricingOverlay.Visible = true
end

local function closePricing()
	pricingOpen = false
	pricingEditMode = false
	pricingOverlay.Visible = false
	pendingSlot = nil
	pendingCardId = nil
	priceInput = ""
end

-- Numpad connections
for _, btn in numpadFrame:GetChildren() do
	if btn:IsA("TextButton") then
		btn.MouseButton1Click:Connect(function()
			if not pricingOpen then return end
			local text = btn.Text
			if text == "C" then
				priceInput = ""
			elseif text == "00" then
				if #priceInput < 5 then
					priceInput = priceInput .. "00"
				end
			else
				if #priceInput >= 6 then return end
				if priceInput == "0" then
					priceInput = text
				else
					priceInput = priceInput .. text
				end
			end
			updatePriceDisplay()
		end)
	end
end

confirmBtn.MouseButton1Click:Connect(function()
	if not pricingOpen or not pendingSlot or not pendingCardId then return end
	local price = tonumber(priceInput) or 0
	if price < 1 then return end

	if pricingEditMode then
		UpdateShelfPriceEvent:FireServer(pendingSlot, price)
	else
		PlaceCardEvent:FireServer(pendingSlot, pendingCardId, price)
		clearSelection:Fire()
	end
	closePricing()
end)

cancelBtn.MouseButton1Click:Connect(function()
	closePricing()
end)

-- =====================
-- KEYBOARD INPUT FOR PRICING
-- =====================
local PRICE_KEY_TO_DIGIT = {
	[Enum.KeyCode.Zero] = "0",    [Enum.KeyCode.KeypadZero] = "0",
	[Enum.KeyCode.One] = "1",     [Enum.KeyCode.KeypadOne] = "1",
	[Enum.KeyCode.Two] = "2",     [Enum.KeyCode.KeypadTwo] = "2",
	[Enum.KeyCode.Three] = "3",   [Enum.KeyCode.KeypadThree] = "3",
	[Enum.KeyCode.Four] = "4",    [Enum.KeyCode.KeypadFour] = "4",
	[Enum.KeyCode.Five] = "5",    [Enum.KeyCode.KeypadFive] = "5",
	[Enum.KeyCode.Six] = "6",     [Enum.KeyCode.KeypadSix] = "6",
	[Enum.KeyCode.Seven] = "7",   [Enum.KeyCode.KeypadSeven] = "7",
	[Enum.KeyCode.Eight] = "8",   [Enum.KeyCode.KeypadEight] = "8",
	[Enum.KeyCode.Nine] = "9",    [Enum.KeyCode.KeypadNine] = "9",
}

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed or not pricingOpen then return end

	local digit = PRICE_KEY_TO_DIGIT[input.KeyCode]
	if digit then
		if #priceInput >= 6 then return end
		if priceInput == "0" or priceInput == "" then
			priceInput = digit
		else
			priceInput = priceInput .. digit
		end
		updatePriceDisplay()
	elseif input.KeyCode == Enum.KeyCode.Backspace then
		if #priceInput > 1 then
			priceInput = priceInput:sub(1, -2)
		else
			priceInput = ""
		end
		updatePriceDisplay()
	elseif input.KeyCode == Enum.KeyCode.Return or input.KeyCode == Enum.KeyCode.KeypadEnter then
		confirmBtn.MouseButton1Click:Fire()
	elseif input.KeyCode == Enum.KeyCode.Escape then
		closePricing()
	end
end)

-- =====================
-- QUICK MENU CONNECTIONS
-- =====================
qmChangePriceBtn.MouseButton1Click:Connect(function()
	if not quickMenuSlot then return end
	local slotData = localSlotState[quickMenuSlot]
	if not slotData then
		closeQuickMenu()
		return
	end
	local slotName = quickMenuSlot
	closeQuickMenu()
	openPricing(slotName, slotData.cardId, true, slotData.shelfPrice)
end)

qmRemoveBtn.MouseButton1Click:Connect(function()
	if not quickMenuSlot then return end
	RemoveCardEvent:FireServer(quickMenuSlot)
	closeQuickMenu()
end)

qmCancelBtn.MouseButton1Click:Connect(function()
	closeQuickMenu()
end)

-- =====================
-- HOVER DETECTION
-- =====================
RunService.RenderStepped:Connect(function()
	if pricingOpen or quickMenuOpen then
		selectionBox.Adornee = nil
		currentHover = nil
		return
	end

	local target = mouse.Target

	if target and target:GetAttribute("IsSlot") then
		local slotData = localSlotState[target.Name]

		if slotData then
			-- Occupied slot: show yellow/orange highlight
			if currentHover ~= target then
				currentHover = target
				selectionBox.Color3 = Color3.new(1, 0.7, 0.2)
				selectionBox.SurfaceColor3 = Color3.new(1, 0.8, 0.3)
				selectionBox.Adornee = target
			end
		else
			-- Only check selected card for empty slots
			local hasCard = getSelectedCard:Invoke() ~= nil
			if hasCard then
				-- Empty slot with card selected: show blue highlight
				if currentHover ~= target then
					currentHover = target
					selectionBox.Color3 = Color3.new(0.2, 0.5, 1)
					selectionBox.SurfaceColor3 = Color3.new(0.3, 0.6, 1)
					selectionBox.Adornee = target
				end
			else
				if currentHover then
					currentHover = nil
					selectionBox.Adornee = nil
				end
			end
		end
	else
		if currentHover then
			currentHover = nil
			selectionBox.Adornee = nil
		end
	end
end)

-- =====================
-- CLICK HANDLING
-- =====================
mouse.Button1Down:Connect(function()
	if pricingOpen or quickMenuOpen then return end
	if not currentHover then return end

	local slotName = currentHover.Name
	local slotData = localSlotState[slotName]

	if slotData then
		openQuickMenu(slotName)
	else
		local cardId = getSelectedCard:Invoke()
		if not cardId then return end
		openPricing(slotName, cardId)
	end
end)

-- Listen for slot updates from server
UpdateSlotEvent.OnClientEvent:Connect(function(slotName, cardId, playerId, shelfPrice)
	if cardId then
		localSlotState[slotName] = { cardId = cardId, shelfPrice = shelfPrice }
	else
		localSlotState[slotName] = nil
	end
end)

print("[ShelfInteraction] Loaded with quick menu + edit mode")
