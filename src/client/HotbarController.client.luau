local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local CardData = require(ReplicatedStorage:WaitForChild("CardData"))

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local InitInventoryEvent = Remotes:WaitForChild("InitInventory")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local selectedCardId = nil
local slotButtons = {}
local currentCardIds = {}

-- BindableEvent to notify other scripts when selection changes
local selectionChanged = Instance.new("BindableEvent")
selectionChanged.Name = "CardSelectionChanged"
selectionChanged.Parent = player

-- =====================
-- HOTBAR GUI
-- =====================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "HotbarGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local hotbarFrame = Instance.new("Frame")
hotbarFrame.Name = "HotbarFrame"
hotbarFrame.Size = UDim2.new(0, 420, 0, 70)
hotbarFrame.Position = UDim2.new(0.5, -210, 1, -90)
hotbarFrame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
hotbarFrame.BackgroundTransparency = 0.3
hotbarFrame.BorderSizePixel = 0
hotbarFrame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = hotbarFrame

local listLayout = Instance.new("UIListLayout")
listLayout.FillDirection = Enum.FillDirection.Horizontal
listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
listLayout.VerticalAlignment = Enum.VerticalAlignment.Center
listLayout.Padding = UDim.new(0, 5)
listLayout.Parent = hotbarFrame

local uiPadding = Instance.new("UIPadding")
uiPadding.PaddingLeft = UDim.new(0, 5)
uiPadding.PaddingRight = UDim.new(0, 5)
uiPadding.Parent = hotbarFrame

-- Hint label: "Press I for Inventory"
local hintLabel = Instance.new("TextLabel")
hintLabel.Name = "HintLabel"
hintLabel.Size = UDim2.new(0, 200, 0, 20)
hintLabel.Position = UDim2.new(0.5, -100, 1, -125)
hintLabel.BackgroundTransparency = 1
hintLabel.Text = "[F] Inventory"
hintLabel.TextColor3 = Color3.new(0.7, 0.7, 0.7)
hintLabel.TextSize = 18
hintLabel.Font = Enum.Font.LuckiestGuy
hintLabel.Parent = screenGui

-- =====================
-- SELECTION VISUALS
-- =====================
local SLOT_SIZE = 60
local SELECTED_INNER_SIZE = 48
local SELECTED_BORDER_THICKNESS = 3

local function applySelectedVisual(button)
	-- Shrink the card inner area
	local inner = button:FindFirstChild("InnerCard")
	if inner then
		inner.Size = UDim2.new(0, SELECTED_INNER_SIZE, 0, SELECTED_INNER_SIZE)
		inner.Position = UDim2.new(0.5, -SELECTED_INNER_SIZE / 2, 0.5, -SELECTED_INNER_SIZE / 2)
	end

	-- Get card color
	local cardColor = inner and inner.BackgroundColor3 or Color3.new(1, 1, 1)

	-- Show selection border matching the card color
	local stroke = button:FindFirstChildOfClass("UIStroke")
	if stroke then
		stroke.Thickness = SELECTED_BORDER_THICKNESS
		stroke.Color = cardColor
		stroke.Transparency = 0
	end

	-- Background gap also uses the card color (darker)
	button.BackgroundColor3 = cardColor
	button.BackgroundTransparency = 0.5
end

local function clearSelectedVisual(button)
	-- Restore card to full size
	local inner = button:FindFirstChild("InnerCard")
	if inner then
		inner.Size = UDim2.new(1, 0, 1, 0)
		inner.Position = UDim2.new(0, 0, 0, 0)
	end

	-- Hide border
	local stroke = button:FindFirstChildOfClass("UIStroke")
	if stroke then
		stroke.Thickness = 2
		stroke.Color = Color3.new(1, 1, 1)
		stroke.Transparency = 1
	end

	-- Hide button background (card fills the whole slot)
	button.BackgroundTransparency = 1
end

local function selectCard(cardId)
	-- Clear all
	for _, btn in slotButtons do
		clearSelectedVisual(btn)
	end

	if selectedCardId == cardId then
		selectedCardId = nil
		selectionChanged:Fire(nil)
	else
		selectedCardId = cardId
		if slotButtons[cardId] then
			applySelectedVisual(slotButtons[cardId])
		end
		selectionChanged:Fire(cardId)
	end
end

local function clearSelection()
	for _, btn in slotButtons do
		clearSelectedVisual(btn)
	end
	selectedCardId = nil
	selectionChanged:Fire(nil)
end

-- =====================
-- HOTBAR SLOTS
-- =====================
local function createSlot(cardId)
	local cardInfo = CardData.GetCardById(cardId)
	if not cardInfo then return end

	-- Outer button: acts as the selection container
	local button = Instance.new("TextButton")
	button.Name = cardId
	button.Size = UDim2.new(0, SLOT_SIZE, 0, SLOT_SIZE)
	button.BackgroundTransparency = 1
	button.BorderSizePixel = 0
	button.Text = ""
	button.Parent = hotbarFrame

	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 8)
	btnCorner.Parent = button

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 2
	stroke.Color = Color3.new(1, 1, 1)
	stroke.Transparency = 1
	stroke.Parent = button

	-- Inner card: the colored card that shrinks on selection
	local inner = Instance.new("Frame")
	inner.Name = "InnerCard"
	inner.Size = UDim2.new(1, 0, 1, 0)
	inner.Position = UDim2.new(0, 0, 0, 0)
	inner.BackgroundColor3 = cardInfo.color
	inner.BorderSizePixel = 0
	inner.Parent = button

	local innerCorner = Instance.new("UICorner")
	innerCorner.CornerRadius = UDim.new(0, 6)
	innerCorner.Parent = inner

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -4, 1, -4)
	label.Position = UDim2.new(0, 2, 0, 2)
	label.BackgroundTransparency = 1
	label.Text = cardInfo.name
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextScaled = true
	label.Font = Enum.Font.LuckiestGuy
	label.TextStrokeTransparency = 0.5
	label.Parent = inner

	button.MouseButton1Click:Connect(function()
		selectCard(cardId)
	end)

	slotButtons[cardId] = button
end

local function refreshHotbar(cardIds)
	for _, btn in slotButtons do
		btn:Destroy()
	end
	slotButtons = {}
	currentCardIds = cardIds
	selectedCardId = nil
	selectionChanged:Fire(nil)

	for _, cardId in cardIds do
		createSlot(cardId)
	end
end

InitInventoryEvent.OnClientEvent:Connect(refreshHotbar)

-- =====================
-- INVENTORY PANEL (toggle with "I")
-- =====================
local inventoryOpen = false

local invPanel = Instance.new("Frame")
invPanel.Name = "InventoryPanel"
invPanel.Size = UDim2.new(0, 340, 0, 400)
invPanel.Position = UDim2.new(0.5, -170, 0.5, -200)
invPanel.BackgroundColor3 = Color3.new(0.12, 0.12, 0.15)
invPanel.BackgroundTransparency = 0.05
invPanel.BorderSizePixel = 0
invPanel.Visible = false
invPanel.Parent = screenGui

local invCorner = Instance.new("UICorner")
invCorner.CornerRadius = UDim.new(0, 12)
invCorner.Parent = invPanel

local invStroke = Instance.new("UIStroke")
invStroke.Thickness = 2
invStroke.Color = Color3.new(0.3, 0.3, 0.4)
invStroke.Parent = invPanel

-- Title
local invTitle = Instance.new("TextLabel")
invTitle.Size = UDim2.new(1, 0, 0, 40)
invTitle.BackgroundTransparency = 1
invTitle.Text = "Inventory"
invTitle.TextColor3 = Color3.new(1, 1, 1)
invTitle.TextSize = 22
invTitle.Font = Enum.Font.LuckiestGuy
invTitle.Parent = invPanel

-- Close button
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -35, 0, 5)
closeBtn.BackgroundColor3 = Color3.new(0.8, 0.2, 0.2)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.new(1, 1, 1)
closeBtn.TextSize = 16
closeBtn.Font = Enum.Font.LuckiestGuy
closeBtn.BorderSizePixel = 0
closeBtn.Parent = invPanel

local closeBtnCorner = Instance.new("UICorner")
closeBtnCorner.CornerRadius = UDim.new(0, 6)
closeBtnCorner.Parent = closeBtn

-- Scrolling frame for cards
local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Name = "CardList"
scrollFrame.Size = UDim2.new(1, -20, 1, -50)
scrollFrame.Position = UDim2.new(0, 10, 0, 45)
scrollFrame.BackgroundTransparency = 1
scrollFrame.BorderSizePixel = 0
scrollFrame.ScrollBarThickness = 4
scrollFrame.ScrollBarImageColor3 = Color3.new(0.5, 0.5, 0.5)
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
scrollFrame.Parent = invPanel

local gridLayout = Instance.new("UIGridLayout")
gridLayout.CellSize = UDim2.new(0, 95, 0, 120)
gridLayout.CellPadding = UDim2.new(0, 10, 0, 10)
gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
gridLayout.Parent = scrollFrame

local function refreshInventoryPanel()
	for _, child in scrollFrame:GetChildren() do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	for _, cardId in currentCardIds do
		local cardInfo = CardData.GetCardById(cardId)
		if not cardInfo then continue end

		local card = Instance.new("Frame")
		card.Name = cardId
		card.BackgroundColor3 = cardInfo.color
		card.BorderSizePixel = 0
		card.Parent = scrollFrame

		local cardCorner = Instance.new("UICorner")
		cardCorner.CornerRadius = UDim.new(0, 8)
		cardCorner.Parent = card

		local cardStroke = Instance.new("UIStroke")
		cardStroke.Thickness = 1
		cardStroke.Color = Color3.new(0.8, 0.8, 0.8)
		cardStroke.Transparency = 0.5
		cardStroke.Parent = card

		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.new(1, -8, 0.5, 0)
		nameLabel.Position = UDim2.new(0, 4, 0.5, 0)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = cardInfo.name
		nameLabel.TextColor3 = Color3.new(1, 1, 1)
		nameLabel.TextScaled = true
		nameLabel.Font = Enum.Font.LuckiestGuy
		nameLabel.TextStrokeTransparency = 0.3
		nameLabel.Parent = card

		-- Card type label
		local typeLabel = Instance.new("TextLabel")
		typeLabel.Size = UDim2.new(1, -8, 0, 16)
		typeLabel.Position = UDim2.new(0, 4, 0, 4)
		typeLabel.BackgroundTransparency = 1
		typeLabel.Text = "Pokémon TCG"
		typeLabel.TextColor3 = Color3.new(1, 1, 1)
		typeLabel.TextSize = 10
		typeLabel.Font = Enum.Font.LuckiestGuy
		typeLabel.TextStrokeTransparency = 0.3
		typeLabel.TextXAlignment = Enum.TextXAlignment.Left
		typeLabel.Parent = card
	end
end

local function toggleInventory()
	inventoryOpen = not inventoryOpen
	if inventoryOpen then
		refreshInventoryPanel()
	end
	invPanel.Visible = inventoryOpen
end

closeBtn.MouseButton1Click:Connect(toggleInventory)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.F then
		toggleInventory()
	end
end)

-- =====================
-- EXPOSE FOR OTHER SCRIPTS
-- =====================
local getSelectedCard = Instance.new("BindableFunction")
getSelectedCard.Name = "GetSelectedCard"
getSelectedCard.OnInvoke = function()
	return selectedCardId
end
getSelectedCard.Parent = player

local clearEvent = Instance.new("BindableEvent")
clearEvent.Name = "ClearCardSelection"
clearEvent.Event:Connect(function()
	clearSelection()
end)
clearEvent.Parent = player
