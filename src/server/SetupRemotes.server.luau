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

-- Checkout remotes
local openCheckout = Instance.new("RemoteEvent")
openCheckout.Name = "OpenCheckout"
openCheckout.Parent = remotes

local submitChange = Instance.new("RemoteEvent")
submitChange.Name = "SubmitChange"
submitChange.Parent = remotes

local checkoutResult = Instance.new("RemoteEvent")
checkoutResult.Name = "CheckoutResult"
checkoutResult.Parent = remotes

local updateMoney = Instance.new("RemoteEvent")
updateMoney.Name = "UpdateMoney"
updateMoney.Parent = remotes

local buyCard = Instance.new("RemoteEvent")
buyCard.Name = "BuyCard"
buyCard.Parent = remotes

local buyCardResult = Instance.new("RemoteEvent")
buyCardResult.Name = "BuyCardResult"
buyCardResult.Parent = remotes

local closeCheckout = Instance.new("RemoteEvent")
closeCheckout.Name = "CloseCheckout"
closeCheckout.Parent = remotes

local cancelCheckout = Instance.new("RemoteEvent")
cancelCheckout.Name = "CancelCheckout"
cancelCheckout.Parent = remotes

-- Money remote function (client requests current balance)
local getMoney = Instance.new("RemoteFunction")
getMoney.Name = "GetMoney"
getMoney.Parent = remotes

-- Day cycle remotes
local timeUpdate = Instance.new("RemoteEvent")
timeUpdate.Name = "TimeUpdate"
timeUpdate.Parent = remotes

local endDay = Instance.new("RemoteFunction")
endDay.Name = "EndDay"
endDay.Parent = remotes

-- Delivery remotes
local deliveryUpdate = Instance.new("RemoteEvent")
deliveryUpdate.Name = "DeliveryUpdate"
deliveryUpdate.Parent = remotes

local deliveryArrived = Instance.new("RemoteEvent")
deliveryArrived.Name = "DeliveryArrived"
deliveryArrived.Parent = remotes

local updateShelfPrice = Instance.new("RemoteEvent")
updateShelfPrice.Name = "UpdateShelfPrice"
updateShelfPrice.Parent = remotes

-- Shop name remotes
local requestShopName = Instance.new("RemoteEvent")
requestShopName.Name = "RequestShopName"
requestShopName.Parent = remotes

local setShopName = Instance.new("RemoteEvent")
setShopName.Name = "SetShopName"
setShopName.Parent = remotes
