# Card Game Shop - Roblox Project

Pokemon TCG card shop game built with Rojo + Luau.

## Project Structure

```
src/
  server/          -> ServerScriptService (*.server.luau)
  client/          -> StarterPlayerScripts (*.client.luau)
  shared/          -> ReplicatedStorage (modules)
```

Rojo syncs files via `default.project.json`. Server scripts run on the server, client scripts run per-player.

## Architecture

### Server Scripts
- **SetupRemotes** - Creates all RemoteEvents/RemoteFunctions in `Remotes` folder. Runs first.
- **DayCycleManager** - In-game clock (1 real second = 1 game minute). Starts at 8:00 AM when shop opens, warning at 18:00. Handles EndDay. Creates `CloseShop`, `ResetDayStats` BindableEvents.
- **InventoryManager** - Player inventory, money, card buying. Exposes `GetPlayerMoney`, `SetPlayerMoney`, `AddCardToInventory`, `QueueDeliveryItem` BindableEvents/Functions.
- **ShelfManager** - Card slots on PokemonShelf with custom pricing. Exposes `GetFilledSlots` BindableFunction (returns cardId + shelfPrice).
- **BuyerNPC** - NPC customer AI: spawning, pathfinding, price evaluation, multi-card buying, queue, shop sign toggle.
- **CheckoutManager** - Cash register checkout flow supporting multiple cards per transaction. Creates `NPCAtRegister`, `CheckoutDone`, `QueueEmpty` BindableEvents.
- **DeliveryManager** - Delivery timer, box spawning, collection via ProximityPrompt.

### Client Scripts
- **ComputerShop** - CardMarket.gg browser UI for buying cards + End Day button with daily summary.
- **CheckoutUI** - Cash register modal with numpad for giving change.
- **DeliveryUI** - Delivery progress bar notification.
- **ClockUI** - Digital clock display, warning after 18:00.
- **HotbarController** - Card hotbar + inventory panel (toggle with F).
- **CardHand** - Attaches selected card to player's hand.
- **ShelfInteraction** - Click-based shelf interaction with pricing UI modal. Player sets custom price when placing cards.

### Shared Modules
- **CardData** - Card definitions, prices, colors, rarities.

## Cross-Script Communication

Server scripts communicate via **BindableEvents/BindableFunctions** in ReplicatedStorage:
- `GetFilledSlots` (BindableFunction) - ShelfManager exposes filled shelf slots
- `NPCPickedUpCard` (BindableEvent) - BuyerNPC notifies ShelfManager when NPC takes a card
- `NPCAtRegister` (BindableEvent) - CheckoutManager notifies when NPC is ready at register
- `CheckoutDone` (BindableEvent) - CheckoutManager signals sale complete
- `QueueEmpty` (BindableEvent) - BuyerNPC signals no more customers
- `QueueDeliveryItem` (BindableEvent) - InventoryManager queues a delivery item
- `AddCardToInventory` (BindableEvent) - DeliveryManager adds cards after collection
- `GetPlayerMoney` / `SetPlayerMoney` - Shared money state between InventoryManager and CheckoutManager
- `ShopOpened` (BindableEvent) - BuyerNPC signals when shop opens (DayCycleManager starts clock)
- `CloseShop` (BindableEvent) - DayCycleManager signals BuyerNPC to close shop
- `ResetDayStats` (BindableEvent) - DayCycleManager resets daily counters in BuyerNPC and CheckoutManager
- `GetBuyerStats` (BindableFunction) - BuyerNPC exposes daily visitor/buyer/feedback stats
- `GetSaleStats` (BindableFunction) - CheckoutManager exposes daily revenue/cards sold

Server-client communication uses **RemoteEvents** in `Remotes` folder (created by SetupRemotes).

## Code Conventions

- **Font**: Always use `Enum.Font.LuckiestGuy` for all UI text. No exceptions.
- **Logging**: Every script prints `[ScriptName] message` for debugging.
- **BindableEvent ownership**: The script that **fires** the event should **create** it. The listening script uses `WaitForChild`.
- **Templates**: Models used for cloning (BuyerNPC, DeliveryBox) are moved to ServerStorage at startup, originals destroyed from workspace.
- **Streaming workaround**: For models that may not be accessible on the client due to streaming, create invisible Parts (`Transparency=1, CanCollide=false`) as ProximityPrompt parents.
- **ProximityPrompt**: Used for all player interactions (shop sign, cash register, laptop, shelf slots, delivery boxes).
- **No backup editing**: There is a backup of PokemonStore in workspace. Never modify or delete the backup.

## Key Positions (inside PokemonStore)

- Store entrance/door: ~(8, Y, 22)
- NPC spawn: (8, Y, 15) - outside store
- NPC enter: (2, Y, 30) - just inside door
- Shelf browse area: (-18, Y, 45)
- Register front (queue pos 1): (24, Y, 53)
- Queue extends in -Z direction: spacing 3.5 studs
- Cash register: ~(25.9, 6.4, 57.5)
- Delivery box spawn: (8, 1, 19) - outside store front

## Sounds (SoundService)

- **Honk** - Played when delivery arrives (client-side)
- **Store Door Bell** - Played when NPC enters the store (server-side)
- **Bell2** - Played when checkout sale is successfully completed

## Game Economy

- Player starts with $50, no starter cards
- Cards have `cost` (buy from shop) and `price` (market value reference)
- When placing cards on shelves, player sets a custom `shelfPrice`
- NPCs evaluate shelfPrice vs market price:
  - shelfPrice > market * 1.5 → NPC refuses to buy (too expensive)
  - shelfPrice <= market * 0.7 → NPC may buy multiple cards (up to 3)
  - Otherwise → NPC buys normally
- Card rarities: Common ($3-10 cost), Rare ($40-75 cost), Ultra Rare ($150-250 cost), Legendary ($500-800 cost)
