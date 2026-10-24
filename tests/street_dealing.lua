local handlers = {}
local sent
local sales = {}
local inventory = 10
local alerts = 0
local xp = 0
local rolls = {}
local positions = setmetatable({}, { __mode = 'k' })

local function vector(value)
    local result = newproxy(true)
    positions[result] = value
    local mt = getmetatable(result)
    mt.__sub = function(a, b) return vector(positions[a] - positions[b]) end
    mt.__len = function(a) return math.abs(positions[a]) end
    return result
end

local original_random = math.random
math.random = function()
    assert(#rolls > 0, 'missing random value')
    return table.remove(rolls, 1)
end
local function random_values(...)
    rolls = { ... }
end

source = 1
sale_modes = { [1] = 'dealing' }
config = {
    drugs = {
        { id = 'water', label = 'Water', dealing = {
            required_level = 1,
            price = { min = 10, optimal = 15, max = 20 },
            quantity = { min = 1, max = 5 }
        } }
    },
    dealing = {
        police = { jobs = {}, required = 0 },
        price_influence = 30,
        ped_models = {},
        ped_types = { normal = { label = 'Normal', buy = 55, steal = 8, refuse = 12, alert = 15, xp = 25 } }
    }
}
lang = { dealing = { server = { notifications = {
    header = 'Deals', no_drugs = 'No drugs', not_enough_police = '%d / %d',
    reclaimed_drugs = 'Recovered'
} } } }
utils = {
    skills = {
        get_skill = function() return { level = 1 } end,
        modify_skill = function(_, _, amount) xp = xp + amount end
    },
    fw = {
        get_item = function() return { quantity = inventory } end,
        adjust_inventory = function(_, data)
            local item = data.items[1]
            inventory = inventory + (item.action == 'add' and item.quantity or -item.quantity)
            return true
        end
    }
}

RegisterNetEvent = function(name, handler) handlers[name] = handler end
AddEventHandler = function() end
TriggerClientEvent = function(name, _, data) sent = { name = name, data = data } end
NetworkGetEntityFromNetworkId = function(id) return id + 100 end
GetPlayerPed = function() return 1 end
DoesEntityExist = function() return true end
GetEntityType = function() return 1 end
IsPedAPlayer = function() return false end
GetEntityCoords = function() return vector(0) end
GetEntityModel = function() return 1 end
GetEntityHealth = function() return 0 end
get_police_players = function() return {} end
send_notification = function() end
alert_police = function() alerts = alerts + 1 end
complete_sale = function(_, _, id, amount)
    sales[#sales + 1] = { id = id, amount = amount }
    inventory = inventory - amount
    return true
end

dofile('server/scripts/dealing.lua')
local prepare = handlers['mz_drugselling:sv:prepare_street_sale']
local submit = handlers['mz_drugselling:sv:submit_street_offer']
local recover = handlers['mz_drugselling:sv:recover_stolen_drugs']

random_values(10000)
prepare(1)
assert(sent.name == 'mz_drugselling:cl:open_street_offer')
assert(sent.data.offers[1].optimal == 15)
submit('water', 999)
assert(sent.data.outcome == 'unavailable' and #sales == 0)

random_values(10000, 3, 5000, 10000)
prepare(2)
submit('water', 10)
assert(sent.data.outcome == 'sold' and sent.data.total == 30)
assert(#sales == 1 and sales[1].amount == 3 and xp == 25 and inventory == 7)

random_values(10000, 2, 5000, 10000)
prepare(3)
submit('water', 20)
assert(sent.data.outcome == 'refused' and #sales == 1)

random_values(10000, 1, 500, 10000)
prepare(4)
submit('water', 15)
assert(sent.data.outcome == 'stolen' and inventory == 6)
recover(4)
assert(inventory == 7)
recover(4)
assert(inventory == 7)

math.random = original_random
print('street_dealing: ok')
