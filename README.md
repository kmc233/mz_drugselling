# MZ Drug Selling

A FiveM drug selling resource featuring direct street sales, corner dealing, delivery orders by text, and bulk sales. Players earn money and dealing experience by negotiating prices, completing orders, and selling in bulk.

This resource can be used with the free [Drugs Creator](https://muziscripts.com/scripts/7745731).

## Features

| Mode | How to access | Description |
| --- | --- | --- |
| Street sales | Interact directly with pedestrians | Choose a drug and price. The customer type, offer, and available stock affect the outcome. |
| Corner dealing | Start it on the phone | Customers approach the player and negotiate through the offer interface. |
| Deliveries | Receive orders on the phone | Orders specify the drug, quantity, price, area, and deadline. Accept an order and travel to the delivery location. |
| Bulk sales | Interact with the dealer at the configured location | Choose how much to sell. The unit price depends on your level and the bulk price multiplier. |

Street sale and corner dealing customers may buy, refuse, or steal drugs. In direct street sales, customers may also refuse before receiving an offer. Each customer type has its own chance of calling the police. Deliveries have a configurable chance of triggering a police alert after a successful handoff. Alerts also require the configured number of online police officers and an active dispatch resource.

Delivery orders arrive at configurable intervals. The pending order limit, deadline, cancellation cooldown, and retention time for ended orders can all be configured. Police availability is checked before accepting an order, and inventory is checked at delivery. Accepting an order stops any active street sale or corner dealing mode.

## Dependencies

- Framework: Qbox (`qbx_core`), QBCore (`qb-core`), or ESX (`es_extended`).
- `ox_lib`: callbacks and notifications.
- Target system: `ox_target` or `qb-target`.
- Optional dispatch system: `cd_dispatch`, `codem-dispatch`, `origen_police`, `ps-dispatch`, or `rcore_dispatch`.

## Installation

1. Name the resource directory `mz_drugselling`. Ensure the framework, inventory, `ox_lib`, and selected target system start before this resource.
2. Add the `dealer_phone` item to your inventory and ensure the configured drugs and payment items exist. The resource registers the phone as a usable item through the framework.
3. Update the framework, language, items, payment, and location settings in `config.lua` for your server.
4. Start `mz_drugselling`.

For example, add the following to `ox_inventory/data/items.lua`:

```lua
['dealer_phone'] = {
    label = 'Burner Phone',
    weight = 200,
    stack = false,
    close = true,
    description = 'A phone for arranging sales.'
},
```

For other inventory systems, add the same item ID using their item definition format. After changing item definitions, restart or refresh the inventory resource as required.
