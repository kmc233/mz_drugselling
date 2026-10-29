# Drug selling

This resource keeps the BOII phone, deliveries, and bulk dealer, and adds priced street offers and corner selling.

## Sales modes

| Mode | Entry | Sale rules |
| --- | --- | --- |
| Street | Dealer phone: 1 | Target an ambient NPC; choose an item and set its unit price. |
| Corner | Dealer phone: 2 | Customers approach automatically; uses the same offer rules as street sales. |
| Delivery | Dealer phone: 3 | Choose one of six SMS orders, then travel to the customer and deliver at the listed fixed price. |
| Bulk | Visit the configured bulk dealer | Choose an item and quantity at a fixed wholesale unit price. |

Street outcomes are calculated on the server. The NPC model determines its personality, including direct refusal, buying, theft, police alert, and XP. The price changes the buying chance. The server also chooses the transaction quantity. Edit these rules in `server/config.lua`.

Delivery orders arrive as individual SMS messages during a session, with six to eight total orders and a separate expiry time for each message. Each order specifies the item, quantity, price, area, and deadline when generated. Accepting an order marks its location; inventory is checked only at handoff. An incomplete order can be cancelled or expires, and another order can be accepted after the configured cooldown. The fixed bulk dealer remains an immediate, lower-price way to clear inventory without an order or deadline.

The default `water` and `burger` entries are placeholders. Replace them with your inventory's drug item IDs, prices, quantities, and images before using the resource. The wholesale `price` is **per item** and should normally be below street prices.

Sales pay `black_money` items equal to the total sale price (for example, a $60 sale gives 60 items). No payout amount is stored in item metadata.

## Dependencies

This resource uses `qbx_core` for players, money and persistent dealing XP, `ox_inventory` for items, `ox_lib` for callbacks, notifications and the bulk-dealer menu, and `ox_target` by default for the bulk dealer. It no longer requires `boii_utils` or `boii_ui`. Start those resources before `mz_drugselling`.

Add a `dealer_phone` item to `ox_inventory/data/items.lua` if it is not already defined, then restart `ox_inventory`. The resource registers its usable-item action with `qbx_core`. Dealing XP is stored in Qbox player metadata (`mz_drugselling_xp`): 1000 XP per level, starting at level 1. Existing `boii_utils` skill XP is not imported. Images and `.ttf` fonts are ignored by Git, so keep the required files in `ui/assets` on the server.

```lua
['dealer_phone'] = {
    label = 'Dealer Phone', weight = 200, stack = false, close = true,
    description = 'A phone for arranging sales.'
},
```

## Local checks

```powershell
lua tests/utils.lua
lua tests/complete_sale.lua
lua tests/street_dealing.lua
lua tests/bulk_dealer.lua
lua tests/delivery_orders.lua
```

These tests cover server-side sale decisions and bulk quantities. Target interactions, entity networking, UI focus, and framework integrations require an in-game test.
