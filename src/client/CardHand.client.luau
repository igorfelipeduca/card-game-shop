local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local CardData = require(ReplicatedStorage:WaitForChild("CardData"))

local player = Players.LocalPlayer
local selectionChanged = player:WaitForChild("CardSelectionChanged")

local currentCardPart = nil

local function removeCardFromHand()
	if currentCardPart then
		currentCardPart:Destroy()
		currentCardPart = nil
	end
end

local function attachCardToHand(cardId)
	removeCardFromHand()

	if not cardId then return end

	local cardInfo = CardData.GetCardById(cardId)
	if not cardInfo then return end

	local character = player.Character
	if not character then return end

	local rightHand = character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm")
	if not rightHand then return end

	-- Create card part (thin rectangle like a card)
	local card = Instance.new("Part")
	card.Name = "HeldCard"
	card.Size = Vector3.new(1.4, 2, 0.05)
	card.Color = cardInfo.color
	card.Material = Enum.Material.SmoothPlastic
	card.CanCollide = false
	card.Massless = true
	card.Parent = character

	-- Card name on front
	local frontGui = Instance.new("SurfaceGui")
	frontGui.Name = "FrontLabel"
	frontGui.Face = Enum.NormalId.Front
	frontGui.Parent = card

	local frontLabel = Instance.new("TextLabel")
	frontLabel.Size = UDim2.new(1, 0, 1, 0)
	frontLabel.BackgroundTransparency = 1
	frontLabel.Text = cardInfo.name
	frontLabel.TextColor3 = Color3.new(1, 1, 1)
	frontLabel.TextScaled = true
	frontLabel.Font = Enum.Font.LuckiestGuy
	frontLabel.TextStrokeTransparency = 0.3
	frontLabel.Parent = frontGui

	-- Card name on back too
	local backGui = Instance.new("SurfaceGui")
	backGui.Name = "BackLabel"
	backGui.Face = Enum.NormalId.Back
	backGui.Parent = card

	local backLabel = Instance.new("TextLabel")
	backLabel.Size = UDim2.new(1, 0, 1, 0)
	backLabel.BackgroundTransparency = 1
	backLabel.Text = cardInfo.name
	backLabel.TextColor3 = Color3.new(1, 1, 1)
	backLabel.TextScaled = true
	backLabel.Font = Enum.Font.LuckiestGuy
	backLabel.TextStrokeTransparency = 0.3
	backLabel.Parent = backGui

	-- Weld to hand
	local weld = Instance.new("Weld")
	weld.Part0 = rightHand
	weld.Part1 = card
	-- Offset: slightly in front and to the side of the hand, tilted like holding a card
	weld.C0 = CFrame.new(0, -0.5, -0.5) * CFrame.Angles(math.rad(-10), math.rad(0), math.rad(0))
	weld.Parent = card

	currentCardPart = card
end

-- Listen for selection changes
selectionChanged.Event:Connect(function(cardId)
	attachCardToHand(cardId)
end)

-- Clean up on respawn
player.CharacterAdded:Connect(function()
	currentCardPart = nil
	-- Re-attach if card was selected
	task.wait(1)
	local getSelectedCard = player:FindFirstChild("GetSelectedCard")
	if getSelectedCard then
		local cardId = getSelectedCard:Invoke()
		if cardId then
			attachCardToHand(cardId)
		end
	end
end)
