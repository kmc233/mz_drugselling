local events, sent, timers = {}, {}, {}
local inventory, sales = 0, 0
source = 1
sale_modes = { [1] = 'delivery' }
config = {
    sales_adjustments = { delivery = { price_multiplier = 0.8, quantity_multiplier = 1.8 } },
    drugs = {{ id = 'water', label = 'Water', required_level = 1,
        price = { min = 10, optimal = 15, max = 20 }, quantity = { min = 3, max = 5 } }},
    deliveries = {
        locations = {{ label = 'Davis', coords = { x = 1, y = 2, z = 3, w = 0 } }},
        order_count = { min = 6, max = 8 }, arrival_interval = { min = 1, max = 1 },
        offer_seconds = 600, delivery_seconds = 600,
        refresh_cooldown = 60, chance = { alert = 0 },
        police = { jobs = {}, on_duty_required = false, required = 0 }
    }
}
lang = { deliveries = {
    client = { notifications = { header = 'Delivery' } },
    server = { notifications = { not_enough_police = '%d/%d' } }
} }
utils = {
    skills = { get_skill = function() return { level = 1 } end },
    fw = { get_item = function() return { quantity = inventory } end }
}
RegisterNetEvent = function(name, handler) events[name] = handler end
AddEventHandler = function(name, handler) events[name] = handler end
TriggerClientEvent = function(name, _, data) sent[name] = data or true end
SetTimeout = function(_, handler) timers[#timers + 1] = handler end
get_police_players = function() return {} end
send_notification = function() end
alert_police = function() error('unexpected police alert') end
local vector = { __sub = function() return '' end }
vector3 = function(x, y, z) return setmetatable({ x = x, y = y, z = z }, vector) end
GetPlayerPed = function() return 1 end
GetEntityCoords = function() return vector3(1, 2, 3) end
complete_sale = function(_, sale, _, amount)
    if inventory < amount then return false end
    inventory = inventory - amount
    sales = sales + 1
    assert(sale.drugs[1].quantity == amount)
    return true
end
reward_xp = function() end
dofile('server/scripts/deliveries.lua')

events['mz_drugselling:sv:request_delivery']()
local inbox = sent['mz_drugselling:cl:delivery_orders']
assert(#inbox.orders == 1)
local first_arrival = #timers
timers[first_arrival]()
assert(#sent['mz_drugselling:cl:delivery_orders'].orders == 2)
local order = inbox.orders[1]
assert(order.total == order.price * order.quantity and order.area == 'Davis')
events['mz_drugselling:sv:accept_delivery'](order.id)
assert(sent['mz_drugselling:cl:delivery_orders'].active_id == order.id)
assert(sent['mz_drugselling:cl:spawn_delivery_ped'])
events['mz_drugselling:sv:complete_delivery']()
assert(sales == 0 and sent['mz_drugselling:cl:delivery_orders'].active_id == order.id)
inventory = order.quantity
events['mz_drugselling:sv:complete_delivery']()
assert(sales == 1 and inventory == 0)
assert(sent['mz_drugselling:cl:delivery_orders'].active_id == nil)
events['mz_drugselling:sv:complete_delivery']()
assert(sales == 1)
events['mz_drugselling:sv:accept_delivery'](sent['mz_drugselling:cl:delivery_orders'].orders[2].id)
assert(sent['mz_drugselling:cl:delivery_orders'].active_id == nil)
for i = 1, #timers do if timers[i] then timers[i]() end end
assert(sent['mz_drugselling:cl:delivery_orders'].active_id == nil)
print('delivery_orders: ok')
