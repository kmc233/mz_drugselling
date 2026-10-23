local inventory = 5
local payment
local notice

config = {
    debug = false,
    dealing = { payments = { type = 'item', item = { id = 'black_money' } } },
    deliveries = { payments = { type = 'item', item = { id = 'black_money' } } }
}
lang = {
    general = { server = { sold_drugs = 'Sold for $%d: %dx %s' } },
    dealing = { server = { notifications = { header = 'Sales' } } }
}
utils = {
    callback = { register = function() end },
    fw = {
        get_item = function() return { quantity = inventory } end,
        adjust_inventory = function(_, data)
            local entry = data.items[1]
            if entry.action == 'remove' then inventory = inventory - entry.quantity
            else
                assert(entry.item_id == 'black_money' and entry.data == nil)
                payment = entry.quantity
            end
            return true
        end,
        register_item = function() end
    },
    ui = { notify = function(_, data) notice = data.message end }
}
RegisterNetEvent = function() end
AddEventHandler = function() end

dofile('server/main.lua')
assert(complete_sale(1, { drugs = {{ id = 'water', label = 'Water', price = 10 }} }, 'water', 2))
assert(inventory == 3 and payment == 20)
assert(notice == 'Sold for $20: 2x Water')
assert(complete_sale(1, { drugs = {{ id = 'water', label = 'Water', price = 8 }} }, 'water', 1, 'bulk'))
assert(inventory == 2 and payment == 8)
assert(complete_sale(1, { drugs = {{ id = 'water', label = 'Water', price = 12 }} }, 'water', 1, 'delivery'))
assert(inventory == 1 and payment == 12)
print('complete_sale: ok')
