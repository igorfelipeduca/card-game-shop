local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local DeliveryUpdateEvent = Remotes:WaitForChild("DeliveryUpdate")
local DeliveryArrivedEvent = Remotes:WaitForChild("DeliveryArrived")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- =====================
-- DELIVERY TRACKER UI (below money display)
-- =====================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DeliveryGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local tracker = Instance.new("Frame")
tracker.Name = "DeliveryTracker"
tracker.Size = UDim2.new(0, 200, 0, 60)
tracker.Position = UDim2.new(1, -210, 0, 100)
tracker.BackgroundColor3 = Color3.new(0.12, 0.1, 0.06)
tracker.BackgroundTransparency = 0.1
tracker.BorderSizePixel = 0
tracker.Visible = false
tracker.Parent = screenGui

local trackerCorner = Instance.new("UICorner")
trackerCorner.CornerRadius = UDim.new(0, 8)
trackerCorner.Parent = tracker

local trackerStroke = Instance.new("UIStroke")
trackerStroke.Thickness = 2
trackerStroke.Color = Color3.new(0.6, 0.45, 0.15)
trackerStroke.Parent = tracker

-- Title
local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -10, 0, 18)
titleLabel.Position = UDim2.new(0, 8, 0, 4)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "Delivery incoming..."
titleLabel.TextColor3 = Color3.new(1, 0.85, 0.4)
titleLabel.TextSize = 12
titleLabel.Font = Enum.Font.LuckiestGuy
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = tracker

-- Items count + time
local infoLabel = Instance.new("TextLabel")
infoLabel.Name = "InfoLabel"
infoLabel.Size = UDim2.new(1, -10, 0, 14)
infoLabel.Position = UDim2.new(0, 8, 0, 22)
infoLabel.BackgroundTransparency = 1
infoLabel.Text = "1 item | 15s"
infoLabel.TextColor3 = Color3.new(0.8, 0.7, 0.5)
infoLabel.TextSize = 10
infoLabel.Font = Enum.Font.LuckiestGuy
infoLabel.TextXAlignment = Enum.TextXAlignment.Left
infoLabel.Parent = tracker

-- Close button (X)
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 18, 0, 18)
closeBtn.Position = UDim2.new(1, -22, 0, 4)
closeBtn.BackgroundColor3 = Color3.new(0.5, 0.2, 0.2)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.new(1, 1, 1)
closeBtn.TextSize = 10
closeBtn.Font = Enum.Font.LuckiestGuy
closeBtn.BorderSizePixel = 0
closeBtn.ZIndex = 3
closeBtn.Visible = false
closeBtn.Parent = tracker

local closeBtnCorner = Instance.new("UICorner")
closeBtnCorner.CornerRadius = UDim.new(1, 0)
closeBtnCorner.Parent = closeBtn

closeBtn.MouseButton1Click:Connect(function()
	tracker.Visible = false
end)

-- Progress bar background
local barBg = Instance.new("Frame")
barBg.Size = UDim2.new(1, -16, 0, 10)
barBg.Position = UDim2.new(0, 8, 0, 42)
barBg.BackgroundColor3 = Color3.new(0.2, 0.18, 0.1)
barBg.BorderSizePixel = 0
barBg.Parent = tracker

local barBgCorner = Instance.new("UICorner")
barBgCorner.CornerRadius = UDim.new(0, 5)
barBgCorner.Parent = barBg

-- Progress bar fill
local barFill = Instance.new("Frame")
barFill.Name = "Fill"
barFill.Size = UDim2.new(0, 0, 1, 0)
barFill.BackgroundColor3 = Color3.new(0.9, 0.65, 0.1)
barFill.BorderSizePixel = 0
barFill.Parent = barBg

local barFillCorner = Instance.new("UICorner")
barFillCorner.CornerRadius = UDim.new(0, 5)
barFillCorner.Parent = barFill

-- =====================
-- STATE
-- =====================
local deliveryActive = false
local totalTime = 0
local remainingAtReceive = 0
local receiveTime = 0
local totalItems = 0

-- =====================
-- EVENTS
-- =====================
DeliveryUpdateEvent.OnClientEvent:Connect(function(data)
	deliveryActive = true
	totalTime = data.totalTime
	remainingAtReceive = data.remainingTime
	receiveTime = tick()
	totalItems = data.totalItems

	titleLabel.Text = "Delivery incoming..."
	titleLabel.TextColor3 = Color3.new(1, 0.85, 0.4)
	barFill.BackgroundColor3 = Color3.new(0.9, 0.65, 0.1)
	closeBtn.Visible = false
	tracker.Visible = true
end)

DeliveryArrivedEvent.OnClientEvent:Connect(function()
	deliveryActive = false

	-- Play Honk sound
	local honk = SoundService:FindFirstChild("Honk")
	if honk then
		honk:Play()
	end

	closeBtn.Visible = true
	titleLabel.Text = "Delivery arrived!"
	titleLabel.TextColor3 = Color3.new(0.3, 1, 0.3)
	local itemText = totalItems .. " item" .. (totalItems > 1 and "s" or "")
	infoLabel.Text = itemText .. " | Collect outside!"
	barFill.Size = UDim2.new(1, 0, 1, 0)
	barFill.BackgroundColor3 = Color3.new(0.2, 0.8, 0.2)

	task.delay(3, function()
		if not deliveryActive then
			tracker.Visible = false
		end
	end)
end)

-- =====================
-- PROGRESS UPDATE LOOP
-- =====================
RunService.Heartbeat:Connect(function()
	if not deliveryActive then return end

	local elapsed = tick() - receiveTime
	local remaining = math.max(0, remainingAtReceive - elapsed)
	local progress = math.clamp(1 - (remaining / totalTime), 0, 1)

	barFill.Size = UDim2.new(progress, 0, 1, 0)

	local secs = math.ceil(remaining)
	local itemText = totalItems .. " item" .. (totalItems > 1 and "s" or "")
	infoLabel.Text = itemText .. " | " .. secs .. "s"
end)
