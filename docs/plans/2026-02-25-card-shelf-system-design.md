# Card Shop Shelf System (MVP)

## Overview
Player spawns with 6 iconic Pokemon TCG cards in a hotbar UI. The shelf in the scene has 36 empty slots (blue semi-transparent placeholders). Player selects a card in the hotbar, hovers over an empty slot (blue highlight), clicks to place. Clicking an occupied slot returns the card to inventory.

## Architecture

### Client (`src/client`)
- **HotbarController** — GUI with 6 slots at bottom of screen showing inventory cards. Click to select active card.
- **ShelfInteraction** — Detects hover on shelf slots via mouse raycast, shows highlight, processes clicks (place/remove card).

### Server (`src/server`)
- **InventoryManager** — Manages player inventory. Gives initial cards on PlayerAdded.
- **ShelfManager** — Manages shelf slot state (empty/occupied). Processes RemoteEvents for place/remove.

### Shared (`src/shared`)
- **CardData** — Module with card data (name, representative color).

## Cards
| Name | Color |
|------|-------|
| Charizard EX | Orange (Color3 1, 0.4, 0) |
| Pikachu VMAX | Yellow (Color3 1, 0.9, 0) |
| Mewtwo GX | Purple (Color3 0.6, 0.2, 0.8) |
| Blastoise EX | Blue (Color3 0.2, 0.4, 1) |
| Gengar VMAX | Dark Purple (Color3 0.4, 0.1, 0.5) |
| Rayquaza V | Green (Color3 0.2, 0.8, 0.3) |

## Data Flow
1. Player joins -> Server gives 6 cards -> Client renders hotbar
2. Player selects card in hotbar -> card highlighted
3. Player hovers empty slot -> SelectionBox appears
4. Player clicks -> RemoteEvent -> Server validates -> updates state -> fires back -> Client updates visual
5. Player clicks occupied slot -> reverse process

## Shelf Slots
- 36 existing product boxes (Part 2x2x2 with Decal) converted to slots
- Empty: semi-transparent, Decal removed
- Hover: SelectionBox highlight
- Occupied: opaque with card color + SurfaceGui with card name
