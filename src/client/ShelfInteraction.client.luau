local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CardData = require(ReplicatedStorage:WaitForChild("CardData"))

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local PlaceCardEvent = Remotes:WaitForChild("PlaceCard")
local RemoveCardEvent = Remotes:WaitForChild("RemoveCard")
local UpdateSlotEvent = Remotes:WaitForChild("UpdateSlot")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local mouse = player:GetMouse()

local getSelectedCard = player:WaitForChild("GetSelectedCard")
local clearSelection = player:WaitForChild("ClearCardSelection")

-- Track slot states locally
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
-- PRICING UI
-- =====================
local pricingOpen = false
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

local function openPricing(slotName, cardId)
	local cardInfo = CardData.GetCardById(cardId)
	if not cardInfo then return end

	pendingSlot = slotName
	pendingCardId = cardId
	currentCardCost = cardInfo.cost
	priceInput = tostring(cardInfo.price)
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
	PlaceCardEvent:FireServer(pendingSlot, pendingCardId, price)
	clearSelection:Fire()
	closePricing()
end)

cancelBtn.MouseButton1Click:Connect(function()
	closePricing()
end)

-- =====================
-- HOVER DETECTION
-- =====================
RunService.RenderStepped:Connect(function()
	if pricingOpen then
		selectionBox.Adornee = nil
		currentHover = nil
		return
	end

	local hasCard = getSelectedCard:Invoke() ~= nil
	local target = mouse.Target

	if hasCard and target and target:GetAttribute("IsSlot") and not localSlotState[target.Name] then
		if currentHover ~= target then
			currentHover = target
			selectionBox.Adornee = target
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
	if pricingOpen then return end
	if not currentHover then return end

	local slotName = currentHover.Name
	local slotOccupied = localSlotState[slotName]

	if slotOccupied then
		RemoveCardEvent:FireServer(slotName)
	else
		local cardId = getSelectedCard:Invoke()
		if not cardId then return end
		openPricing(slotName, cardId)
	end
end)

-- Listen for slot updates from server
UpdateSlotEvent.OnClientEvent:Connect(function(slotName, cardId, playerId)
	localSlotState[slotName] = cardId
end)
