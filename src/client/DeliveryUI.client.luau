local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local DeliveryUpdateEvent = Remotes:WaitForChild("DeliveryUpdate")
local DeliveryArrivedEvent = Remotes:WaitForChild("DeliveryArrived")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Delivery stages with progress thresholds
local STAGES = {
	{ threshold = 0.0, text = "Packing order...", icon = "[ ]" },
	{ threshold = 0.25, text = "Package shipped!", icon = "[>>]" },
	{ threshold = 0.55, text = "Out for delivery...", icon = "[>>>]" },
	{ threshold = 0.80, text = "Almost there!", icon = "[!]" },
}

-- =====================
-- DELIVERY TRACKER UI
-- =====================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DeliveryGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local tracker = Instance.new("Frame")
tracker.Name = "DeliveryTracker"
tracker.Size = UDim2.new(0, 220, 0, 80)
tracker.Position = UDim2.new(1, -230, 0, 100)
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

-- Stage icon
local stageIcon = Instance.new("TextLabel")
stageIcon.Size = UDim2.new(0, 30, 0, 18)
stageIcon.Position = UDim2.new(0, 8, 0, 4)
stageIcon.BackgroundTransparency = 1
stageIcon.Text = "[ ]"
stageIcon.TextColor3 = Color3.new(1, 0.85, 0.4)
stageIcon.TextSize = 11
stageIcon.Font = Enum.Font.LuckiestGuy
stageIcon.TextXAlignment = Enum.TextXAlignment.Left
stageIcon.Parent = tracker

-- Title (stage text)
local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -48, 0, 18)
titleLabel.Position = UDim2.new(0, 38, 0, 4)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "Packing order..."
titleLabel.TextColor3 = Color3.new(1, 0.85, 0.4)
titleLabel.TextSize = 12
titleLabel.Font = Enum.Font.LuckiestGuy
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = tracker

-- Items count + time
local infoLabel = Instance.new("TextLabel")
infoLabel.Name = "InfoLabel"
infoLabel.Size = UDim2.new(1, -10, 0, 14)
infoLabel.Position = UDim2.new(0, 8, 0, 24)
infoLabel.BackgroundTransparency = 1
infoLabel.Text = "1 item | 7s"
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
barBg.Size = UDim2.new(1, -16, 0, 12)
barBg.Position = UDim2.new(0, 8, 0, 44)
barBg.BackgroundColor3 = Color3.new(0.2, 0.18, 0.1)
barBg.BorderSizePixel = 0
barBg.Parent = tracker

local barBgCorner = Instance.new("UICorner")
barBgCorner.CornerRadius = UDim.new(0, 6)
barBgCorner.Parent = barBg

-- Progress bar fill
local barFill = Instance.new("Frame")
barFill.Name = "Fill"
barFill.Size = UDim2.new(0, 0, 1, 0)
barFill.BackgroundColor3 = Color3.new(0.9, 0.65, 0.1)
barFill.BorderSizePixel = 0
barFill.Parent = barBg

local barFillCorner = Instance.new("UICorner")
barFillCorner.CornerRadius = UDim.new(0, 6)
barFillCorner.Parent = barFill

-- Truck icon on progress bar
local truckLabel = Instance.new("TextLabel")
truckLabel.Size = UDim2.new(0, 20, 0, 16)
truckLabel.Position = UDim2.new(0, -2, 0, -2)
truckLabel.BackgroundTransparency = 1
truckLabel.Text = ">"
truckLabel.TextColor3 = Color3.new(1, 1, 1)
truckLabel.TextSize = 14
truckLabel.Font = Enum.Font.LuckiestGuy
truckLabel.TextXAlignment = Enum.TextXAlignment.Right
truckLabel.ZIndex = 3
truckLabel.Parent = barFill

-- Stage dots under progress bar
local dotsFrame = Instance.new("Frame")
dotsFrame.Size = UDim2.new(1, -16, 0, 14)
dotsFrame.Position = UDim2.new(0, 8, 0, 58)
dotsFrame.BackgroundTransparency = 1
dotsFrame.Parent = tracker

for i, stage in STAGES do
	local dot = Instance.new("Frame")
	dot.Name = "Dot" .. i
	dot.Size = UDim2.new(0, 6, 0, 6)
	dot.Position = UDim2.new(stage.threshold, -3, 0, 0)
	dot.BackgroundColor3 = Color3.new(0.3, 0.25, 0.15)
	dot.BorderSizePixel = 0
	dot.Parent = dotsFrame

	local dotCorner = Instance.new("UICorner")
	dotCorner.CornerRadius = UDim.new(1, 0)
	dotCorner.Parent = dot
end

-- =====================
-- STATE
-- =====================
local deliveryActive = false
local totalTime = 0
local remainingAtReceive = 0
local receiveTime = 0
local totalItems = 0
local currentStage = 0

local function getStageForProgress(progress)
	local stage = 1
	for i, s in STAGES do
		if progress >= s.threshold then
			stage = i
		end
	end
	return stage
end

local function updateStageVisuals(stage)
	if stage == currentStage then return end
	currentStage = stage

	local stageData = STAGES[stage]
	titleLabel.Text = stageData.text
	stageIcon.Text = stageData.icon

	-- Update dot colors
	for i = 1, #STAGES do
		local dot = dotsFrame:FindFirstChild("Dot" .. i)
		if dot then
			if i <= stage then
				dot.BackgroundColor3 = Color3.new(1, 0.85, 0.3)
			else
				dot.BackgroundColor3 = Color3.new(0.3, 0.25, 0.15)
			end
		end
	end

	-- Color shifts per stage
	if stage <= 2 then
		barFill.BackgroundColor3 = Color3.new(0.9, 0.65, 0.1)
	elseif stage == 3 then
		barFill.BackgroundColor3 = Color3.new(0.9, 0.5, 0.1)
	else
		barFill.BackgroundColor3 = Color3.new(0.3, 0.85, 0.3)
	end
end

-- =====================
-- EVENTS
-- =====================
DeliveryUpdateEvent.OnClientEvent:Connect(function(data)
	deliveryActive = true
	totalTime = data.totalTime
	remainingAtReceive = data.remainingTime
	receiveTime = tick()
	totalItems = data.totalItems
	currentStage = 0

	titleLabel.TextColor3 = Color3.new(1, 0.85, 0.4)
	barFill.BackgroundColor3 = Color3.new(0.9, 0.65, 0.1)
	closeBtn.Visible = false
	tracker.Visible = true

	updateStageVisuals(1)
end)

DeliveryArrivedEvent.OnClientEvent:Connect(function()
	deliveryActive = false

	-- Play Honk sound
	local honk = SoundService:FindFirstChild("Honk")
	if honk then
		honk:Play()
	end

	closeBtn.Visible = true
	stageIcon.Text = "[OK]"
	titleLabel.Text = "Delivery arrived!"
	titleLabel.TextColor3 = Color3.new(0.3, 1, 0.3)
	local itemText = totalItems .. " item" .. (totalItems > 1 and "s" or "")
	infoLabel.Text = itemText .. " | Collect outside!"
	barFill.Size = UDim2.new(1, 0, 1, 0)
	barFill.BackgroundColor3 = Color3.new(0.2, 0.8, 0.2)

	-- Light up all dots
	for i = 1, #STAGES do
		local dot = dotsFrame:FindFirstChild("Dot" .. i)
		if dot then
			dot.BackgroundColor3 = Color3.new(0.3, 1, 0.3)
		end
	end

	task.delay(5, function()
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

	-- Update stage
	local stage = getStageForProgress(progress)
	updateStageVisuals(stage)
end)

print("[DeliveryUI] Loaded with delivery stages")
