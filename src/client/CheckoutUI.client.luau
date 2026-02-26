local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local OpenCheckoutEvent = Remotes:WaitForChild("OpenCheckout")
local SubmitChangeEvent = Remotes:WaitForChild("SubmitChange")
local CheckoutResultEvent = Remotes:WaitForChild("CheckoutResult")
local UpdateMoneyEvent = Remotes:WaitForChild("UpdateMoney")
local CloseCheckoutEvent = Remotes:WaitForChild("CloseCheckout")
local CancelCheckoutEvent = Remotes:WaitForChild("CancelCheckout")
local GetMoneyRemote = Remotes:WaitForChild("GetMoney")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local currentInput = ""
local checkoutOpen = false

-- =====================
-- MONEY DISPLAY (top-right)
-- =====================
local moneyGui = Instance.new("ScreenGui")
moneyGui.Name = "MoneyGui"
moneyGui.ResetOnSpawn = false
moneyGui.Parent = playerGui

local moneyFrame = Instance.new("Frame")
moneyFrame.Size = UDim2.new(0, 160, 0, 40)
moneyFrame.Position = UDim2.new(1, -170, 0, 10)
moneyFrame.BackgroundColor3 = Color3.new(0.1, 0.15, 0.1)
moneyFrame.BackgroundTransparency = 0.2
moneyFrame.BorderSizePixel = 0
moneyFrame.Parent = moneyGui

local moneyCorner = Instance.new("UICorner")
moneyCorner.CornerRadius = UDim.new(0, 8)
moneyCorner.Parent = moneyFrame

local moneyStroke = Instance.new("UIStroke")
moneyStroke.Thickness = 2
moneyStroke.Color = Color3.new(0.2, 0.6, 0.2)
moneyStroke.Parent = moneyFrame

local moneyIcon = Instance.new("TextLabel")
moneyIcon.Size = UDim2.new(0, 30, 1, 0)
moneyIcon.Position = UDim2.new(0, 8, 0, 0)
moneyIcon.BackgroundTransparency = 1
moneyIcon.Text = "$"
moneyIcon.TextColor3 = Color3.new(0.3, 1, 0.3)
moneyIcon.TextSize = 24
moneyIcon.Font = Enum.Font.LuckiestGuy
moneyIcon.Parent = moneyFrame

local moneyLabel = Instance.new("TextLabel")
moneyLabel.Name = "MoneyAmount"
moneyLabel.Size = UDim2.new(1, -45, 1, 0)
moneyLabel.Position = UDim2.new(0, 38, 0, 0)
moneyLabel.BackgroundTransparency = 1
moneyLabel.Text = "0"
moneyLabel.TextColor3 = Color3.new(0.3, 1, 0.3)
moneyLabel.TextSize = 22
moneyLabel.Font = Enum.Font.LuckiestGuy
moneyLabel.TextXAlignment = Enum.TextXAlignment.Right
moneyLabel.Parent = moneyFrame

UpdateMoneyEvent.OnClientEvent:Connect(function(amount)
	moneyLabel.Text = tostring(amount)
end)

-- Fetch initial balance from server (solves race condition)
local initialMoney = GetMoneyRemote:InvokeServer()
moneyLabel.Text = tostring(initialMoney)

-- =====================
-- CASH REGISTER UI
-- =====================
local registerGui = Instance.new("ScreenGui")
registerGui.Name = "RegisterGui"
registerGui.ResetOnSpawn = false
registerGui.Parent = playerGui

-- Dark overlay
local overlay = Instance.new("Frame")
overlay.Size = UDim2.new(1, 0, 1, 0)
overlay.BackgroundColor3 = Color3.new(0, 0, 0)
overlay.BackgroundTransparency = 0.5
overlay.BorderSizePixel = 0
overlay.Visible = false
overlay.Parent = registerGui

-- Main register panel
local panel = Instance.new("Frame")
panel.Name = "RegisterPanel"
panel.Size = UDim2.new(0, 400, 0, 530)
panel.Position = UDim2.new(0.5, -200, 0.5, -265)
panel.BackgroundColor3 = Color3.new(0.08, 0.08, 0.1)
panel.BorderSizePixel = 0
panel.Parent = overlay

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 12)
panelCorner.Parent = panel

local panelStroke = Instance.new("UIStroke")
panelStroke.Thickness = 2
panelStroke.Color = Color3.new(0.3, 0.3, 0.4)
panelStroke.Parent = panel

-- Title bar
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 45)
titleBar.BackgroundColor3 = Color3.new(0.15, 0.15, 0.2)
titleBar.BorderSizePixel = 0
titleBar.Parent = panel

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 12)
titleCorner.Parent = titleBar

local titleFix = Instance.new("Frame")
titleFix.Size = UDim2.new(1, 0, 0, 12)
titleFix.Position = UDim2.new(0, 0, 1, -12)
titleFix.BackgroundColor3 = Color3.new(0.15, 0.15, 0.2)
titleFix.BorderSizePixel = 0
titleFix.Parent = titleBar

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, 0, 1, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "CASH REGISTER"
titleLabel.TextColor3 = Color3.new(1, 1, 1)
titleLabel.TextSize = 18
titleLabel.Font = Enum.Font.LuckiestGuy
titleLabel.Parent = titleBar

-- Close button
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -38, 0, 8)
closeBtn.BackgroundColor3 = Color3.new(0.7, 0.2, 0.2)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.new(1, 1, 1)
closeBtn.TextSize = 14
closeBtn.Font = Enum.Font.LuckiestGuy
closeBtn.BorderSizePixel = 0
closeBtn.ZIndex = 3
closeBtn.Parent = panel

local closeBtnCorner = Instance.new("UICorner")
closeBtnCorner.CornerRadius = UDim.new(0, 6)
closeBtnCorner.Parent = closeBtn

-- Card display area (scrollable for multiple cards)
local cardDisplay = Instance.new("Frame")
cardDisplay.Name = "CardDisplay"
cardDisplay.Size = UDim2.new(1, -30, 0, 60)
cardDisplay.Position = UDim2.new(0, 15, 0, 55)
cardDisplay.BackgroundColor3 = Color3.new(0.12, 0.12, 0.15)
cardDisplay.BorderSizePixel = 0
cardDisplay.ClipsDescendants = true
cardDisplay.Parent = panel

local cardDisplayCorner = Instance.new("UICorner")
cardDisplayCorner.CornerRadius = UDim.new(0, 8)
cardDisplayCorner.Parent = cardDisplay

local cardListLayout = Instance.new("UIListLayout")
cardListLayout.FillDirection = Enum.FillDirection.Vertical
cardListLayout.Padding = UDim.new(0, 2)
cardListLayout.Parent = cardDisplay

-- =====================
-- RECEIPT AREA
-- =====================
local receiptFrame = Instance.new("Frame")
receiptFrame.Size = UDim2.new(1, -30, 0, 120)
receiptFrame.Position = UDim2.new(0, 15, 0, 123)
receiptFrame.BackgroundColor3 = Color3.new(0.95, 0.93, 0.85)
receiptFrame.BorderSizePixel = 0
receiptFrame.Parent = panel

local receiptCorner = Instance.new("UICorner")
receiptCorner.CornerRadius = UDim.new(0, 6)
receiptCorner.Parent = receiptFrame

local function makeReceiptLine(yPos, leftText, rightText, rightColor, fontSize)
	local left = Instance.new("TextLabel")
	left.Size = UDim2.new(0.5, -5, 0, 28)
	left.Position = UDim2.new(0, 12, 0, yPos)
	left.BackgroundTransparency = 1
	left.Text = leftText
	left.TextColor3 = Color3.new(0.2, 0.2, 0.2)
	left.TextSize = fontSize or 15
	left.Font = Enum.Font.LuckiestGuy
	left.TextXAlignment = Enum.TextXAlignment.Left
	left.Parent = receiptFrame

	local right = Instance.new("TextLabel")
	right.Name = leftText
	right.Size = UDim2.new(0.5, -12, 0, 28)
	right.Position = UDim2.new(0.5, 0, 0, yPos)
	right.BackgroundTransparency = 1
	right.Text = rightText
	right.TextColor3 = rightColor or Color3.new(0.1, 0.1, 0.1)
	right.TextSize = fontSize or 17
	right.Font = Enum.Font.LuckiestGuy
	right.TextXAlignment = Enum.TextXAlignment.Right
	right.Parent = receiptFrame

	return right
end

local totalValue = makeReceiptLine(6, "Total", "$0")
local paymentValue = makeReceiptLine(30, "Customer Pays", "$0", Color3.new(0.1, 0.4, 0.1))

-- Separator
local separator = Instance.new("Frame")
separator.Size = UDim2.new(1, -24, 0, 2)
separator.Position = UDim2.new(0, 12, 0, 58)
separator.BackgroundColor3 = Color3.new(0.6, 0.6, 0.6)
separator.BorderSizePixel = 0
separator.Parent = receiptFrame

-- Change due (highlighted)
local changeDueLabel = Instance.new("TextLabel")
changeDueLabel.Size = UDim2.new(0.5, -5, 0, 28)
changeDueLabel.Position = UDim2.new(0, 12, 0, 64)
changeDueLabel.BackgroundTransparency = 1
changeDueLabel.Text = "CHANGE DUE"
changeDueLabel.TextColor3 = Color3.new(0.6, 0.1, 0.1)
changeDueLabel.TextSize = 14
changeDueLabel.Font = Enum.Font.LuckiestGuy
changeDueLabel.TextXAlignment = Enum.TextXAlignment.Left
changeDueLabel.Parent = receiptFrame

local changeDueValue = Instance.new("TextLabel")
changeDueValue.Name = "ChangeDue"
changeDueValue.Size = UDim2.new(0.5, -12, 0, 28)
changeDueValue.Position = UDim2.new(0.5, 0, 0, 64)
changeDueValue.BackgroundTransparency = 1
changeDueValue.Text = "$0"
changeDueValue.TextColor3 = Color3.new(0.8, 0.1, 0.1)
changeDueValue.TextSize = 22
changeDueValue.Font = Enum.Font.LuckiestGuy
changeDueValue.TextXAlignment = Enum.TextXAlignment.Right
changeDueValue.Parent = receiptFrame

-- Hint text
local hintLabel = Instance.new("TextLabel")
hintLabel.Size = UDim2.new(1, -24, 0, 16)
hintLabel.Position = UDim2.new(0, 12, 0, 96)
hintLabel.BackgroundTransparency = 1
hintLabel.Text = "Enter this amount below and press OK"
hintLabel.TextColor3 = Color3.new(0.4, 0.4, 0.4)
hintLabel.TextSize = 10
hintLabel.Font = Enum.Font.LuckiestGuy
hintLabel.Parent = receiptFrame

-- =====================
-- LED-style input display
-- =====================
local inputDisplay = Instance.new("Frame")
inputDisplay.Size = UDim2.new(1, -30, 0, 50)
inputDisplay.Position = UDim2.new(0, 15, 0, 250)
inputDisplay.BackgroundColor3 = Color3.new(0.02, 0.05, 0.02)
inputDisplay.BorderSizePixel = 0
inputDisplay.Parent = panel

local inputDisplayCorner = Instance.new("UICorner")
inputDisplayCorner.CornerRadius = UDim.new(0, 6)
inputDisplayCorner.Parent = inputDisplay

local inputDisplayStroke = Instance.new("UIStroke")
inputDisplayStroke.Thickness = 2
inputDisplayStroke.Color = Color3.new(0.1, 0.3, 0.1)
inputDisplayStroke.Parent = inputDisplay

local inputLabel = Instance.new("TextLabel")
inputLabel.Name = "InputLabel"
inputLabel.Size = UDim2.new(1, -16, 1, 0)
inputLabel.Position = UDim2.new(0, 8, 0, 0)
inputLabel.BackgroundTransparency = 1
inputLabel.Text = "$ 0"
inputLabel.TextColor3 = Color3.new(0.2, 1, 0.2)
inputLabel.TextSize = 32
inputLabel.Font = Enum.Font.LuckiestGuy
inputLabel.TextXAlignment = Enum.TextXAlignment.Right
inputLabel.Parent = inputDisplay

-- Status/feedback label
local statusLabel = Instance.new("TextLabel")
statusLabel.Name = "StatusLabel"
statusLabel.Size = UDim2.new(1, -30, 0, 25)
statusLabel.Position = UDim2.new(0, 15, 0, 305)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = ""
statusLabel.TextColor3 = Color3.new(1, 0.3, 0.3)
statusLabel.TextSize = 14
statusLabel.Font = Enum.Font.LuckiestGuy
statusLabel.Parent = panel

-- =====================
-- NUMPAD
-- =====================
local numpadFrame = Instance.new("Frame")
numpadFrame.Size = UDim2.new(0, 260, 0, 130)
numpadFrame.Position = UDim2.new(0.5, -130, 0, 335)
numpadFrame.BackgroundTransparency = 1
numpadFrame.Parent = panel

local numpadGrid = Instance.new("UIGridLayout")
numpadGrid.CellSize = UDim2.new(0, 78, 0, 38)
numpadGrid.CellPadding = UDim2.new(0, 8, 0, 4)
numpadGrid.HorizontalAlignment = Enum.HorizontalAlignment.Center
numpadGrid.SortOrder = Enum.SortOrder.LayoutOrder
numpadGrid.Parent = numpadFrame

local function makeNumpadButton(text, order, bgColor, textColor)
	local btn = Instance.new("TextButton")
	btn.Name = "Num_" .. text
	btn.LayoutOrder = order
	btn.BackgroundColor3 = bgColor or Color3.new(0.2, 0.2, 0.25)
	btn.Text = text
	btn.TextColor3 = textColor or Color3.new(1, 1, 1)
	btn.TextSize = 20
	btn.Font = Enum.Font.LuckiestGuy
	btn.BorderSizePixel = 0
	btn.Parent = numpadFrame

	local bc = Instance.new("UICorner")
	bc.CornerRadius = UDim.new(0, 6)
	bc.Parent = btn

	return btn
end

makeNumpadButton("1", 1)
makeNumpadButton("2", 2)
makeNumpadButton("3", 3)
makeNumpadButton("4", 4)
makeNumpadButton("5", 5)
makeNumpadButton("6", 6)
makeNumpadButton("7", 7)
makeNumpadButton("8", 8)
makeNumpadButton("9", 9)
makeNumpadButton("C", 10, Color3.new(0.6, 0.15, 0.15))
makeNumpadButton("0", 11)
makeNumpadButton("OK", 12, Color3.new(0.1, 0.5, 0.1))

-- =====================
-- INPUT LOGIC
-- =====================
local function updateDisplay()
	if currentInput == "" then
		inputLabel.Text = "$ 0"
	else
		inputLabel.Text = "$ " .. currentInput
	end
end

local function pressNumber(num)
	if not checkoutOpen then return end
	if #currentInput >= 5 then return end
	if currentInput == "0" and num == "0" then return end
	if currentInput == "0" and num ~= "0" then
		currentInput = num
	else
		currentInput = currentInput .. num
	end
	updateDisplay()
end

local function pressClear()
	if not checkoutOpen then return end
	currentInput = ""
	statusLabel.Text = ""
	updateDisplay()
end

local function pressOK()
	if not checkoutOpen then return end
	local amount = tonumber(currentInput) or 0
	SubmitChangeEvent:FireServer(amount)
end

-- Connect numpad buttons
for _, btn in numpadFrame:GetChildren() do
	if btn:IsA("TextButton") then
		btn.MouseButton1Click:Connect(function()
			local text = btn.Text
			if text == "C" then
				pressClear()
			elseif text == "OK" then
				pressOK()
			else
				pressNumber(text)
			end
		end)
	end
end

-- =====================
-- OPEN / CLOSE
-- =====================
local function openRegister(data)
	checkoutOpen = true
	currentInput = ""
	overlay.Visible = true

	-- Clear previous card entries
	for _, child in cardDisplay:GetChildren() do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	-- Add card entries
	for i, item in data.items do
		local entry = Instance.new("Frame")
		entry.Size = UDim2.new(1, 0, 0, 28)
		entry.LayoutOrder = i
		entry.BackgroundColor3 = Color3.new(item.cardColor.R, item.cardColor.G, item.cardColor.B)
		entry.BackgroundTransparency = 0.3
		entry.BorderSizePixel = 0
		entry.Parent = cardDisplay

		local name = Instance.new("TextLabel")
		name.Size = UDim2.new(0.65, -5, 1, 0)
		name.Position = UDim2.new(0, 8, 0, 0)
		name.BackgroundTransparency = 1
		name.Text = item.cardName
		name.TextColor3 = Color3.new(1, 1, 1)
		name.TextSize = 13
		name.Font = Enum.Font.LuckiestGuy
		name.TextXAlignment = Enum.TextXAlignment.Left
		name.TextStrokeTransparency = 0.3
		name.Parent = entry

		local price = Instance.new("TextLabel")
		price.Size = UDim2.new(0.35, -8, 1, 0)
		price.Position = UDim2.new(0.65, 0, 0, 0)
		price.BackgroundTransparency = 1
		price.Text = "$" .. item.shelfPrice
		price.TextColor3 = Color3.new(1, 1, 0.4)
		price.TextSize = 13
		price.Font = Enum.Font.LuckiestGuy
		price.TextXAlignment = Enum.TextXAlignment.Right
		price.Parent = entry
	end

	-- Adjust card display height based on item count
	local displayHeight = math.max(28, #data.items * 30)
	cardDisplay.Size = UDim2.new(1, -30, 0, displayHeight)

	-- Set receipt values
	totalValue.Text = "$" .. data.totalPrice
	paymentValue.Text = "$" .. data.payment

	-- Calculate and show change due
	local changeDue = data.payment - data.totalPrice
	changeDueValue.Text = "$" .. changeDue

	statusLabel.Text = ""
	updateDisplay()
end

local function closeRegister()
	checkoutOpen = false
	overlay.Visible = false
	currentInput = ""
end

closeBtn.MouseButton1Click:Connect(function()
	closeRegister()
	CancelCheckoutEvent:FireServer()
end)

-- =====================
-- SERVER EVENTS
-- =====================
OpenCheckoutEvent.OnClientEvent:Connect(function(data)
	openRegister(data)
end)

CheckoutResultEvent.OnClientEvent:Connect(function(success, message)
	if success then
		statusLabel.TextColor3 = Color3.new(0.2, 1, 0.2)
		statusLabel.Text = message
		-- Disable input while waiting for next customer
		checkoutOpen = false
		currentInput = ""
		updateDisplay()
	else
		statusLabel.TextColor3 = Color3.new(1, 0.3, 0.3)
		statusLabel.Text = message
		local originalPos = inputDisplay.Position
		for i = 1, 4 do
			inputDisplay.Position = originalPos + UDim2.new(0, 5, 0, 0)
			task.wait(0.05)
			inputDisplay.Position = originalPos + UDim2.new(0, -5, 0, 0)
			task.wait(0.05)
		end
		inputDisplay.Position = originalPos
	end
end)

-- Server says no more customers in queue
CloseCheckoutEvent.OnClientEvent:Connect(function()
	task.wait(1)
	closeRegister()
end)
