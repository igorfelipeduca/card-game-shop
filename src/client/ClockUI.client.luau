local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local TimeUpdateEvent = Remotes:WaitForChild("TimeUpdate")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- =====================
-- CLOCK UI (top-right)
-- =====================
local clockGui = Instance.new("ScreenGui")
clockGui.Name = "ClockGui"
clockGui.ResetOnSpawn = false
clockGui.Parent = playerGui

local clockFrame = Instance.new("Frame")
clockFrame.Size = UDim2.new(0, 110, 0, 38)
clockFrame.Position = UDim2.new(1, -120, 0, 55)
clockFrame.BackgroundColor3 = Color3.new(0.08, 0.08, 0.1)
clockFrame.BackgroundTransparency = 0.15
clockFrame.BorderSizePixel = 0
clockFrame.Visible = false
clockFrame.Parent = clockGui

local clockCorner = Instance.new("UICorner")
clockCorner.CornerRadius = UDim.new(0, 8)
clockCorner.Parent = clockFrame

local clockStroke = Instance.new("UIStroke")
clockStroke.Thickness = 2
clockStroke.Color = Color3.new(0.3, 0.3, 0.4)
clockStroke.Parent = clockFrame

local clockLabel = Instance.new("TextLabel")
clockLabel.Size = UDim2.new(1, -10, 1, 0)
clockLabel.Position = UDim2.new(0, 5, 0, 0)
clockLabel.BackgroundTransparency = 1
clockLabel.Text = "08:00"
clockLabel.TextColor3 = Color3.new(0.3, 1, 0.3)
clockLabel.TextSize = 22
clockLabel.Font = Enum.Font.LuckiestGuy
clockLabel.Parent = clockFrame

-- Warning banner
local warningFrame = Instance.new("Frame")
warningFrame.Size = UDim2.new(0, 280, 0, 32)
warningFrame.Position = UDim2.new(0.5, -140, 0, 10)
warningFrame.BackgroundColor3 = Color3.new(0.6, 0.1, 0.1)
warningFrame.BackgroundTransparency = 0.1
warningFrame.BorderSizePixel = 0
warningFrame.Visible = false
warningFrame.Parent = clockGui

local warningCorner = Instance.new("UICorner")
warningCorner.CornerRadius = UDim.new(0, 8)
warningCorner.Parent = warningFrame

local warningLabel = Instance.new("TextLabel")
warningLabel.Size = UDim2.new(1, -10, 1, 0)
warningLabel.Position = UDim2.new(0, 5, 0, 0)
warningLabel.BackgroundTransparency = 1
warningLabel.Text = "It's late! Close your shop on the computer"
warningLabel.TextColor3 = Color3.new(1, 0.3, 0.3)
warningLabel.TextSize = 12
warningLabel.Font = Enum.Font.LuckiestGuy
warningLabel.Parent = warningFrame

-- =====================
-- TIME UPDATE FROM SERVER
-- =====================
TimeUpdateEvent.OnClientEvent:Connect(function(data)
	if data.dayEnded then
		clockFrame.Visible = false
		warningFrame.Visible = false
		return
	end

	clockFrame.Visible = true
	clockLabel.Text = string.format("%02d:%02d", data.hour, data.minute)

	if data.isLate then
		clockLabel.TextColor3 = Color3.new(1, 0.2, 0.2)
		clockStroke.Color = Color3.new(0.6, 0.15, 0.15)
		warningFrame.Visible = true
	else
		clockLabel.TextColor3 = Color3.new(0.3, 1, 0.3)
		clockStroke.Color = Color3.new(0.3, 0.3, 0.4)
		warningFrame.Visible = false
	end
end)
