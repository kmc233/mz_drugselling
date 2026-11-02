local callbacks = {}
local inventory = 10
local last_sale
local positions = setmetatable({}, { __mode = 'k' })

local function vector(value)
    local result = newproxy(true)
    positions[result] = value
    local mt = getmetatable(result)
    mt.__sub = function(a, b) return vector(positions[a] - positions[b]) end
    mt.__len = function(a) return math.abs(positions[a]) end
    return result
end

lang = { general = { server = {
    invalid_sale_data = 'Invalid', missing_drug_config = 'Unknown', insufficient_quantity = 'Inventory'
} }, bulk_dealer = { server = { bulk_sell_notification = '$%d for %dx %s' } } }
config = {
    inventoryImagePath = 'nui://ox_inventory/web/images/',
    bulk_dealer = { enabled = true, ped = { coords = { x = 0, y = 0, z = 0 } } },
    sales_adjustments = { bulk = { price_multiplier = 0.5 } },
    skills = { bulk = { price_per_level = 0.01 } },
    drugs = {{ id = 'water', label = 'Water', image = 'water.png',
        required_level = 1, price = { min = 10, optimal = 16, max = 20 }, quantity = { min = 1, max = 5 } }}
}
utils = {
    callback = { register = function(name, handler) callbacks[name] = handler end },
    skills = { get_skill = function() return { level = 1, current_xp = 0, required_xp = 100 } end },
    fw = { get_item = function() return { quantity = inventory } end }
}
GetPlayerPed = function() return 1 end
GetEntityCoords = function() return vector(0) end
vector3 = function() return vector(0) end
complete_sale = function(_, _, id, amount)
    last_sale = { id = id, amount = amount }
    inventory = inventory - amount
    return true
end
reward_xp = function() end

dofile('server/scripts/bulk_dealer.lua')
local get_data = callbacks['mz_drugselling:sv:get_bulk_dealer_data']
local sell = callbacks['mz_drugselling:sv:bulk_sell_drugs']

local data
get_data(1, {}, function(result) data = result end)
assert(data.drugs[1].price == 8 and data.drugs[1].quantity == 10)
assert(data.price_multiplier == 0.5 and data.price_per_level == 0.01)
assert(data.drugs[1].image == 'nui://ox_inventory/web/images/water.png')
config.inventoryImagePath = 'auto'
utils.fw.name = 'esx'
get_data(1, {}, function(result) data = result end)
assert(data.drugs[1].image == 'nui://ox_inventory/web/images/water.png')
config.inventoryImagePath = 'https://images.example/items'
get_data(1, {}, function(result) data = result end)
assert(data.drugs[1].image == 'https://images.example/items/water.png')

local accepted
sell(1, { drug = 'water', quantity = 0 }, function(ok) accepted = ok end)
assert(accepted == false and inventory == 10)
sell(1, { drug = 'water', quantity = 11 }, function(ok) accepted = ok end)
assert(accepted == false and inventory == 10)
sell(1, { drug = 'water', quantity = 5 }, function(ok, message)
    accepted = ok
    assert(message == '$40 for 5x Water')
end)
assert(accepted == true and inventory == 5)
assert(last_sale.id == 'water' and last_sale.amount == 5)
print('bulk_dealer: ok')
