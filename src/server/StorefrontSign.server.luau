print("[StorefrontSign] Starting...")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local SetShopNameEvent = Remotes:WaitForChild("SetShopName")

-- StorefrontSign is a Part inside PokemonStore
local store = workspace:WaitForChild("PokemonStore", 10)
if not store then
	warn("[StorefrontSign] PokemonStore not found!")
	return
end

local signPart = store:WaitForChild("StorefrontSign", 10)
if not signPart then
	warn("[StorefrontSign] StorefrontSign not found inside PokemonStore!")
	return
end

print("[StorefrontSign] Found part. Size: " .. signPart.Size.X .. "x" .. signPart.Size.Y)

-- =====================
-- STATE
-- =====================
local shopName = nil
local nameLabel = nil

-- =====================
-- BUILD SIGN
-- =====================
-- Sign is 30 x 4.5 studs (very wide banner).
-- Layout: small Pokeball badge on left | shop name in center-right.
local function buildSign()
	-- Remove existing SurfaceGui
	local existing = signPart:FindFirstChild("SignGui")
	if existing then existing:Destroy() end

	local gui = Instance.new("SurfaceGui")
	gui.Name = "SignGui"
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 50
	gui.Parent = signPart
	-- Canvas: ~1500 x 225 px

	-- White background
	local bg = Instance.new("Frame")
	bg.Size = UDim2.new(1, 0, 1, 0)
	bg.BackgroundColor3 = Color3.new(1, 1, 1)
	bg.BorderSizePixel = 0
	bg.Parent = gui

	local bgCorner = Instance.new("UICorner")
	bgCorner.CornerRadius = UDim.new(0, 14)
	bgCorner.Parent = bg

	-- Left badge: red section (~15% width) with Pokeball circle
	local badge = Instance.new("Frame")
	badge.Size = UDim2.new(0.14, 0, 1, 0)
	badge.BackgroundColor3 = Color3.new(0.88, 0.1, 0.1)
	badge.BorderSizePixel = 0
	badge.ZIndex = 2
	badge.Parent = bg

	local badgeCornerL = Instance.new("UICorner")
	badgeCornerL.CornerRadius = UDim.new(0, 14)
	badgeCornerL.Parent = badge

	-- Fix right corners of badge (should be square)
	local badgeFix = Instance.new("Frame")
	badgeFix.Size = UDim2.new(0, 14, 1, 0)
	badgeFix.Position = UDim2.new(1, -14, 0, 0)
	badgeFix.BackgroundColor3 = Color3.new(0.88, 0.1, 0.1)
	badgeFix.BorderSizePixel = 0
	badgeFix.ZIndex = 2
	badgeFix.Parent = badge

	-- Pokeball outer circle (dark) inside badge
	local outerCircle = Instance.new("Frame")
	outerCircle.Size = UDim2.new(0, 70, 0, 70)
	outerCircle.Position = UDim2.new(0.5, -35, 0.5, -35)
	outerCircle.BackgroundColor3 = Color3.new(1, 1, 1)
	outerCircle.BorderSizePixel = 0
	outerCircle.ZIndex = 3
	outerCircle.Parent = badge

	local outerCorner = Instance.new("UICorner")
	outerCorner.CornerRadius = UDim.new(1, 0)
	outerCorner.Parent = outerCircle

	-- Pokeball top half (red inside white circle)
	local pokeTop = Instance.new("Frame")
	pokeTop.Size = UDim2.new(1, 0, 0.5, 0)
	pokeTop.BackgroundColor3 = Color3.new(0.88, 0.1, 0.1)
	pokeTop.BorderSizePixel = 0
	pokeTop.ZIndex = 4
	pokeTop.Parent = outerCircle

	local pokeTopCorner = Instance.new("UICorner")
	pokeTopCorner.CornerRadius = UDim.new(0.5, 0)
	pokeTopCorner.Parent = pokeTop

	local pokeTopFix = Instance.new("Frame")
	pokeTopFix.Size = UDim2.new(1, 0, 0, 10)
	pokeTopFix.Position = UDim2.new(0, 0, 1, -10)
	pokeTopFix.BackgroundColor3 = Color3.new(0.88, 0.1, 0.1)
	pokeTopFix.BorderSizePixel = 0
	pokeTopFix.ZIndex = 4
	pokeTopFix.Parent = pokeTop

	-- Center line
	local pokeLine = Instance.new("Frame")
	pokeLine.Size = UDim2.new(1, 0, 0, 8)
	pokeLine.Position = UDim2.new(0, 0, 0.5, -4)
	pokeLine.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
	pokeLine.BorderSizePixel = 0
	pokeLine.ZIndex = 5
	pokeLine.Parent = outerCircle

	-- Center button (inner circle)
	local innerCircle = Instance.new("Frame")
	innerCircle.Size = UDim2.new(0, 28, 0, 28)
	innerCircle.Position = UDim2.new(0.5, -14, 0.5, -14)
	innerCircle.BackgroundColor3 = Color3.new(1, 1, 1)
	innerCircle.BorderSizePixel = 0
	innerCircle.ZIndex = 6
	innerCircle.Parent = outerCircle

	local innerCorner = Instance.new("UICorner")
	innerCorner.CornerRadius = UDim.new(1, 0)
	innerCorner.Parent = innerCircle

	-- Thin black inner ring on button
	local innerRing = Instance.new("UIStroke")
	innerRing.Thickness = 4
	innerRing.Color = Color3.new(0.1, 0.1, 0.1)
	innerRing.Parent = innerCircle

	-- Vertical divider between badge and name area
	local divider = Instance.new("Frame")
	divider.Size = UDim2.new(0, 4, 0.7, 0)
	divider.Position = UDim2.new(0.14, 0, 0.15, 0)
	divider.BackgroundColor3 = Color3.new(0.85, 0.85, 0.87)
	divider.BorderSizePixel = 0
	divider.ZIndex = 2
	divider.Parent = bg

	-- Shop name label (center-right area)
	nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "ShopNameLabel"
	nameLabel.Size = UDim2.new(0.83, -20, 0.75, 0)
	nameLabel.Position = UDim2.new(0.15, 10, 0.12, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = shopName or "POKÉMON STORE"
	nameLabel.TextColor3 = Color3.new(0.88, 0.1, 0.1)
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.LuckiestGuy
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.ZIndex = 2
	nameLabel.Parent = bg

	-- Subtitle
	local subtitle = Instance.new("TextLabel")
	subtitle.Size = UDim2.new(0.83, -20, 0.28, 0)
	subtitle.Position = UDim2.new(0.15, 10, 0.68, 0)
	subtitle.BackgroundTransparency = 1
	subtitle.Text = "POKÉMON TCG SHOP"
	subtitle.TextColor3 = Color3.new(0.5, 0.5, 0.5)
	subtitle.TextScaled = true
	subtitle.Font = Enum.Font.LuckiestGuy
	subtitle.TextXAlignment = Enum.TextXAlignment.Left
	subtitle.ZIndex = 2
	subtitle.Parent = bg

	print("[StorefrontSign] Sign built")
end

local function updateShopName(name)
	shopName = name
	if nameLabel then
		nameLabel.Text = name
	end
end

-- =====================
-- LISTEN FOR NAME
-- =====================
SetShopNameEvent.OnServerEvent:Connect(function(player, name)
	if type(name) ~= "string" then return end
	name = name:sub(1, 30)
	if #name == 0 then
		name = player.Name
	end
	updateShopName(name)
	print("[StorefrontSign] Name updated to: " .. name)
end)

-- =====================
-- INIT
-- =====================
buildSign()

print("[StorefrontSign] Ready!")
