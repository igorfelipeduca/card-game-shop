local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local RequestShopNameEvent = Remotes:WaitForChild("RequestShopName")
local SetShopNameEvent = Remotes:WaitForChild("SetShopName")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- =====================
-- NAMING MODAL UI
-- =====================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ShopNameGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local overlay = Instance.new("Frame")
overlay.Size = UDim2.new(1, 0, 1, 0)
overlay.BackgroundColor3 = Color3.new(0, 0, 0)
overlay.BackgroundTransparency = 0.5
overlay.BorderSizePixel = 0
overlay.Visible = false
overlay.Parent = screenGui

local panel = Instance.new("Frame")
panel.Size = UDim2.new(0, 340, 0, 280)
panel.Position = UDim2.new(0.5, -170, 0.5, -140)
panel.BackgroundColor3 = Color3.new(1, 1, 1)
panel.BorderSizePixel = 0
panel.Parent = overlay

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 12)
panelCorner.Parent = panel

-- Red top bar (Pokeball style)
local topBar = Instance.new("Frame")
topBar.Size = UDim2.new(1, 0, 0, 60)
topBar.BackgroundColor3 = Color3.new(0.85, 0.1, 0.1)
topBar.BorderSizePixel = 0
topBar.Parent = panel

local topBarCorner = Instance.new("UICorner")
topBarCorner.CornerRadius = UDim.new(0, 12)
topBarCorner.Parent = topBar

-- Fix bottom corners of topBar
local topBarFix = Instance.new("Frame")
topBarFix.Size = UDim2.new(1, 0, 0, 12)
topBarFix.Position = UDim2.new(0, 0, 1, -12)
topBarFix.BackgroundColor3 = Color3.new(0.85, 0.1, 0.1)
topBarFix.BorderSizePixel = 0
topBarFix.Parent = topBar

-- Title
local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -20, 1, 0)
titleLabel.Position = UDim2.new(0, 10, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "NAME YOUR SHOP!"
titleLabel.TextColor3 = Color3.new(1, 1, 1)
titleLabel.TextSize = 22
titleLabel.Font = Enum.Font.LuckiestGuy
titleLabel.Parent = topBar

-- Black divider line
local divider = Instance.new("Frame")
divider.Size = UDim2.new(1, 0, 0, 3)
divider.Position = UDim2.new(0, 0, 0, 60)
divider.BackgroundColor3 = Color3.new(0.15, 0.15, 0.15)
divider.BorderSizePixel = 0
divider.ZIndex = 2
divider.Parent = panel

-- Mini Pokeball on divider
local miniPoke = Instance.new("Frame")
miniPoke.Size = UDim2.new(0, 24, 0, 24)
miniPoke.Position = UDim2.new(0.5, -12, 0, 48)
miniPoke.BackgroundColor3 = Color3.new(0.15, 0.15, 0.15)
miniPoke.BorderSizePixel = 0
miniPoke.ZIndex = 3
miniPoke.Parent = panel

local miniPokeCorner = Instance.new("UICorner")
miniPokeCorner.CornerRadius = UDim.new(1, 0)
miniPokeCorner.Parent = miniPoke

local miniPokeInner = Instance.new("Frame")
miniPokeInner.Size = UDim2.new(0, 14, 0, 14)
miniPokeInner.Position = UDim2.new(0.5, -7, 0.5, -7)
miniPokeInner.BackgroundColor3 = Color3.new(1, 1, 1)
miniPokeInner.BorderSizePixel = 0
miniPokeInner.ZIndex = 4
miniPokeInner.Parent = miniPoke

local miniPokeInnerCorner = Instance.new("UICorner")
miniPokeInnerCorner.CornerRadius = UDim.new(1, 0)
miniPokeInnerCorner.Parent = miniPokeInner

-- Subtitle
local subtitle = Instance.new("TextLabel")
subtitle.Size = UDim2.new(1, -40, 0, 24)
subtitle.Position = UDim2.new(0, 20, 0, 80)
subtitle.BackgroundTransparency = 1
subtitle.Text = "Choose a name for your store:"
subtitle.TextColor3 = Color3.new(0.4, 0.4, 0.4)
subtitle.TextSize = 13
subtitle.Font = Enum.Font.LuckiestGuy
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.Parent = panel

-- Text input
local inputFrame = Instance.new("Frame")
inputFrame.Size = UDim2.new(1, -40, 0, 44)
inputFrame.Position = UDim2.new(0, 20, 0, 112)
inputFrame.BackgroundColor3 = Color3.new(0.95, 0.95, 0.96)
inputFrame.BorderSizePixel = 0
inputFrame.Parent = panel

local inputCorner = Instance.new("UICorner")
inputCorner.CornerRadius = UDim.new(0, 8)
inputCorner.Parent = inputFrame

local inputStroke = Instance.new("UIStroke")
inputStroke.Thickness = 2
inputStroke.Color = Color3.new(0.8, 0.8, 0.82)
inputStroke.Parent = inputFrame

local nameInput = Instance.new("TextBox")
nameInput.Name = "NameInput"
nameInput.Size = UDim2.new(1, -16, 1, 0)
nameInput.Position = UDim2.new(0, 8, 0, 0)
nameInput.BackgroundTransparency = 1
nameInput.PlaceholderText = "Type your shop name..."
nameInput.PlaceholderColor3 = Color3.new(0.65, 0.65, 0.7)
nameInput.Text = ""
nameInput.TextColor3 = Color3.new(0.15, 0.15, 0.15)
nameInput.TextSize = 16
nameInput.Font = Enum.Font.LuckiestGuy
nameInput.TextXAlignment = Enum.TextXAlignment.Left
nameInput.ClearTextOnFocus = false
nameInput.Parent = inputFrame

-- Character count
local charCount = Instance.new("TextLabel")
charCount.Size = UDim2.new(1, -40, 0, 16)
charCount.Position = UDim2.new(0, 20, 0, 160)
charCount.BackgroundTransparency = 1
charCount.Text = "0/30"
charCount.TextColor3 = Color3.new(0.6, 0.6, 0.6)
charCount.TextSize = 10
charCount.Font = Enum.Font.LuckiestGuy
charCount.TextXAlignment = Enum.TextXAlignment.Right
charCount.Parent = panel

-- Confirm button
local confirmBtn = Instance.new("TextButton")
confirmBtn.Size = UDim2.new(1, -40, 0, 40)
confirmBtn.Position = UDim2.new(0, 20, 0, 190)
confirmBtn.BackgroundColor3 = Color3.new(0.85, 0.1, 0.1)
confirmBtn.Text = "OPEN MY SHOP!"
confirmBtn.TextColor3 = Color3.new(1, 1, 1)
confirmBtn.TextSize = 16
confirmBtn.Font = Enum.Font.LuckiestGuy
confirmBtn.BorderSizePixel = 0
confirmBtn.Parent = panel

local confirmCorner = Instance.new("UICorner")
confirmCorner.CornerRadius = UDim.new(0, 8)
confirmCorner.Parent = confirmBtn

-- Hint
local hint = Instance.new("TextLabel")
hint.Size = UDim2.new(1, -40, 0, 18)
hint.Position = UDim2.new(0, 20, 0, 238)
hint.BackgroundTransparency = 1
hint.Text = "Leave empty for default name"
hint.TextColor3 = Color3.new(0.7, 0.7, 0.7)
hint.TextSize = 10
hint.Font = Enum.Font.LuckiestGuy
hint.Parent = panel

-- =====================
-- LOGIC
-- =====================
local defaultName = ""

nameInput:GetPropertyChangedSignal("Text"):Connect(function()
	local text = nameInput.Text
	if #text > 30 then
		nameInput.Text = text:sub(1, 30)
		return
	end
	charCount.Text = #text .. "/30"
end)

local function openNaming(defName)
	defaultName = defName or player.Name
	nameInput.Text = defaultName
	charCount.Text = #defaultName .. "/30"
	overlay.Visible = true
	nameInput:CaptureFocus()
end

local function closeNaming()
	overlay.Visible = false
end

confirmBtn.MouseButton1Click:Connect(function()
	local name = nameInput.Text
	if #name == 0 then
		name = defaultName
	end
	SetShopNameEvent:FireServer(name)
	closeNaming()
end)

RequestShopNameEvent.OnClientEvent:Connect(function(defName)
	openNaming(defName)
end)

print("[ShopNameUI] Loaded")
