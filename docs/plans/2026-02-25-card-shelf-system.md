# Card Shop Shelf System Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a system where players spawn with 6 Pokemon TCG cards in a hotbar and can place/remove them on a 36-slot shelf display.

**Architecture:** Client-server model using RemoteEvents. Server owns inventory and shelf state; client handles UI (hotbar ScreenGui) and shelf interaction (mouse raycast + SelectionBox). Shared CardData module defines card properties.

**Tech Stack:** Roblox Luau, Rojo (file sync), RemoteEvents, ScreenGui, SurfaceGui, SelectionBox, BillboardGui

---

### Task 1: CardData Shared Module

**Files:**
- Create: `src/shared/CardData.luau`

**Step 1: Create the CardData module with card definitions**

```lua
-- src/shared/CardData.luau
local CardData = {}

CardData.Cards = {
	{
		id = "charizard_ex",
		name = "Charizard EX",
		color = Color3.new(1, 0.4, 0),
	},
	{
		id = "pikachu_vmax",
		name = "Pikachu VMAX",
		color = Color3.new(1, 0.9, 0),
	},
	{
		id = "mewtwo_gx",
		name = "Mewtwo GX",
		color = Color3.new(0.6, 0.2, 0.8),
	},
	{
		id = "blastoise_ex",
		name = "Blastoise EX",
		color = Color3.new(0.2, 0.4, 1),
	},
	{
		id = "gengar_vmax",
		name = "Gengar VMAX",
		color = Color3.new(0.4, 0.1, 0.5),
	},
	{
		id = "rayquaza_v",
		name = "Rayquaza V",
		color = Color3.new(0.2, 0.8, 0.3),
	},
}

function CardData.GetCardById(id: string)
	for _, card in CardData.Cards do
		if card.id == id then
			return card
		end
	end
	return nil
end

return CardData
```

**Step 2: Verify via Rojo sync + run_code**

Run in Studio: `require(game.ReplicatedStorage.CardData)` and print card count.
Expected: 6 cards loaded.

**Step 3: Commit**

```bash
git add src/shared/CardData.luau
git commit -m "feat: add CardData shared module with 6 Pokemon TCG cards"
```

---

### Task 2: RemoteEvents Setup

**Files:**
- Create: `src/server/SetupRemotes.server.luau`

**Step 1: Create server script that creates RemoteEvents on startup**

```lua
-- src/server/SetupRemotes.server.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local remotes = Instance.new("Folder")
remotes.Name = "Remotes"
remotes.Parent = ReplicatedStorage

local placeCard = Instance.new("RemoteEvent")
placeCard.Name = "PlaceCard"
placeCard.Parent = remotes

local removeCard = Instance.new("RemoteEvent")
removeCard.Name = "RemoveCard"
removeCard.Parent = remotes

local initInventory = Instance.new("RemoteEvent")
initInventory.Name = "InitInventory"
initInventory.Parent = remotes

local updateSlot = Instance.new("RemoteEvent")
updateSlot.Name = "UpdateSlot"
updateSlot.Parent = remotes
```

**Step 2: Verify remotes exist after play**

Run in play mode: check `game.ReplicatedStorage.Remotes` has 4 children.

**Step 3: Commit**

```bash
git add src/server/SetupRemotes.server.luau
git commit -m "feat: add RemoteEvents setup for card shelf system"
```

---

### Task 3: Shelf Slot Setup (Server)

**Files:**
- Create: `src/server/ShelfManager.server.luau`

**Step 1: Create ShelfManager that converts shelf products into named slots**

```lua
-- src/server/ShelfManager.server.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local CardData = require(ReplicatedStorage:WaitForChild("CardData"))

-- Wait for remotes
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local PlaceCardEvent = Remotes:WaitForChild("PlaceCard")
local RemoveCardEvent = Remotes:WaitForChild("RemoveCard")
local UpdateSlotEvent = Remotes:WaitForChild("UpdateSlot")

-- State: slotName -> { cardId: string, playerId: number } or nil
local slotState = {}

-- Find and setup shelf slots
local function setupSlots()
	local shelf = workspace:FindFirstChild("ShopShelfDisplay", true)
	if not shelf then
		warn("ShopShelfDisplay not found")
		return
	end

	local marketShelf = shelf:FindFirstChild("Model")
	if marketShelf then
		marketShelf = marketShelf:FindFirstChild("Model")
	end
	if marketShelf then
		marketShelf = marketShelf:FindFirstChild("Market Shelf")
	end
	if not marketShelf then
		warn("Market Shelf not found")
		return
	end

	local slotIndex = 0
	for _, child in marketShelf:GetChildren() do
		if child:IsA("Part") and child.Size == Vector3.new(2, 2, 2) then
			slotIndex += 1
			child.Name = "Slot_" .. slotIndex

			-- Remove decals
			for _, decal in child:GetChildren() do
				if decal:IsA("Decal") then
					decal:Destroy()
				end
			end

			-- Make semi-transparent placeholder
			child.Transparency = 0.7
			child.Color = Color3.new(0.5, 0.5, 0.5)
			child.Material = Enum.Material.SmoothPlastic

			-- Add CollectionService tag for client detection
			child:SetAttribute("IsSlot", true)
			child:SetAttribute("SlotIndex", slotIndex)

			slotState[child.Name] = nil
		end
	end

	print("[ShelfManager] Setup " .. slotIndex .. " slots")
end

-- Handle place card request
PlaceCardEvent.OnServerEvent:Connect(function(player, slotName, cardId)
	-- Validate card exists
	local cardInfo = CardData.GetCardById(cardId)
	if not cardInfo then
		warn("[ShelfManager] Invalid card: " .. tostring(cardId))
		return
	end

	-- Validate slot exists and is empty
	if slotState[slotName] ~= nil then
		warn("[ShelfManager] Slot occupied: " .. slotName)
		return
	end

	-- Find the slot part
	local shelf = workspace:FindFirstChild("ShopShelfDisplay", true)
	local slotPart = shelf:FindFirstChild(slotName, true)
	if not slotPart then
		warn("[ShelfManager] Slot not found: " .. slotName)
		return
	end

	-- Update state
	slotState[slotName] = { cardId = cardId, playerId = player.UserId }

	-- Update visual
	slotPart.Transparency = 0
	slotPart.Color = cardInfo.color
	slotPart.Material = Enum.Material.SmoothPlastic

	-- Add SurfaceGui with card name
	local existing = slotPart:FindFirstChild("CardLabel")
	if existing then existing:Destroy() end

	local surfaceGui = Instance.new("SurfaceGui")
	surfaceGui.Name = "CardLabel"
	surfaceGui.Face = Enum.NormalId.Front
	surfaceGui.Parent = slotPart

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = cardInfo.name
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.Parent = surfaceGui

	-- Notify all clients
	UpdateSlotEvent:FireAllClients(slotName, cardId, player.UserId)

	print("[ShelfManager] " .. player.Name .. " placed " .. cardInfo.name .. " in " .. slotName)
end)

-- Handle remove card request
RemoveCardEvent.OnServerEvent:Connect(function(player, slotName)
	local state = slotState[slotName]
	if not state then
		warn("[ShelfManager] Slot already empty: " .. slotName)
		return
	end

	-- Only the player who placed it can remove it
	if state.playerId ~= player.UserId then
		warn("[ShelfManager] Not your card")
		return
	end

	local cardId = state.cardId

	-- Find slot part
	local shelf = workspace:FindFirstChild("ShopShelfDisplay", true)
	local slotPart = shelf:FindFirstChild(slotName, true)
	if not slotPart then return end

	-- Reset visual
	slotPart.Transparency = 0.7
	slotPart.Color = Color3.new(0.5, 0.5, 0.5)

	local label = slotPart:FindFirstChild("CardLabel")
	if label then label:Destroy() end

	-- Clear state
	slotState[slotName] = nil

	-- Notify all clients
	UpdateSlotEvent:FireAllClients(slotName, nil, nil)

	print("[ShelfManager] " .. player.Name .. " removed card from " .. slotName)
end)

setupSlots()
```

**Step 2: Verify slots are created**

Run in play mode and check that 36 slots exist with `IsSlot` attribute.

**Step 3: Commit**

```bash
git add src/server/ShelfManager.server.luau
git commit -m "feat: add ShelfManager - slot setup and place/remove card logic"
```

---

### Task 4: Inventory Manager (Server)

**Files:**
- Create: `src/server/InventoryManager.server.luau`

**Step 1: Create InventoryManager that gives cards on join and tracks inventory**

```lua
-- src/server/InventoryManager.server.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local CardData = require(ReplicatedStorage:WaitForChild("CardData"))

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local InitInventoryEvent = Remotes:WaitForChild("InitInventory")
local PlaceCardEvent = Remotes:WaitForChild("PlaceCard")
local RemoveCardEvent = Remotes:WaitForChild("RemoveCard")

-- State: playerId -> { cardId = true, ... }
local inventories = {}

local function giveInitialCards(player)
	local inv = {}
	for _, card in CardData.Cards do
		inv[card.id] = true
	end
	inventories[player.UserId] = inv

	-- Send to client
	local cardIds = {}
	for id in inv do
		table.insert(cardIds, id)
	end
	InitInventoryEvent:FireClient(player, cardIds)
	print("[InventoryManager] Gave " .. #cardIds .. " cards to " .. player.Name)
end

-- When placing a card, remove from inventory
PlaceCardEvent.OnServerEvent:Connect(function(player, slotName, cardId)
	local inv = inventories[player.UserId]
	if not inv or not inv[cardId] then
		warn("[InventoryManager] Player doesn't have card: " .. tostring(cardId))
		return
	end
	inv[cardId] = nil
end)

-- When removing a card, add back to inventory
RemoveCardEvent.OnServerEvent:Connect(function(player, slotName)
	-- We need to know which card was in the slot
	-- The ShelfManager handles the slot state, we listen for UpdateSlot
end)

-- Listen for slot updates to restore cards to inventory
Remotes:WaitForChild("UpdateSlot") -- ensure exists

-- Track what card each player removes (via attribute on slot)
-- Simpler approach: trust ShelfManager and re-add on RemoveCard
-- We'll store placed cards mapping: playerId -> { slotName = cardId }
local placedCards = {}

PlaceCardEvent.OnServerEvent:Connect(function(player, slotName, cardId)
	if not placedCards[player.UserId] then
		placedCards[player.UserId] = {}
	end
	placedCards[player.UserId][slotName] = cardId
end)

RemoveCardEvent.OnServerEvent:Connect(function(player, slotName)
	local placed = placedCards[player.UserId]
	if placed and placed[slotName] then
		local cardId = placed[slotName]
		local inv = inventories[player.UserId]
		if inv then
			inv[cardId] = true
		end
		placed[slotName] = nil

		-- Notify client their inventory updated
		local cardIds = {}
		for id in inv do
			table.insert(cardIds, id)
		end
		InitInventoryEvent:FireClient(player, cardIds)
	end
end)

-- Cleanup on leave
Players.PlayerRemoving:Connect(function(player)
	inventories[player.UserId] = nil
	placedCards[player.UserId] = nil
end)

Players.PlayerAdded:Connect(giveInitialCards)

-- Handle players already in game (studio testing)
for _, player in Players:GetPlayers() do
	task.spawn(giveInitialCards, player)
end
```

**Step 2: Verify cards are given on join**

Run in play mode and check output log for "Gave 6 cards".

**Step 3: Commit**

```bash
git add src/server/InventoryManager.server.luau
git commit -m "feat: add InventoryManager - initial cards and inventory tracking"
```

---

### Task 5: Hotbar UI (Client)

**Files:**
- Create: `src/client/HotbarController.client.luau`

**Step 1: Create hotbar GUI that shows inventory cards**

```lua
-- src/client/HotbarController.client.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local CardData = require(ReplicatedStorage:WaitForChild("CardData"))

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local InitInventoryEvent = Remotes:WaitForChild("InitInventory")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Selected card state
local selectedCardId = nil

-- Create hotbar GUI
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

local padding = Instance.new("UIPadding")
padding.PaddingLeft = UDim.new(0, 5)
padding.PaddingRight = UDim.new(0, 5)
padding.Parent = hotbarFrame

local slotButtons = {}

local function createSlot(cardId)
	local cardInfo = CardData.GetCardById(cardId)
	if not cardInfo then return end

	local button = Instance.new("TextButton")
	button.Name = cardId
	button.Size = UDim2.new(0, 60, 0, 60)
	button.BackgroundColor3 = cardInfo.color
	button.BorderSizePixel = 0
	button.Text = ""
	button.Parent = hotbarFrame

	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 6)
	btnCorner.Parent = button

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -4, 1, -4)
	label.Position = UDim2.new(0, 2, 0, 2)
	label.BackgroundTransparency = 1
	label.Text = cardInfo.name
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.TextStrokeTransparency = 0.5
	label.Parent = button

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 2
	stroke.Color = Color3.new(1, 1, 1)
	stroke.Transparency = 1
	stroke.Parent = button

	button.MouseButton1Click:Connect(function()
		-- Deselect previous
		for _, btn in slotButtons do
			local s = btn:FindFirstChildOfClass("UIStroke")
			if s then s.Transparency = 1 end
		end

		if selectedCardId == cardId then
			selectedCardId = nil
		else
			selectedCardId = cardId
			stroke.Transparency = 0
		end
	end)

	slotButtons[cardId] = button
end

local function refreshHotbar(cardIds)
	-- Clear existing
	for _, btn in slotButtons do
		btn:Destroy()
	end
	slotButtons = {}
	selectedCardId = nil

	-- Create new slots
	for _, cardId in cardIds do
		createSlot(cardId)
	end
end

-- Listen for inventory updates
InitInventoryEvent.OnClientEvent:Connect(refreshHotbar)

-- Expose selected card for ShelfInteraction
local module = {}
module.GetSelectedCardId = function()
	return selectedCardId
end
module.ClearSelection = function()
	selectedCardId = nil
	for _, btn in slotButtons do
		local s = btn:FindFirstChildOfClass("UIStroke")
		if s then s.Transparency = 1 end
	end
end

-- Store in ReplicatedStorage for cross-script access
local bindable = Instance.new("BindableFunction")
bindable.Name = "GetSelectedCard"
bindable.OnInvoke = function()
	return selectedCardId
end
bindable.Parent = player

local clearBindable = Instance.new("BindableEvent")
clearBindable.Name = "ClearCardSelection"
clearBindable.Event:Connect(function()
	module.ClearSelection()
end)
clearBindable.Parent = player
```

**Step 2: Verify hotbar renders on play**

Run play mode and check that 6 colored buttons appear at bottom of screen.

**Step 3: Commit**

```bash
git add src/client/HotbarController.client.luau
git commit -m "feat: add HotbarController - card inventory UI with selection"
```

---

### Task 6: Shelf Interaction (Client)

**Files:**
- Create: `src/client/ShelfInteraction.client.luau`

**Step 1: Create shelf interaction script with hover highlight and click to place/remove**

```lua
-- src/client/ShelfInteraction.client.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local PlaceCardEvent = Remotes:WaitForChild("PlaceCard")
local RemoveCardEvent = Remotes:WaitForChild("RemoveCard")
local UpdateSlotEvent = Remotes:WaitForChild("UpdateSlot")

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local camera = workspace.CurrentCamera

-- Wait for bindables from HotbarController
local getSelectedCard = player:WaitForChild("GetSelectedCard")
local clearSelection = player:WaitForChild("ClearCardSelection")

-- Track slot states locally
local localSlotState = {} -- slotName -> cardId or nil

-- Selection box for hover
local selectionBox = Instance.new("SelectionBox")
selectionBox.Color3 = Color3.new(0.2, 0.5, 1)
selectionBox.LineThickness = 0.05
selectionBox.SurfaceTransparency = 0.7
selectionBox.SurfaceColor3 = Color3.new(0.3, 0.6, 1)
selectionBox.Parent = player.PlayerGui

local currentHover = nil

-- Hover detection
RunService.RenderStepped:Connect(function()
	local target = mouse.Target
	if target and target:GetAttribute("IsSlot") then
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

-- Click handling
mouse.Button1Down:Connect(function()
	if not currentHover then return end

	local slotName = currentHover.Name
	local slotOccupied = localSlotState[slotName]

	if slotOccupied then
		-- Remove card from slot
		RemoveCardEvent:FireServer(slotName)
	else
		-- Place card in slot
		local cardId = getSelectedCard:Invoke()
		if not cardId then return end
		PlaceCardEvent:FireServer(slotName, cardId)
		clearSelection:Fire()
	end
end)

-- Listen for slot updates from server
UpdateSlotEvent.OnClientEvent:Connect(function(slotName, cardId, playerId)
	localSlotState[slotName] = cardId
end)
```

**Step 2: Verify full interaction loop**

Run play mode:
1. Select a card in hotbar (white border appears)
2. Hover over a slot (blue highlight)
3. Click to place (slot becomes card color with name)
4. Click occupied slot (card returns to hotbar)

**Step 3: Commit**

```bash
git add src/client/ShelfInteraction.client.luau
git commit -m "feat: add ShelfInteraction - hover highlight and click to place/remove"
```

---

### Task 7: Integration Test

**Step 1: Run full play test**

Enter play mode and verify:
- [ ] 6 cards appear in hotbar at bottom of screen
- [ ] Clicking a card highlights it with white border
- [ ] Hovering over shelf slots shows blue SelectionBox
- [ ] Clicking empty slot with selected card places it (slot becomes colored with name)
- [ ] Clicking occupied slot removes card and returns it to hotbar
- [ ] Cards can be re-placed after removal

**Step 2: Fix any issues found**

**Step 3: Final commit**

```bash
git add -A
git commit -m "feat: complete card shelf system MVP"
```
